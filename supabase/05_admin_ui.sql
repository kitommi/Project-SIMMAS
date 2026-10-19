-- =====================================================================
-- SIMMAS — 05_admin_ui.sql
-- Tambahan untuk redesign UI admin. Jalankan SETELAH 01 dan 02.
-- Aman dijalankan ulang.
-- =====================================================================

-- ---------- Kolom tambahan ----------
alter table public.siswa add column if not exists email text;
alter table public.guru  add column if not exists email text;
alter table public.guru  add column if not exists jurusan text;
alter table public.guru  add column if not exists is_active boolean not null default true;
alter table public.dudi  add column if not exists status text not null default 'terverifikasi'
  check (status in ('terverifikasi', 'menunggu', 'ditolak'));

-- ---------- Kunjungan guru pembimbing ----------
create table if not exists public.kunjungan_guru (
  id          uuid primary key default gen_random_uuid(),
  guru_id     uuid not null references public.guru (id) on delete cascade,
  dudi_id     uuid not null references public.dudi (id) on delete cascade,
  tanggal     date not null default current_date,
  catatan     text,
  created_at  timestamptz not null default now()
);
create index if not exists kunjungan_guru_idx on public.kunjungan_guru (guru_id, tanggal desc);
alter table public.kunjungan_guru enable row level security;
drop policy if exists kunjungan_select on public.kunjungan_guru;
drop policy if exists kunjungan_guru_write on public.kunjungan_guru;
drop policy if exists kunjungan_admin_all on public.kunjungan_guru;
create policy kunjungan_select on public.kunjungan_guru for select to authenticated
  using (public.is_admin() or guru_id = public.my_guru_id());
create policy kunjungan_guru_write on public.kunjungan_guru for insert to authenticated
  with check (guru_id = public.my_guru_id());
create policy kunjungan_admin_all on public.kunjungan_guru for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------- Pengaturan aplikasi (1 baris) ----------
create table if not exists public.app_settings (
  id               int primary key default 1 check (id = 1),
  nama_aplikasi    text not null default 'SIMMAS',
  deskripsi        text not null default 'Sistem Informasi Manajemen Magang Siswa',
  hero_judul       text not null default 'Magang lebih teratur.',
  hero_subjudul    text not null default 'Platform manajemen magang siswa SMK yang menghubungkan sekolah, guru pembimbing, dan dunia usaha.',
  kontak_email     text,
  kontak_telepon   text,
  nama_sekolah     text,
  kepala_sekolah   text,
  nip_kepsek       text,
  alamat_sekolah   text,
  telp_sekolah     text,
  updated_at       timestamptz not null default now()
);
insert into public.app_settings (id) values (1) on conflict (id) do nothing;
drop trigger if exists trg_app_settings_updated_at on public.app_settings;
create trigger trg_app_settings_updated_at before update on public.app_settings
  for each row execute function public.set_updated_at();
alter table public.app_settings enable row level security;
drop policy if exists app_settings_read on public.app_settings;
drop policy if exists app_settings_admin_write on public.app_settings;
-- Boleh dibaca publik (dipakai landing page); hanya admin yang menulis.
create policy app_settings_read on public.app_settings for select to anon, authenticated using (true);
create policy app_settings_admin_write on public.app_settings for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
grant select on public.app_settings to anon;

-- ---------- Log aktivitas ----------
create table if not exists public.activity_logs (
  id           bigint generated always as identity primary key,
  created_at   timestamptz not null default now(),
  level        text not null default 'INFO' check (level in ('INFO', 'WARN', 'ERROR')),
  aksi         text not null,
  modul        text not null default 'AUTH',
  actor_id     uuid,
  actor_email  text,
  actor_role   text,
  ip           text,
  metadata     jsonb not null default '{}'::jsonb
);
create index if not exists activity_logs_time_idx on public.activity_logs (created_at desc);
create index if not exists activity_logs_level_idx on public.activity_logs (level);
alter table public.activity_logs enable row level security;
drop policy if exists activity_logs_admin_select on public.activity_logs;
create policy activity_logs_admin_select on public.activity_logs for select to authenticated
  using (public.is_admin());

-- Dipanggil dari Flutter setelah login: supabase.rpc('log_activity', ...)
create or replace function public.log_activity(
  p_aksi text,
  p_level text default 'INFO',
  p_modul text default 'AUTH',
  p_metadata jsonb default '{}'::jsonb
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
  v_role  text;
  v_ip    text;
begin
  if auth.uid() is null then return; end if;
  select email, role into v_email, v_role from public.profiles where id = auth.uid();
  begin
    v_ip := split_part(coalesce(current_setting('request.headers', true)::json ->> 'x-forwarded-for', ''), ',', 1);
  exception when others then
    v_ip := null;
  end;
  insert into public.activity_logs (level, aksi, modul, actor_id, actor_email, actor_role, ip, metadata)
  values (
    case when upper(p_level) in ('INFO', 'WARN', 'ERROR') then upper(p_level) else 'INFO' end,
    p_aksi, p_modul, auth.uid(), v_email, v_role, nullif(trim(v_ip), ''),
    coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;

create or replace function public.clear_activity_logs()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Hanya admin yang boleh membersihkan log.' using errcode = '42501';
  end if;
  delete from public.activity_logs where true;
end;
$$;

revoke all on function public.log_activity(text, text, text, jsonb) from public, anon;
revoke all on function public.clear_activity_logs() from public, anon;
grant execute on function public.log_activity(text, text, text, jsonb) to authenticated;
grant execute on function public.clear_activity_logs() to authenticated;

-- ---------- View untuk halaman admin (mengikuti RLS pemanggil) ----------
drop view if exists public.v_dashboard_stats;
create view public.v_dashboard_stats with (security_invoker = true) as
select
  (select count(*) from public.siswa)                                        as total_siswa,
  (select count(*) from public.guru)                                         as total_guru,
  (select count(*) from public.dudi where is_active)                         as total_dudi,
  (select count(*) from public.permohonan_magang where status = 'menunggu')  as permohonan_menunggu,
  (select count(*) from public.permohonan_magang where status = 'disetujui') as permohonan_disetujui,
  (select count(*) from public.permohonan_magang where status = 'ditolak')   as permohonan_ditolak,
  (select count(*) from public.penempatan where status = 'aktif')            as penempatan_aktif;

create or replace view public.v_trend_pengajuan with (security_invoker = true) as
select
  m::date as bulan,
  (select count(*) from public.permohonan_magang
     where date_trunc('month', diajukan_at) = m) as pengajuan,
  (select count(*) from public.permohonan_magang
     where status = 'disetujui' and date_trunc('month', diajukan_at) = m) as disetujui
from generate_series(
  date_trunc('month', now()) - interval '5 months',
  date_trunc('month', now()),
  interval '1 month'
) as m;

create or replace view public.v_siswa_list with (security_invoker = true) as
select
  s.id, s.nis, s.nama,
  coalesce(s.email, pr.email) as email,
  k.nama as kelas,
  s.is_active,
  case when pa.status = 'aktif' then 'sedang_magang'
       when pa.status = 'selesai' then 'lulus'
       else 'belum_magang' end as status_magang,
  d.nama as industri,
  g.nama as pembimbing
from public.siswa s
left join public.profiles pr on pr.id = s.profile_id
left join public.kelas k on k.id = s.kelas_id
left join lateral (
  select p.* from public.penempatan p
  where p.siswa_id = s.id and p.status in ('aktif', 'selesai')
  order by case p.status when 'aktif' then 0 else 1 end, p.created_at desc
  limit 1
) pa on true
left join public.dudi d on d.id = pa.dudi_id
left join public.guru g on g.id = pa.guru_id;

create or replace view public.v_guru_list with (security_invoker = true) as
select
  g.id, g.nip, g.nama,
  coalesce(g.email, pr.email) as email,
  g.jurusan, g.is_active,
  (select count(*) from public.penempatan p
     where p.guru_id = g.id and p.status = 'aktif') as bimbingan
from public.guru g
left join public.profiles pr on pr.id = g.profile_id;

create or replace view public.v_dudi_list with (security_invoker = true) as
select
  d.id, d.nama, d.alamat, d.kota, d.bidang_usaha,
  d.kontak_nama, d.kontak_telepon, d.kuota, d.status, d.is_active,
  (select count(*) from public.penempatan p
     where p.dudi_id = d.id and p.status = 'aktif') as siswa_aktif
from public.dudi d;

create or replace view public.v_penempatan_detail with (security_invoker = true) as
select
  pn.id, pn.status, pn.tanggal_mulai, pn.tanggal_selesai, pn.created_at,
  pn.siswa_id, pn.dudi_id, pn.guru_id,
  s.nama as siswa, s.nis, k.nama as kelas,
  d.nama as dudi, g.nama as pembimbing
from public.penempatan pn
join public.siswa s on s.id = pn.siswa_id
left join public.kelas k on k.id = s.kelas_id
join public.dudi d on d.id = pn.dudi_id
left join public.guru g on g.id = pn.guru_id;

create or replace view public.v_pengajuan_menunggu with (security_invoker = true) as
select
  pm.id, pm.diajukan_at,
  s.nama as siswa, s.nis, k.nama as kelas,
  d.nama as dudi,
  concat_ws(', ', d.alamat, d.kota) as lokasi,
  d.kontak_nama as pic
from public.permohonan_magang pm
join public.siswa s on s.id = pm.siswa_id
left join public.kelas k on k.id = s.kelas_id
join public.dudi d on d.id = pm.dudi_id
where pm.status = 'menunggu'
order by pm.diajukan_at;

create or replace view public.v_monitoring with (security_invoker = true) as
select
  pn.id,
  s.nama as siswa, k.nama as kelas,
  d.nama as dudi, g.nama as pembimbing,
  coalesce(h.hadir, 0) as hadir, coalesce(h.sakit, 0) as sakit,
  coalesce(h.izin, 0)  as izin,  coalesce(h.alpa, 0)  as alpa,
  coalesce(j.total, 0) as jurnal, coalesce(j.minggu, 0) as jurnal_minggu,
  case when coalesce(h.alpa, 0) >= 3 then 'bermasalah'
       when coalesce(h.alpa, 0) >= 1
         or coalesce(h.sakit, 0) + coalesce(h.izin, 0) >= 3 then 'perlu_perhatian'
       else 'normal' end as status,
  greatest(h.last_at, j.last_at) as aktivitas_terakhir
from public.penempatan pn
join public.siswa s on s.id = pn.siswa_id
left join public.kelas k on k.id = s.kelas_id
join public.dudi d on d.id = pn.dudi_id
left join public.guru g on g.id = pn.guru_id
left join lateral (
  select count(*) filter (where kh.status = 'hadir') as hadir,
         count(*) filter (where kh.status = 'sakit') as sakit,
         count(*) filter (where kh.status = 'izin')  as izin,
         count(*) filter (where kh.status = 'alpa')  as alpa,
         max(kh.updated_at) as last_at
  from public.kehadiran kh where kh.penempatan_id = pn.id
) h on true
left join lateral (
  select count(*) as total,
         count(*) filter (where jr.tanggal >= date_trunc('week', current_date)) as minggu,
         max(jr.updated_at) as last_at
  from public.jurnal jr where jr.penempatan_id = pn.id
) j on true
where pn.status = 'aktif';

create or replace view public.v_kunjungan_detail with (security_invoker = true) as
select kg.id, kg.tanggal, kg.catatan, g.nama as guru, d.nama as dudi
from public.kunjungan_guru kg
join public.guru g on g.id = kg.guru_id
join public.dudi d on d.id = kg.dudi_id;

do $$
declare v text;
begin
  foreach v in array array[
    'v_dashboard_stats', 'v_trend_pengajuan', 'v_siswa_list', 'v_guru_list',
    'v_dudi_list', 'v_penempatan_detail', 'v_pengajuan_menunggu',
    'v_monitoring', 'v_kunjungan_detail'
  ] loop
    execute format('revoke all on public.%I from anon', v);
    execute format('grant select on public.%I to authenticated', v);
  end loop;
end $$;

-- Realtime untuk log & notifikasi
do $$
begin
  begin alter publication supabase_realtime add table public.activity_logs;
  exception when duplicate_object then null; end;
end $$;

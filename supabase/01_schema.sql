-- =====================================================================
-- SIMMAS — 01_schema.sql
-- Tabel, index, trigger, view, realtime. Jalankan PERTAMA di
-- Supabase Dashboard > SQL Editor. Aman dijalankan ulang (idempotent).
-- =====================================================================

-- ---------- Util: updated_at otomatis ----------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------- profiles (1:1 dengan auth.users) ----------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  nama        text not null default '',
  email       text,
  role        text not null default 'siswa'
              check (role in ('siswa', 'guru', 'admin')),
  telepon     text,
  avatar_url  text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
-- Bila tabel `profiles` sudah ada dari versi lama (id, nama, role), tambahkan kolom baru:
alter table public.profiles add column if not exists email       text;
alter table public.profiles add column if not exists telepon     text;
alter table public.profiles add column if not exists avatar_url  text;
alter table public.profiles add column if not exists is_active   boolean not null default true;
alter table public.profiles add column if not exists created_at  timestamptz not null default now();
alter table public.profiles add column if not exists updated_at  timestamptz not null default now();
create index if not exists profiles_role_idx on public.profiles (role);
create index if not exists profiles_email_idx on public.profiles (lower(email));

-- ---------- Master data ----------
create table if not exists public.kelas (
  id          uuid primary key default gen_random_uuid(),
  nama        text not null unique,            -- mis. 'AK1'
  jurusan     text,
  angkatan    int,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.periode_magang (
  id               uuid primary key default gen_random_uuid(),
  nama             text not null,               -- mis. 'PKL 2026/2027'
  tanggal_mulai    date not null,
  tanggal_selesai  date not null,
  is_active        boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  check (tanggal_selesai >= tanggal_mulai)
);
-- Hanya satu periode yang boleh aktif.
create unique index if not exists periode_magang_one_active
  on public.periode_magang (is_active) where is_active;

-- Data guru/siswa boleh ada SEBELUM akun login dibuat (profile_id nullable).
create table if not exists public.guru (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid unique references public.profiles (id) on delete set null,
  nip         text unique,
  nama        text not null,
  telepon     text,
  bidang      text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.siswa (
  id             uuid primary key default gen_random_uuid(),
  profile_id     uuid unique references public.profiles (id) on delete set null,
  nis            text not null unique,
  nama           text not null,
  kelas_id       uuid references public.kelas (id) on delete set null,
  jenis_kelamin  text check (jenis_kelamin in ('L', 'P')),
  telepon        text,
  alamat         text,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index if not exists siswa_kelas_idx on public.siswa (kelas_id);

create table if not exists public.dudi (
  id              uuid primary key default gen_random_uuid(),
  nama            text not null,
  alamat          text,
  kota            text,
  bidang_usaha    text,
  kontak_nama     text,
  kontak_telepon  text,
  kontak_email    text,
  kuota           int not null default 0 check (kuota >= 0),
  latitude        double precision,             -- validasi lokasi absensi
  longitude       double precision,
  radius_meter    int not null default 200 check (radius_meter > 0),
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists dudi_active_idx on public.dudi (is_active);
create index if not exists dudi_nama_idx on public.dudi (lower(nama));

-- ---------- Alur magang ----------
create table if not exists public.permohonan_magang (
  id           uuid primary key default gen_random_uuid(),
  siswa_id     uuid not null references public.siswa (id) on delete cascade,
  dudi_id      uuid not null references public.dudi (id) on delete restrict,
  periode_id   uuid not null references public.periode_magang (id) on delete restrict,
  status       text not null default 'menunggu'
               check (status in ('menunggu', 'disetujui', 'ditolak')),
  catatan      text,
  diajukan_at  timestamptz not null default now(),
  diproses_by  uuid references public.profiles (id) on delete set null,
  diproses_at  timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (siswa_id, dudi_id, periode_id)
);
create index if not exists permohonan_status_idx  on public.permohonan_magang (status);
create index if not exists permohonan_siswa_idx   on public.permohonan_magang (siswa_id);
create index if not exists permohonan_dudi_idx    on public.permohonan_magang (dudi_id);
create index if not exists permohonan_diajukan_idx on public.permohonan_magang (diajukan_at desc);

create table if not exists public.penempatan (
  id                   uuid primary key default gen_random_uuid(),
  siswa_id             uuid not null references public.siswa (id) on delete cascade,
  dudi_id              uuid not null references public.dudi (id) on delete restrict,
  guru_id              uuid references public.guru (id) on delete set null,   -- pembimbing
  periode_id           uuid not null references public.periode_magang (id) on delete restrict,
  permohonan_id        uuid references public.permohonan_magang (id) on delete set null,
  tanggal_mulai        date not null,
  tanggal_selesai      date not null,
  status               text not null default 'aktif'
                       check (status in ('aktif', 'selesai', 'dibatalkan')),
  nomor_surat          text,
  surat_pengantar_path text,                    -- path di bucket 'surat-pengantar'
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  unique (siswa_id, periode_id),
  check (tanggal_selesai >= tanggal_mulai)
);
create index if not exists penempatan_guru_idx   on public.penempatan (guru_id);
create index if not exists penempatan_dudi_idx   on public.penempatan (dudi_id, periode_id, status);
create index if not exists penempatan_status_idx on public.penempatan (status);

create table if not exists public.jurnal (
  id             uuid primary key default gen_random_uuid(),
  penempatan_id  uuid not null references public.penempatan (id) on delete cascade,
  tanggal        date not null default current_date,
  kegiatan       text not null,
  kendala        text,
  status         text not null default 'menunggu'
                 check (status in ('menunggu', 'disetujui', 'ditolak')),
  catatan_guru   text,
  approved_by    uuid references public.profiles (id) on delete set null,
  approved_at    timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (penempatan_id, tanggal)
);
create index if not exists jurnal_penempatan_idx on public.jurnal (penempatan_id, tanggal desc);
create index if not exists jurnal_status_idx     on public.jurnal (status);

create table if not exists public.kehadiran (
  id             uuid primary key default gen_random_uuid(),
  penempatan_id  uuid not null references public.penempatan (id) on delete cascade,
  tanggal        date not null default current_date,
  jam_masuk      timestamptz,
  jam_keluar     timestamptz,
  status         text not null default 'hadir'
                 check (status in ('hadir', 'izin', 'sakit', 'alpa')),
  latitude       double precision,
  longitude      double precision,
  keterangan     text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (penempatan_id, tanggal)
);
create index if not exists kehadiran_penempatan_idx on public.kehadiran (penempatan_id, tanggal desc);

-- ---------- Notifikasi & audit ----------
create table if not exists public.notifikasi (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  judul       text not null,
  isi         text,
  tautan      text,
  is_read     boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists notifikasi_user_idx
  on public.notifikasi (user_id, is_read, created_at desc);

create table if not exists public.audit_logs (
  id         bigint generated always as identity primary key,
  actor_id   uuid,
  aksi       text not null,                     -- INSERT | UPDATE | DELETE
  tabel      text not null,
  record_id  text,
  data_lama  jsonb,
  data_baru  jsonb,
  created_at timestamptz not null default now()
);
create index if not exists audit_logs_tabel_idx on public.audit_logs (tabel, created_at desc);
create index if not exists audit_logs_actor_idx on public.audit_logs (actor_id);

-- ---------- Trigger updated_at ----------
do $$
declare t text;
begin
  foreach t in array array[
    'profiles', 'kelas', 'periode_magang', 'guru', 'siswa', 'dudi',
    'permohonan_magang', 'penempatan', 'jurnal', 'kehadiran'
  ] loop
    execute format('drop trigger if exists trg_%1$s_updated_at on public.%1$I', t);
    execute format(
      'create trigger trg_%1$s_updated_at before update on public.%1$I
         for each row execute function public.set_updated_at()', t);
  end loop;
end $$;

-- ---------- Sinkronisasi auth.users -> profiles ----------
-- PENTING: role SELALU 'siswa' saat akun baru. raw_user_meta_data dikirim oleh
-- klien sehingga TIDAK boleh dipercaya untuk menentukan role. Admin yang
-- menaikkan role lewat dashboard / SQL.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, nama, role)
  values (
    new.id,
    new.email,
    coalesce(nullif(new.raw_user_meta_data ->> 'nama', ''), split_part(new.email, '@', 1)),
    'siswa'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.handle_user_email_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles set email = new.email where id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_email_changed on auth.users;
create trigger on_auth_user_email_changed
  after update of email on auth.users
  for each row when (old.email is distinct from new.email)
  execute function public.handle_user_email_change();

-- Backfill: user lama di auth.users yang belum punya profile.
insert into public.profiles (id, email, nama, role)
select u.id, u.email, split_part(u.email, '@', 1), 'siswa'
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id);

-- ---------- Fungsi bantu untuk RLS (SECURITY DEFINER = tanpa rekursi RLS) ----------
create or replace function public.get_my_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid() and is_active
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.get_my_role() = 'admin', false)
$$;

create or replace function public.is_guru()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.get_my_role() = 'guru', false)
$$;

create or replace function public.my_siswa_id()
returns uuid language sql stable security definer set search_path = public as $$
  select id from public.siswa where profile_id = auth.uid() limit 1
$$;

create or replace function public.my_guru_id()
returns uuid language sql stable security definer set search_path = public as $$
  select id from public.guru where profile_id = auth.uid() limit 1
$$;

create or replace function public.is_my_penempatan(pid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.penempatan p
    where p.id = pid and p.siswa_id = public.my_siswa_id()
  )
$$;

create or replace function public.is_supervised_penempatan(pid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.penempatan p
    where p.id = pid and p.guru_id is not null and p.guru_id = public.my_guru_id()
  )
$$;

create or replace function public.is_supervised_siswa(sid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.penempatan p
    where p.siswa_id = sid and p.guru_id is not null and p.guru_id = public.my_guru_id()
  )
$$;

create or replace function public.is_my_guru(gid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.penempatan p
    where p.guru_id = gid and p.siswa_id = public.my_siswa_id()
  )
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'get_my_role()', 'is_admin()', 'is_guru()', 'my_siswa_id()', 'my_guru_id()',
    'is_my_penempatan(uuid)', 'is_supervised_penempatan(uuid)',
    'is_supervised_siswa(uuid)', 'is_my_guru(uuid)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

-- ---------- Guard: user biasa tidak boleh menaikkan role-nya sendiri ----------
create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- auth.uid() null = service_role / SQL Editor -> diizinkan.
  if auth.uid() is not null and not public.is_admin() then
    if new.role is distinct from old.role
       or new.is_active is distinct from old.is_active
       or new.id is distinct from old.id then
      raise exception 'Tidak diizinkan mengubah role atau status akun.' using errcode = '42501';
    end if;
    new.email := old.email; -- email dikelola lewat auth
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_guard on public.profiles;
create trigger trg_profiles_guard
  before update on public.profiles
  for each row execute function public.guard_profile_update();

-- ---------- Alur permohonan: validasi, kuota, penempatan otomatis ----------
create or replace function public.permohonan_before_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_kuota  int;
  v_terisi int;
begin
  if auth.uid() is not null and not public.is_admin() then
    -- Siswa pemilik tidak boleh memalsukan data pemrosesan.
    new.diproses_by := old.diproses_by;
    new.diproses_at := old.diproses_at;
  end if;

  if new.status is distinct from old.status then
    if new.status in ('disetujui', 'ditolak') then
      new.diproses_by := auth.uid();
      new.diproses_at := now();
    end if;

    if new.status = 'disetujui' then
      if exists (
        select 1 from public.penempatan
        where siswa_id = new.siswa_id and periode_id = new.periode_id
          and status <> 'dibatalkan'
      ) then
        raise exception 'Siswa sudah memiliki penempatan pada periode ini.';
      end if;

      select kuota into v_kuota from public.dudi where id = new.dudi_id;
      select count(*) into v_terisi from public.penempatan
        where dudi_id = new.dudi_id and periode_id = new.periode_id and status = 'aktif';
      if v_terisi >= coalesce(v_kuota, 0) then
        raise exception 'Kuota penempatan DUDI sudah penuh.';
      end if;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_permohonan_before_update on public.permohonan_magang;
create trigger trg_permohonan_before_update
  before update on public.permohonan_magang
  for each row execute function public.permohonan_before_update();

create or replace function public.permohonan_after_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mulai   date;
  v_selesai date;
begin
  if new.status = 'disetujui' and old.status is distinct from 'disetujui' then
    select tanggal_mulai, tanggal_selesai into v_mulai, v_selesai
      from public.periode_magang where id = new.periode_id;

    insert into public.penempatan
      (siswa_id, dudi_id, periode_id, permohonan_id, tanggal_mulai, tanggal_selesai)
    values
      (new.siswa_id, new.dudi_id, new.periode_id, new.id, v_mulai, v_selesai)
    on conflict (siswa_id, periode_id) do nothing;

    insert into public.notifikasi (user_id, judul, isi, tautan)
    select s.profile_id, 'Permohonan disetujui',
           'Permohonan magang Anda telah disetujui.', '/siswa/dashboard'
    from public.siswa s
    where s.id = new.siswa_id and s.profile_id is not null;

  elsif new.status = 'ditolak' and old.status is distinct from 'ditolak' then
    insert into public.notifikasi (user_id, judul, isi, tautan)
    select s.profile_id, 'Permohonan ditolak',
           coalesce(new.catatan, 'Permohonan magang Anda ditolak.'), '/siswa/permohonan'
    from public.siswa s
    where s.id = new.siswa_id and s.profile_id is not null;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_permohonan_after_update on public.permohonan_magang;
create trigger trg_permohonan_after_update
  after update on public.permohonan_magang
  for each row execute function public.permohonan_after_update();

-- ---------- Jurnal: siapa boleh mengubah apa + notifikasi guru ----------
create or replace function public.jurnal_before_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or public.is_admin() then
    return new;
  end if;

  if public.is_supervised_penempatan(old.penempatan_id) then
    -- Guru: hanya boleh memutuskan status + catatan.
    new.penempatan_id := old.penempatan_id;
    new.tanggal       := old.tanggal;
    new.kegiatan      := old.kegiatan;
    new.kendala       := old.kendala;
    if new.status is distinct from old.status then
      new.approved_by := auth.uid();
      new.approved_at := now();
    end if;
  else
    -- Siswa pemilik: boleh revisi isi, status kembali 'menunggu'.
    new.penempatan_id := old.penempatan_id;
    new.status        := 'menunggu';
    new.catatan_guru  := old.catatan_guru;
    new.approved_by   := null;
    new.approved_at   := null;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_jurnal_before_update on public.jurnal;
create trigger trg_jurnal_before_update
  before update on public.jurnal
  for each row execute function public.jurnal_before_update();

create or replace function public.jurnal_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifikasi (user_id, judul, isi, tautan)
  select g.profile_id, 'Jurnal baru',
         'Ada jurnal baru dari ' || s.nama || ' menunggu persetujuan.', '/guru/jurnal'
  from public.penempatan p
  join public.siswa s on s.id = p.siswa_id
  join public.guru  g on g.id = p.guru_id
  where p.id = new.penempatan_id and g.profile_id is not null;
  return null;
end;
$$;

drop trigger if exists trg_jurnal_after_insert on public.jurnal;
create trigger trg_jurnal_after_insert
  after insert on public.jurnal
  for each row execute function public.jurnal_after_insert();

-- ---------- Kehadiran: validasi radius lokasi magang ----------
create or replace function public.haversine_m(
  lat1 double precision, lon1 double precision,
  lat2 double precision, lon2 double precision)
returns double precision
language sql immutable as $$
  select 2 * 6371000 * asin(sqrt(
    power(sin(radians(lat2 - lat1) / 2), 2) +
    cos(radians(lat1)) * cos(radians(lat2)) * power(sin(radians(lon2 - lon1) / 2), 2)
  ))
$$;

create or replace function public.kehadiran_validate()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  d record;
begin
  if auth.uid() is null or public.is_admin() or new.status <> 'hadir' then
    return new;
  end if;

  select du.latitude, du.longitude, du.radius_meter into d
  from public.penempatan p
  join public.dudi du on du.id = p.dudi_id
  where p.id = new.penempatan_id;

  -- DUDI belum punya koordinat -> validasi lokasi dilewati.
  if d.latitude is null or d.longitude is null then
    return new;
  end if;
  if new.latitude is null or new.longitude is null then
    raise exception 'Lokasi wajib disertakan untuk absen hadir.';
  end if;
  if public.haversine_m(new.latitude, new.longitude, d.latitude, d.longitude)
       > coalesce(d.radius_meter, 200) then
    raise exception 'Anda berada di luar radius lokasi magang.';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_kehadiran_validate on public.kehadiran;
create trigger trg_kehadiran_validate
  before insert or update on public.kehadiran
  for each row execute function public.kehadiran_validate();

-- ---------- Audit log ----------
create or replace function public.log_audit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.audit_logs (actor_id, aksi, tabel, record_id, data_lama, data_baru)
  values (
    auth.uid(), tg_op, tg_table_name,
    coalesce(to_jsonb(new) ->> 'id', to_jsonb(old) ->> 'id'),
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end
  );
  return null;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array[
    'profiles', 'siswa', 'guru', 'dudi', 'permohonan_magang', 'penempatan'
  ] loop
    execute format('drop trigger if exists trg_%1$s_audit on public.%1$I', t);
    execute format(
      'create trigger trg_%1$s_audit after insert or update or delete on public.%1$I
         for each row execute function public.log_audit()', t);
  end loop;
end $$;

-- ---------- View untuk dashboard (mengikuti RLS pemanggil) ----------
create or replace view public.v_dashboard_stats
with (security_invoker = true) as
select
  (select count(*) from public.siswa)                                   as total_siswa,
  (select count(*) from public.guru)                                    as total_guru,
  (select count(*) from public.dudi where is_active)                    as total_dudi,
  (select count(*) from public.permohonan_magang where status = 'menunggu') as permohonan_menunggu,
  (select count(*) from public.penempatan where status = 'aktif')       as penempatan_aktif;

create or replace view public.v_permohonan_detail
with (security_invoker = true) as
select
  pm.id,
  pm.status,
  pm.catatan,
  pm.diajukan_at,
  pm.siswa_id,
  pm.dudi_id,
  pm.periode_id,
  s.nama  as nama_siswa,
  k.nama  as kelas,
  d.nama  as perusahaan
from public.permohonan_magang pm
join public.siswa s on s.id = pm.siswa_id
left join public.kelas k on k.id = s.kelas_id
join public.dudi d on d.id = pm.dudi_id;

revoke all on public.v_dashboard_stats, public.v_permohonan_detail from anon;
grant select on public.v_dashboard_stats, public.v_permohonan_detail to authenticated;

-- ---------- Realtime ----------
do $$
declare t text;
begin
  foreach t in array array['permohonan_magang', 'jurnal', 'notifikasi'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;

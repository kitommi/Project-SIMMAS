-- =====================================================================
-- SIMMAS — 07_siswa_ui.sql
-- Panel Peserta Magang: absensi (foto, Alfa otomatis), jurnal (foto),
-- pengajuan (posisi). Jalankan setelah 05 dan 06. Aman dijalankan ulang.
-- =====================================================================

-- Tanggal "hari ini" mengikuti WIB (server Supabase memakai UTC).
create or replace function public.today_wib()
returns date language sql stable as $$
  select (now() at time zone 'Asia/Jakarta')::date
$$;
grant execute on function public.today_wib() to authenticated;

-- ---------- Kolom tambahan ----------
alter table public.permohonan_magang add column if not exists posisi text;
alter table public.kehadiran add column if not exists foto_masuk_path  text;
alter table public.kehadiran add column if not exists foto_pulang_path text;
alter table public.kehadiran add column if not exists auto_alfa boolean not null default false;

-- ---------- Policy kehadiran: batas "hari ini" memakai WIB ----------
drop policy if exists kehadiran_insert_own on public.kehadiran;
drop policy if exists kehadiran_update_own on public.kehadiran;
create policy kehadiran_insert_own on public.kehadiran
  for insert to authenticated
  with check (public.is_my_penempatan(penempatan_id) and tanggal = public.today_wib());
create policy kehadiran_update_own on public.kehadiran
  for update to authenticated
  using      (public.is_my_penempatan(penempatan_id) and tanggal = public.today_wib())
  with check (public.is_my_penempatan(penempatan_id) and tanggal = public.today_wib());

-- ---------- Jurnal: hapus boleh untuk 'menunggu' dan 'ditolak' ----------
drop policy if exists jurnal_delete on public.jurnal;
create policy jurnal_delete on public.jurnal
  for delete to authenticated
  using (public.is_my_penempatan(penempatan_id) and status in ('menunggu', 'ditolak'));

-- ---------- Cap waktu SERVER untuk Clock In / Clock Out ----------
-- Jam masuk/pulang tidak dipercaya dari klien.
create or replace function public.kehadiran_stamp()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Lewati untuk admin/service_role dan untuk pembuatan Alfa otomatis.
  if auth.uid() is null
     or public.is_admin()
     or current_setting('simmas.auto_alfa', true) = '1' then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.tanggal    := public.today_wib();
    new.auto_alfa  := false;
    new.jam_keluar := null;
    new.jam_masuk  := case when new.status in ('hadir', 'izin', 'sakit') then now() end;
  else
    new.penempatan_id := old.penempatan_id;
    new.tanggal       := old.tanggal;
    new.status        := old.status;
    new.auto_alfa     := old.auto_alfa;
    new.jam_masuk     := old.jam_masuk;
    if new.jam_keluar is not null and old.jam_keluar is null and old.status = 'hadir' then
      new.jam_keluar := now();
    else
      new.jam_keluar := old.jam_keluar;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_kehadiran_stamp on public.kehadiran;
create trigger trg_kehadiran_stamp
  before insert or update on public.kehadiran
  for each row execute function public.kehadiran_stamp();

-- ---------- Alfa otomatis ----------
-- Hari kerja (Senin-Jumat) sebelum hari ini tanpa catatan kehadiran => 'alpa'.
-- Hari libur nasional BELUM dikecualikan.
create or replace function public._insert_auto_alfa(p_siswa uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  perform set_config('simmas.auto_alfa', '1', true);
  with ins as (
    insert into public.kehadiran (penempatan_id, tanggal, status, keterangan, auto_alfa)
    select p.id, d::date, 'alpa', 'Tidak melakukan absensi (Otomatis Alfa)', true
    from public.penempatan p
    cross join lateral generate_series(
      greatest(p.tanggal_mulai, public.today_wib() - 60),
      least(p.tanggal_selesai, public.today_wib() - 1),
      interval '1 day'
    ) as d
    where p.status = 'aktif'
      and (p_siswa is null or p.siswa_id = p_siswa)
      and extract(isodow from d) between 1 and 5
      and not exists (
        select 1 from public.kehadiran k
        where k.penempatan_id = p.id and k.tanggal = d::date
      )
    on conflict (penempatan_id, tanggal) do nothing
    returning 1
  )
  select count(*) into v_count from ins;
  perform set_config('simmas.auto_alfa', '0', true);
  return v_count;
end;
$$;

-- Dipanggil aplikasi saat siswa membuka halaman Absensi.
create or replace function public.sync_my_alfa()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sid uuid := public.my_siswa_id();
begin
  if v_sid is null then return 0; end if;
  return public._insert_auto_alfa(v_sid);
end;
$$;

-- Untuk penjadwalan harian (semua siswa). Tidak dapat dipanggil dari aplikasi.
create or replace function public.generate_auto_alfa()
returns int
language sql
security definer
set search_path = public
as $$
  select public._insert_auto_alfa(null)
$$;

revoke all on function public._insert_auto_alfa(uuid) from public, anon, authenticated;
revoke all on function public.generate_auto_alfa() from public, anon, authenticated;
revoke all on function public.sync_my_alfa() from public, anon;
grant execute on function public.sync_my_alfa() to authenticated;

-- OPSIONAL (jadwal otomatis tiap malam, butuh ekstensi pg_cron):
--   create extension if not exists pg_cron;
--   select cron.schedule('simmas-auto-alfa', '5 17 * * *',
--                        $$select public.generate_auto_alfa()$$);   -- 00:05 WIB

-- ---------- Storage: foto absensi & foto jurnal (privat) ----------
-- Path: {siswa_id}/nama-file.jpg
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('absensi-foto', 'absensi-foto', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('jurnal-foto',  'jurnal-foto',  false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

do $$
declare
  b text;
begin
  foreach b in array array['absensi-foto', 'jurnal-foto'] loop
    execute format('drop policy if exists %I on storage.objects', b || '_siswa_insert');
    execute format('drop policy if exists %I on storage.objects', b || '_siswa_select');
    execute format('drop policy if exists %I on storage.objects', b || '_siswa_delete');
    execute format('drop policy if exists %I on storage.objects', b || '_guru_select');
    execute format('drop policy if exists %I on storage.objects', b || '_admin_all');

    execute format($f$create policy %I on storage.objects for insert to authenticated
      with check (bucket_id = %L and (storage.foldername(name))[1] = public.my_siswa_id()::text)$f$,
      b || '_siswa_insert', b);
    execute format($f$create policy %I on storage.objects for select to authenticated
      using (bucket_id = %L and (storage.foldername(name))[1] = public.my_siswa_id()::text)$f$,
      b || '_siswa_select', b);
    execute format($f$create policy %I on storage.objects for delete to authenticated
      using (bucket_id = %L and (storage.foldername(name))[1] = public.my_siswa_id()::text)$f$,
      b || '_siswa_delete', b);
    execute format($f$create policy %I on storage.objects for select to authenticated
      using (bucket_id = %L and public.is_guru() and
        case when (storage.foldername(name))[1] ~ '^[0-9a-fA-F-]{36}$'
             then public.is_supervised_siswa(((storage.foldername(name))[1])::uuid)
             else false end)$f$,
      b || '_guru_select', b);
    execute format($f$create policy %I on storage.objects for all to authenticated
      using (bucket_id = %L and public.is_admin())
      with check (bucket_id = %L and public.is_admin())$f$,
      b || '_admin_all', b, b);
  end loop;
end $$;

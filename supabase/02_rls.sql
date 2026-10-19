-- =====================================================================
-- SIMMAS — 02_rls.sql
-- Row Level Security. Jalankan SETELAH 01_schema.sql.
-- Prinsip: deny-by-default. Tidak ada policy untuk `anon` => anon tidak
-- bisa membaca/menulis apa pun. `(select auth.uid())` dipakai agar
-- dievaluasi sekali per query (lebih cepat).
-- =====================================================================

alter table public.profiles          enable row level security;
alter table public.kelas             enable row level security;
alter table public.periode_magang    enable row level security;
alter table public.guru              enable row level security;
alter table public.siswa             enable row level security;
alter table public.dudi              enable row level security;
alter table public.permohonan_magang enable row level security;
alter table public.penempatan        enable row level security;
alter table public.jurnal            enable row level security;
alter table public.kehadiran         enable row level security;
alter table public.notifikasi        enable row level security;
alter table public.audit_logs        enable row level security;

-- ---------------------------------------------------------------- profiles
drop policy if exists profiles_select      on public.profiles;
drop policy if exists profiles_update_own  on public.profiles;
drop policy if exists profiles_admin_all   on public.profiles;

create policy profiles_select on public.profiles
  for select to authenticated
  using (
    id = (select auth.uid())
    or public.is_admin()
    or (public.is_guru() and role = 'siswa')
  );

-- Role/is_active dilindungi trigger trg_profiles_guard.
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy profiles_admin_all on public.profiles
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ------------------------------------------- kelas, periode_magang, dudi
-- Semua user login boleh membaca; hanya admin yang boleh menulis.
do $$
declare t text;
begin
  foreach t in array array['kelas', 'periode_magang', 'dudi'] loop
    execute format('drop policy if exists %1$s_select on public.%1$I', t);
    execute format('drop policy if exists %1$s_admin_write on public.%1$I', t);
    execute format(
      'create policy %1$s_select on public.%1$I for select to authenticated using (true)', t);
    execute format(
      'create policy %1$s_admin_write on public.%1$I for all to authenticated
         using (public.is_admin()) with check (public.is_admin())', t);
  end loop;
end $$;

-- -------------------------------------------------------------------- guru
drop policy if exists guru_select      on public.guru;
drop policy if exists guru_admin_write on public.guru;

create policy guru_select on public.guru
  for select to authenticated
  using (
    public.is_admin()
    or profile_id = (select auth.uid())
    or public.is_my_guru(id)            -- siswa melihat pembimbingnya
  );
create policy guru_admin_write on public.guru
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ------------------------------------------------------------------- siswa
drop policy if exists siswa_select      on public.siswa;
drop policy if exists siswa_admin_write on public.siswa;

create policy siswa_select on public.siswa
  for select to authenticated
  using (
    public.is_admin()
    or profile_id = (select auth.uid())
    or (public.is_guru() and public.is_supervised_siswa(id))
  );
create policy siswa_admin_write on public.siswa
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- -------------------------------------------------------- permohonan_magang
drop policy if exists permohonan_select       on public.permohonan_magang;
drop policy if exists permohonan_insert_own   on public.permohonan_magang;
drop policy if exists permohonan_update_own   on public.permohonan_magang;
drop policy if exists permohonan_delete_own   on public.permohonan_magang;
drop policy if exists permohonan_admin_all    on public.permohonan_magang;

create policy permohonan_select on public.permohonan_magang
  for select to authenticated
  using (public.is_admin() or siswa_id = public.my_siswa_id());

create policy permohonan_insert_own on public.permohonan_magang
  for insert to authenticated
  with check (siswa_id = public.my_siswa_id() and status = 'menunggu');

create policy permohonan_update_own on public.permohonan_magang
  for update to authenticated
  using      (siswa_id = public.my_siswa_id() and status = 'menunggu')
  with check (siswa_id = public.my_siswa_id() and status = 'menunggu');

create policy permohonan_delete_own on public.permohonan_magang
  for delete to authenticated
  using (siswa_id = public.my_siswa_id() and status = 'menunggu');

create policy permohonan_admin_all on public.permohonan_magang
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- -------------------------------------------------------------- penempatan
drop policy if exists penempatan_select      on public.penempatan;
drop policy if exists penempatan_admin_write on public.penempatan;

create policy penempatan_select on public.penempatan
  for select to authenticated
  using (
    public.is_admin()
    or siswa_id = public.my_siswa_id()
    or (guru_id is not null and guru_id = public.my_guru_id())
  );
create policy penempatan_admin_write on public.penempatan
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ------------------------------------------------------------------ jurnal
drop policy if exists jurnal_select     on public.jurnal;
drop policy if exists jurnal_insert_own on public.jurnal;
drop policy if exists jurnal_update     on public.jurnal;
drop policy if exists jurnal_delete     on public.jurnal;
drop policy if exists jurnal_admin_all  on public.jurnal;

create policy jurnal_select on public.jurnal
  for select to authenticated
  using (
    public.is_admin()
    or public.is_my_penempatan(penempatan_id)
    or public.is_supervised_penempatan(penempatan_id)
  );

create policy jurnal_insert_own on public.jurnal
  for insert to authenticated
  with check (public.is_my_penempatan(penempatan_id) and status = 'menunggu');

-- Siswa: hanya jurnal yang masih 'menunggu'/'ditolak'. Guru: jurnal bimbingannya.
-- Pembatasan kolom ditangani trigger trg_jurnal_before_update.
create policy jurnal_update on public.jurnal
  for update to authenticated
  using (
    (public.is_my_penempatan(penempatan_id) and status in ('menunggu', 'ditolak'))
    or public.is_supervised_penempatan(penempatan_id)
  )
  with check (
    public.is_my_penempatan(penempatan_id)
    or public.is_supervised_penempatan(penempatan_id)
  );

create policy jurnal_delete on public.jurnal
  for delete to authenticated
  using (public.is_my_penempatan(penempatan_id) and status = 'menunggu');

create policy jurnal_admin_all on public.jurnal
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- --------------------------------------------------------------- kehadiran
drop policy if exists kehadiran_select     on public.kehadiran;
drop policy if exists kehadiran_insert_own on public.kehadiran;
drop policy if exists kehadiran_update_own on public.kehadiran;
drop policy if exists kehadiran_admin_all  on public.kehadiran;

create policy kehadiran_select on public.kehadiran
  for select to authenticated
  using (
    public.is_admin()
    or public.is_my_penempatan(penempatan_id)
    or public.is_supervised_penempatan(penempatan_id)
  );

-- Siswa hanya boleh mencatat/ubah kehadiran HARI INI (tidak bisa backdate).
create policy kehadiran_insert_own on public.kehadiran
  for insert to authenticated
  with check (public.is_my_penempatan(penempatan_id) and tanggal = current_date);

create policy kehadiran_update_own on public.kehadiran
  for update to authenticated
  using      (public.is_my_penempatan(penempatan_id) and tanggal = current_date)
  with check (public.is_my_penempatan(penempatan_id) and tanggal = current_date);

create policy kehadiran_admin_all on public.kehadiran
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- -------------------------------------------------------------- notifikasi
-- INSERT hanya lewat trigger SECURITY DEFINER (tidak ada policy insert).
drop policy if exists notifikasi_select_own on public.notifikasi;
drop policy if exists notifikasi_update_own on public.notifikasi;
drop policy if exists notifikasi_delete_own on public.notifikasi;

create policy notifikasi_select_own on public.notifikasi
  for select to authenticated using (user_id = (select auth.uid()));
create policy notifikasi_update_own on public.notifikasi
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy notifikasi_delete_own on public.notifikasi
  for delete to authenticated using (user_id = (select auth.uid()));

-- -------------------------------------------------------------- audit_logs
drop policy if exists audit_logs_admin_select on public.audit_logs;
create policy audit_logs_admin_select on public.audit_logs
  for select to authenticated using (public.is_admin());

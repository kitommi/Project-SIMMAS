-- =====================================================================
-- SIMMAS — 04_seed.sql  (HANYA untuk development)
-- Prasyarat: buat 3 user lewat Dashboard > Authentication > Users
-- ("Add user" > centang Auto Confirm User), dengan email:
--     admin@simmas.sch.id   guru@simmas.sch.id   siswa@simmas.sch.id
-- dan password pilihan Anda sendiri. Lalu jalankan skrip ini.
-- =====================================================================

-- Role & nama untuk akun demo
update public.profiles set role = 'admin', nama = 'Administrator'   where email = 'admin@simmas.sch.id';
update public.profiles set role = 'guru',  nama = 'Budi Santoso'    where email = 'guru@simmas.sch.id';
update public.profiles set role = 'siswa', nama = 'Nama Sohiva'     where email = 'siswa@simmas.sch.id';

insert into public.kelas (nama, jurusan, angkatan) values
  ('AK1', 'Akuntansi', 2026), ('AK2', 'Akuntansi', 2026),
  ('AK3', 'Akuntansi', 2026), ('AK4', 'Akuntansi', 2026)
on conflict (nama) do nothing;

insert into public.periode_magang (nama, tanggal_mulai, tanggal_selesai, is_active)
select 'PKL 2026/2027', date '2026-11-01', date '2027-02-28', true
where not exists (select 1 from public.periode_magang where nama = 'PKL 2026/2027');

insert into public.dudi (nama, alamat, kota, bidang_usaha, kuota)
select v.nama, v.alamat, v.kota, v.bidang, v.kuota
from (values
  ('Perusahaan Mitra A', 'Jl. Contoh No. 1', 'Sidoarjo', 'Akuntansi', 10),
  ('Perusahaan Mitra B', 'Jl. Contoh No. 2', 'Surabaya', 'Perdagangan', 5),
  ('Kekor Mitra',        'Jl. Contoh No. 3', 'Gresik',   'Manufaktur', 3)
) as v(nama, alamat, kota, bidang, kuota)
where not exists (select 1 from public.dudi d where d.nama = v.nama);

-- Guru demo (terhubung ke akun guru@...)
insert into public.guru (profile_id, nip, nama, bidang)
select id, '198001012005011001', nama, 'Akuntansi'
from public.profiles where email = 'guru@simmas.sch.id'
on conflict do nothing;

-- Siswa demo (terhubung ke akun siswa@...) + beberapa siswa tanpa akun
insert into public.siswa (profile_id, nis, nama, kelas_id, jenis_kelamin)
select p.id, '2026001', p.nama, (select id from public.kelas where nama = 'AK1'), 'L'
from public.profiles p where p.email = 'siswa@simmas.sch.id'
on conflict do nothing;

insert into public.siswa (nis, nama, kelas_id, jenis_kelamin)
select v.nis, v.nama, (select id from public.kelas where nama = v.kelas), v.jk
from (values
  ('2026002', 'Nama Gampet',    'AK2', 'L'),
  ('2026003', 'Aurah Nagan',    'AK3', 'P'),
  ('2026004', 'Nama Satkiyal',  'AK4', 'L'),
  ('2026005', 'Matia Hngwari',  'AK2', 'P')
) as v(nis, nama, kelas, jk)
on conflict (nis) do nothing;

-- Contoh permohonan (semua 'menunggu'; setujui dari dashboard admin untuk
-- mencoba trigger kuota + pembuatan penempatan otomatis)
insert into public.permohonan_magang (siswa_id, dudi_id, periode_id, status)
select s.id, d.id, per.id, 'menunggu'
from public.siswa s
cross join lateral (
  select dd.id from public.dudi dd order by md5(s.nis || dd.nama) limit 1
) d
cross join (select id from public.periode_magang where is_active limit 1) per
on conflict do nothing;

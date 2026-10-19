-- =====================================================================
-- SIMMAS — 06_guru_siswa_ui.sql
-- Tambahan untuk panel Guru Pembimbing. Jalankan setelah 05_admin_ui.sql.
-- Aman dijalankan ulang.
-- =====================================================================

-- Kolom FOTO pada tabel Jurnal & Absensi (path file di Storage; opsional).
alter table public.jurnal add column if not exists foto_path text;

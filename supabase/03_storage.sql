-- =====================================================================
-- SIMMAS — 03_storage.sql  (opsional: hanya bila memakai upload file)
-- Konvensi path:  avatars/{auth.uid}/foto.jpg
--                 surat-pengantar/{siswa_id}/surat.pdf
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp']),
  ('surat-pengantar', 'surat-pengantar', false, 5242880, array['application/pdf'])
on conflict (id) do nothing;

-- ---- avatars: publik dibaca, tulis hanya ke folder milik sendiri ----
drop policy if exists avatars_read         on storage.objects;
drop policy if exists avatars_insert_own   on storage.objects;
drop policy if exists avatars_update_own   on storage.objects;
drop policy if exists avatars_delete_own   on storage.objects;

create policy avatars_read on storage.objects
  for select using (bucket_id = 'avatars');

create policy avatars_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars'
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy avatars_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy avatars_delete_own on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

-- ---- surat-pengantar: privat. Admin kelola; siswa baca foldernya sendiri ----
drop policy if exists surat_admin_all   on storage.objects;
drop policy if exists surat_siswa_read  on storage.objects;

create policy surat_admin_all on storage.objects
  for all to authenticated
  using (bucket_id = 'surat-pengantar' and public.is_admin())
  with check (bucket_id = 'surat-pengantar' and public.is_admin());

create policy surat_siswa_read on storage.objects
  for select to authenticated
  using (bucket_id = 'surat-pengantar'
         and (storage.foldername(name))[1] = public.my_siswa_id()::text);

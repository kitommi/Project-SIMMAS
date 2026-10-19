# SIMMAS — Flutter + Supabase

Replikasi Flutter multi-platform dari situs SIMMAS (Next.js): landing page, login,
dashboard responsif per role (admin / guru / siswa), dengan backend Supabase.

## 1. Buat proyek Flutter lalu timpa dengan isi paket ini

```bash
flutter create --org id.sch.simmas --platforms=android,ios,web,windows,macos,linux simmas
cd simmas
# salin isi zip ini ke dalam folder simmas (timpa pubspec.yaml, lib/, assets/, dll.)
rm -f test/widget_test.dart
flutter pub get
```

## 2. Setup Supabase (Dashboard)
1. Buat project baru. Catat **Project URL** dan **anon public key** (Settings > API).
2. Authentication > Providers: pastikan **Email** aktif. Untuk sekolah (akun dibuat admin),
   matikan "Allow new users to sign up" bila tidak ingin pendaftaran mandiri.
3. SQL Editor: jalankan berurutan `supabase/01_schema.sql`, `02_rls.sql`,
   `05_admin_ui.sql` (view + tabel untuk UI admin baru), lalu `03_storage.sql` (opsional).
4. Authentication > Users > Add user (centang Auto Confirm) untuk
   `admin@simmas.sch.id`, `guru@simmas.sch.id`, `siswa@simmas.sch.id`
   dengan password Anda sendiri, lalu jalankan `supabase/04_seed.sql` (dev saja).
5. Database > Replication: pastikan `permohonan_magang` ada di publication `supabase_realtime`
   (sudah ditambahkan oleh 01_schema.sql).
6. Authentication > URL Configuration: isi Site URL / Redirect URL (untuk reset password).

## 3. Jalankan
```bash
cp env/dev.example.json env/dev.json   # isi URL + anon key
flutter run -d chrome --dart-define-from-file=env/dev.json
flutter run -d <android/ios/windows/macos/linux> --dart-define-from-file=env/dev.json
flutter build web --release --dart-define-from-file=env/prod.json
```
Di produksi set `SHOW_DEMO_ACCOUNTS=false`. **Jangan pernah** memasukkan `service_role` key ke app.

## 4. Konfigurasi platform
- **Android**: tambahkan `<uses-permission android:name="android.permission.INTERNET"/>` di
  `android/app/src/main/AndroidManifest.xml` (wajib untuk build release).
- **macOS**: tambahkan `com.apple.security.network.client = true` di
  `macos/Runner/DebugProfile.entitlements` dan `Release.entitlements`.
- **Web**: bila font Google diblokir, bundel font Plus Jakarta Sans sebagai asset.

## 5. Membuat user dari aplikasi admin
Pembuatan user butuh `service_role`, jadi lakukan lewat **Edge Function** (server-side),
bukan dari Flutter. Setelah user dibuat, trigger membuat `profiles` (role `siswa`);
admin menaikkan role lewat UPDATE (diizinkan RLS untuk admin).

## 6. UI admin (redesign)
Tema terang saja (font Inter). Halaman admin: Dashboard, Monitoring Global, Data Guru/Siswa/DUDI,
Penempatan Magang, Pengaturan Sistem, Log Aktivitas & Audit. Ctrl/⌘+K membuka pencarian halaman.
Log `LOGIN_SUCCESS`/`LOGOUT` dicatat lewat RPC `log_activity` (05_admin_ui.sql).

## 7. Status
Terimplementasi: landing, login (validasi + demo akun + overlay sukses), shell dashboard
adaptif, beranda admin (statistik + tabel realtime + setujui/tolak), beranda siswa
(penempatan, jurnal, tambah jurnal), beranda guru (setujui/tolak jurnal).
Menu lain (Data Siswa, DUDI, Laporan, dst.) memakai `PlaceholderPage`; ikuti pola
`DashboardRepository` + `AdminHomePage` untuk CRUD-nya.

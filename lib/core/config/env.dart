import 'package:flutter/foundation.dart';

/// Konfigurasi build-time lewat `--dart-define` / `--dart-define-from-file`.
/// Tidak ada rahasia yang di-hardcode di repo.
///
/// PENTING: hanya `anon` key yang boleh ada di aplikasi klien. `service_role`
/// key TIDAK PERNAH boleh dimasukkan ke aplikasi Flutter. Keamanan data dijaga
/// oleh Row Level Security (lihat supabase/02_rls.sql).
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Menampilkan blok "Akun Demo" di halaman login (default: hanya debug).
  static const showDemoAccounts =
      bool.fromEnvironment('SHOW_DEMO_ACCOUNTS', defaultValue: kDebugMode);

  static void assertConfigured() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL / SUPABASE_ANON_KEY belum di-set.\n'
        'Jalankan: flutter run --dart-define-from-file=env/dev.json',
      );
    }
  }
}

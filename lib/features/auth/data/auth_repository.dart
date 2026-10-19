import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';

class AuthResult {
  const AuthResult._({this.user, this.error});

  factory AuthResult.success(AppUser user) => AuthResult._(user: user);
  factory AuthResult.failure(String message) => AuthResult._(error: message);

  final AppUser? user;
  final String? error;
  bool get success => user != null;
}

/// Satu-satunya tempat yang bicara ke `supabase.auth` dan tabel `profiles`.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final uid = res.user?.id;
      if (uid == null) return AuthResult.failure('Email atau password salah.');

      final profile = await fetchProfile(uid);
      if (profile == null) {
        await _client.auth.signOut();
        return AuthResult.failure(
          'Profil pengguna tidak ditemukan atau akun dinonaktifkan. '
          'Hubungi admin sekolah.',
        );
      }
      await _logActivity('LOGIN_SUCCESS');
      return AuthResult.success(profile);
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } on PostgrestException catch (e) {
      return AuthResult.failure('Gagal memuat profil: ${e.message}');
    } catch (_) {
      return AuthResult.failure(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Mengambil profil; `null` bila tidak ada atau `is_active = false`.
  Future<AppUser?> fetchProfile(String uid) async {
    final row = await _client
        .from('profiles')
        .select('id, nama, email, role, avatar_url, is_active')
        .eq('id', uid)
        .maybeSingle();
    if (row == null || row['is_active'] == false) return null;
    return AppUser.fromMap(row);
  }

  /// Catat aktivitas ke tabel `activity_logs` lewat RPC (gagal = diabaikan).
  Future<void> _logActivity(String aksi) async {
    try {
      await _client.rpc('log_activity', params: {'p_aksi': aksi});
    } catch (_) {
      // Pencatatan log tidak boleh menggagalkan login.
    }
  }

  Future<void> signOut() async {
    await _logActivity('LOGOUT');
    await _client.auth.signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Periksa kotak masuk Anda.';
    }
    if (msg.contains('too many') || msg.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
    }
    return e.message;
  }
}

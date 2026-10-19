import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

/// State auth global. Dipakai `GoRouter.refreshListenable` untuk route guard.
class AuthController extends ChangeNotifier {
  AuthController(this._repo);

  final AuthRepository _repo;
  StreamSubscription<AuthState>? _sub;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  /// Dipanggil sekali sebelum `runApp`: memulihkan sesi tersimpan.
  Future<void> bootstrap() async {
    final session = _repo.currentSession;
    if (session != null) {
      try {
        _user = await _repo.fetchProfile(session.user.id);
        if (_user == null) await _repo.signOut();
      } catch (_) {
        // Offline saat start: biarkan user kembali login.
        _user = null;
      }
    }
    _sub = _repo.authChanges.listen((state) {
      if (state.event == AuthChangeEvent.signedOut && _user != null) {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _repo.signIn(email: email, password: password);
    if (result.success) {
      _user = result.user;
      notifyListeners();
    }
    return result;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) =>
      _repo.sendPasswordReset(email);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/guru/data/guru_repository.dart';
import 'features/siswa/data/siswa_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Env.assertConfigured(); // gagal cepat bila --dart-define belum diisi

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );
  final client = Supabase.instance.client;

  final auth = AuthController(AuthRepository(client));
  await auth.bootstrap(); // pulihkan sesi sebelum router dibuat

  runApp(
    SimmasApp(
      deps: AppDependencies(
        auth: auth,
        admin: AdminRepository(client),
        notifications: NotificationService(client),
        siswa: SiswaRepository(client),
        guru: GuruRepository(client),
      ),
    ),
  );
}

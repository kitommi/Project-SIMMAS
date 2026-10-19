import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class SimmasApp extends StatefulWidget {
  const SimmasApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<SimmasApp> createState() => _SimmasAppState();
}

class _SimmasAppState extends State<SimmasApp> {
  late final GoRouter _router = buildRouter(widget.deps);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SIMMAS - Sistem Manajemen Magang Siswa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}

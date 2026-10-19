import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/data/admin_repository.dart';
import '../../features/admin/presentation/admin_dashboard_page.dart';
import '../../features/admin/presentation/dudi_page.dart';
import '../../features/admin/presentation/guru_page.dart';
import '../../features/admin/presentation/log_page.dart';
import '../../features/admin/presentation/monitoring_page.dart';
import '../../features/admin/presentation/penempatan_page.dart';
import '../../features/admin/presentation/pengaturan_page.dart';
import '../../features/admin/presentation/siswa_page.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/dashboard/presentation/app_shell.dart';
import '../../features/dashboard/presentation/nav_items.dart';
import '../../features/dashboard/presentation/placeholder_page.dart';
import '../../features/guru/data/guru_repository.dart';
import '../../features/guru/presentation/guru_dashboard_page.dart';
import '../../features/guru/presentation/guru_jurnal_page.dart';
import '../../features/guru/presentation/guru_kunjungan_page.dart';
import '../../features/guru/presentation/guru_siswa_page.dart';
import '../../features/landing/presentation/landing_page.dart';
import '../../features/siswa/data/siswa_repository.dart';
import '../../features/siswa/presentation/absensi_page.dart';
import '../../features/siswa/presentation/jurnal_page.dart';
import '../../features/siswa/presentation/pengajuan_page.dart';
import '../../features/siswa/presentation/siswa_home_page.dart';
import '../services/notification_service.dart';

/// Dependency container sederhana (tanpa package DI tambahan).
class AppDependencies {
  AppDependencies({
    required this.auth,
    required this.admin,
    required this.siswa,
    required this.guru,
    required this.notifications,
  });

  final AuthController auth;
  final AdminRepository admin;
  final SiswaRepository siswa;
  final GuruRepository guru;
  final NotificationService notifications;
}

GoRouter buildRouter(AppDependencies d) {
  Widget pageFor(UserRole role, NavItem item) {
    final user = d.auth.user;
    if (user == null) return const SizedBox.shrink(); // transisi logout

    switch (item.path) {
      case '/admin/dashboard':
        return AdminDashboardPage(repo: d.admin, user: user);
      case '/admin/monitoring':
        return MonitoringPage(repo: d.admin);
      case '/admin/guru':
        return GuruPage(repo: d.admin);
      case '/admin/siswa':
        return SiswaPage(repo: d.admin);
      case '/admin/dudi':
        return DudiPage(repo: d.admin);
      case '/admin/penempatan':
        return PenempatanPage(repo: d.admin);
      case '/admin/pengaturan':
        return PengaturanPage(repo: d.admin);
      case '/admin/log':
        return LogPage(repo: d.admin);
      case '/guru/dashboard':
        return GuruDashboardPage(user: user, repo: d.guru);
      case '/guru/siswa':
        return GuruSiswaPage(repo: d.guru);
      case '/guru/jurnal':
        return GuruJurnalPage(repo: d.guru);
      case '/guru/kunjungan':
        return GuruKunjunganPage(repo: d.guru);
      case '/siswa/dashboard':
        return SiswaHomePage(user: user, repository: d.siswa);
      case '/siswa/pengajuan':
        return SiswaPengajuanPage(repo: d.siswa);
      case '/siswa/absensi':
        return SiswaAbsensiPage(repo: d.siswa);
      case '/siswa/jurnal':
        return SiswaJurnalPage(repo: d.siswa);
      default:
        return PlaceholderPage(title: item.label);
    }
  }

  const protectedPrefixes = ['/admin', '/guru', '/siswa'];

  return GoRouter(
    initialLocation: '/', // landing page lebih dulu, login diakses dari sana
    refreshListenable: d.auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final user = d.auth.user;
      final isProtected = protectedPrefixes.any(loc.startsWith);

      if (isProtected && user == null) return '/login';
      // Role guard: admin tidak bisa membuka /siswa/*, dst.
      if (isProtected && user != null && !loc.startsWith('/${user.role.name}')) {
        return user.role.homePath;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => LandingPage(auth: d.auth)),
      GoRoute(path: '/login', builder: (_, __) => LoginPage(auth: d.auth)),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          auth: d.auth,
          notifications: d.notifications,
          location: state.uri.path,
          child: child,
        ),
        routes: [
          for (final role in UserRole.values)
            for (final item in navItemsFor(role))
              GoRoute(
                path: item.path,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: pageFor(role, item),
                ),
              ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.uri.path}')),
    ),
  );
}

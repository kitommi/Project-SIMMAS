import 'package:flutter/material.dart';

import '../../auth/domain/app_user.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.path, {this.title, this.shortLabel});
  final String label;
  final IconData icon;
  final String path;

  /// Judul halaman di topbar (default: label).
  final String? title;

  /// Label ringkas untuk bottom navigation di HP.
  final String? shortLabel;
  String get pageTitle => title ?? label;
  String get short => shortLabel ?? label;
}

class NavGroup {
  const NavGroup(this.title, this.items);
  final String title;
  final List<NavItem> items;
}

/// Menu sidebar bergrup per role. Grup admin mengikuti desain referensi.
List<NavGroup> navGroupsFor(UserRole role) => switch (role) {
      UserRole.admin => const [
          NavGroup('Overview', [
            NavItem('Dashboard', Icons.dashboard_outlined, '/admin/dashboard'),
            NavItem('Monitoring Global', Icons.monitor_heart_outlined, '/admin/monitoring', title: 'Monitoring'),
          ]),
          NavGroup('Master Data', [
            NavItem('Data Guru', Icons.badge_outlined, '/admin/guru', title: 'Manajemen Guru'),
            NavItem('Data Siswa', Icons.groups_outlined, '/admin/siswa', title: 'Manajemen Siswa'),
            NavItem('Data DUDI', Icons.apartment_outlined, '/admin/dudi', title: 'Manajemen DUDI'),
          ]),
          NavGroup('Manajemen', [
            NavItem('Penempatan Magang', Icons.place_outlined, '/admin/penempatan', title: 'Penempatan Magang'),
          ]),
          NavGroup('Sistem', [
            NavItem('Pengaturan Sistem', Icons.settings_outlined, '/admin/pengaturan'),
            NavItem('Log Aktivitas & Audit', Icons.shield_outlined, '/admin/log', title: 'Log Aktivitas & Audit'),
          ]),
        ],
      UserRole.guru => const [
          NavGroup('Overview', [
            NavItem('Dashboard', Icons.dashboard_outlined, '/guru/dashboard'),
          ]),
          NavGroup('Bimbingan', [
            NavItem('Siswa Bimbingan', Icons.groups_outlined, '/guru/siswa', title: 'Manajemen Siswa', shortLabel: 'Siswa'),
            NavItem('Jurnal & Absensi', Icons.menu_book_outlined, '/guru/jurnal', title: 'Jurnal Kegiatan', shortLabel: 'Jurnal'),
            NavItem('Kunjungan Lapangan', Icons.place_outlined, '/guru/kunjungan', title: 'Kunjungan', shortLabel: 'Kunjungan'),
          ]),
        ],
      UserRole.siswa => const [
          NavGroup('Utama', [
            NavItem('Dashboard', Icons.dashboard_outlined, '/siswa/dashboard'),
            NavItem('Pengajuan Magang', Icons.send_outlined, '/siswa/pengajuan', shortLabel: 'Pengajuan'),
          ]),
          NavGroup('Kegiatan Magang', [
            NavItem('Absensi Harian', Icons.event_available_outlined, '/siswa/absensi', title: 'Absensi', shortLabel: 'Absensi'),
            NavItem('Jurnal Kegiatan', Icons.menu_book_outlined, '/siswa/jurnal', shortLabel: 'Jurnal'),
          ]),
        ],
    };

List<NavItem> navItemsFor(UserRole role) => [for (final g in navGroupsFor(role)) ...g.items];

String roleBadge(UserRole role) => switch (role) {
      UserRole.admin => 'ADMINISTRATOR',
      UserRole.guru => 'PEMBIMBING',
      UserRole.siswa => 'PESERTA MAGANG',
    };

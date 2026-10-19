import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';

/// Halaman menu yang belum diimplementasikan. Salin pola `SiswaPage` +
/// `AdminRepository` untuk membuat CRUD Data Siswa, DUDI, dsb.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_outlined, size: 40, color: c.mutedForeground),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Halaman ini belum diimplementasikan.',
              style: TextStyle(color: c.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

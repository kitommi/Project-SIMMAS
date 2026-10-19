import 'package:flutter/material.dart';

import '../theme/simmas_colors.dart';

/// Badge status (Disetujui / Menunggu / Ditolak) seperti pada mockup tabel.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  /// 'disetujui' | 'menunggu' | 'ditolak' (atau status lain -> netral).
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final (label, bg, fg) = switch (status) {
      'disetujui' => ('Disetujui', c.success, Colors.white),
      'menunggu' => ('Menunggu', c.warning.withValues(alpha: .35), c.warningForeground),
      'ditolak' => ('Ditolak', c.destructive, Colors.white),
      _ => (status, c.muted, c.mutedForeground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

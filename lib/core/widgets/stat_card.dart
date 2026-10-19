import 'package:flutter/material.dart';

import '../theme/simmas_colors.dart';

/// Kartu statistik ("Total Siswa 324") pada dashboard.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.mutedForeground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.75,
                  ),
                ),
              ],
            ),
          ),
          if (icon != null)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: c.primary, size: 22),
            ),
        ],
      ),
    );
  }
}

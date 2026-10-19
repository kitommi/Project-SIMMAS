import 'package:flutter/material.dart';

import '../theme/simmas_colors.dart';

/// `text-xs uppercase tracking-[0.2em] font-semibold` pada situs asli.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.4,
        color: color ?? context.sc.mutedForeground,
      ),
    );
  }
}

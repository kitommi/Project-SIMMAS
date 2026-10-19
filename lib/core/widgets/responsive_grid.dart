import 'package:flutter/material.dart';

/// Grid adaptif: jumlah kolom dihitung dari lebar yang tersedia
/// (tanpa overflow di HP, tablet, maupun desktop).
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 280,
    this.spacing = 16,
    this.maxColumns = 4,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = ((width + spacing) / (minItemWidth + spacing))
            .floor()
            .clamp(1, maxColumns)
            .toInt();
        final itemWidth = (width - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

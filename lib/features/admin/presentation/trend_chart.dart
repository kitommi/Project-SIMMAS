import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../data/admin_models.dart';

/// Area chart 2 seri (pengajuan & disetujui) tanpa dependensi tambahan.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.points, this.height = 260});

  final List<TrendPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(points, const Color(0xFFE2E8F0), const Color(0xFF64748B)),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points, this.grid, this.label);

  final List<TrendPoint> points;
  final Color grid;
  final Color label;

  static const _blue = Color(0xFF2563EB);
  static const _sky = Color(0xFF38BDF8);

  void _text(Canvas canvas, String t, Offset at, {bool center = false, bool right = false}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: 11, color: label)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? at.dx - tp.width / 2 : (right ? at.dx - tp.width : at.dx);
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0, top = 8.0, bottom = 26.0;
    final w = size.width - left;
    final h = size.height - top - bottom;
    final maxData = points.fold<int>(0, (m, p) => math.max(m, math.max(p.pengajuan, p.disetujui)));
    final maxV = math.max(4, maxData).toDouble();

    // Grid putus-putus + label sumbu Y.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + h * i / 4;
      for (double x = left; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), gridPaint);
      }
      _text(canvas, (maxV * (4 - i) / 4).round().toString(), Offset(left - 8, y), right: true);
    }

    if (points.isEmpty) return;

    Offset pt(int i, int v) => Offset(
          left + (points.length == 1 ? w / 2 : w * i / (points.length - 1)),
          top + h * (1 - v / maxV),
        );

    void series(List<int> vals, Color color, double fillAlpha) {
      final pts = [for (var i = 0; i < vals.length; i++) pt(i, vals[i])];
      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 0; i < pts.length - 1; i++) {
        final a = pts[i], b = pts[i + 1];
        final cx = (a.dx + b.dx) / 2;
        line.cubicTo(cx, a.dy, cx, b.dy, b.dx, b.dy);
      }
      final fill = Path.from(line)
        ..lineTo(pts.last.dx, top + h)
        ..lineTo(pts.first.dx, top + h)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: fillAlpha), color.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(left, top, w, h)),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }

    series([for (final p in points) p.pengajuan], _blue, .22);
    series([for (final p in points) p.disetujui], _sky, .18);

    for (var i = 0; i < points.length; i++) {
      _text(canvas, bulanPendek(points[i].bulan), Offset(pt(i, 0).dx, size.height - bottom / 2 + 2), center: true);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.points != points;
}

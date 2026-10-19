import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/diagonal_clipper.dart';
import '../../../core/widgets/simmas_logo.dart';

/// Panel kiri halaman login (`aside` — hanya tampil di layar >= 1024px).
class LoginBranding extends StatelessWidget {
  const LoginBranding({super.key, required this.onLogoTap});

  final VoidCallback onLogoTap;

  static const _points = [
    'Penempatan magang terpusat & transparan',
    'Monitoring kehadiran & jurnal real-time',
    'Koordinasi sekolah, guru, dan industri',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final fg = c.primaryForeground;
    final xl = MediaQuery.sizeOf(context).width >= Breakpoints.xl;
    final padX = xl ? 56.0 : 40.0;

    return ClipRect(
      child: ColoredBox(
        color: c.primary,
        child: Stack(
          children: [
            Positioned(
              top: -96,
              right: -96,
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: fg.withValues(alpha: .10), width: 56),
                ),
              ),
            ),
            Positioned(
              bottom: -64,
              left: -64,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: fg.withValues(alpha: .07), width: 40),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 128,
              child: ClipPath(
                clipper: const DiagonalClipper(topLeft: .4),
                child: ColoredBox(color: fg.withValues(alpha: .04)),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padX, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onLogoTap,
                    borderRadius: BorderRadius.circular(12),
                    child: SimmasBrand(size: 40, framed: true, color: fg),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SISTEM INFORMASI MANAJEMEN MAGANG SISWA',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.4,
                                color: fg.withValues(alpha: .5),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'Magang\n'),
                                  TextSpan(
                                    text: 'lebih\n',
                                    style: TextStyle(color: fg.withValues(alpha: .5)),
                                  ),
                                  const TextSpan(text: 'teratur.'),
                                ],
                              ),
                              style: TextStyle(
                                fontSize: xl ? 48 : 36,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                letterSpacing: xl ? -1.2 : -0.9,
                                color: fg,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                'Platform manajemen magang siswa SMK yang '
                                'menghubungkan sekolah, guru pembimbing, dan '
                                'dunia usaha dalam satu sistem terpadu.',
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: fg.withValues(alpha: .65),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            for (final p in _points)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.check_circle_outline,
                                        size: 16,
                                        color: fg.withValues(alpha: .6),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        p,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          height: 1.3,
                                          color: fg.withValues(alpha: .75),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 24),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: fg.withValues(alpha: .10)),
                      ),
                    ),
                    child: Row(
                      children: [
                        _Stat('50+', 'SMK Aktif', fg),
                        _Divider(fg),
                        _Stat('10k+', 'Siswa Terdaftar', fg),
                        _Divider(fg),
                        _Stat('200+', 'Mitra DUDI', fg),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.fg);
  final String value;
  final String label;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: fg),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg.withValues(alpha: .5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider(this.fg);
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: fg.withValues(alpha: .15),
      );
}

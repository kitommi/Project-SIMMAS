import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/simmas_colors.dart';

/// Ikon graduation-cap (Lucide) persis seperti `icon.svg` situs asli,
/// di dalam tile biru `rounded-xl`.
class SimmasLogo extends StatelessWidget {
  const SimmasLogo({super.key, this.size = 36, this.framed = false});

  final double size;

  /// `true` = tile putih di luar (varian panel branding login, `p-1.5`).
  final bool framed;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"
 fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
<path d="M21.42 10.922a1 1 0 0 0-.019-1.838L12.83 5.18a2 2 0 0 0-1.66 0L2.6 9.08a1 1 0 0 0 0 1.832l8.57 3.908a2 2 0 0 0 1.66 0z"/>
<path d="M22 10v6"/>
<path d="M6 12.5V16a6 3 0 0 0 12 0v-3.5"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    final inner = framed ? size - 12 : size;
    final tile = Container(
      width: inner,
      height: inner,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SimmasColors.logoBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: SvgPicture.string(_svg, width: inner * .78, height: inner * .78),
    );
    if (!framed) return tile;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: tile,
    );
  }
}

/// Logo + wordmark "SIMMAS".
class SimmasBrand extends StatelessWidget {
  const SimmasBrand({super.key, this.size = 36, this.framed = false, this.color});

  final double size;
  final bool framed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SimmasLogo(size: size, framed: framed),
        const SizedBox(width: 10),
        Text(
          'SIMMAS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.45,
            color: color ?? context.sc.foreground,
          ),
        ),
      ],
    );
  }
}

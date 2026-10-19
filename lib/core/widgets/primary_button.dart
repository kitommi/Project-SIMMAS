import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/simmas_colors.dart';

enum AppButtonVariant { primary, outline, light }

/// Tombol seperti `Button` shadcn pada situs asli (tinggi default 48 = `h-12`).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.trailingIcon,
    this.height = 48,
    this.expand = true,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final IconData? trailingIcon;
  final double height;
  final bool expand;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final isMobile = MediaQuery.sizeOf(context).width < 640;
    final (bg, fg, side) = switch (variant) {
      AppButtonVariant.primary => (c.primary, c.primaryForeground, BorderSide.none),
      AppButtonVariant.light => (c.primaryForeground, c.primary, BorderSide.none),
      AppButtonVariant.outline => (c.card, c.foreground, BorderSide(color: c.border)),
    };

    final content = loading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: isMobile ? 14 : 16,
                height: isMobile ? 14 : 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              ),
              const SizedBox(width: 8),
              Text(loadingLabel ?? label),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 16),
              ],
            ],
          );

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: .7),
        disabledForegroundColor: fg.withValues(alpha: .9),
        minimumSize: Size(expand ? double.infinity : 0, isMobile ? 44 : height),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
        elevation: 0,
        side: side,
        textStyle: TextStyle(
          fontSize: isMobile ? 13 : 14,
          fontWeight: FontWeight.w700,
          letterSpacing: .35,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
      ),
      child: content,
    );
    return expand ? button : IntrinsicWidth(child: button);
  }
}

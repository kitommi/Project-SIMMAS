import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/simmas_colors.dart';
import '../utils/formatters.dart';

enum Tone { blue, purple, green, amber, red, slate }

class ToneColors {
  const ToneColors(this.bg, this.fg, this.border);
  final Color bg;
  final Color fg;
  final Color border;
}

ToneColors toneOf(Tone t) => switch (t) {
      Tone.blue => const ToneColors(Color(0xFFEFF6FF), Color(0xFF2563EB), Color(0xFFDBEAFE)),
      Tone.purple => const ToneColors(Color(0xFFF5F3FF), Color(0xFF7C3AED), Color(0xFFEDE9FE)),
      Tone.green => const ToneColors(Color(0xFFECFDF5), Color(0xFF059669), Color(0xFFA7F3D0)),
      Tone.amber => const ToneColors(Color(0xFFFEF9C3), Color(0xFF92400E), Color(0xFFFDE68A)),
      Tone.red => const ToneColors(Color(0xFFFEF2F2), Color(0xFFDC2626), Color(0xFFFECACA)),
      Tone.slate => const ToneColors(Color(0xFFF1F5F9), Color(0xFF475569), Color(0xFFE2E8F0)),
    };

const kPanelShadow = [BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 2))];

/// Kartu putih rounded-24 dengan border halus (card utama di seluruh halaman).
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.footer,
    this.fill = false,
    this.color,
    this.borderColor,
    this.bodyPadding = const EdgeInsets.fromLTRB(28, 0, 28, 24),
    this.headerPadding = const EdgeInsets.fromLTRB(28, 24, 28, 20),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? footer;

  /// `true` bila Panel berada di dalam baris dengan tinggi sama (Expanded body).
  final bool fill;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets bodyPadding;
  final EdgeInsets headerPadding;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 640;
    final body = Padding(padding: isMobile ? const EdgeInsets.fromLTRB(16, 0, 16, 16) : bodyPadding, child: child);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor ?? c.border),
        boxShadow: kPanelShadow,
      ),
      child: Column(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: isMobile ? const EdgeInsets.fromLTRB(16, 16, 16, 12) : headerPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!, style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w700, letterSpacing: -.2)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!, style: TextStyle(fontSize: isMobile ? 13 : 14, color: c.mutedForeground)),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          if (fill) Expanded(child: body) else body,
          if (footer != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: c.background.withValues(alpha: .6),
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

/// Kartu statistik: label uppercase, tile ikon berwarna, angka besar, subteks.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    this.tone = Tone.blue,
    this.showArrow = false,
    this.dash = false,
    this.progress,
    this.onTap,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Tone tone;
  final bool showArrow;
  final bool dash;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final t = toneOf(tone);
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 640;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, isMobile ? 18 : 22, isMobile ? 16 : 24, isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border),
          boxShadow: kPanelShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: isMobile ? 10 : 12, fontWeight: FontWeight.w600, letterSpacing: isMobile ? 0.8 : 1.1, color: c.mutedForeground),
                  ),
                ),
                Container(
                  width: isMobile ? 36 : 44,
                  height: isMobile ? 36 : 44,
                  decoration: BoxDecoration(
                    color: t.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.border),
                  ),
                  child: Icon(icon, size: isMobile ? 18 : 21, color: t.fg),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(value, style: TextStyle(fontSize: isMobile ? 28 : 34, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: isMobile ? -0.8 : -1)),
                const Spacer(),
                if (showArrow) Icon(Icons.arrow_forward, size: isMobile ? 16 : 18, color: c.mutedForeground.withValues(alpha: .6)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (dash) ...[Text('—  ', style: TextStyle(color: c.mutedForeground))],
                Flexible(
                  child: Text(sub, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isMobile ? 12 : 14, color: c.mutedForeground)),
                ),
              ],
            ),
            if (progress != null) ...[const SizedBox(height: 14), MiniProgress(value: progress!)],
          ],
        ),
      ),
    );
  }
}

/// Badge kapsul (status / level) dengan titik atau ikon opsional.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.tone = Tone.slate, this.dot = false, this.icon, this.solid = false});

  final String text;
  final Tone tone;
  final bool dot;
  final IconData? icon;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final t = toneOf(tone);
    final fg = solid ? Colors.white : t.fg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? t.fg : t.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: solid ? t.fg : t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          ),
        ],
      ),
    );
  }
}

class InitialAvatar extends StatelessWidget {
  const InitialAvatar(this.name, {super.key, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = toneOf(Tone.blue);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.bg, shape: BoxShape.circle, border: Border.all(color: t.border)),
      child: Text(inisial(name), style: TextStyle(fontSize: size * .32, fontWeight: FontWeight.w700, color: t.fg)),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.tone = Tone.blue, this.size = 44});

  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = toneOf(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(size * .32), border: Border.all(color: t.border)),
      child: Icon(icon, size: size * .48, color: t.fg),
    );
  }
}

class MiniProgress extends StatelessWidget {
  const MiniProgress({super.key, required this.value, this.color = const Color(0xFF10B981), this.height = 6});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: height,
        color: color,
        backgroundColor: const Color(0xFFF1F5F9),
      ),
    );
  }
}

/// Chip angka kecil (kuota, jumlah bimbingan, jurnal).
class CountBadge extends StatelessWidget {
  const CountBadge(this.text, {super.key, this.tone = Tone.slate, this.icon});

  final String text;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = toneOf(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: t.fg), const SizedBox(width: 4)],
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.fg)),
        ],
      ),
    );
  }
}

// ───────────────────────────── Toolbar ─────────────────────────────

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return SizedBox(
      height: 48,
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: c.mutedForeground),
          prefixIcon: Icon(Icons.search, size: 20, color: c.mutedForeground),
          filled: true,
          fillColor: c.background,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.primary, width: 1.5)),
        ),
      ),
    );
  }
}

class FilterDropdown extends StatelessWidget {
  const FilterDropdown({super.key, required this.value, required this.items, required this.onChanged});

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final safe = items.contains(value) ? value : items.first;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safe,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: c.mutedForeground),
          style: TextStyle(fontSize: 14, color: c.foreground, fontWeight: FontWeight.w500),
          items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class CountChip extends StatelessWidget {
  const CountChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.mutedForeground)),
    );
  }
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({super.key, required this.label, required this.onPressed, this.icon = Icons.add, this.color});

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final isMobile = MediaQuery.sizeOf(context).width < 640;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isMobile ? 18 : 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color ?? c.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: (color ?? c.primary).withValues(alpha: .4),
        disabledForegroundColor: Colors.white.withValues(alpha: .9),
        minimumSize: Size(0, isMobile ? 44 : 48),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 22),
        elevation: 3,
        shadowColor: (color ?? c.primary).withValues(alpha: .4),
        textStyle: TextStyle(fontSize: isMobile ? 14 : 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// Kartu toolbar: search kiri, filter, counter, tombol aksi kanan.
class ToolbarCard extends StatelessWidget {
  const ToolbarCard({super.key, required this.search, this.filters = const [], this.count, this.action});

  final Widget search;
  final List<Widget> filters;
  final String? count;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final filterRow = filters.isEmpty
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 1, height: 28, color: c.border, margin: const EdgeInsets.symmetric(horizontal: 14)),
              Icon(Icons.tune, size: 18, color: c.mutedForeground),
              const SizedBox(width: 10),
              for (var i = 0; i < filters.length; i++) ...[if (i > 0) const SizedBox(width: 10), filters[i]],
            ],
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.border), boxShadow: kPanelShadow),
      child: LayoutBuilder(
        builder: (context, cons) {
          if (cons.maxWidth >= 1000) {
            return Row(
              children: [
                Expanded(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: search)),
                if (filterRow != null) filterRow,
                const Spacer(),
                if (count != null) CountChip(count!),
                if (action != null) ...[const SizedBox(width: 16), action!],
              ],
            );
          }
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: cons.maxWidth, child: search),
              for (final f in filters) f,
              if (count != null) CountChip(count!),
              if (action != null) action!,
            ],
          );
        },
      ),
    );
  }
}

/// Tab switcher (segmented pill) seperti "Monitoring Kehadiran & Jurnal Siswa".
class PillTabs extends StatelessWidget {
  const PillTabs({super.key, required this.labels, this.icons = const [], required this.index, required this.onChanged});

  final List<String> labels;
  final List<IconData> icons;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < labels.length; i++)
              GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: i == index ? c.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: i == index ? const [BoxShadow(color: Color(0x140F172A), blurRadius: 4, offset: Offset(0, 1))] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i < icons.length) ...[
                        Icon(icons[i], size: 17, color: i == index ? c.foreground : c.mutedForeground),
                        const SizedBox(width: 8),
                      ],
                      Text(labels[i], style: TextStyle(fontSize: 14, fontWeight: i == index ? FontWeight.w600 : FontWeight.w500, color: i == index ? c.foreground : c.mutedForeground)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dua kolom (>= breakpoint) dengan tinggi sama, atau ditumpuk di layar sempit.
class TwoColumn extends StatelessWidget {
  const TwoColumn({super.key, required this.left, required this.right, this.leftFlex = 7, this.rightFlex = 4, this.breakpoint = 1000, this.gap = 24});

  /// Builder menerima `fill` = true bila berada di baris lebar (tinggi disamakan).
  final Widget Function(bool fill) left;
  final Widget Function(bool fill) right;
  final int leftFlex;
  final int rightFlex;
  final double breakpoint;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        if (cons.maxWidth >= breakpoint) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: leftFlex, child: left(true)),
                SizedBox(width: gap),
                Expanded(flex: rightFlex, child: right(true)),
              ],
            ),
          );
        }
        return Column(children: [left(false), SizedBox(height: gap), right(false)]);
      },
    );
  }
}

/// Wrapper halaman: padding responsif + scroll.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.onRefresh});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pad = w >= 1100 ? 40.0 : (w >= 700 ? 28.0 : 12.0);
    final topPad = w >= 700 ? 28.0 : 16.0;
    final bottomPad = w >= 700 ? 40.0 : 24.0;
    final gap = w >= 700 ? 24.0 : 16.0;
    final list = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(pad, topPad, pad, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
        ],
      ),
    );
    return onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key, this.icon = Icons.inbox_outlined});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: c.mutedForeground.withValues(alpha: .6)),
            const SizedBox(height: 10),
            Text(text, style: TextStyle(color: c.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState(this.message, {super.key, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.destructive.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(kRadius * 1.6),
        border: Border.all(color: c.destructive.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: c.destructive),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

/// Memuat future dengan spinner / error / data (dipakai tiap halaman).
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.future, required this.onRetry, required this.builder});

  final Future<T> future;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorState('Gagal memuat data: ${snap.error}', onRetry: onRetry);
        }
        if (!snap.hasData) {
          return const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()));
        }
        return builder(snap.data as T);
      },
    );
  }
}


// ───────────────────── Komponen panel guru / siswa ─────────────────────

class PageTitle extends StatelessWidget {
  const PageTitle(this.icon, this.text, {super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 640;
    return Row(
      children: [
        Icon(icon, size: mobile ? 24 : 30, color: context.sc.primary),
        SizedBox(width: mobile ? 8 : 12),
        Flexible(child: Text(text, style: TextStyle(fontSize: mobile ? 22 : 30, fontWeight: FontWeight.w800, letterSpacing: -.8))),
      ],
    );
  }
}

/// Kartu dengan header berlatar abu muda + ikon (mis. "Jurnal Perlu Evaluasi").
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.trailing,
    this.footer,
    this.fill = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? footer;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final body = Padding(padding: const EdgeInsets.all(24), child: child);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.border), boxShadow: kPanelShadow),
      child: Column(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(color: c.background.withValues(alpha: .7), border: Border(bottom: BorderSide(color: c.border))),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          if (fill) Expanded(child: body) else body,
          if (footer != null) Container(padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))), child: footer),
        ],
      ),
    );
  }
}

/// Border putus-putus rounded (empty state besar).
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.child, this.radius = 20, this.color});

  final Widget child;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashPainter(color ?? context.sc.border, radius),
      child: child,
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color || old.radius != radius;
}

/// Empty state besar: lingkaran ikon biru + judul + deskripsi (+ tombol).
class BigEmptyState extends StatelessWidget {
  const BigEmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.action});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final mobile = MediaQuery.sizeOf(context).width < 640;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 24, vertical: mobile ? 32 : 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: mobile ? 72 : 88,
                height: mobile ? 72 : 88,
                decoration: BoxDecoration(color: toneOf(Tone.blue).bg, shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: c.primary),
              ),
              const SizedBox(height: 24),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: mobile ? 19 : 22, fontWeight: FontWeight.w800, letterSpacing: -.4)),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: mobile ? 14 : 16, height: 1.5, color: c.mutedForeground)),
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner biru gradasi dengan tombol CTA putih (dashboard guru, dll).
class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, required this.title, required this.spans, required this.ctaLabel, required this.ctaIcon, required this.onCta});

  final String title;
  final List<InlineSpan> spans;
  final String ctaLabel;
  final IconData ctaIcon;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 760;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tanggalLengkap(DateTime.now()).toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2, color: Colors.white.withValues(alpha: .75))),
        const SizedBox(height: 10),
        Text(title, style: TextStyle(fontSize: narrow ? 22 : 30, fontWeight: FontWeight.w800, letterSpacing: -.8, color: Colors.white, height: 1.15)),
        const SizedBox(height: 6),
        Text.rich(TextSpan(style: TextStyle(fontSize: narrow ? 14 : 16, color: Colors.white.withValues(alpha: .9)), children: spans)),
      ],
    );
    final cta = FilledButton.icon(
      onPressed: onCta,
      icon: Icon(ctaIcon, size: 18),
      label: Row(mainAxisSize: MainAxisSize.min, children: [Text(ctaLabel), const SizedBox(width: 8), const Icon(Icons.arrow_forward, size: 16)]),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D4ED8),
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 18 : 48, vertical: narrow ? 20 : 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF0EA5E9)]),
        boxShadow: const [BoxShadow(color: Color(0x332563EB), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: narrow
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 20), cta])
          : Row(children: [Expanded(child: text), const SizedBox(width: 24), cta]),
    );
  }
}

/// Satu item timeline (ikon bulat + garis vertikal + kartu isi).
class TimelineItem extends StatelessWidget {
  const TimelineItem({super.key, required this.icon, required this.child, this.isLast = false});

  final IconData icon;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: toneOf(Tone.blue).bg, shape: BoxShape.circle, border: Border.all(color: toneOf(Tone.blue).border)),
                  child: Icon(icon, size: 22, color: c.primary),
                ),
                if (!isLast) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: c.border)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 16), child: child)),
        ],
      ),
    );
  }
}

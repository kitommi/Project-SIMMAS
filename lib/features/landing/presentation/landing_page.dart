import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/diagonal_clipper.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/simmas_logo.dart';
import '../../auth/presentation/auth_controller.dart';

/// Halaman awal aplikasi (replikasi `index.html`). Login dicapai dari sini.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key, required this.auth});

  final AuthController auth;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _featuresKey = GlobalKey();
  final _panduanKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openApp() {
    final user = widget.auth.user;
    context.go(user != null ? user.role.homePath : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final w = MediaQuery.sizeOf(context).width;
    final hasSession = widget.auth.isAuthenticated;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.background,
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Fitur'),
                onTap: () {
                  _scaffoldKey.currentState?.closeEndDrawer();
                  _scrollTo(_featuresKey);
                },
              ),
              ListTile(
                title: const Text('Panduan'),
                onTap: () {
                  _scaffoldKey.currentState?.closeEndDrawer();
                  _scrollTo(_panduanKey);
                },
              ),
              const SizedBox(height: 8),
              AppButton(
                label: hasSession ? 'Buka Dashboard' : 'Masuk',
                trailingIcon: Icons.arrow_forward,
                onPressed: _openApp,
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _Hero(
                  hasSession: hasSession,
                  onStart: _openApp,
                  onFeatures: () => _scrollTo(_featuresKey),
                ),
                KeyedSubtree(key: _featuresKey, child: const _Features()),
                KeyedSubtree(key: _panduanKey, child: const _Steps()),
                _Cta(onStart: _openApp),
                const _Footer(),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 16,
                  left: w < Breakpoints.sm ? 16 : 24,
                  right: w < Breakpoints.sm ? 16 : 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1152),
                    child: _Header(
                      hasSession: hasSession,
                      onFeatures: () => _scrollTo(_featuresKey),
                      onPanduan: () => _scrollTo(_panduanKey),
                      onStart: _openApp,
                      onMenu: () => _scaffoldKey.currentState?.openEndDrawer(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Header (pill floating) ─────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.hasSession,
    required this.onFeatures,
    required this.onPanduan,
    required this.onStart,
    required this.onMenu,
  });

  final bool hasSession;
  final VoidCallback onFeatures;
  final VoidCallback onPanduan;
  final VoidCallback onStart;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.md;

    Widget navLink(String text, VoidCallback onTap) => TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: c.foreground, padding: const EdgeInsets.symmetric(horizontal: 18)),
          child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border.withValues(alpha: .7)),
        boxShadow: const [BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          const SimmasBrand(size: 40),
          if (wide) ...[
            Expanded(
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [navLink('Fitur', onFeatures), navLink('Panduan', onPanduan)]),
              ),
            ),
            OutlinedButton(
              onPressed: onStart,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.primary,
                backgroundColor: const Color(0xFFEFF6FF),
                side: const BorderSide(color: Color(0xFFDBEAFE)),
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                shape: const StadiumBorder(),
              ),
              child: Text(hasSession ? 'Dashboard' : 'Masuk'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                elevation: 3,
                shadowColor: c.primary.withValues(alpha: .4),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                shape: const StadiumBorder(),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(hasSession ? 'Buka Dashboard' : 'Mulai Sekarang'),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
              ]),
            ),
          ] else ...[
            const Spacer(),
            IconButton(tooltip: 'Menu', onPressed: onMenu, icon: const Icon(Icons.menu)),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────────── Hero ─────────────────────────────────

/// Poligon biru diagonal sisi kanan: (69% 0) (100% 0) (100% 100%) (62% 100%).
class _HeroBlueClipper extends CustomClipper<Path> {
  const _HeroBlueClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * .69, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(size.width * .62, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.hasSession,
    required this.onStart,
    required this.onFeatures,
  });

  final bool hasSession;
  final VoidCallback onStart;
  final VoidCallback onFeatures;

  static const _blue = Color(0xFF2563EB);
  static const _points = [
    'Penempatan magang terpusat & transparan',
    'Monitoring kehadiran & jurnal real-time',
    'Koordinasi sekolah, guru, dan industri',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final screenH = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final wide = w >= Breakpoints.lg;
        final h1 = w >= Breakpoints.xl ? 96.0 : (w >= Breakpoints.lg ? 80.0 : (w >= Breakpoints.md ? 64.0 : (w < 420 ? 38.0 : 46.0)));

        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Sistem Informasi Manajemen Magang Siswa'),
            const SizedBox(height: 20),
            Text(
              wide ? 'Magang\nlebih\nteratur.' : 'Magang lebih\nteratur.',
              style: TextStyle(fontSize: h1, fontWeight: FontWeight.w800, height: .98, letterSpacing: -h1 * .04),
            ),
            const SizedBox(height: 28),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                'Platform manajemen magang siswa SMK yang menghubungkan sekolah, guru pembimbing, dan dunia usaha dalam satu sistem terpadu.',
                style: TextStyle(fontSize: 19, height: 1.65, color: c.mutedForeground),
              ),
            ),
            const SizedBox(height: 28),
            for (final p in _points)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 22, color: c.primary),
                    const SizedBox(width: 12),
                    Flexible(child: Text(p, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            const SizedBox(height: 26),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                AppButton(
                  label: hasSession ? 'Buka Dashboard' : 'Mulai Sekarang',
                  trailingIcon: Icons.arrow_forward,
                  height: 56,
                  expand: false,
                  onPressed: onStart,
                ),
                AppButton(
                  label: 'Lihat Fitur',
                  variant: AppButtonVariant.outline,
                  height: 56,
                  expand: false,
                  onPressed: onFeatures,
                ),
              ],
            ),
          ],
        );

        final mock = Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 540), child: const _BrowserMock()),
        );

        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenH),
          child: ClipRect(
            child: Stack(
              children: [
                // Area biru diagonal (hanya desktop/tablet lebar).
                if (wide)
                  const Positioned.fill(
                    child: ClipPath(clipper: _HeroBlueClipper(), child: ColoredBox(color: _blue)),
                  ),
                // Ring dekoratif kiri-bawah.
                Positioned(
                  left: -150,
                  bottom: -170,
                  child: Container(
                    width: 440,
                    height: 440,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: .85), width: 64),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(wide ? 48 : 24, wide ? 150 : 120, wide ? 48 : 24, 80),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1360),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(flex: 11, child: text),
                                const SizedBox(width: 48),
                                Expanded(flex: 10, child: mock),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text,
                                const SizedBox(height: 48),
                                Container(
                                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
                                  decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(28)),
                                  child: mock,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Mockup jendela browser (3 titik + address bar) + badge "LIVE 324 Siswa".
class _BrowserMock extends StatelessWidget {
  const _BrowserMock();

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    Widget dot(Color color) => Container(
          width: 13,
          height: 13,
          margin: const EdgeInsets.only(right: 7),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.border),
            boxShadow: const [BoxShadow(color: Color(0x330F172A), blurRadius: 48, offset: Offset(0, 24))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  color: const Color(0xFFF8FAFC),
                  child: Row(
                    children: [
                      dot(const Color(0xFFF87171)),
                      dot(const Color(0xFFFBBF24)),
                      dot(const Color(0xFF34D399)),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Container(height: 24, decoration: BoxDecoration(color: const Color(0xFFE2E8F0).withValues(alpha: .7), borderRadius: BorderRadius.circular(8))),
                      ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/images/dashboard_mockup.jpg', fit: BoxFit.cover, semanticLabel: 'Tampilan Dashboard SIMMAS'),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: -16,
          top: -32,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x401D4ED8), blurRadius: 24, offset: Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('324 Siswa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────── Section wrapper ────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.child,
    this.background,
    this.ringAlignment = Alignment.topRight,
  });

  final Widget child;
  final Color? background;
  final Alignment ringAlignment;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final w = MediaQuery.sizeOf(context).width;
    final padV = w >= Breakpoints.md ? 112.0 : 72.0;
    return Container(
      width: double.infinity,
      color: background ?? c.background,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: ringAlignment == Alignment.topRight ? -80 : null,
              right: ringAlignment == Alignment.topRight ? -80 : null,
              bottom: ringAlignment == Alignment.bottomLeft ? -64 : null,
              left: ringAlignment == Alignment.bottomLeft ? -64 : null,
              child: Container(
                width: 288,
                height: 288,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.primary.withValues(alpha: .06),
                    width: 48,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: padV),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.label, required this.line1, required this.line2});

  final String label;
  final String line1;
  final String line2;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final w = MediaQuery.sizeOf(context).width;
    final size = w >= Breakpoints.xl ? 48.0 : (w >= Breakpoints.md ? 36.0 : 30.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$line1\n'),
              TextSpan(text: line2, style: TextStyle(color: c.primary)),
            ],
          ),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -size * .025,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────── Fitur ────────────────────────────────

class _Features extends StatelessWidget {
  const _Features();

  static const _cards = [
    (Icons.menu_book_outlined, 'Untuk Siswa', 'Jurnal & Kehadiran',
        'Catat jurnal harian dan isi daftar hadir secara digital dari mana saja, kapan saja.'),
    (Icons.groups_outlined, 'Untuk Guru Pembimbing', 'Monitoring Terpadu',
        'Pantau aktivitas, setujui jurnal, dan evaluasi performa siswa dalam satu dashboard.'),
    (Icons.work_outline, 'Untuk Admin Sekolah', 'Manajemen Penempatan',
        'Kelola data DUDI, plotting pembimbing, dan cetak surat pengantar secara otomatis.'),
  ];

  static const _bullets = [
    'Export Laporan Otomatis (PDF/Excel)',
    'Notifikasi Real-time untuk Guru',
    'Riwayat Penempatan per Angkatan',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return _Section(
      background: c.muted.withValues(alpha: .3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading(label: 'Fitur Platform', line1: 'Solusi untuk', line2: 'setiap peran.'),
          const SizedBox(height: 64),
          ResponsiveGrid(
            minItemWidth: 300,
            spacing: 24,
            maxColumns: 3,
            children: [
              for (final (icon, role, title, desc) in _cards)
                _FeatureCard(icon: icon, role: role, title: title, description: desc),
            ],
          ),
          const SizedBox(height: 80),
          LayoutBuilder(
            builder: (context, cons) {
              final wide = cons.maxWidth >= Breakpoints.lg;
              final left = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Lebih dari Catatan Digital'),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Akurasi data,\n'),
                        TextSpan(text: 'setiap hari.', style: TextStyle(color: c.primary)),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -.75,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SIMMAS memastikan akurasi data kehadiran dengan fitur '
                    'pencatatan presisi dan validasi lokasi magang.',
                    style: TextStyle(fontSize: 16, height: 1.6, color: c.mutedForeground),
                  ),
                  const SizedBox(height: 24),
                  for (final b in _bullets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 18, color: c.primary),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              b,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
              const right = _WeeklySummary();
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 64),
                        const Expanded(child: right),
                      ],
                    )
                  : Column(children: [left, const SizedBox(height: 48), right]);
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.icon,
    required this.role,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String role;
  final String title;
  final String description;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover ? c.primary.withValues(alpha: .3) : c.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: c.primary, size: 22),
            ),
            const SizedBox(height: 20),
            Text(
              widget.role.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: c.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: TextStyle(fontSize: 14, height: 1.6, color: c.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  const _WeeklySummary();

  static const _tiles = [
    ('Jurnal Disetujui', '142'),
    ('Absensi Tercatat', '98%'),
    ('Siswa Aktif', '324'),
    ('Perusahaan Mitra', '200+'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sc;

    Widget tile((String, String) t) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.muted.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.$1.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: c.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.$2,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.6,
                  ),
                ),
              ],
            ),
          ),
        );

    return Stack(
      children: [
        Positioned.fill(
          child: Transform.rotate(
            angle: -0.0349, // -2deg
            child: Container(
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Ringkasan Mingguan'),
              const SizedBox(height: 24),
              Row(children: [tile(_tiles[0]), const SizedBox(width: 16), tile(_tiles[1])]),
              const SizedBox(height: 16),
              Row(children: [tile(_tiles[2]), const SizedBox(width: 16), tile(_tiles[3])]),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────── Cara kerja ────────────────────────────

class _Steps extends StatelessWidget {
  const _Steps();

  static const _steps = [
    (Icons.business_outlined, '01', 'Registrasi DUDI',
        'Admin sekolah mendaftarkan daftar industri (DUDI) dan menetapkan kuota penempatan siswa.'),
    (Icons.send_outlined, '02', 'Pengajuan Siswa',
        'Siswa memilih atau mengajukan tempat magang melalui dashboard masing-masing.'),
    (Icons.description_outlined, '03', 'Persetujuan & Surat',
        'Sekolah mencetak surat pengantar otomatis untuk diserahkan ke pihak industri.'),
    (Icons.insights_outlined, '04', 'Monitoring',
        'Siswa mengisi jurnal harian, guru memantau perkembangan secara real-time dari sistem.'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return _Section(
      ringAlignment: Alignment.bottomLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading(label: 'Cara Kerja', line1: 'Empat langkah,', line2: 'satu sistem.'),
          const SizedBox(height: 64),
          ResponsiveGrid(
            minItemWidth: 250,
            spacing: 24,
            maxColumns: 4,
            children: [
              for (final (icon, no, title, desc) in _steps)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: c.primaryForeground, size: 22),
                          ),
                          Text(
                            no,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: c.border,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        desc,
                        style: TextStyle(fontSize: 14, height: 1.6, color: c.mutedForeground),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── CTA ───────────────────────────────

class _Cta extends StatelessWidget {
  const _Cta({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final fg = c.primaryForeground;
    final w = MediaQuery.sizeOf(context).width;
    final size = w >= Breakpoints.xl ? 60.0 : (w >= Breakpoints.md ? 48.0 : 36.0);

    return Container(
      width: double.infinity,
      color: c.primary,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: -96,
              left: -96,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: fg.withValues(alpha: .07), width: 56),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: w * .4,
              child: ClipPath(
                clipper: const DiagonalClipper(topLeft: .4),
                child: ColoredBox(color: fg.withValues(alpha: .04)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 96),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      SectionLabel('Mulai Sekarang', color: fg.withValues(alpha: .5)),
                      const SizedBox(height: 24),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Siap untuk\n'),
                            TextSpan(
                              text: 'digitalisasi\n',
                              style: TextStyle(color: fg.withValues(alpha: .5)),
                            ),
                            const TextSpan(text: 'magang?'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: size,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          letterSpacing: -size * .025,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Text(
                          'Tingkatkan efisiensi pemantauan dan evaluasi siswa magang '
                          'dengan platform yang dirancang untuk produktivitas maksimal.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: fg.withValues(alpha: .65),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      AppButton(
                        label: 'Masuk ke Dashboard',
                        trailingIcon: Icons.arrow_forward,
                        variant: AppButtonVariant.light,
                        height: 52,
                        expand: false,
                        onPressed: onStart,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── Footer ──────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final year = DateTime.now().year;

    Widget column(String title, List<String> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: c.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            for (final i in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(i, style: const TextStyle(fontSize: 14)),
              ),
          ],
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              ResponsiveGrid(
                minItemWidth: 200,
                spacing: 40,
                maxColumns: 4,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SimmasBrand(size: 36),
                      const SizedBox(height: 16),
                      Text(
                        'Sistem Informasi Manajemen Magang Siswa untuk SMK modern.',
                        style: TextStyle(fontSize: 14, height: 1.6, color: c.mutedForeground),
                      ),
                    ],
                  ),
                  column('Produk', const ['Fitur', 'Panduan', 'Keamanan']),
                  column('Akses', const ['Siswa', 'Guru Pembimbing', 'Administrator']),
                  column('Legal', const ['Kebijakan Privasi', 'Ketentuan Layanan']),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 8,
                  children: [
                    Text(
                      '© $year SIMMAS. Didesain untuk pendidikan Indonesia.',
                      style: TextStyle(fontSize: 12, color: c.mutedForeground),
                    ),
                    Text(
                      'Versi 2.0.0',
                      style: TextStyle(fontSize: 12, color: c.mutedForeground),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

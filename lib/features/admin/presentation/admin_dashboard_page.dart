import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../../auth/domain/app_user.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'trend_chart.dart';

class _DashData {
  const _DashData(this.stats, this.trend, this.logs, this.dudi);
  final DashboardStats stats;
  final List<TrendPoint> trend;
  final List<LogEntry> logs;
  final List<DudiRow> dudi;
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.repo, required this.user});

  final AdminRepository repo;
  final AppUser user;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<_DashData> _future;
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _future = _load();
    // Realtime: data ikut berubah saat ada pengajuan baru / diproses.
    var first = true; // event pertama = snapshot awal, sudah dimuat di atas
    _sub = widget.repo.permohonanChanges().listen((_) {
      if (first) {
        first = false;
        return;
      }
      if (mounted) setState(() => _future = _load());
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<_DashData> _load() async {
    final r = await Future.wait<Object>([
      widget.repo.fetchStats(),
      widget.repo.fetchTrend(),
      widget.repo.fetchLogs(limit: 5),
      widget.repo.fetchDudi(),
    ]);
    return _DashData(r[0] as DashboardStats, r[1] as List<TrendPoint>, r[2] as List<LogEntry>, r[3] as List<DudiRow>);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashData>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return PageBody(onRefresh: _refresh, children: [ErrorState('Gagal memuat dashboard: ${snap.error}', onRetry: _refresh)]);
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final d = snap.data!;
        final nama = widget.user.nama.isEmpty ? 'Admin' : widget.user.nama.split(' ').first;

        return PageBody(
          onRefresh: _refresh,
          children: [
            _WelcomeBanner(nama: nama, menunggu: d.stats.menunggu, onReview: () => context.go('/admin/penempatan')),
            ResponsiveGrid(
              minItemWidth: 240,
              maxColumns: 4,
              children: [
                StatTile(label: 'Total Siswa', value: '${d.stats.siswa}', sub: 'Data real-time', icon: Icons.groups_outlined, tone: Tone.blue, showArrow: true, dash: true, onTap: () => context.go('/admin/siswa')),
                StatTile(label: 'Guru Pembimbing', value: '${d.stats.guru}', sub: 'Data real-time', icon: Icons.school_outlined, tone: Tone.purple, showArrow: true, dash: true, onTap: () => context.go('/admin/guru')),
                StatTile(label: 'Mitra DUDI', value: '${d.stats.dudi}', sub: 'Data real-time', icon: Icons.apartment_outlined, tone: Tone.green, showArrow: true, dash: true, onTap: () => context.go('/admin/dudi')),
                StatTile(label: 'Menunggu Validasi', value: '${d.stats.menunggu}', sub: 'Data real-time', icon: Icons.schedule, tone: Tone.amber, showArrow: true, dash: true, onTap: () => context.go('/admin/penempatan')),
              ],
            ),
            TwoColumn(
              leftFlex: 7,
              rightFlex: 4,
              left: (fill) => Panel(
                fill: fill,
                title: 'Tren Pengajuan Magang',
                subtitle: 'Jumlah pengajuan & persetujuan 6 bulan terakhir',
                child: TrendChart(points: d.trend),
              ),
              right: (fill) => _StatusPanel(stats: d.stats, fill: fill, onDetail: () => context.go('/admin/penempatan')),
            ),
            TwoColumn(
              leftFlex: 6,
              rightFlex: 5,
              left: (fill) => _ActivityPanel(logs: d.logs, fill: fill, onAll: () => context.go('/admin/log')),
              right: (fill) => _ShortcutPanel(stats: d.stats, fill: fill),
            ),
            _DistribusiPanel(dudi: d.dudi),
          ],
        );
      },
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.nama, required this.menunggu, required this.onReview});

  final String nama;
  final int menunggu;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 760;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tanggalLengkap(DateTime.now()).toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2, color: Colors.white.withValues(alpha: .75))),
        const SizedBox(height: 10),
        Text('Selamat datang kembali, $nama', style: TextStyle(fontSize: narrow ? 22 : 30, fontWeight: FontWeight.w800, letterSpacing: -.8, color: Colors.white, height: 1.15)),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: .9)),
            children: [
              const TextSpan(text: 'Ada '),
              TextSpan(text: '$menunggu pengajuan', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              const TextSpan(text: ' yang menunggu validasi Anda hari ini.'),
            ],
          ),
        ),
      ],
    );
    final cta = FilledButton.icon(
      onPressed: onReview,
      icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
      label: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Tinjau Pengajuan'), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 16)]),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D4ED8),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 24 : 48, vertical: narrow ? 28 : 44),
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

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.stats, required this.fill, required this.onDetail});

  final DashboardStats stats;
  final bool fill;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final total = stats.disetujui + stats.menunggu + stats.ditolak;
    double pct(int v) => total == 0 ? 0 : v / total;

    Widget row(String label, int v, Tone tone, IconData icon, Color bar) => Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            children: [
              Row(
                children: [
                  IconTile(icon, tone: tone, size: 38),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                  Text('$v', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  SizedBox(width: 40, child: Text('${(pct(v) * 100).round()}%', textAlign: TextAlign.right, style: TextStyle(fontSize: 13, color: context.sc.mutedForeground))),
                ],
              ),
              const SizedBox(height: 10),
              MiniProgress(value: pct(v), color: bar),
            ],
          ),
        );

    return Panel(
      fill: fill,
      title: 'Status Pengajuan',
      subtitle: 'Distribusi status magang siswa',
      trailing: TextButton(onPressed: onDetail, child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Detail'), SizedBox(width: 4), Icon(Icons.chevron_right, size: 18)])),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          row('Disetujui', stats.disetujui, Tone.green, Icons.check_circle_outline, const Color(0xFF10B981)),
          row('Menunggu', stats.menunggu, Tone.amber, Icons.schedule, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.logs, required this.fill, required this.onAll});

  final List<LogEntry> logs;
  final bool fill;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return Panel(
      fill: fill,
      title: 'Aktivitas Sistem Terakhir',
      subtitle: 'Log aktivitas terbaru dari seluruh pengguna',
      footer: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: onAll,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Lihat semua log', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.primary)),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward, size: 16, color: c.primary),
          ]),
        ),
      ),
      child: logs.isEmpty
          ? const EmptyState('Belum ada aktivitas tercatat.')
          : Column(
              children: [
                for (final l in logs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        InitialAvatar(l.email == '—' ? 'AD' : l.email, size: 44),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.aksi, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text('${l.email} → ${l.modul}', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: c.mutedForeground)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Pill(l.level, tone: levelTone(l.level), icon: Icons.info_outline),
                            const SizedBox(height: 4),
                            Text(waktuRelatif(l.waktu), style: TextStyle(fontSize: 12, color: c.mutedForeground)),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

Tone levelTone(String level) => switch (level) {
      'ERROR' => Tone.red,
      'WARN' => Tone.amber,
      _ => Tone.blue,
    };

class _ShortcutPanel extends StatelessWidget {
  const _ShortcutPanel({required this.stats, required this.fill});

  final DashboardStats stats;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final items = [
      ('Data Siswa', '${stats.siswa} siswa terdaftar', Icons.groups_outlined, Tone.blue, '/admin/siswa'),
      ('Data Guru', '${stats.guru} guru pembimbing aktif', Icons.badge_outlined, Tone.purple, '/admin/guru'),
      ('Mitra DUDI', '${stats.dudi} perusahaan terverifikasi', Icons.apartment_outlined, Tone.green, '/admin/dudi'),
      ('Penempatan Magang', '${stats.menunggu} pengajuan menunggu validasi', Icons.place_outlined, Tone.amber, '/admin/penempatan'),
      ('Monitoring Global', 'Pantau absensi & jurnal siswa', Icons.monitor_heart_outlined, Tone.blue, '/admin/monitoring'),
    ];
    return Panel(
      fill: fill,
      title: 'Kelola Data',
      subtitle: 'Pintasan navigasi dan manajemen data master',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${items.length} Modul Terhubung', style: TextStyle(fontSize: 14, color: c.mutedForeground)),
          Text('Panel SIMMAS', style: TextStyle(fontSize: 13, color: c.mutedForeground.withValues(alpha: .7))),
        ],
      ),
      child: Column(
        children: [
          for (final (title, sub, icon, tone, path) in items)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.go(path),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    IconTile(icon, tone: tone, size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(sub, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: c.mutedForeground)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: c.mutedForeground.withValues(alpha: .6)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DistribusiPanel extends StatelessWidget {
  const _DistribusiPanel({required this.dudi});

  final List<DudiRow> dudi;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final sorted = [...dudi]..sort((a, b) => b.siswaAktif.compareTo(a.siswaAktif));
    final label = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: c.mutedForeground);

    return Panel(
      title: 'Sebaran Siswa per Tempat Magang',
      subtitle: 'Jumlah siswa aktif magang di tiap mitra DUDI',
      bodyPadding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      child: sorted.isEmpty
          ? const EmptyState('Belum ada mitra DUDI.')
          : LayoutBuilder(
              builder: (context, cons) {
                final showBar = cons.maxWidth >= 560;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
                      child: Row(children: [
                        Expanded(flex: 5, child: Text('MITRA DUDI', style: label)),
                        Expanded(flex: 2, child: Text('SISWA MAGANG', textAlign: TextAlign.right, style: label)),
                        if (showBar) Expanded(flex: 3, child: Padding(padding: const EdgeInsets.only(left: 28), child: Text('PROPORSI', style: label))),
                      ]),
                    ),
                    Divider(color: c.border, height: 1),
                    for (final d in sorted)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                        child: Row(children: [
                          Expanded(
                            flex: 5,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(d.lokasi, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                            ]),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text.rich(TextSpan(children: [
                                TextSpan(text: '${d.siswaAktif}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                TextSpan(text: ' / ${d.kuota}', style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                              ])),
                            ),
                          ),
                          if (showBar)
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: MiniProgress(value: d.kuota == 0 ? 0 : d.siswaAktif / d.kuota),
                              ),
                            ),
                        ]),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

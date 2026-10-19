import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../../auth/domain/app_user.dart';
import '../data/guru_models.dart';
import '../data/guru_repository.dart';

class _Data {
  const _Data(this.bimbingan, this.jurnal, this.hadir);
  final List<BimbinganRow> bimbingan;
  final List<JurnalItem> jurnal;
  final int hadir;
}

class GuruDashboardPage extends StatefulWidget {
  const GuruDashboardPage({super.key, required this.user, required this.repo});

  final AppUser user;
  final GuruRepository repo;

  @override
  State<GuruDashboardPage> createState() => _GuruDashboardPageState();
}

class _GuruDashboardPageState extends State<GuruDashboardPage> {
  late Future<_Data> _future = _load();

  Future<_Data> _load() async {
    final r = await Future.wait<Object>([widget.repo.fetchBimbingan(), widget.repo.fetchJurnal(limit: 100), widget.repo.hadirHariIni()]);
    return _Data(r[0] as List<BimbinganRow>, r[1] as List<JurnalItem>, r[2] as int);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      onRefresh: _refresh,
      children: [
        AsyncBody<_Data>(
          future: _future,
          onRetry: _refresh,
          builder: (d) {
            final aktif = d.bimbingan.where((b) => b.status == 'aktif').toList();
            final menunggu = d.jurnal.where((j) => j.status == 'menunggu').toList();
            final pct = aktif.isEmpty ? 0 : (d.hadir * 100 / aktif.length).round().clamp(0, 100);
            final nama = widget.user.nama.isEmpty ? 'Guru Pembimbing' : widget.user.nama;

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              HeroBanner(
                title: 'Selamat datang, $nama',
                spans: [
                  const TextSpan(text: 'Ada '),
                  TextSpan(text: '${menunggu.length} jurnal', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                  const TextSpan(text: ' siswa bimbingan yang menunggu evaluasi Anda.'),
                ],
                ctaLabel: 'Lihat Jurnal',
                ctaIcon: Icons.menu_book_outlined,
                onCta: () => context.go('/guru/jurnal'),
              ),
              const SizedBox(height: 24),
              ResponsiveGrid(minItemWidth: 280, maxColumns: 3, children: [
                StatTile(label: 'Siswa Bimbingan', value: '${aktif.length}', sub: 'Siswa aktif magang', icon: Icons.groups_outlined, tone: Tone.blue, showArrow: true, onTap: () => context.go('/guru/siswa')),
                StatTile(label: 'Jurnal Belum Dinilai', value: '${menunggu.length}', sub: 'Perlu evaluasi segera', icon: Icons.description_outlined, tone: Tone.amber, showArrow: true, onTap: () => context.go('/guru/jurnal')),
                StatTile(label: 'Kehadiran Hari Ini', value: '${d.hadir}/${aktif.length}', sub: '$pct% siswa hadir', icon: Icons.check_circle_outline, tone: Tone.green, progress: pct / 100),
              ]),
              const SizedBox(height: 24),
              TwoColumn(
                leftFlex: 1,
                rightFlex: 1,
                left: (fill) => SectionCard(
                  fill: fill,
                  icon: Icons.schedule,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Jurnal Perlu Evaluasi',
                  footer: Center(
                    child: TextButton(
                      onPressed: () => context.go('/guru/jurnal'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF92400E)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Text('Lihat semua tugas (${menunggu.length})'), const SizedBox(width: 4), const Icon(Icons.chevron_right, size: 18)]),
                    ),
                  ),
                  child: menunggu.isEmpty
                      ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 36), child: Text('Semua jurnal bimbingan Anda sudah dievaluasi.', style: TextStyle(fontSize: 16, color: c.mutedForeground))))
                      : Column(children: [
                          for (final j in menunggu.take(5))
                            InkWell(
                              onTap: () => context.go('/guru/jurnal'),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(children: [
                                  InitialAvatar(j.siswa, size: 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(j.siswa, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      Text('${tanggalPendek(j.tanggal)} • ${j.kegiatan}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                                    ]),
                                  ),
                                  const Pill('Menunggu', tone: Tone.amber, dot: true),
                                ]),
                              ),
                            ),
                        ]),
                ),
                right: (fill) => SectionCard(
                  fill: fill,
                  icon: Icons.groups_outlined,
                  iconColor: c.primary,
                  title: 'Daftar Siswa Bimbingan',
                  trailing: TextButton(onPressed: () => context.go('/guru/siswa'), child: const Text('Lihat Semua', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  child: aktif.isEmpty
                      ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 36), child: Text('Belum ada siswa yang dibimbing.', style: TextStyle(fontSize: 16, color: c.mutedForeground))))
                      : Column(children: [
                          for (final b in aktif.take(5))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                InitialAvatar(b.siswa, size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(b.siswa, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                    Text('${b.kelas} • ${b.dudi}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                                  ]),
                                ),
                              ]),
                            ),
                        ]),
                ),
              ),
            ]);
          },
        ),
      ],
    );
  }
}

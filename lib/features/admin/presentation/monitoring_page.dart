import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_table.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'data_page_helpers.dart';

class _MonData {
  const _MonData(this.rows, this.kunjungan);
  final List<MonitoringRow> rows;
  final List<KunjunganRow> kunjungan;
}

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key, required this.repo});

  final AdminRepository repo;

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  late Future<_MonData> _future = _load();
  int _tab = 0;
  String _q = '', _kelas = 'Semua Kelas';

  Future<_MonData> _load() async {
    final r = await Future.wait<Object>([widget.repo.fetchMonitoring(), widget.repo.fetchKunjungan()]);
    return _MonData(r[0] as List<MonitoringRow>, r[1] as List<KunjunganRow>);
  }

  void _reload() => setState(() => _future = _load());

  void _detail(MonitoringRow r) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(r.siswa, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.kelas} • ${r.dudi}'),
            Text('Pembimbing: ${r.pembimbing}'),
            const SizedBox(height: 12),
            Text('Hadir: ${r.hadir}   Sakit: ${r.sakit}   Izin: ${r.izin}   Alpa: ${r.alpa}'),
            Text('Total jurnal: ${r.jurnal} (minggu ini: ${r.jurnalMinggu})'),
            Text('Aktivitas terakhir: ${waktuRelatif(r.aktivitasTerakhir)}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  Widget _num(int v, Color color) => Text('$v', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color));

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      onRefresh: () async => _reload(),
      children: [
        AsyncBody<_MonData>(
          future: _future,
          onRetry: _reload,
          builder: (d) {
            final all = d.rows;
            final rows = all.where((r) => matches(_q, [r.siswa, r.dudi, r.pembimbing]) && (_kelas == 'Semua Kelas' || r.kelas == _kelas)).toList();
            final totalHadir = all.fold<int>(0, (s, r) => s + r.hadir);
            final totalCatat = all.fold<int>(0, (s, r) => s + r.hadir + r.sakit + r.izin + r.alpa);
            final persen = totalCatat == 0 ? 0 : (totalHadir * 100 / totalCatat).round();
            final jurnalMinggu = all.fold<int>(0, (s, r) => s + r.jurnalMinggu);
            final perhatian = all.where((r) => r.status != 'normal').length;

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ResponsiveGrid(minItemWidth: 240, maxColumns: 4, children: [
                StatTile(label: 'Total Siswa Aktif', value: '${all.length}', sub: 'Siswa sedang magang', icon: Icons.groups_outlined),
                StatTile(label: 'Tingkat Kehadiran', value: '$persen%', sub: 'Rata-rata kehadiran harian', icon: Icons.monitor_heart_outlined, tone: Tone.green),
                StatTile(label: 'Jurnal Terkumpul', value: '$jurnalMinggu', sub: 'Total jurnal minggu ini', icon: Icons.menu_book_outlined, tone: Tone.purple),
                StatTile(label: 'Perlu Perhatian', value: '$perhatian', sub: 'Siswa bermasalah/alfa', icon: Icons.warning_amber_rounded, tone: Tone.amber),
              ]),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: PillTabs(
                  labels: ['Monitoring Kehadiran & Jurnal Siswa', 'Kunjungan Guru Pembimbing (${d.kunjungan.length})'],
                  icons: const [Icons.groups_outlined, Icons.apartment_outlined],
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
              const SizedBox(height: 20),
              if (_tab == 0) ...[
                ToolbarCard(
                  search: SearchBox(hint: 'Cari siswa atau DUDI...', onChanged: (v) => setState(() => _q = v)),
                  filters: [FilterDropdown(value: _kelas, items: withAll('Semua Kelas', all.map((e) => e.kelas)), onChanged: (v) => setState(() => _kelas = v))],
                  count: '${rows.length} Data',
                ),
                const SizedBox(height: 20),
                AdminTable<MonitoringRow>(
                  selectable: false,
                  minWidth: 1000,
                  emptyText: 'Belum ada siswa yang sedang magang.',
                  columns: [
                    Col(
                      'Siswa & Kelas',
                      (r) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(r.siswa, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        Text(r.kelas, style: TextStyle(fontSize: 14, color: c.mutedForeground)),
                      ]),
                      flex: 2,
                    ),
                    Col(
                      'DUDI & Pembimbing',
                      (r) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(r.dudi, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        Text(r.pembimbing, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: c.mutedForeground)),
                      ]),
                      flex: 3,
                    ),
                    Col(
                      'Kehadiran (H/S/I/A)',
                      (r) => Row(mainAxisSize: MainAxisSize.min, children: [
                        _num(r.hadir, const Color(0xFF059669)),
                        Text('  /  ', style: TextStyle(color: c.border)),
                        _num(r.sakit, const Color(0xFFF59E0B)),
                        Text('  /  ', style: TextStyle(color: c.border)),
                        _num(r.izin, const Color(0xFF2563EB)),
                        Text('  /  ', style: TextStyle(color: c.border)),
                        _num(r.alpa, const Color(0xFFDC2626)),
                      ]),
                      flex: 2.2,
                    ),
                    Col('Jurnal', (r) => CountBadge('${r.jurnal}', tone: Tone.blue), flex: 1),
                    Col(
                      'Status',
                      (r) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        switch (r.status) {
                          'bermasalah' => const Pill('Bermasalah', tone: Tone.red, dot: true),
                          'perlu_perhatian' => const Pill('Perlu Perhatian', tone: Tone.amber, dot: true),
                          _ => const Pill('Normal', tone: Tone.green, dot: true),
                        },
                        const SizedBox(height: 4),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.schedule, size: 13, color: c.mutedForeground),
                          const SizedBox(width: 4),
                          Text(waktuRelatif(r.aktivitasTerakhir), style: TextStyle(fontSize: 12, color: c.mutedForeground)),
                        ]),
                      ]),
                      flex: 2.4,
                    ),
                    Col(
                      'Aksi',
                      (r) => TextButton.icon(onPressed: () => _detail(r), icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('Detail')),
                      flex: 1.1,
                    ),
                  ],
                  rows: rows,
                ),
              ] else
                AdminTable<KunjunganRow>(
                  selectable: false,
                  minWidth: 760,
                  emptyText: 'Belum ada kunjungan guru tercatat.',
                  columns: [
                    Col('Guru Pembimbing', (r) => Text(r.guru, style: const TextStyle(fontWeight: FontWeight.w600)), flex: 2),
                    Col('DUDI', (r) => Text(r.dudi), flex: 2),
                    Col('Tanggal', (r) => Text(tanggalPendek(r.tanggal)), flex: 1.4),
                    Col('Catatan', (r) => Text(r.catatan, overflow: TextOverflow.ellipsis, maxLines: 2), flex: 3),
                  ],
                  rows: d.kunjungan,
                ),
            ]);
          },
        ),
      ],
    );
  }
}

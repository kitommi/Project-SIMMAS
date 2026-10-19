import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_table.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../../admin/presentation/data_page_helpers.dart';
import '../data/guru_models.dart';
import '../data/guru_repository.dart';

class _Data {
  const _Data(this.jurnal, this.absensi);
  final List<JurnalItem> jurnal;
  final List<AbsensiItem> absensi;
}

class GuruJurnalPage extends StatefulWidget {
  const GuruJurnalPage({super.key, required this.repo});

  final GuruRepository repo;

  @override
  State<GuruJurnalPage> createState() => _GuruJurnalPageState();
}

class _GuruJurnalPageState extends State<GuruJurnalPage> {
  late Future<_Data> _future = _load();
  int _tab = 0;
  String _q = '';

  Future<_Data> _load() async {
    final r = await Future.wait<Object>([widget.repo.fetchJurnal(), widget.repo.fetchAbsensi()]);
    return _Data(r[0] as List<JurnalItem>, r[1] as List<AbsensiItem>);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _setuju(JurnalItem j) async {
    final ok = await runAction(context, () => widget.repo.updateStatusJurnal(j.id, setuju: true), success: 'Jurnal ${j.siswa} disetujui.');
    if (ok) _reload();
  }

  Future<void> _revisi(JurnalItem j) async {
    final v = await showFormDialog(
      context,
      title: 'Minta Revisi Jurnal',
      submitLabel: 'Kirim',
      fields: const [FieldSpec('catatan', 'Catatan revisi untuk siswa', type: FieldType.multiline, required: true)],
    );
    if (v == null || !mounted) return;
    final ok = await runAction(context, () => widget.repo.updateStatusJurnal(j.id, setuju: false, catatan: v['catatan'] as String?), success: 'Permintaan revisi dikirim.');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      onRefresh: () async => _reload(),
      children: [
        const PageTitle(Icons.menu_book_outlined, 'Validasi Jurnal & Absensi'),
        AsyncBody<_Data>(
          future: _future,
          onRetry: _reload,
          builder: (d) {
            final now = DateTime.now();
            final menunggu = d.jurnal.where((j) => j.status == 'menunggu').length;
            final disetujui = d.jurnal.where((j) => j.status == 'disetujui' && j.tanggal != null && j.tanggal!.year == now.year && j.tanggal!.month == now.month).length;
            final revisi = d.jurnal.where((j) => j.status == 'ditolak').length;
            final jurnal = d.jurnal.where((j) => matches(_q, [j.siswa, j.kegiatan, j.nis])).toList();
            final absensi = d.absensi.where((a) => matches(_q, [a.siswa, a.nis, a.keterangan])).toList();

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ResponsiveGrid(minItemWidth: 260, maxColumns: 3, children: [
                StatTile(label: 'Menunggu Validasi', value: '$menunggu', sub: 'Butuh review segera', icon: Icons.schedule, tone: Tone.amber),
                StatTile(label: 'Jurnal Disetujui', value: '$disetujui', sub: 'Bulan ini', icon: Icons.check_circle_outline, tone: Tone.green),
                StatTile(label: 'Perlu Revisi', value: '$revisi', sub: 'Menunggu perbaikan siswa', icon: Icons.error_outline, tone: Tone.red),
              ]),
              const SizedBox(height: 24),
              Align(alignment: Alignment.centerLeft, child: PillTabs(labels: const ['Jurnal', 'Absensi'], index: _tab, onChanged: (i) => setState(() => _tab = i))),
              const SizedBox(height: 20),
              Panel(
                bodyPadding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: SearchBox(hint: 'Cari nama siswa atau kegiatan...', onChanged: (v) => setState(() => _q = v))),
                  ),
                  const SizedBox(height: 16),
                  if (_tab == 0)
                    AdminTable<JurnalItem>(
                      selectable: false,
                      showPager: jurnal.length > 10,
                      minWidth: 900,
                      emptyText: 'Tidak ada jurnal yang sesuai dengan kriteria.',
                      columns: [
                        Col(
                          'Tanggal & Siswa',
                          (j) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(j.siswa, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            Text(tanggalPendek(j.tanggal), style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                          ]),
                          flex: 2,
                        ),
                        Col(
                          'Kegiatan',
                          (j) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(j.kegiatan, maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (j.catatan.isNotEmpty) Text('Catatan: ${j.catatan}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.mutedForeground)),
                          ]),
                          flex: 4,
                        ),
                        Col('Foto', (j) => j.foto == null ? Text('—', style: TextStyle(color: c.mutedForeground)) : Icon(Icons.image_outlined, color: c.primary), flex: .8),
                        Col(
                          'Status',
                          (j) => switch (j.status) {
                            'disetujui' => const Pill('Disetujui', tone: Tone.green, dot: true),
                            'ditolak' => const Pill('Perlu Revisi', tone: Tone.red, dot: true),
                            _ => const Pill('Menunggu', tone: Tone.amber, dot: true),
                          },
                          flex: 1.4,
                        ),
                        Col(
                          'Aksi',
                          (j) => j.status == 'menunggu'
                              ? Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(tooltip: 'Minta revisi', onPressed: () => _revisi(j), icon: Icon(Icons.close, color: c.destructive)),
                                  IconButton(tooltip: 'Setujui', onPressed: () => _setuju(j), icon: Icon(Icons.check, color: c.success)),
                                ])
                              : Text('—', style: TextStyle(color: c.mutedForeground)),
                          flex: 1.4,
                        ),
                      ],
                      rows: jurnal,
                    )
                  else
                    AdminTable<AbsensiItem>(
                      selectable: false,
                      showPager: absensi.length > 10,
                      minWidth: 900,
                      emptyText: 'Belum ada data absensi.',
                      columns: [
                        Col(
                          'Tanggal & Siswa',
                          (a) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(a.siswa, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            Text(tanggalPendek(a.tanggal), style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                          ]),
                          flex: 2,
                        ),
                        Col('Masuk', (a) => Text(jamMenit(a.jamMasuk)), flex: 1),
                        Col('Keluar', (a) => Text(jamMenit(a.jamKeluar)), flex: 1),
                        Col(
                          'Status',
                          (a) => switch (a.status) {
                            'hadir' => const Pill('Hadir', tone: Tone.green, dot: true),
                            'izin' => const Pill('Izin', tone: Tone.blue, dot: true),
                            'sakit' => const Pill('Sakit', tone: Tone.amber, dot: true),
                            _ => const Pill('Alpa', tone: Tone.red, dot: true),
                          },
                          flex: 1.2,
                        ),
                        Col('Keterangan', (a) => Text(a.keterangan, maxLines: 2, overflow: TextOverflow.ellipsis), flex: 3),
                      ],
                      rows: absensi,
                    ),
                ]),
              ),
            ]);
          },
        ),
      ],
    );
  }
}

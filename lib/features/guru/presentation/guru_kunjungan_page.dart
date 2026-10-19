import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../../admin/presentation/data_page_helpers.dart';
import '../data/guru_models.dart';
import '../data/guru_repository.dart';

class GuruKunjunganPage extends StatefulWidget {
  const GuruKunjunganPage({super.key, required this.repo});

  final GuruRepository repo;

  @override
  State<GuruKunjunganPage> createState() => _GuruKunjunganPageState();
}

class _GuruKunjunganPageState extends State<GuruKunjunganPage> {
  late Future<List<KunjunganItem>> _future = widget.repo.fetchKunjungan();
  String _q = '';

  void _reload() => setState(() => _future = widget.repo.fetchKunjungan());

  Future<void> _tambah() async {
    final dudi = await widget.repo.dudiOptions();
    if (!mounted) return;
    final v = await showFormDialog(
      context,
      title: 'Tambah Kunjungan',
      fields: [
        FieldSpec('dudi_id', 'DUDI yang dikunjungi', type: FieldType.dropdown, required: true, options: dudi),
        const FieldSpec('tanggal', 'Tanggal kunjungan', type: FieldType.date, required: true),
        const FieldSpec('catatan', 'Catatan kunjungan', type: FieldType.multiline),
      ],
    );
    if (v == null || !mounted) return;
    final ok = await runAction(
      context,
      () => widget.repo.tambahKunjungan(dudiId: v['dudi_id'] as String, tanggal: v['tanggal'] as String, catatan: v['catatan'] as String?),
      success: 'Kunjungan ditambahkan.',
    );
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      onRefresh: () async => _reload(),
      children: [
        const PageTitle(Icons.place_outlined, 'Kunjungan Lapangan'),
        AsyncBody<List<KunjunganItem>>(
          future: _future,
          onRetry: _reload,
          builder: (all) {
            final now = DateTime.now();
            final rows = all.where((k) => matches(_q, [k.dudi, k.catatan])).toList();
            final bulanIni = all.where((k) => k.tanggal != null && k.tanggal!.year == now.year && k.tanggal!.month == now.month).length;
            final dudiUnik = all.map((k) => k.dudi).toSet().length;

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ResponsiveGrid(minItemWidth: 260, maxColumns: 3, children: [
                StatTile(label: 'Total Kunjungan', value: '${all.length}', sub: 'Seluruh riwayat tercatat', icon: Icons.place_outlined, tone: Tone.blue),
                StatTile(label: 'Bulan Ini', value: '$bulanIni', sub: 'Kunjungan periode berjalan', icon: Icons.calendar_today_outlined, tone: Tone.amber),
                StatTile(label: 'DUDI Dikunjungi', value: '$dudiUnik', sub: 'Mitra industri unik', icon: Icons.apartment_outlined, tone: Tone.green),
              ]),
              const SizedBox(height: 24),
              ToolbarCard(
                search: SearchBox(hint: 'Cari DUDI atau catatan kunjungan...', onChanged: (v) => setState(() => _q = v)),
                count: '${rows.length} Kunjungan',
                action: PrimaryAction(label: 'Tambah Kunjungan', onPressed: _tambah),
              ),
              const SizedBox(height: 24),
              Panel(
                bodyPadding: const EdgeInsets.all(24),
                child: rows.isEmpty
                    ? const EmptyState('Belum ada kunjungan tercatat.')
                    : Column(children: [
                        for (var i = 0; i < rows.length; i++)
                          TimelineItem(
                            icon: Icons.apartment_outlined,
                            isLast: i == rows.length - 1,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                              decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Expanded(child: Text(rows[i].dudi, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(999)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.calendar_today_outlined, size: 13, color: c.mutedForeground),
                                      const SizedBox(width: 6),
                                      Text(tanggalLengkapTanpaHari(rows[i].tanggal), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.mutedForeground)),
                                    ]),
                                  ),
                                ]),
                                if (rows[i].catatan.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(rows[i].catatan, style: TextStyle(fontSize: 15, height: 1.5, color: c.foreground.withValues(alpha: .8))),
                                ],
                              ]),
                            ),
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

import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_table.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../../admin/presentation/data_page_helpers.dart';
import '../data/guru_models.dart';
import '../data/guru_repository.dart';

class GuruSiswaPage extends StatefulWidget {
  const GuruSiswaPage({super.key, required this.repo});

  final GuruRepository repo;

  @override
  State<GuruSiswaPage> createState() => _GuruSiswaPageState();
}

class _GuruSiswaPageState extends State<GuruSiswaPage> {
  late Future<List<BimbinganRow>> _future = widget.repo.fetchBimbingan();
  String _q = '';

  void _reload() => setState(() => _future = widget.repo.fetchBimbingan());

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      onRefresh: () async => _reload(),
      children: [
        const PageTitle(Icons.groups_outlined, 'Bimbingan Siswa'),
        AsyncBody<List<BimbinganRow>>(
          future: _future,
          onRetry: _reload,
          builder: (all) {
            final rows = all.where((r) => matches(_q, [r.siswa, r.nis, r.kelas, r.dudi])).toList();
            final aktif = all.where((r) => r.status == 'aktif').length;
            final selesai = all.where((r) => r.status == 'selesai').length;

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ResponsiveGrid(minItemWidth: 260, maxColumns: 3, children: [
                StatTile(label: 'Total Bimbingan', value: '${all.length}', sub: 'Siswa di-plot ke Anda', icon: Icons.groups_outlined, tone: Tone.blue),
                StatTile(label: 'Sedang Aktif', value: '$aktif', sub: 'Aktif di tempat magang', icon: Icons.track_changes, tone: Tone.amber),
                StatTile(label: 'Selesai (Dinilai)', value: '$selesai', sub: 'Sudah diberi nilai', icon: Icons.check_circle_outline, tone: Tone.green),
              ]),
              const SizedBox(height: 24),
              Panel(
                bodyPadding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Align(alignment: Alignment.centerLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: SearchBox(hint: 'Cari nama, NIS, atau kelas...', onChanged: (v) => setState(() => _q = v)))),
                  const SizedBox(height: 16),
                  if (all.isEmpty)
                    const DashedBox(
                      child: BigEmptyState(
                        icon: Icons.groups_outlined,
                        title: 'Belum ada siswa bimbingan',
                        subtitle: 'Siswa yang di-plot ke Anda oleh admin akan muncul di sini.',
                      ),
                    )
                  else
                    AdminTable<BimbinganRow>(
                      selectable: false,
                      minWidth: 900,
                      emptyText: 'Tidak ada siswa yang cocok.',
                      columns: [
                        Col(
                          'Nama Lengkap',
                          (r) => Row(children: [
                            InitialAvatar(r.siswa),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                Text(r.siswa, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                Text('NIS: ${r.nis}', style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                              ]),
                            ),
                          ]),
                          flex: 2.4,
                        ),
                        Col('Kelas', (r) => Text(r.kelas), flex: 1),
                        Col('Tempat Magang', (r) => Text(r.dudi, overflow: TextOverflow.ellipsis), flex: 2),
                        Col('Periode', (r) => Text('${tanggalPendek(r.mulai)} – ${tanggalPendek(r.selesai)}', style: const TextStyle(fontSize: 13)), flex: 2.2),
                        Col(
                          'Status',
                          (r) => r.status == 'selesai' ? const Pill('Selesai', tone: Tone.green, dot: true) : const Pill('Aktif', tone: Tone.blue, dot: true),
                          flex: 1.2,
                        ),
                      ],
                      rows: rows,
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

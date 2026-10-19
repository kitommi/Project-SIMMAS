import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_table.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'data_page_helpers.dart';

class _PenData {
  const _PenData(this.rows, this.pending);
  final List<PenempatanRow> rows;
  final List<PengajuanRow> pending;
}

class PenempatanPage extends StatefulWidget {
  const PenempatanPage({super.key, required this.repo});

  final AdminRepository repo;

  @override
  State<PenempatanPage> createState() => _PenempatanPageState();
}

class _PenempatanPageState extends State<PenempatanPage> {
  late Future<_PenData> _future = _load();
  String _q = '', _kelas = 'Semua Kelas', _dudi = 'Semua DUDI', _status = 'Semua Status';

  static const _statusLabel = {'aktif': 'Berlangsung', 'selesai': 'Selesai', 'dibatalkan': 'Dibatalkan'};

  Future<_PenData> _load() async {
    final r = await Future.wait<Object>([widget.repo.fetchPenempatan(), widget.repo.fetchPengajuanMenunggu()]);
    return _PenData(r[0] as List<PenempatanRow>, r[1] as List<PengajuanRow>);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _decide(PengajuanRow p, bool setuju) async {
    if (!setuju && !await confirmDialog(context, title: 'Tolak pengajuan?', message: 'Pengajuan ${p.siswa} ke ${p.dudi} akan ditolak.', confirmLabel: 'Tolak')) return;
    if (!mounted) return;
    final ok = await runAction(
      context,
      () => widget.repo.setPermohonanStatus(p.id, setuju ? 'disetujui' : 'ditolak'),
      success: setuju ? '${p.siswa} ditempatkan di ${p.dudi}. Tetapkan pembimbing dari menu aksi.' : 'Pengajuan ditolak.',
    );
    if (ok) _reload();
  }

  Future<void> _tambah() async {
    final siswa = await widget.repo.siswaBelumMagang();
    final dudi = await widget.repo.dudiOptions();
    final guru = await widget.repo.guruOptions();
    if (!mounted) return;
    final v = await showFormDialog(
      context,
      title: 'Tambah Penempatan',
      fields: [
        FieldSpec('siswa_id', 'Siswa', type: FieldType.dropdown, required: true, options: siswa),
        FieldSpec('dudi_id', 'Tempat magang (DUDI)', type: FieldType.dropdown, required: true, options: dudi),
        FieldSpec('guru_id', 'Guru pembimbing', type: FieldType.dropdown, options: guru),
      ],
    );
    if (v == null || !mounted) return;
    final ok = await runAction(
      context,
      () => widget.repo.tambahPenempatan(siswaId: v['siswa_id'] as String, dudiId: v['dudi_id'] as String, guruId: v['guru_id'] as String?),
      success: 'Penempatan ditambahkan.',
    );
    if (ok) _reload();
  }

  Future<void> _setPembimbing(PenempatanRow r) async {
    final guru = await widget.repo.guruOptions();
    if (!mounted) return;
    final v = await showFormDialog(
      context,
      title: 'Tetapkan Pembimbing',
      fields: [FieldSpec('guru_id', 'Guru pembimbing', type: FieldType.dropdown, required: true, options: guru)],
    );
    if (v == null || !mounted) return;
    final ok = await runAction(context, () => widget.repo.updateRow('penempatan', r.id, {'guru_id': v['guru_id']}), success: 'Pembimbing ditetapkan.');
    if (ok) _reload();
  }

  Future<void> _setStatus(PenempatanRow r, String status) async {
    final ok = await runAction(context, () => widget.repo.updateRow('penempatan', r.id, {'status': status}), success: 'Status penempatan diperbarui.');
    if (ok) _reload();
  }

  Future<void> _delete(PenempatanRow r) async {
    if (!await confirmDialog(context, title: 'Hapus penempatan?', message: 'Penempatan ${r.siswa} di ${r.dudi} beserta jurnal dan kehadirannya akan dihapus.')) return;
    if (!mounted) return;
    final ok = await runAction(context, () => widget.repo.deleteRow('penempatan', r.id), success: 'Penempatan dihapus.');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      onRefresh: () async => _reload(),
      children: [
        AsyncBody<_PenData>(
          future: _future,
          onRetry: _reload,
          builder: (d) {
            final all = d.rows;
            final rows = all.where((r) {
              return matches(_q, [r.siswa, r.nis, r.dudi, r.pembimbing]) &&
                  (_kelas == 'Semua Kelas' || r.kelas == _kelas) &&
                  (_dudi == 'Semua DUDI' || r.dudi == _dudi) &&
                  (_status == 'Semua Status' || _statusLabel[r.status] == _status);
            }).toList();
            int n(String s) => all.where((r) => r.status == s).length;
            final dudiTerlibat = all.where((r) => r.status == 'aktif').map((r) => r.dudi).toSet().length;

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ResponsiveGrid(minItemWidth: 240, maxColumns: 4, children: [
                StatTile(label: 'Menunggu Validasi', value: '${d.pending.length}', sub: 'Pengajuan siswa masuk', icon: Icons.error_outline, tone: Tone.amber),
                StatTile(label: 'Sedang Berlangsung', value: '${n('aktif')}', sub: 'Siswa magang aktif', icon: Icons.work_outline, tone: Tone.blue),
                StatTile(label: 'Selesai Magang', value: '${n('selesai')}', sub: 'Program selesai', icon: Icons.check_circle_outline, tone: Tone.green),
                StatTile(label: 'DUDI Terlibat', value: '$dudiTerlibat', sub: 'Mitra aktif', icon: Icons.link, tone: Tone.purple),
              ]),
              if (d.pending.isNotEmpty) ...[
                const SizedBox(height: 24),
                _PendingCard(items: d.pending, onDecide: _decide),
              ],
              const SizedBox(height: 24),
              ToolbarCard(
                search: SearchBox(hint: 'Cari siswa, NIS, DUDI atau guru...', onChanged: (v) => setState(() => _q = v)),
                filters: [
                  FilterDropdown(value: _kelas, items: withAll('Semua Kelas', all.map((e) => e.kelas)), onChanged: (v) => setState(() => _kelas = v)),
                  FilterDropdown(value: _dudi, items: withAll('Semua DUDI', all.map((e) => e.dudi)), onChanged: (v) => setState(() => _dudi = v)),
                  FilterDropdown(value: _status, items: ['Semua Status', ..._statusLabel.values], onChanged: (v) => setState(() => _status = v)),
                ],
                count: '${rows.length} Penempatan',
                action: PrimaryAction(label: 'Tambah Penempatan', onPressed: _tambah),
              ),
              const SizedBox(height: 24),
              AdminTable<PenempatanRow>(
                minWidth: 1100,
                emptyText: 'Belum ada penempatan.',
                columns: [
                  Col(
                    'Siswa',
                    (r) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(r.siswa, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('NIS: ${r.nis}', style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                    ]),
                    flex: 2,
                  ),
                  Col('Kelas', (r) => Text(r.kelas), flex: 1),
                  Col('Tempat Magang', (r) => Text(r.dudi, overflow: TextOverflow.ellipsis), flex: 2),
                  Col('Guru Pembimbing', (r) => Text(r.pembimbing, overflow: TextOverflow.ellipsis, style: TextStyle(color: r.pembimbing == 'Belum ditentukan' ? c.mutedForeground : null)), flex: 2),
                  Col('Periode', (r) => Text('${tanggalPendek(r.mulai)} – ${tanggalPendek(r.selesai)}', style: const TextStyle(fontSize: 13)), flex: 2.2),
                  Col(
                    'Status',
                    (r) => switch (r.status) {
                      'selesai' => const Pill('Selesai', tone: Tone.green, dot: true),
                      'dibatalkan' => const Pill('Dibatalkan', tone: Tone.red, dot: true),
                      _ => const Pill('Berlangsung', tone: Tone.blue, dot: true),
                    },
                    flex: 1.4,
                  ),
                ],
                rows: rows,
                menuBuilder: (r) => [
                  const PopupMenuItem(value: 'pembimbing', child: Text('Tetapkan Pembimbing')),
                  if (r.status == 'aktif') const PopupMenuItem(value: 'selesai', child: Text('Tandai Selesai')),
                  if (r.status == 'aktif') const PopupMenuItem(value: 'batal', child: Text('Batalkan')),
                  const PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ],
                onMenuSelected: (a, r) => switch (a) {
                  'pembimbing' => _setPembimbing(r),
                  'selesai' => _setStatus(r, 'selesai'),
                  'batal' => _setStatus(r, 'dibatalkan'),
                  _ => _delete(r),
                },
              ),
            ]);
          },
        ),
      ],
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.items, required this.onDecide});

  final List<PengajuanRow> items;
  final Future<void> Function(PengajuanRow, bool) onDecide;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final amber = toneOf(Tone.amber);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: kPanelShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
            child: Row(children: [
              const IconTile(Icons.schedule, tone: Tone.amber, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Pengajuan Magang Menunggu Validasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF451A03))),
                  Text('Terdapat ${items.length} siswa yang telah mengajukan tempat magang dan menunggu penugasan pembimbing.', style: TextStyle(fontSize: 14, color: amber.fg)),
                ]),
              ),
              const SizedBox(width: 12),
              Pill('${items.length} Pengajuan', tone: Tone.amber, solid: true),
            ]),
          ),
          for (final p in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: BoxDecoration(color: c.muted.withValues(alpha: .55), border: const Border(top: BorderSide(color: Color(0xFFFDE68A)))),
              child: LayoutBuilder(builder: (context, cons) {
                final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 6, children: [
                    Text(p.siswa, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    CountBadge(p.kelas),
                    Text('NIS: ${p.nis}', style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 40, runSpacing: 8, children: [
                    _Meta(Icons.apartment_outlined, p.dudi, p.lokasi, Icons.place_outlined),
                    _Meta(Icons.work_outline, p.pic, 'Diajukan: ${tanggalPendek(p.diajukan)}', Icons.event_outlined),
                  ]),
                ]);
                final actions = Wrap(spacing: 12, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: () => onDecide(p, false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.destructive,
                      side: BorderSide(color: c.destructive.withValues(alpha: .3)),
                      backgroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => onDecide(p, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Setujui & Tempatkan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.success,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ]);
                return cons.maxWidth >= 860
                    ? Row(children: [Expanded(child: info), const SizedBox(width: 16), actions])
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, const SizedBox(height: 14), actions]);
              }),
            ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.title, this.sub, this.subIcon);

  final IconData icon;
  final String title;
  final String sub;
  final IconData subIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    Widget line(IconData i, String t, {bool strong = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 16, color: strong ? c.primary : c.mutedForeground),
          const SizedBox(width: 8),
          Flexible(child: Text(t, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: strong ? FontWeight.w500 : FontWeight.w400, color: strong ? c.foreground : c.mutedForeground))),
        ]);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [line(icon, title, strong: true), const SizedBox(height: 6), line(subIcon, sub)]),
    );
  }
}

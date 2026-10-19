import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/widgets/admin_table.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'data_page_helpers.dart';

class DudiPage extends StatefulWidget {
  const DudiPage({super.key, required this.repo});

  final AdminRepository repo;

  @override
  State<DudiPage> createState() => _DudiPageState();
}

class _DudiPageState extends State<DudiPage> {
  late Future<List<DudiRow>> _future = widget.repo.fetchDudi();
  String _q = '', _status = 'Semua Status';

  static const _statusLabel = {'terverifikasi': 'Terverifikasi', 'menunggu': 'Menunggu', 'ditolak': 'Ditolak'};

  void _reload() => setState(() => _future = widget.repo.fetchDudi());

  Future<void> _form({DudiRow? edit}) async {
    final v = await showFormDialog(
      context,
      title: edit == null ? 'Tambah DUDI' : 'Edit DUDI',
      fields: [
        const FieldSpec('nama', 'Nama perusahaan', required: true),
        const FieldSpec('alamat', 'Alamat'),
        const FieldSpec('kota', 'Kota'),
        const FieldSpec('bidang_usaha', 'Bidang usaha'),
        const FieldSpec('kontak_nama', 'Nama PIC'),
        const FieldSpec('kontak_telepon', 'Telepon PIC'),
        const FieldSpec('kuota', 'Kuota siswa', type: FieldType.number, required: true),
        FieldSpec('status', 'Status', type: FieldType.dropdown, required: true, options: [for (final e in _statusLabel.entries) Option(e.key, e.value)]),
      ],
      initial: edit == null
          ? const {'status': 'terverifikasi'}
          : {
              'nama': edit.nama,
              'alamat': edit.alamat,
              'kota': edit.kota,
              'bidang_usaha': edit.bidang == '—' ? '' : edit.bidang,
              'kontak_nama': edit.pic == '—' ? '' : edit.pic,
              'kontak_telepon': edit.kontak == '—' ? '' : edit.kontak,
              'kuota': edit.kuota,
              'status': edit.status,
            },
    );
    if (v == null || !mounted) return;
    final data = {...v, 'kuota': v['kuota'] ?? 0};
    final ok = await runAction(
      context,
      () => edit == null ? widget.repo.insertRow('dudi', data) : widget.repo.updateRow('dudi', edit.id, data),
      success: edit == null ? 'DUDI ditambahkan.' : 'DUDI diperbarui.',
    );
    if (ok) _reload();
  }

  Future<void> _delete(DudiRow r) async {
    if (!await confirmDialog(context, title: 'Hapus DUDI?', message: '${r.nama} akan dihapus. DUDI yang masih punya penempatan/permohonan tidak dapat dihapus.')) return;
    if (!mounted) return;
    final ok = await runAction(context, () => widget.repo.deleteRow('dudi', r.id), success: 'DUDI dihapus.');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      onRefresh: () async => _reload(),
      children: [
        AsyncBody<List<DudiRow>>(
          future: _future,
          onRetry: _reload,
          builder: (all) {
            final rows = all.where((r) => matches(_q, [r.nama, r.alamat, r.kota, r.bidang, r.pic]) && (_status == 'Semua Status' || _statusLabel[r.status] == _status)).toList();
            int n(String s) => all.where((r) => r.status == s).length;
            final ditempatkan = all.fold<int>(0, (s, r) => s + r.siswaAktif);

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ResponsiveGrid(minItemWidth: 240, maxColumns: 4, children: [
                StatTile(label: 'Total Mitra DUDI', value: '${all.length}', sub: 'perusahaan terdaftar', icon: Icons.apartment_outlined),
                StatTile(label: 'Terverifikasi', value: '${n('terverifikasi')}', sub: 'siap menerima siswa', icon: Icons.verified_user_outlined, tone: Tone.green),
                StatTile(label: 'Menunggu Validasi', value: '${n('menunggu')}', sub: 'perlu ditinjau', icon: Icons.schedule, tone: Tone.amber),
                StatTile(label: 'Siswa Ditempatkan', value: '$ditempatkan', sub: 'magang aktif', icon: Icons.groups_outlined, tone: Tone.purple),
              ]),
              const SizedBox(height: 24),
              ToolbarCard(
                search: SearchBox(hint: 'Cari perusahaan, alamat, atau bidang usaha...', onChanged: (v) => setState(() => _q = v)),
                filters: [FilterDropdown(value: _status, items: ['Semua Status', ..._statusLabel.values], onChanged: (v) => setState(() => _status = v))],
                count: '${rows.length} DUDI',
                action: PrimaryAction(label: 'Tambah DUDI', onPressed: () => _form()),
              ),
              const SizedBox(height: 24),
              AdminTable<DudiRow>(
                minWidth: 1100,
                emptyText: 'Tidak ada DUDI yang cocok.',
                columns: [
                  Col(
                    'Perusahaan',
                    (r) => Row(children: [
                      const IconTile(Icons.apartment_outlined, tone: Tone.green, size: 44),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text(r.nama, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          Text(r.lokasi, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                        ]),
                      ),
                    ]),
                    flex: 2.6,
                  ),
                  Col(
                    'PIC & Kontak',
                    (r) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(r.pic, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(r.kontak, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                    ]),
                    flex: 2,
                  ),
                  Col('Bidang Usaha', (r) => Text(r.bidang, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)), flex: 2),
                  Col('Kuota', (r) => CountBadge('${r.kuota}'), flex: .9),
                  Col('Siswa Aktif', (r) => CountBadge('${r.siswaAktif}', tone: Tone.blue, icon: Icons.groups_outlined), flex: 1.2),
                  Col(
                    'Status',
                    (r) => switch (r.status) {
                      'terverifikasi' => const Pill('Terverifikasi', tone: Tone.green, dot: true),
                      'menunggu' => const Pill('Menunggu', tone: Tone.amber, dot: true),
                      _ => const Pill('Ditolak', tone: Tone.red, dot: true),
                    },
                    flex: 1.5,
                  ),
                ],
                rows: rows,
                menuBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ],
                onMenuSelected: (a, r) => a == 'edit' ? _form(edit: r) : _delete(r),
              ),
            ]);
          },
        ),
      ],
    );
  }
}

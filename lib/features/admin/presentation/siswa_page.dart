import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/widgets/admin_table.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'data_page_helpers.dart';

class SiswaPage extends StatefulWidget {
  const SiswaPage({super.key, required this.repo});

  final AdminRepository repo;

  @override
  State<SiswaPage> createState() => _SiswaPageState();
}

class _SiswaPageState extends State<SiswaPage> {
  late Future<List<SiswaRow>> _future = widget.repo.fetchSiswa();
  String _q = '', _kelas = 'Semua Kelas', _industri = 'Semua Industri', _status = 'Semua Status';

  static const _statusLabel = {'belum_magang': 'Belum Magang', 'sedang_magang': 'Sedang Magang', 'lulus': 'Lulus Magang'};

  void _reload() => setState(() => _future = widget.repo.fetchSiswa());

  List<FieldSpec> get _fields => const [
        FieldSpec('nis', 'NIS', required: true),
        FieldSpec('nama', 'Nama lengkap', required: true),
        FieldSpec('kelas', 'Kelas', hint: 'mis. XII RPL 1'),
        FieldSpec('email', 'Email', type: FieldType.email),
      ];

  Future<void> _form({SiswaRow? edit}) async {
    final v = await showFormDialog(
      context,
      title: edit == null ? 'Tambah Siswa' : 'Edit Siswa',
      fields: _fields,
      initial: edit == null ? const {} : {'nis': edit.nis, 'nama': edit.nama, 'kelas': edit.kelas == '—' ? '' : edit.kelas, 'email': edit.email},
    );
    if (v == null || !mounted) return;
    final ok = await runAction(context, () async {
      final data = {'nis': v['nis'], 'nama': v['nama'], 'email': v['email'], 'kelas_id': await widget.repo.ensureKelasId(v['kelas'] as String?)};
      edit == null ? await widget.repo.insertRow('siswa', data) : await widget.repo.updateRow('siswa', edit.id, data);
    }, success: edit == null ? 'Siswa ditambahkan.' : 'Siswa diperbarui.');
    if (ok) _reload();
  }

  Future<void> _delete(SiswaRow r) async {
    if (!await confirmDialog(context, title: 'Hapus siswa?', message: '${r.nama} akan dihapus beserta permohonan dan penempatannya.')) return;
    if (!mounted) return;
    final ok = await runAction(context, () => widget.repo.deleteRow('siswa', r.id), success: 'Siswa dihapus.');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      onRefresh: () async => _reload(),
      children: [
        AsyncBody<List<SiswaRow>>(
          future: _future,
          onRetry: _reload,
          builder: (all) {
            final rows = all.where((r) {
              final st = _statusLabel[r.status] ?? r.status;
              return matches(_q, [r.nama, r.nis, r.kelas, r.email]) &&
                  (_kelas == 'Semua Kelas' || r.kelas == _kelas) &&
                  (_industri == 'Semua Industri' || r.industri == _industri) &&
                  (_status == 'Semua Status' || st == _status);
            }).toList();
            int n(String s) => all.where((r) => r.status == s).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResponsiveGrid(minItemWidth: 240, maxColumns: 4, children: [
                  StatTile(label: 'Total Siswa', value: '${all.length}', sub: 'Siswa terdaftar', icon: Icons.groups_outlined),
                  StatTile(label: 'Sedang Magang', value: '${n('sedang_magang')}', sub: 'Aktif di industri', icon: Icons.work_outline, tone: Tone.blue),
                  StatTile(label: 'Belum Magang', value: '${n('belum_magang')}', sub: 'Perlu ditempatkan', icon: Icons.schedule, tone: Tone.amber),
                  StatTile(label: 'Lulus Magang', value: '${n('lulus')}', sub: 'Selesai program', icon: Icons.school_outlined, tone: Tone.green),
                ]),
                const SizedBox(height: 24),
                ToolbarCard(
                  search: SearchBox(hint: 'Cari nama, NIS, atau kelas...', onChanged: (v) => setState(() => _q = v)),
                  filters: [
                    FilterDropdown(value: _kelas, items: withAll('Semua Kelas', all.map((e) => e.kelas)), onChanged: (v) => setState(() => _kelas = v)),
                    FilterDropdown(value: _industri, items: withAll('Semua Industri', all.map((e) => e.industri)), onChanged: (v) => setState(() => _industri = v)),
                    FilterDropdown(value: _status, items: ['Semua Status', ..._statusLabel.values], onChanged: (v) => setState(() => _status = v)),
                  ],
                  count: '${rows.length} Siswa',
                  action: PrimaryAction(label: 'Tambah Siswa', onPressed: () => _form()),
                ),
                const SizedBox(height: 24),
                AdminTable<SiswaRow>(
                  mobilePrimary: 1,
                  minWidth: 1100,
                  emptyText: 'Tidak ada siswa yang cocok.',
                  columns: [
                    Col('NIS', (r) => Text(r.nis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)), flex: 1.2),
                    Col(
                      'Nama Lengkap',
                      (r) => Row(children: [
                        InitialAvatar(r.nama.isEmpty ? '?' : r.nama.substring(0, 1)),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(r.nama, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            if (r.email.isNotEmpty) Text(r.email, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                          ]),
                        ),
                      ]),
                      flex: 2.4,
                    ),
                    Col('Kelas', (r) => Text(r.kelas), flex: .9),
                    Col(
                      'Status Magang',
                      (r) => switch (r.status) {
                        'sedang_magang' => const Pill('Sedang Magang', tone: Tone.blue, dot: true),
                        'lulus' => const Pill('Lulus Magang', tone: Tone.green, dot: true),
                        _ => const Pill('Belum Magang', tone: Tone.slate, dot: true),
                      },
                      flex: 1.5,
                    ),
                    Col('Industri', (r) => Text(r.industri, overflow: TextOverflow.ellipsis), flex: 1.8),
                    Col('Guru Pembimbing', (r) => Text(r.pembimbing, overflow: TextOverflow.ellipsis), flex: 1.8),
                  ],
                  rows: rows,
                  menuBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                  ],
                  onMenuSelected: (a, r) => a == 'edit' ? _form(edit: r) : _delete(r),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

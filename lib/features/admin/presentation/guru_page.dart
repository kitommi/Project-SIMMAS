import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/widgets/admin_table.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'data_page_helpers.dart';

class GuruPage extends StatefulWidget {
  const GuruPage({super.key, required this.repo});

  final AdminRepository repo;

  @override
  State<GuruPage> createState() => _GuruPageState();
}

class _GuruPageState extends State<GuruPage> {
  late Future<List<GuruRow>> _future = widget.repo.fetchGuru();
  String _q = '', _jurusan = 'Semua Jurusan', _status = 'Semua Status';

  void _reload() => setState(() => _future = widget.repo.fetchGuru());

  Future<void> _form({GuruRow? edit}) async {
    final v = await showFormDialog(
      context,
      title: edit == null ? 'Tambah Guru' : 'Edit Guru',
      fields: const [
        FieldSpec('nip', 'NIP'),
        FieldSpec('nama', 'Nama lengkap', required: true),
        FieldSpec('email', 'Email', type: FieldType.email),
        FieldSpec('jurusan', 'Jurusan', hint: 'mis. RPL'),
      ],
      initial: edit == null ? const {} : {'nip': edit.nip == '—' ? '' : edit.nip, 'nama': edit.nama, 'email': edit.email, 'jurusan': edit.jurusan == '—' ? '' : edit.jurusan},
    );
    if (v == null || !mounted) return;
    final ok = await runAction(
      context,
      () => edit == null ? widget.repo.insertRow('guru', v) : widget.repo.updateRow('guru', edit.id, v),
      success: edit == null ? 'Guru ditambahkan.' : 'Guru diperbarui.',
    );
    if (ok) _reload();
  }

  Future<void> _toggle(GuruRow r) async {
    final ok = await runAction(context, () => widget.repo.updateRow('guru', r.id, {'is_active': !r.aktif}), success: r.aktif ? 'Guru dinonaktifkan.' : 'Guru diaktifkan.');
    if (ok) _reload();
  }

  Future<void> _delete(GuruRow r) async {
    if (!await confirmDialog(context, title: 'Hapus guru?', message: '${r.nama} akan dihapus. Penempatan yang dibimbing menjadi tanpa pembimbing.')) return;
    if (!mounted) return;
    final ok = await runAction(context, () => widget.repo.deleteRow('guru', r.id), success: 'Guru dihapus.');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      onRefresh: () async => _reload(),
      children: [
        AsyncBody<List<GuruRow>>(
          future: _future,
          onRetry: _reload,
          builder: (all) {
            final rows = all.where((r) {
              final st = r.aktif ? 'Aktif' : 'Nonaktif';
              return matches(_q, [r.nama, r.nip, r.email]) && (_jurusan == 'Semua Jurusan' || r.jurusan == _jurusan) && (_status == 'Semua Status' || st == _status);
            }).toList();
            final aktif = all.where((r) => r.aktif).length;
            final totalBimbingan = all.fold<int>(0, (s, r) => s + r.bimbingan);
            final rata = all.isEmpty ? 0 : (totalBimbingan / all.length).round();

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ResponsiveGrid(minItemWidth: 260, maxColumns: 3, children: [
                StatTile(label: 'Total Guru Pembimbing', value: '${all.length}', sub: 'Guru terdaftar', icon: Icons.school_outlined),
                StatTile(label: 'Guru Aktif', value: '$aktif', sub: 'Siap membimbing', icon: Icons.check_circle_outline, tone: Tone.green),
                StatTile(label: 'Rata-rata Bimbingan', value: '$rata', sub: 'Siswa per guru', icon: Icons.groups_outlined, tone: Tone.purple),
              ]),
              const SizedBox(height: 24),
              ToolbarCard(
                search: SearchBox(hint: 'Cari nama atau NIP...', onChanged: (v) => setState(() => _q = v)),
                filters: [
                  FilterDropdown(value: _jurusan, items: withAll('Semua Jurusan', all.map((e) => e.jurusan)), onChanged: (v) => setState(() => _jurusan = v)),
                  FilterDropdown(value: _status, items: const ['Semua Status', 'Aktif', 'Nonaktif'], onChanged: (v) => setState(() => _status = v)),
                ],
                count: '${rows.length} Guru',
                action: PrimaryAction(label: 'Tambah Guru', onPressed: () => _form()),
              ),
              const SizedBox(height: 24),
              AdminTable<GuruRow>(
                mobilePrimary: 1,
                emptyText: 'Tidak ada guru yang cocok.',
                columns: [
                  Col('NIP', (r) => Text(r.nip, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)), flex: 1.8),
                  Col(
                    'Nama Lengkap',
                    (r) => Row(children: [
                      InitialAvatar(r.nama),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text(r.nama, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          if (r.email.isNotEmpty) Text(r.email, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                        ]),
                      ),
                    ]),
                    flex: 3,
                  ),
                  Col('Jurusan', (r) => Text(r.jurusan), flex: 1),
                  Col('Bimbingan', (r) => CountBadge('${r.bimbingan}', tone: r.bimbingan > 0 ? Tone.blue : Tone.slate, icon: Icons.groups_outlined), flex: 1),
                  Col('Status', (r) => r.aktif ? const Pill('Aktif', tone: Tone.green, dot: true) : const Pill('Nonaktif', tone: Tone.slate, dot: true), flex: 1),
                ],
                rows: rows,
                menuBuilder: (r) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'toggle', child: Text(r.aktif ? 'Nonaktifkan' : 'Aktifkan')),
                  const PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ],
                onMenuSelected: (a, r) => switch (a) {
                  'edit' => _form(edit: r),
                  'toggle' => _toggle(r),
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

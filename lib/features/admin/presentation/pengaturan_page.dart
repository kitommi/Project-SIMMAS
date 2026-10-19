import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/simmas_colors.dart';
import '../../../core/widgets/admin_ui.dart';
import '../data/admin_repository.dart';
import 'data_page_helpers.dart';

class _Field {
  const _Field(this.key, this.label, {this.hint, this.lines = 1});
  final String key;
  final String label;
  final String? hint;
  final int lines;
}

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key, required this.repo});

  final AdminRepository repo;

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  late Future<Map<String, dynamic>> _future = widget.repo.fetchSettings();
  final Map<String, TextEditingController> _ctrl = {};
  int _tab = 0;
  bool _saving = false;

  static const _tabs = ['Identitas Aplikasi', 'Halaman Depan', 'Data Sekolah'];
  static const _sections = <List<_Field>>[
    [
      _Field('nama_aplikasi', 'Nama Aplikasi'),
      _Field('deskripsi', 'Deskripsi', lines: 3),
      _Field('kontak_email', 'Email Kontak', hint: 'kontak@sekolah.sch.id'),
      _Field('kontak_telepon', 'Telepon Kontak'),
    ],
    [
      _Field('hero_judul', 'Hero Title'),
      _Field('hero_subjudul', 'Hero Subtitle', lines: 3),
    ],
    [
      _Field('nama_sekolah', 'Nama Sekolah'),
      _Field('kepala_sekolah', 'Kepala Sekolah'),
      _Field('nip_kepsek', 'NIP Kepala Sekolah'),
      _Field('alamat_sekolah', 'Alamat', lines: 3),
      _Field('telp_sekolah', 'Telepon Sekolah'),
    ],
  ];

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key, Map<String, dynamic> data) =>
      _ctrl.putIfAbsent(key, () => TextEditingController(text: data[key]?.toString() ?? ''));

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = {for (final e in _ctrl.entries) e.key: e.value.text.trim().isEmpty ? null : e.value.text.trim()};
    // Kolom NOT NULL tidak boleh dikirim null.
    for (final k in ['nama_aplikasi', 'deskripsi', 'hero_judul', 'hero_subjudul']) {
      if (data.containsKey(k) && data[k] == null) data.remove(k);
    }
    await runAction(context, () => widget.repo.saveSettings(data), success: 'Pengaturan disimpan.');
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      children: [
        AsyncBody<Map<String, dynamic>>(
          future: _future,
          onRetry: () => setState(() => _future = widget.repo.fetchSettings()),
          builder: (data) {
            // Semua field dibuat sekali agar nilai tab lain tidak hilang saat berpindah tab.
            for (final f in _sections.expand((e) => e)) {
              _controller(f.key, data);
            }
            OutlineInputBorder border(Color color, [double w = 1]) =>
                OutlineInputBorder(borderRadius: BorderRadius.circular(kRadius * 1.2), borderSide: BorderSide(color: color, width: w));

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: PillTabs(
                  labels: _tabs,
                  icons: const [Icons.tune, Icons.web_outlined, Icons.school_outlined],
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
              const SizedBox(height: 20),
              Panel(
                title: _tabs[_tab],
                subtitle: switch (_tab) {
                  0 => 'Nama, deskripsi, dan kontak yang tampil di seluruh aplikasi',
                  1 => 'Teks utama pada halaman depan (landing page)',
                  _ => 'Data resmi sekolah untuk surat dan laporan',
                },
                bodyPadding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final f in _sections[_tab])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(f.label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: c.mutedForeground)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _ctrl[f.key],
                            minLines: f.lines,
                            maxLines: f.lines,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: f.hint,
                              filled: true,
                              fillColor: c.background,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              enabledBorder: border(c.border),
                              focusedBorder: border(c.primary, 1.5),
                            ),
                          ),
                        ]),
                      ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: PrimaryAction(label: _saving ? 'Menyimpan...' : 'Simpan Pengaturan', icon: Icons.save_outlined, onPressed: _saving ? null : _save),
                    ),
                  ],
                ),
              ),
            ]);
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/photo_picker.dart';
import '../../../core/widgets/admin_table.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../admin/presentation/data_page_helpers.dart';
import '../data/siswa_repository.dart';
import 'siswa_widgets.dart';

class _Data {
  const _Data(this.status, this.jurnal);
  final MagangStatus status;
  final List<Jurnal> jurnal;
}

class _JurnalResult {
  const _JurnalResult(this.tanggal, this.kegiatan, this.kendala, this.foto);
  final DateTime tanggal;
  final String kegiatan;
  final String? kendala;
  final PickedPhoto? foto;
}

class SiswaJurnalPage extends StatefulWidget {
  const SiswaJurnalPage({super.key, required this.repo});

  final SiswaRepository repo;

  @override
  State<SiswaJurnalPage> createState() => _SiswaJurnalPageState();
}

class _SiswaJurnalPageState extends State<SiswaJurnalPage> {
  late Future<_Data> _future = _load();
  String _q = '';

  Future<_Data> _load() async {
    final status = await widget.repo.fetchStatus();
    final jurnal = await widget.repo.fetchJurnal();
    return _Data(status, jurnal);
  }

  void _reload() => setState(() => _future = _load());

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _tulis(_Data d) async {
    final r = await showDialog<_JurnalResult>(context: context, builder: (_) => const _JurnalDialog());
    if (r == null || !mounted) return;
    if (d.jurnal.any((j) => _sameDay(j.tanggal, r.tanggal))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jurnal untuk ${tanggalPendek(r.tanggal)} sudah ada. Edit jurnal tersebut.')));
      return;
    }
    final ok = await runAction(
      context,
      () => widget.repo.tambahJurnal(penempatanId: d.status.penempatan!.id, tanggal: r.tanggal, kegiatan: r.kegiatan, kendala: r.kendala, foto: r.foto),
      success: 'Jurnal tersimpan.',
    );
    if (ok) _reload();
  }

  Future<void> _edit(Jurnal j) async {
    final r = await showDialog<_JurnalResult>(context: context, builder: (_) => _JurnalDialog(edit: j));
    if (r == null || !mounted) return;
    final ok = await runAction(
      context,
      () => widget.repo.ubahJurnal(j.id, kegiatan: r.kegiatan, kendala: r.kendala, foto: r.foto),
      success: 'Jurnal diperbarui dan dikirim ulang untuk dinilai.',
    );
    if (ok) _reload();
  }

  Future<void> _hapus(Jurnal j) async {
    if (!await confirmDialog(context, title: 'Hapus jurnal?', message: 'Jurnal tanggal ${tanggalPendek(j.tanggal)} akan dihapus.')) return;
    if (!mounted) return;
    final ok = await runAction(context, () => widget.repo.hapusJurnal(j.id), success: 'Jurnal dihapus.');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      onRefresh: () async => _reload(),
      children: [
        AsyncBody<_Data>(
          future: _future,
          onRetry: _reload,
          builder: (d) {
            final approved = d.status.isMagangApproved;
            final rows = d.jurnal.where((j) => matches(_q, [j.kegiatan, j.kendala])).toList();
            final isMobile = MediaQuery.sizeOf(context).width < 640;

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (!approved) ...[AccessBanner(onAjukan: () => context.go('/siswa/pengajuan')), const SizedBox(height: 24)],
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.border), boxShadow: kPanelShadow),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    decoration: BoxDecoration(color: c.background.withValues(alpha: .7), border: Border(bottom: BorderSide(color: c.border))),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 12,
                      spacing: 16,
                      children: [
                        ConstrainedBox(constraints: BoxConstraints(maxWidth: 460, minWidth: isMobile ? 200 : 260), child: SearchBox(hint: 'Cari kegiatan atau kendala...', onChanged: (v) => setState(() => _q = v))),
                        PrimaryAction(label: 'Tulis Jurnal', onPressed: approved ? () => _tulis(d) : null),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: AdminTable<Jurnal>(
                      selectable: false,
                      showPager: rows.length > 10,
                      minWidth: isMobile ? 600 : 900,
                      emptyText: 'Belum ada jurnal.',
                      columns: [
                        Col('Tanggal', (j) => Text(tanggalPendek(j.tanggal), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)), flex: 1.6),
                        Col(
                          'Kegiatan',
                          (j) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(j.kegiatan, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            if (j.kendala.isNotEmpty) Text('Kendala: ${j.kendala}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.mutedForeground)),
                            if (j.status == 'ditolak' && j.catatanGuru.isNotEmpty) Text('Catatan guru: ${j.catatanGuru}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.destructive)),
                          ]),
                          flex: 4,
                        ),
                        Col(
                          'Foto',
                          (j) => j.foto == null
                              ? Text('–', style: TextStyle(color: c.mutedForeground))
                              : PhotoChip(
                                  label: 'Foto Kegiatan',
                                  onTap: () => showPhotoDialog(context, title: 'Foto Kegiatan — ${tanggalPendek(j.tanggal)}', urlFuture: widget.repo.signedUrl(SiswaRepository.bucketJurnal, j.foto!)),
                                ),
                          flex: 2,
                          align: Alignment.center,
                        ),
                        Col(
                          'Status',
                          (j) => switch (j.status) {
                            'disetujui' => const Pill('Disetujui', tone: Tone.green, dot: true),
                            'ditolak' => const Pill('Ditolak', tone: Tone.red, dot: true),
                            _ => const Pill('Menunggu', tone: Tone.slate, dot: true),
                          },
                          flex: 1.6,
                          align: Alignment.center,
                        ),
                        Col(
                          'Aksi',
                          (j) => j.bisaDiubah
                              ? Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(tooltip: 'Edit', onPressed: () => _edit(j), icon: Icon(Icons.edit_outlined, size: 20, color: c.mutedForeground)),
                                  IconButton(tooltip: 'Hapus', onPressed: () => _hapus(j), icon: Icon(Icons.delete_outline, size: 20, color: c.mutedForeground)),
                                ])
                              : Text('–', style: TextStyle(color: c.mutedForeground)), // 'disetujui': edit/hapus disembunyikan
                          flex: 1.6,
                          align: Alignment.center,
                        ),
                      ],
                      rows: rows,
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

/// Form tulis / edit jurnal: kegiatan, kendala, dan foto bukti (image_picker).
class _JurnalDialog extends StatefulWidget {
  const _JurnalDialog({this.edit});

  final Jurnal? edit;

  @override
  State<_JurnalDialog> createState() => _JurnalDialogState();
}

class _JurnalDialogState extends State<_JurnalDialog> {
  final _form = GlobalKey<FormState>();
  late final _kegiatan = TextEditingController(text: widget.edit?.kegiatan ?? '');
  late final _kendala = TextEditingController(text: widget.edit?.kendala ?? '');
  late DateTime _tanggal = widget.edit?.tanggal ?? DateTime.now();
  PickedPhoto? _foto;
  bool _fotoError = false;

  bool get _isEdit => widget.edit != null;

  @override
  void dispose() {
    _kegiatan.dispose();
    _kendala.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(context: context, initialDate: _tanggal, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _ambil({required bool galeri}) async {
    final f = await pickPhoto(gallery: galeri);
    if (f != null) {
      setState(() {
        _foto = f;
        _fotoError = false;
      });
    }
  }

  void _submit() {
    final valid = _form.currentState?.validate() ?? false;
    final needFoto = !_isEdit && _foto == null;
    if (needFoto) setState(() => _fotoError = true);
    if (!valid || needFoto) return;
    Navigator.pop(context, _JurnalResult(_tanggal, _kegiatan.text.trim(), _kendala.text.trim().isEmpty ? null : _kendala.text.trim(), _foto));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Jurnal' : 'Tulis Jurnal', style: const TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: _isEdit ? null : _pilihTanggal,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(tanggalLengkapTanpaHari(_tanggal)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _kegiatan,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Deskripsi kegiatan', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Deskripsi kegiatan wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _kendala,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Kendala (opsional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Text('FOTO BUKTI KEGIATAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: c.mutedForeground)),
                const SizedBox(height: 8),
                if (_foto != null)
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_foto!.bytes, height: 160, width: double.infinity, fit: BoxFit.cover)),
                if (_foto == null && _isEdit && widget.edit!.foto != null) Text('Foto sebelumnya dipertahankan bila tidak diganti.', style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(onPressed: () => _ambil(galeri: false), icon: const Icon(Icons.photo_camera_outlined, size: 18), label: const Text('Ambil Foto')),
                  OutlinedButton.icon(onPressed: () => _ambil(galeri: true), icon: const Icon(Icons.photo_library_outlined, size: 18), label: const Text('Pilih dari Galeri')),
                ]),
                if (_fotoError) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Foto bukti kegiatan wajib diunggah', style: TextStyle(fontSize: 12, color: c.destructive))),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}

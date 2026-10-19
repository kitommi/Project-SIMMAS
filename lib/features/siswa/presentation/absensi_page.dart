import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/photo_picker.dart';
import '../../../core/widgets/admin_table.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../admin/presentation/data_page_helpers.dart';
import '../data/siswa_repository.dart';
import 'siswa_widgets.dart';

class _Data {
  const _Data(this.status, this.rows);
  final MagangStatus status;
  final List<AbsensiSiswa> rows;
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

class SiswaAbsensiPage extends StatefulWidget {
  const SiswaAbsensiPage({super.key, required this.repo});

  final SiswaRepository repo;

  @override
  State<SiswaAbsensiPage> createState() => _SiswaAbsensiPageState();
}

class _SiswaAbsensiPageState extends State<SiswaAbsensiPage> {
  late Future<_Data> _future = _load();
  bool _busy = false;

  Future<_Data> _load() async {
    final status = await widget.repo.fetchStatus();
    final rows = await widget.repo.fetchAbsensiBulanIni();
    return _Data(status, rows);
  }

  void _reload() => setState(() => _future = _load());

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _clockIn(_Data d) async {
    // 1) Kamera DEPAN langsung terbuka saat tombol ditekan.
    //    Tidak ada pilihan galeri/file: absensi hanya dari jepretan kamera saat itu juga.
    final photo = await pickSelfieForAttendance(context);
    if (!mounted) return;
    if (photo == null) {
      _snack('Absensi dibatalkan. Foto selfie wajib diambil langsung dari kamera depan.');
      return;
    }

    // 2) Pilih status (Hadir / Izin / Sakit). Izin & Sakit wajib mengisi alasan.
    final choice = await showDialog<(String, String?)>(context: context, builder: (_) => _StatusDialog(photo: photo.bytes));
    if (choice == null || !mounted) return;
    final (status, alasan) = choice;

    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => widget.repo.clockIn(penempatanId: d.status.penempatan!.id, status: status, alasan: alasan, foto: photo),
      success: status == 'hadir' ? 'Clock In berhasil.' : 'Absensi ${status == 'izin' ? 'izin' : 'sakit'} tercatat.',
    );
    if (mounted) setState(() => _busy = false);
    if (ok) _reload();
  }

  Future<void> _clockOut(AbsensiSiswa today) async {
    // Kamera depan langsung terbuka (selfie) - HANYA real-time camera, TIDAK ADA opsi galeri.
    final photo = await pickSelfieForAttendance(context);
    if (!mounted) return;
    if (photo == null) {
      _snack('Absensi dibatalkan. Foto selfie wajib diambil secara real-time untuk Clock Out.');
      return;
    }
    setState(() => _busy = true);
    final ok = await runAction(context, () => widget.repo.clockOut(absensiId: today.id, foto: photo), success: 'Clock Out berhasil.');
    if (mounted) setState(() => _busy = false);
    if (ok) _reload();
  }

  void _preview(String title, String path) =>
      showPhotoDialog(context, title: title, urlFuture: widget.repo.signedUrl(SiswaRepository.bucketAbsensi, path));

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
            final now = DateTime.now();
            final today = d.rows.where((r) => _sameDay(r.tanggal, now)).firstOrNull;
            final isMobile = MediaQuery.sizeOf(context).width < 640;

            final canIn = approved && today == null && !_busy;
            final canOut = approved && today != null && today.status == 'hadir' && today.jamMasuk != null && today.jamKeluar == null && !_busy;

            final subtitle = !approved
                ? 'Absensi terkunci hingga tempat magang dan guru pembimbing ditetapkan'
                : today == null
                    ? 'Anda belum absen hari ini. Silakan Clock In.'
                    : today.status == 'hadir'
                        ? 'Clock In pukul ${jamMenit(today.jamMasuk)}${today.jamKeluar != null ? ' • Clock Out pukul ${jamMenit(today.jamKeluar)}' : ''}'
                        : 'Status hari ini: ${today.status == 'izin' ? 'Izin' : 'Sakit'}';

            final inBtn = FilledButton.icon(
              onPressed: canIn ? () => _clockIn(d) : null,
              icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.login, size: 18),
              label: const Text('Clock In'),
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: c.primary.withValues(alpha: .4),
                disabledForegroundColor: Colors.white.withValues(alpha: .9),
                minimumSize: Size(0, isMobile ? 44 : 48),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 22),
                textStyle: TextStyle(fontSize: isMobile ? 14 : 15, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
            final outBtn = FilledButton.icon(
              onPressed: canOut ? () => _clockOut(today) : null,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Clock Out'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: .4),
                disabledForegroundColor: Colors.white.withValues(alpha: .9),
                minimumSize: Size(0, isMobile ? 44 : 48),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 22),
                textStyle: TextStyle(fontSize: isMobile ? 14 : 15, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );

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
                      runSpacing: 16,
                      spacing: 16,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 620, minWidth: isMobile ? 200 : 280),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconTile(Icons.event_available_outlined, size: isMobile ? 40 : 48),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Status Kehadiran Hari Ini', style: TextStyle(fontSize: isMobile ? 15 : 17, fontWeight: FontWeight.w700)),
                                Text(subtitle, style: TextStyle(fontSize: isMobile ? 13 : 14, color: c.mutedForeground)),
                              ]),
                            ),
                          ]),
                        ),
                        isMobile
                            ? Row(children: [Expanded(child: inBtn), const SizedBox(width: 10), Expanded(child: outBtn)])
                            : Row(mainAxisSize: MainAxisSize.min, children: [inBtn, const SizedBox(width: 12), outBtn]),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('RIWAYAT BULAN INI', style: TextStyle(fontSize: isMobile ? 13 : 15, fontWeight: FontWeight.w700, letterSpacing: .6, color: c.mutedForeground)),
                      const SizedBox(height: 16),
                      AdminTable<AbsensiSiswa>(
                        selectable: false,
                        showPager: false,
                        minWidth: isMobile ? 600 : 900,
                        emptyText: 'Belum ada riwayat absensi bulan ini.',
                        columns: [
                          Col('Tanggal', (r) => Text(hariTanggalPendek(r.tanggal), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)), flex: 2),
                          Col(
                            'Status',
                            (r) => _StatusCell(r),
                            flex: 3,
                            align: Alignment.center,
                          ),
                          Col('Masuk', (r) => Text(r.jamMasuk == null ? '–' : jamMenit(r.jamMasuk), style: const TextStyle(fontSize: 15)), flex: 1.4, align: Alignment.center),
                          Col('Pulang', (r) => Text(r.jamKeluar == null ? '–' : jamMenit(r.jamKeluar), style: const TextStyle(fontSize: 15)), flex: 1.4, align: Alignment.center),
                          Col(
                            'Foto',
                            (r) => (r.fotoMasuk == null && r.fotoPulang == null)
                                ? Text('–', style: TextStyle(color: c.mutedForeground))
                                : Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
                                    if (r.fotoMasuk != null) PhotoChip(label: 'Foto Masuk', onTap: () => _preview('Foto Masuk — ${hariTanggalPendek(r.tanggal)}', r.fotoMasuk!)),
                                    if (r.fotoPulang != null) PhotoChip(label: 'Foto Pulang', onTap: () => _preview('Foto Pulang — ${hariTanggalPendek(r.tanggal)}', r.fotoPulang!)),
                                  ]),
                            flex: 3,
                            align: Alignment.center,
                          ),
                        ],
                        rows: d.rows,
                      ),
                    ]),
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

class _StatusCell extends StatelessWidget {
  const _StatusCell(this.r);

  final AbsensiSiswa r;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final pill = switch (r.status) {
      'hadir' => const Pill('Hadir', tone: Tone.green, dot: true),
      'izin' => const Pill('Izin', tone: Tone.blue, dot: true),
      'sakit' => const Pill('Sakit', tone: Tone.amber, dot: true),
      _ => const Pill('Alfa', tone: Tone.red, dot: true),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pill,
        if (r.autoAlfa) ...[const SizedBox(height: 4), const Pill('Diverifikasi', tone: Tone.green)],
        if (r.keterangan.isNotEmpty && r.status != 'hadir') ...[
          const SizedBox(height: 4),
          Text(r.keterangan, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
        ],
      ],
    );
  }
}

/// Pilihan status (Hadir / Izin / Sakit). Izin & Sakit wajib alasan.
class _StatusDialog extends StatefulWidget {
  const _StatusDialog({required this.photo});

  final Uint8List photo;

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  final _form = GlobalKey<FormState>();
  final _alasan = TextEditingController();
  String _status = 'hadir';

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labels = {'hadir': 'Hadir', 'izin': 'Izin', 'sakit': 'Sakit'};
    return AlertDialog(
      scrollable: true,
      title: const Text('Pilih Status Kehadiran', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(widget.photo, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 14),
              Wrap(spacing: 8, children: [
                for (final e in labels.entries)
                  ChoiceChip(label: Text(e.value), selected: _status == e.key, onSelected: (_) => setState(() => _status = e.key)),
              ]),
              if (_status != 'hadir') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _alasan,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Alasan ${_status == 'izin' ? 'izin' : 'sakit'}', border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Alasan wajib diisi' : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            Navigator.pop(context, (_status, _status == 'hadir' ? null : _alasan.text.trim()));
          },
          child: const Text('Simpan Absensi'),
        ),
      ],
    );
  }
}

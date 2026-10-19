import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../../admin/presentation/data_page_helpers.dart';
import '../data/siswa_repository.dart';

class SiswaPengajuanPage extends StatefulWidget {
  const SiswaPengajuanPage({super.key, required this.repo});

  final SiswaRepository repo;

  @override
  State<SiswaPengajuanPage> createState() => _SiswaPengajuanPageState();
}

class _SiswaPengajuanPageState extends State<SiswaPengajuanPage> {
  late Future<MagangStatus> _future = widget.repo.fetchStatus();

  void _reload() => setState(() => _future = widget.repo.fetchStatus());

  Future<void> _ajukan() async {
    final dudi = await widget.repo.dudiOptions();
    final periode = await widget.repo.periodeAktifId();
    if (!mounted) return;
    if (periode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada periode magang aktif. Hubungi admin sekolah.')));
      return;
    }
    if (dudi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada DUDI terverifikasi yang tersedia.')));
      return;
    }
    final v = await showFormDialog(
      context,
      title: 'Ajukan Tempat Magang',
      submitLabel: 'Ajukan',
      fields: [
        FieldSpec('dudi_id', 'Tempat magang (DUDI)', type: FieldType.dropdown, required: true, options: dudi),
        const FieldSpec('posisi', 'Posisi yang diajukan', hint: 'mis. Mobile Dev', required: true),
      ],
    );
    if (v == null || !mounted) return;
    final ok = await runAction(
      context,
      () => widget.repo.ajukanPermohonan(dudiId: v['dudi_id'] as String, periodeId: periode, posisi: v['posisi'] as String?),
      success: 'Pengajuan terkirim. Menunggu peninjauan sekolah.',
    );
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      onRefresh: () async => _reload(),
      children: [
        AsyncBody<MagangStatus>(
          future: _future,
          onRetry: _reload,
          builder: (s) {
            final p = s.pengajuan;
            if (p == null) {
              return Panel(
                bodyPadding: EdgeInsets.zero,
                child: BigEmptyState(
                  icon: Icons.send_outlined,
                  title: 'Belum Ada Pengajuan',
                  subtitle: 'Pilih tempat magang dari daftar mitra DUDI terverifikasi, lalu kirim pengajuan Anda.',
                  action: AppButton(label: 'Ajukan Tempat Magang Sekarang', expand: false, height: 48, onPressed: _ajukan),
                ),
              );
            }
            return _PengajuanCard(p: p, aktif: s.isMagangApproved, onAjukanUlang: _ajukan);
          },
        ),
      ],
    );
  }
}

class _PengajuanCard extends StatelessWidget {
  const _PengajuanCard({required this.p, required this.aktif, required this.onAjukanUlang});

  final PengajuanSiswa p;
  final bool aktif;
  final VoidCallback onAjukanUlang;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final isMobile = MediaQuery.sizeOf(context).width < 640;
    final badge = switch (p.status) {
      'disetujui' => const Pill('Disetujui', tone: Tone.green, dot: true),
      'ditolak' => const Pill('Ditolak', tone: Tone.red, dot: true),
      _ => const Pill('Menunggu', tone: Tone.amber, dot: true),
    };

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.border), boxShadow: kPanelShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            color: c.background.withValues(alpha: .6),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              runSpacing: 16,
              children: [
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _Stepper(status: p.status, compact: isMobile)),
                Padding(padding: const EdgeInsets.only(top: 8), child: badge),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: LayoutBuilder(builder: (context, cons) {
              final left = _DetailCard(p: p, isMobile: isMobile);
              final right = _StatusCard(p: p, aktif: aktif, onAjukanUlang: onAjukanUlang, isMobile: isMobile);
              if (cons.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [Expanded(child: left), const SizedBox(width: 28), Expanded(child: right)],
                );
              }
              return Column(children: [left, const SizedBox(height: 20), right]);
            }),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final blue = c.primary;
    final grey = c.border;
    final rejected = status == 'ditolak';
    final approved = status == 'disetujui';

    final stepWidth = compact ? 90.0 : 110.0;
    final stepIconSize = compact ? 36.0 : 44.0;
    final stepIconInner = compact ? 16.0 : 20.0;
    final lineWidth = compact ? 24.0 : 36.0;

    Widget step(IconData icon, String label, Color color) => SizedBox(
          width: stepWidth,
          child: Column(children: [
            Container(width: stepIconSize, height: stepIconSize, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, size: stepIconInner, color: Colors.white)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: compact ? 11 : 13, fontWeight: FontWeight.w600)),
          ]),
        );
    Widget line(Color color) => Padding(
          padding: EdgeInsets.only(top: (stepIconSize / 2) - 1.5),
          child: Container(width: lineWidth, height: 3, color: color),
        );

    final step3Color = approved ? c.success : (rejected ? c.destructive : grey);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        step(Icons.description_outlined, 'Ajukan', blue),
        line(blue),
        step(Icons.schedule, compact ? 'Ditinjau' : 'Ditinjau Sekolah', blue),
        line(approved || rejected ? step3Color : grey),
        step(rejected ? Icons.close : Icons.check_circle_outline, rejected ? 'Ditolak' : 'Disetujui', step3Color),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.p, this.isMobile = false});

  final PengajuanSiswa p;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;

    Widget row(IconData icon, Tone tone, String label, String value, [String? sub]) => Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(icon, tone: tone, size: isMobile ? 40 : 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: isMobile ? 13 : 14, color: c.mutedForeground)),
                Text(value, style: TextStyle(fontSize: isMobile ? 15 : 17, fontWeight: FontWeight.w700)),
                if (sub != null) Text(sub, style: TextStyle(fontSize: isMobile ? 13 : 14, color: c.mutedForeground)),
              ]),
            ),
          ]),
        );

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Detail Pengajuan Magang', style: TextStyle(fontSize: isMobile ? 17 : 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Informasi tempat magang yang diajukan.', style: TextStyle(fontSize: isMobile ? 13 : 14, color: c.mutedForeground)),
        row(Icons.apartment_outlined, Tone.blue, 'Tempat Magang (DUDI)', p.dudi, p.lokasi),
        row(Icons.work_outline, Tone.purple, 'Posisi yang Diajukan', p.posisi),
        row(Icons.calendar_month_outlined, Tone.green, 'Tanggal Pengajuan', tanggalLengkapTanpaHari(p.diajukan)),
      ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.p, required this.aktif, required this.onAjukanUlang, this.isMobile = false});

  final PengajuanSiswa p;
  final bool aktif;
  final VoidCallback onAjukanUlang;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;

    Widget shell({required Color bg, required Color border, required IconData icon, required Color iconColor, required String title, required String text, required List<Widget> actions}) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 28, vertical: isMobile ? 24 : 32),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
        child: Column(children: [
          Icon(icon, size: isMobile ? 36 : 40, color: iconColor),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 13 : 14, height: 1.5, color: c.foreground.withValues(alpha: .75))),
          if (actions.isNotEmpty) ...[const SizedBox(height: 18), Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 8, children: actions)],
        ]),
      );
    }

    switch (p.status) {
      case 'disetujui':
        return shell(
          bg: const Color(0xFFF0FDF4),
          border: const Color(0xFFBBF7D0),
          icon: Icons.check_circle_outline,
          iconColor: c.success,
          title: 'Pengajuan Magang Aktif',
          text: aktif ? 'Selamat! Anda sudah terdaftar dan aktif magang. Silakan isi absensi atau jurnal harian Anda.' : 'Pengajuan Anda disetujui. Penempatan sedang diproses oleh Admin.',
          actions: aktif
              ? [
                  FilledButton.icon(
                    onPressed: () => context.go('/siswa/absensi'),
                    icon: const Icon(Icons.event_available_outlined, size: 18),
                    label: const Text('Isi Absensi'),
                    style: FilledButton.styleFrom(backgroundColor: c.primary, minimumSize: const Size(0, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/siswa/jurnal'),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Tulis Jurnal'),
                    style: OutlinedButton.styleFrom(foregroundColor: c.foreground, backgroundColor: Colors.white, side: BorderSide(color: c.border), minimumSize: const Size(0, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ]
              : const [],
        );
      case 'ditolak':
        return shell(
          bg: const Color(0xFFFEF2F2),
          border: const Color(0xFFFECACA),
          icon: Icons.highlight_off,
          iconColor: c.destructive,
          title: 'Pengajuan Ditolak',
          text: p.catatan.isNotEmpty ? 'Catatan: ${p.catatan}' : 'Pengajuan Anda belum dapat disetujui. Silakan ajukan ke tempat magang lain.',
          actions: [AppButton(label: 'Ajukan Ulang', expand: false, height: 42, onPressed: onAjukanUlang)],
        );
      default:
        return shell(
          bg: const Color(0xFFFFFBEB),
          border: const Color(0xFFFDE68A),
          icon: Icons.schedule,
          iconColor: const Color(0xFFD97706),
          title: 'Menunggu Peninjauan',
          text: 'Pengajuan Anda sedang ditinjau oleh sekolah. Anda akan mendapat notifikasi setelah ada keputusan.',
          actions: const [],
        );
    }
  }
}

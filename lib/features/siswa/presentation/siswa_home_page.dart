import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_grid.dart';
import '../../auth/domain/app_user.dart';
import '../data/siswa_repository.dart';

class _Data {
  const _Data(this.status, this.jurnal);
  final MagangStatus status;
  final List<Jurnal> jurnal;
}

/// Dashboard siswa. Gatekeeping: tanpa penempatan aktif -> empty state "Belum
/// Mengajukan Magang".
class SiswaHomePage extends StatefulWidget {
  const SiswaHomePage({super.key, required this.user, required this.repository});

  final AppUser user;
  final SiswaRepository repository;

  @override
  State<SiswaHomePage> createState() => _SiswaHomePageState();
}

class _SiswaHomePageState extends State<SiswaHomePage> {
  late Future<_Data> _data = _load();

  Future<_Data> _load() async {
    final status = await widget.repository.fetchStatus();
    final jurnal = status.isMagangApproved ? await widget.repository.fetchJurnal(limit: 5) : <Jurnal>[];
    return _Data(status, jurnal);
  }

  Future<void> _reload() async {
    setState(() => _data = _load());
    await _data.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return FutureBuilder<_Data>(
      future: _data,
      builder: (context, snap) {
        if (snap.hasError) {
          return PageBody(onRefresh: _reload, children: [ErrorState('Gagal memuat data: ${snap.error}', onRetry: _reload)]);
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final status = snap.data!.status;
        final jurnal = snap.data!.jurnal;
        final penempatan = status.penempatan;

        // ── isMagangApproved == false ──
        if (penempatan == null) {
          return PageBody(
            onRefresh: _reload,
            children: [
              Panel(
                bodyPadding: EdgeInsets.zero,
                child: BigEmptyState(
                  icon: Icons.send_outlined,
                  title: 'Belum Mengajukan Magang',
                  subtitle: 'Anda belum mengajukan tempat magang atau pengajuan Anda masih dalam tahap verifikasi oleh Admin.',
                  action: AppButton(label: 'Ajukan Tempat Magang Sekarang', expand: false, height: 48, onPressed: () => context.go('/siswa/pengajuan')),
                ),
              ),
            ],
          );
        }

        // ── isMagangApproved == true ──
        final disetujui = jurnal.where((j) => j.status == 'disetujui').length;
        final menunggu = jurnal.where((j) => j.status == 'menunggu').length;
        return PageBody(
          onRefresh: _reload,
          children: [
            ResponsiveGrid(minItemWidth: 260, maxColumns: 3, children: [
              StatTile(label: 'Status Magang', value: 'Aktif', sub: penempatan.dudi, icon: Icons.work_outline, tone: Tone.blue),
              StatTile(label: 'Jurnal Disetujui', value: '$disetujui', sub: 'Sudah divalidasi guru', icon: Icons.check_circle_outline, tone: Tone.green),
              StatTile(label: 'Jurnal Menunggu', value: '$menunggu', sub: 'Menunggu validasi', icon: Icons.schedule, tone: Tone.amber),
            ]),
            Panel(
              title: 'Tempat Magang',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(penempatan.dudi, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(penempatan.lokasi, style: TextStyle(color: c.mutedForeground)),
                const SizedBox(height: 10),
                Text('Pembimbing: ${penempatan.pembimbing ?? 'Belum ditentukan'}'),
                Text('Periode: ${tanggalPendek(penempatan.mulai)} – ${tanggalPendek(penempatan.selesai)}'),
                const SizedBox(height: 16),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  AppButton(label: 'Isi Absensi', expand: false, height: 44, onPressed: () => context.go('/siswa/absensi')),
                  AppButton(label: 'Tulis Jurnal', variant: AppButtonVariant.outline, expand: false, height: 44, onPressed: () => context.go('/siswa/jurnal')),
                ]),
              ]),
            ),
            Panel(
              title: 'Jurnal Terbaru',
              trailing: TextButton(onPressed: () => context.go('/siswa/jurnal'), child: const Text('Lihat Semua')),
              child: jurnal.isEmpty
                  ? Text('Belum ada jurnal.', style: TextStyle(color: c.mutedForeground))
                  : Column(children: [
                      for (final j in jurnal)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(j.kegiatan, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(tanggalPendek(j.tanggal)),
                          trailing: Pill(
                            switch (j.status) {
                              'disetujui' => 'Disetujui',
                              'ditolak' => 'Ditolak',
                              _ => 'Menunggu',
                            },
                            tone: switch (j.status) {
                              'disetujui' => Tone.green,
                              'ditolak' => Tone.red,
                              _ => Tone.slate,
                            },
                            dot: true,
                          ),
                        ),
                    ]),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/widgets/admin_ui.dart';

/// Kartu peringatan kuning: akses kegiatan magang belum aktif.
class AccessBanner extends StatelessWidget {
  const AccessBanner({super.key, required this.onAjukan});

  final VoidCallback onAjukan;

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF7C2D12);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: kPanelShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconTile(Icons.shield_outlined, tone: Tone.amber, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Akses Kegiatan Magang Belum Aktif', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: brown)),
                const SizedBox(height: 6),
                const Text(
                  'Anda belum memiliki tempat magang yang disetujui. Anda baru dapat mengisi absensi harian dan jurnal kegiatan setelah pengajuan tempat magang disetujui oleh Admin.',
                  style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF1C1917)),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onAjukan,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    elevation: 2,
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: const StadiumBorder(),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Ajukan Tempat Magang'), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 16)]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol pill kecil untuk membuka preview foto ("Foto Masuk", dll).
class PhotoChip extends StatelessWidget {
  const PhotoChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 16, color: c.primary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.primary)),
          ],
        ),
      ),
    );
  }
}

/// Dialog preview foto dari URL bertanda tangan (bucket privat).
Future<void> showPhotoDialog(BuildContext context, {required String title, required Future<String> urlFuture}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ]),
            ),
            Flexible(
              child: FutureBuilder<String>(
                future: urlFuture,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const Padding(padding: EdgeInsets.all(40), child: Text('Foto tidak dapat dimuat.'));
                  }
                  if (!snap.hasData) {
                    return const Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator());
                  }
                  return InteractiveViewer(
                    child: Image.network(
                      snap.data!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) => progress == null ? child : const Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()),
                      errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(40), child: Text('Foto tidak dapat dimuat.')),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

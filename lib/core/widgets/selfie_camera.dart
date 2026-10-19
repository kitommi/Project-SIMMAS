import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Dialog selfie untuk absensi: kamera DEPAN tampil real-time di dalam dialog.
///
/// - Tidak ada pemilih file / galeri sama sekali; foto hanya bisa dari jepretan
///   kamera saat itu juga.
/// - HP (< 600px): layar penuh agar mudah dijangkau jempol.
/// - Setelah menjepret ada langkah konfirmasi (Ulangi / Gunakan Foto).
class SelfieCameraDialog extends StatefulWidget {
  const SelfieCameraDialog({super.key});

  @override
  State<SelfieCameraDialog> createState() => _SelfieCameraDialogState();
}

class _SelfieCameraDialogState extends State<SelfieCameraDialog> with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  String? _notice; // mis. "kamera depan tidak ditemukan"
  bool _capturing = false;
  (Uint8List, String)? _shot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // Lepas kamera saat aplikasi ke background, buka lagi saat kembali.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
      if (mounted) setState(() => _controller = null);
    } else if (state == AppLifecycleState.resumed && _shot == null && _error == null) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _error = null;
      _notice = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'Kamera tidak ditemukan pada perangkat ini.');
      }

      // Wajib kamera DEPAN. Hanya bila tidak ada (mis. webcam laptop yang
      // dilaporkan sebagai "external") dipakai kamera lain.
      CameraDescription? cam;
      for (final c in cameras) {
        if (c.lensDirection == CameraLensDirection.front) {
          cam = c;
          break;
        }
      }
      if (cam == null) {
        for (final c in cameras) {
          if (c.lensDirection == CameraLensDirection.external) {
            cam = c;
            break;
          }
        }
        cam ??= cameras.first;
        _notice = 'Kamera depan tidak terdeteksi, memakai kamera yang tersedia.';
      }

      final ctrl = CameraController(cam, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() => _controller = ctrl);
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } catch (_) {
      if (mounted) setState(() => _error = 'Kamera tidak dapat dibuka. Pastikan izin kamera sudah diberikan.');
    }
  }

  String _friendly(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
      case 'NotAllowedError':
        return 'Izin kamera ditolak. Aktifkan izin kamera untuk aplikasi/browser di pengaturan, lalu coba lagi.';
      case 'noCamera':
      case 'NotFoundError':
        return 'Kamera tidak ditemukan pada perangkat ini.';
      case 'NotReadableError':
        return 'Kamera sedang dipakai aplikasi lain. Tutup aplikasi tersebut lalu coba lagi.';
      default:
        return e.description ?? 'Kamera tidak dapat dibuka (${e.code}).';
    }
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await ctrl.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _shot = (bytes, file.name));
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal mengambil foto. Coba lagi.');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _retake() => setState(() => _shot = null);

  void _use() => Navigator.of(context).pop(_shot);

  @override
  Widget build(BuildContext context) {
    final fullscreen = MediaQuery.sizeOf(context).width < 600;
    final body = _buildBody(fullscreen);
    if (fullscreen) {
      return Dialog.fullscreen(backgroundColor: Colors.black, child: body);
    }
    return Dialog(
      backgroundColor: Colors.black,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720), child: body),
    );
  }

  Widget _buildBody(bool fullscreen) {
    final ctrl = _controller;
    final ready = ctrl != null && ctrl.value.isInitialized;

    Widget center;
    if (_error != null) {
      center = Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.no_photography_outlined, size: 48, color: Colors.white70),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
          const SizedBox(height: 20),
          Wrap(spacing: 12, children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
              child: const Text('Tutup'),
            ),
            FilledButton(onPressed: _initCamera, child: const Text('Coba Lagi')),
          ]),
        ]),
      );
    } else if (_shot != null) {
      center = Image.memory(_shot!.$1, fit: BoxFit.contain);
    } else if (ctrl != null && ctrl.value.isInitialized) {
      center = AspectRatio(aspectRatio: ctrl.value.aspectRatio, child: CameraPreview(ctrl));
    } else {
      center = const Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(height: 16),
        Text('Membuka kamera depan...', style: TextStyle(color: Colors.white70)),
      ]);
    }

    final bottom = _error != null
        ? const SizedBox.shrink()
        : _shot != null
            ? Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _retake,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Ulangi'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54), minimumSize: const Size(0, 52)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _use,
                    icon: const Icon(Icons.check),
                    label: const Text('Gunakan Foto'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  ),
                ),
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_notice ?? 'Posisikan wajah Anda di dalam layar', style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: ready && !_capturing ? _capture : null,
                  child: Opacity(
                    opacity: ready ? 1 : .4,
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: _capturing ? const Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(strokeWidth: 3)) : null,
                      ),
                    ),
                  ),
                ),
              ]);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(children: [
              const Expanded(child: Text('Foto Selfie Absensi', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Colors.white)),
            ]),
          ),
          Expanded(child: Center(child: center)),
          Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: bottom),
        ],
      ),
    );
  }
}

/// Membuka dialog selfie. Mengembalikan (bytes, nama) atau null bila dibatalkan.
Future<(Uint8List, String)?> showSelfieCameraDialog(BuildContext context) {
  return showDialog<(Uint8List, String)>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const SelfieCameraDialog(),
  );
}

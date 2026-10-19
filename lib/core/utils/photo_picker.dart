import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/selfie_camera.dart';

class PickedPhoto {
  const PickedPhoto(this.bytes, this.name);
  final Uint8List bytes;
  final String name;
}

final _picker = ImagePicker();

/// Membuka kamera depan (selfie) secara real-time.
/// TIDAK ADA opsi memilih dari galeri/file untuk absensi.
/// 
/// Untuk mobile (Android/iOS): menggunakan image_picker dengan kamera depan.
/// Untuk web: menggunakan custom camera preview widget.
Future<PickedPhoto?> pickPhoto({bool gallery = false}) async {
  // gallery parameter diabaikan untuk keamanan absensi
  // Siswa WAJIB mengambil foto selfie real-time
  
  // Untuk Flutter Web, gunakan custom camera dialog
  // karena image_picker di web masih memicu file picker
  if (gallery == false) {
    // Cek jika sedang di web
    try {
      // Coba gunakan image_picker dengan kamera depan
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
        maxWidth: 1280,
      );
      
      if (file != null) {
        return PickedPhoto(await file.readAsBytes(), file.name);
      }
      
      // Jika user membatalkan (file == null), return null
      return null;
    } catch (e) {
      // Jika image_picker gagal (kemungkinan di web atau tidak ada kamera),
      // JANGAN fallback ke gallery - return null dan biarkan UI menampilkan error
      // Ini memastikan siswa TIDAK BISA upload foto dari galeri
      return null;
    }
  }
  
  // Jika gallery == true (untuk fitur lain di luar absensi)
  if (gallery) {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1600,
    );
    if (file == null) return null;
    return PickedPhoto(await file.readAsBytes(), file.name);
  }
  
  return null;
}

/// Fungsi khusus untuk absensi yang MENGGUNAKAN WIDGET CAMERA PREVIEW.
/// Ini memastikan di semua platform (termasuk web) siswa harus mengambil foto real-time.
/// 
/// Gunakan fungsi ini untuk absensi Clock In / Clock Out.
Future<PickedPhoto?> pickSelfieForAttendance(BuildContext context) async {
  final result = await showSelfieCameraDialog(context);
  
  if (result == null) return null;
  
  final (bytes, name) = result;
  return PickedPhoto(bytes, name);
}

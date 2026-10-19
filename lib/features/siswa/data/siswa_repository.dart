import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/photo_picker.dart';
import '../../../core/widgets/form_dialog.dart';
import 'siswa_models.dart';

export 'siswa_models.dart';

/// Akses data panel peserta magang. RLS membatasi semua query ke data milik
/// siswa yang login.
class SiswaRepository {
  SiswaRepository(this._client);

  final SupabaseClient _client;

  static const bucketAbsensi = 'absensi-foto';
  static const bucketJurnal = 'jurnal-foto';

  List<Map<String, dynamic>> _rows(List<dynamic> d) => d.cast<Map<String, dynamic>>();

  String _two(int n) => n.toString().padLeft(2, '0');
  String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
  String _stamp() {
    final n = DateTime.now();
    return '${n.year}${_two(n.month)}${_two(n.day)}_${_two(n.hour)}${_two(n.minute)}${_two(n.second)}';
  }

  Future<String?> siswaId() async {
    final row = await _client.from('siswa').select('id').maybeSingle();
    return row?['id'] as String?;
  }

  Future<String> _upload(String bucket, String path, PickedPhoto foto) async {
    await _client.storage.from(bucket).uploadBinary(path, foto.bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    return path;
  }

  /// URL sementara (1 jam) untuk menampilkan foto dari bucket privat.
  Future<String> signedUrl(String bucket, String path) => _client.storage.from(bucket).createSignedUrl(path, 3600);

  // ───────────── Status magang ─────────────
  Future<Penempatan?> fetchPenempatanAktif() async {
    final rows = await _client
        .from('penempatan')
        .select('id, tanggal_mulai, tanggal_selesai, dudi(nama, alamat, kota), guru(nama)')
        .eq('status', 'aktif')
        .order('created_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : Penempatan.fromMap(_rows(rows).first);
  }

  Future<PengajuanSiswa?> fetchPengajuanTerbaru() async {
    final rows = await _client
        .from('permohonan_magang')
        .select('id, status, posisi, catatan, diajukan_at, dudi(nama, alamat, kota)')
        .order('diajukan_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : PengajuanSiswa.fromMap(_rows(rows).first);
  }

  Future<MagangStatus> fetchStatus() async {
    final r = await Future.wait<Object?>([fetchPenempatanAktif(), fetchPengajuanTerbaru()]);
    return MagangStatus(penempatan: r[0] as Penempatan?, pengajuan: r[1] as PengajuanSiswa?);
  }

  // ───────────── Pengajuan ─────────────
  /// DUDI yang boleh dipilih siswa: aktif & terverifikasi.
  Future<List<Option>> dudiOptions() async {
    final rows = await _client.from('dudi').select('id, nama').eq('is_active', true).eq('status', 'terverifikasi').order('nama');
    return _rows(rows).map((m) => Option(m['id'] as String, m['nama'] as String)).toList();
  }

  Future<String?> periodeAktifId() async {
    final row = await _client.from('periode_magang').select('id').eq('is_active', true).maybeSingle();
    return row?['id'] as String?;
  }

  Future<void> ajukanPermohonan({required String dudiId, required String periodeId, String? posisi}) async {
    final sid = await siswaId();
    if (sid == null) {
      throw const PostgrestException(message: 'Akun Anda belum dihubungkan ke data siswa. Hubungi admin.');
    }
    await _client.from('permohonan_magang').insert({
      'siswa_id': sid,
      'dudi_id': dudiId,
      'periode_id': periodeId,
      if (posisi != null && posisi.isNotEmpty) 'posisi': posisi,
    });
  }

  // ───────────── Absensi ─────────────
  /// Riwayat bulan ini. Sebelumnya server membuat 'Alfa' otomatis untuk
  /// hari kerja yang terlewat (RPC sync_my_alfa).
  Future<List<AbsensiSiswa>> fetchAbsensiBulanIni() async {
    try {
      await _client.rpc('sync_my_alfa');
    } catch (_) {
      // Belum ada penempatan / fungsi belum terpasang: abaikan.
    }
    final now = DateTime.now();
    final rows = await _client
        .from('kehadiran')
        .select('id, tanggal, status, jam_masuk, jam_keluar, keterangan, foto_masuk_path, foto_pulang_path, auto_alfa')
        .gte('tanggal', _iso(DateTime(now.year, now.month, 1)))
        .order('tanggal', ascending: false);
    return _rows(rows).map(AbsensiSiswa.fromMap).toList();
  }

  /// Clock In. Jam masuk dicatat SERVER (trigger), bukan dari perangkat.
  Future<void> clockIn({required String penempatanId, required String status, String? alasan, PickedPhoto? foto}) async {
    final sid = await siswaId();
    String? path;
    if (foto != null && sid != null) {
      path = await _upload(bucketAbsensi, '$sid/${_stamp()}_masuk.jpg', foto);
    }
    await _client.from('kehadiran').insert({
      'penempatan_id': penempatanId,
      'tanggal': _iso(DateTime.now()),
      'status': status,
      if (alasan != null && alasan.isNotEmpty) 'keterangan': alasan,
      if (path != null) 'foto_masuk_path': path,
    });
  }

  Future<void> clockOut({required String absensiId, required PickedPhoto foto}) async {
    final sid = await siswaId();
    if (sid == null) {
      throw const PostgrestException(message: 'Akun Anda belum dihubungkan ke data siswa.');
    }
    final path = await _upload(bucketAbsensi, '$sid/${_stamp()}_pulang.jpg', foto);
    await _client.from('kehadiran').update({
      'jam_keluar': DateTime.now().toUtc().toIso8601String(), // diganti jam server oleh trigger
      'foto_pulang_path': path,
    }).eq('id', absensiId);
  }

  // ───────────── Jurnal ─────────────
  Future<List<Jurnal>> fetchJurnal({int limit = 100}) async {
    final rows = await _client
        .from('jurnal')
        .select('id, tanggal, kegiatan, kendala, status, catatan_guru, foto_path')
        .order('tanggal', ascending: false)
        .limit(limit);
    return _rows(rows).map(Jurnal.fromMap).toList();
  }

  Future<void> tambahJurnal({
    required String penempatanId,
    required DateTime tanggal,
    required String kegiatan,
    String? kendala,
    PickedPhoto? foto,
  }) async {
    final sid = await siswaId();
    String? path;
    if (foto != null && sid != null) {
      path = await _upload(bucketJurnal, '$sid/${_stamp()}.jpg', foto);
    }
    await _client.from('jurnal').insert({
      'penempatan_id': penempatanId,
      'tanggal': _iso(tanggal),
      'kegiatan': kegiatan,
      if (kendala != null && kendala.isNotEmpty) 'kendala': kendala,
      if (path != null) 'foto_path': path,
    });
  }

  /// Edit jurnal ('menunggu'/'ditolak'). Trigger DB mengembalikan status
  /// ke 'menunggu' agar guru menilai ulang.
  Future<void> ubahJurnal(String id, {required String kegiatan, String? kendala, PickedPhoto? foto}) async {
    String? path;
    if (foto != null) {
      final sid = await siswaId();
      if (sid != null) path = await _upload(bucketJurnal, '$sid/${_stamp()}.jpg', foto);
    }
    await _client.from('jurnal').update({
      'kegiatan': kegiatan,
      'kendala': kendala,
      if (path != null) 'foto_path': path,
    }).eq('id', id);
  }

  Future<void> hapusJurnal(String id) async {
    await _client.from('jurnal').delete().eq('id', id);
  }
}

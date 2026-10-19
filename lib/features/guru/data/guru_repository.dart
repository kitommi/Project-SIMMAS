import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/form_dialog.dart';
import 'guru_models.dart';

/// Akses data panel guru pembimbing. RLS membatasi semua query ke
/// penempatan/jurnal/kehadiran/kunjungan milik guru yang login.
class GuruRepository {
  GuruRepository(this._client);

  final SupabaseClient _client;

  List<Map<String, dynamic>> _rows(List<dynamic> data) => data.cast<Map<String, dynamic>>();

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Siswa yang dibimbing (penempatan aktif & selesai).
  Future<List<BimbinganRow>> fetchBimbingan() async {
    final rows = await _client.from('v_penempatan_detail').select().order('created_at', ascending: false);
    return _rows(rows).map(BimbinganRow.fromMap).where((r) => r.status != 'dibatalkan').toList();
  }

  Future<List<JurnalItem>> fetchJurnal({int limit = 200}) async {
    final rows = await _client
        .from('jurnal')
        .select('id, tanggal, kegiatan, kendala, status, catatan_guru, foto_path, penempatan(siswa(nama, nis))')
        .order('tanggal', ascending: false)
        .limit(limit);
    return _rows(rows).map(JurnalItem.fromMap).toList();
  }

  Future<List<AbsensiItem>> fetchAbsensi({int limit = 200}) async {
    final rows = await _client
        .from('kehadiran')
        .select('id, tanggal, jam_masuk, jam_keluar, status, keterangan, penempatan(siswa(nama, nis))')
        .order('tanggal', ascending: false)
        .limit(limit);
    return _rows(rows).map(AbsensiItem.fromMap).toList();
  }

  /// Jumlah siswa bimbingan yang berstatus hadir hari ini.
  Future<int> hadirHariIni() async {
    final rows = await _client.from('kehadiran').select('id').eq('tanggal', _iso(DateTime.now())).eq('status', 'hadir');
    return rows.length;
  }

  Future<List<KunjunganItem>> fetchKunjungan() async {
    final rows = await _client.from('kunjungan_guru').select('id, tanggal, catatan, dudi(nama)').order('tanggal', ascending: false);
    return _rows(rows).map(KunjunganItem.fromMap).toList();
  }

  Future<List<Option>> dudiOptions() async {
    final rows = await _client.from('dudi').select('id, nama').eq('is_active', true).order('nama');
    return _rows(rows).map((m) => Option(m['id'] as String, m['nama'] as String)).toList();
  }

  /// UPDATE status jurnal. Trigger DB mengisi approved_by/approved_at dan
  /// mencegah guru mengubah isi kegiatan siswa.
  Future<void> updateStatusJurnal(String id, {required bool setuju, String? catatan}) async {
    await _client.from('jurnal').update({
      'status': setuju ? 'disetujui' : 'ditolak',
      if (catatan != null && catatan.isNotEmpty) 'catatan_guru': catatan,
    }).eq('id', id);
  }

  /// INSERT kunjungan atas nama guru yang login (RLS memeriksa guru_id).
  Future<void> tambahKunjungan({required String dudiId, required String tanggal, String? catatan}) async {
    final guru = await _client.from('guru').select('id').maybeSingle();
    if (guru == null) {
      throw const PostgrestException(message: 'Akun Anda belum dihubungkan ke data guru. Hubungi admin.');
    }
    await _client.from('kunjungan_guru').insert({
      'guru_id': guru['id'],
      'dudi_id': dudiId,
      'tanggal': tanggal,
      if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
    });
  }
}

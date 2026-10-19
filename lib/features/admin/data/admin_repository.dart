import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/form_dialog.dart';
import 'admin_models.dart';

/// Semua akses data halaman admin. Query tunduk pada RLS (hanya admin lolos).
class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  List<Map<String, dynamic>> _rows(List<dynamic> data) => data.cast<Map<String, dynamic>>();

  // ───────────── Dashboard ─────────────
  Future<DashboardStats> fetchStats() async =>
      DashboardStats.fromMap(await _client.from('v_dashboard_stats').select().single());

  Future<List<TrendPoint>> fetchTrend() async =>
      _rows(await _client.from('v_trend_pengajuan').select().order('bulan')).map(TrendPoint.fromMap).toList();

  Future<List<LogEntry>> fetchLogs({int limit = 200}) async => _rows(
        await _client.from('activity_logs').select().order('created_at', ascending: false).limit(limit),
      ).map(LogEntry.fromMap).toList();

  /// Realtime: emit setiap kali tabel permohonan berubah.
  Stream<void> permohonanChanges() =>
      _client.from('permohonan_magang').stream(primaryKey: ['id']).map((_) {});

  // ───────────── Daftar data ─────────────
  Future<List<SiswaRow>> fetchSiswa() async =>
      _rows(await _client.from('v_siswa_list').select().order('nama')).map(SiswaRow.fromMap).toList();

  Future<List<GuruRow>> fetchGuru() async =>
      _rows(await _client.from('v_guru_list').select().order('nama')).map(GuruRow.fromMap).toList();

  Future<List<DudiRow>> fetchDudi() async =>
      _rows(await _client.from('v_dudi_list').select().order('nama')).map(DudiRow.fromMap).toList();

  Future<List<PenempatanRow>> fetchPenempatan() async => _rows(
        await _client.from('v_penempatan_detail').select().order('created_at', ascending: false),
      ).map(PenempatanRow.fromMap).toList();

  Future<List<PengajuanRow>> fetchPengajuanMenunggu() async =>
      _rows(await _client.from('v_pengajuan_menunggu').select()).map(PengajuanRow.fromMap).toList();

  Future<List<MonitoringRow>> fetchMonitoring() async =>
      _rows(await _client.from('v_monitoring').select().order('siswa')).map(MonitoringRow.fromMap).toList();

  Future<List<KunjunganRow>> fetchKunjungan() async => _rows(
        await _client.from('v_kunjungan_detail').select().order('tanggal', ascending: false),
      ).map(KunjunganRow.fromMap).toList();

  // ───────────── Opsi dropdown ─────────────
  Future<List<Option>> siswaBelumMagang() async => _rows(
        await _client.from('v_siswa_list').select('id, nama, nis').eq('status_magang', 'belum_magang').order('nama'),
      ).map((m) => Option(m['id'] as String, '${m['nama']} (${m['nis']})')).toList();

  Future<List<Option>> dudiOptions() async => _rows(
        await _client.from('dudi').select('id, nama').eq('is_active', true).order('nama'),
      ).map((m) => Option(m['id'] as String, m['nama'] as String)).toList();

  Future<List<Option>> guruOptions() async => _rows(
        await _client.from('guru').select('id, nama').eq('is_active', true).order('nama'),
      ).map((m) => Option(m['id'] as String, m['nama'] as String)).toList();

  // ───────────── CRUD generik ─────────────
  Future<void> insertRow(String table, Map<String, dynamic> data) => _client.from(table).insert(data);

  Future<void> updateRow(String table, String id, Map<String, dynamic> data) =>
      _client.from(table).update(data).eq('id', id);

  Future<void> deleteRow(String table, String id) => _client.from(table).delete().eq('id', id);

  /// Cari kelas berdasarkan nama; buat bila belum ada. Mengembalikan id.
  Future<String?> ensureKelasId(String? nama) async {
    final n = nama?.trim() ?? '';
    if (n.isEmpty) return null;
    final found = await _client.from('kelas').select('id').eq('nama', n).maybeSingle();
    if (found != null) return found['id'] as String;
    final created = await _client.from('kelas').insert({'nama': n}).select('id').single();
    return created['id'] as String;
  }

  /// Penempatan manual: tanggal mengikuti periode magang yang aktif.
  Future<void> tambahPenempatan({required String siswaId, required String dudiId, String? guruId}) async {
    final periode = await _client.from('periode_magang').select('id, tanggal_mulai, tanggal_selesai').eq('is_active', true).maybeSingle();
    if (periode == null) {
      throw const PostgrestException(message: 'Belum ada periode magang aktif. Buat dan aktifkan periode terlebih dahulu.');
    }
    await _client.from('penempatan').insert({
      'siswa_id': siswaId,
      'dudi_id': dudiId,
      if (guruId != null) 'guru_id': guruId,
      'periode_id': periode['id'],
      'tanggal_mulai': periode['tanggal_mulai'],
      'tanggal_selesai': periode['tanggal_selesai'],
    });
  }

  /// Setujui/tolak permohonan. Trigger DB mengecek kuota & membuat penempatan.
  Future<void> setPermohonanStatus(String id, String status) =>
      _client.from('permohonan_magang').update({'status': status}).eq('id', id);

  // ───────────── Pengaturan & log ─────────────
  Future<Map<String, dynamic>> fetchSettings() async =>
      await _client.from('app_settings').select().eq('id', 1).single();

  Future<void> saveSettings(Map<String, dynamic> data) =>
      _client.from('app_settings').update(data).eq('id', 1);

  Future<void> clearLogs() => _client.rpc('clear_activity_logs');
}

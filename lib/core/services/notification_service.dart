import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  const AppNotification({required this.id, required this.judul, required this.isi, required this.dibaca, required this.waktu});
  final String id;
  final String judul;
  final String isi;
  final bool dibaca;
  final DateTime? waktu;

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'].toString(),
        judul: (m['judul'] as String?) ?? '',
        isi: (m['isi'] as String?) ?? '',
        dibaca: m['is_read'] == true,
        waktu: DateTime.tryParse('${m['created_at']}'),
      );
}

/// Notifikasi milik user yang login (RLS: hanya baris miliknya).
class NotificationService {
  NotificationService(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> latest({int limit = 8}) async {
    final rows = await _client.from('notifikasi').select().order('created_at', ascending: false).limit(limit);
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<void> markAllRead() async {
    await _client.from('notifikasi').update({'is_read': true}).eq('is_read', false);
  }
}

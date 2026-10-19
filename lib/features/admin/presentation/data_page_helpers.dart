import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Jalankan aksi tulis ke database dan tampilkan hasilnya sebagai SnackBar.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {required String success}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(success)));
    return true;
  } on PostgrestException catch (e) {
    final dupe = e.code == '23505';
    messenger.showSnackBar(SnackBar(content: Text(dupe ? 'Data sudah ada (duplikat).' : e.message)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
  }
  return false;
}

List<String> withAll(String all, Iterable<String> values) {
  final set = values.where((e) => e.isNotEmpty && e != '—').toSet().toList()..sort();
  return [all, ...set];
}

bool matches(String query, Iterable<String> fields) {
  final q = query.trim().toLowerCase();
  return q.isEmpty || fields.any((f) => f.toLowerCase().contains(q));
}

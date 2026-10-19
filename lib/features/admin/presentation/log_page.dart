import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_table.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../core/widgets/form_dialog.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'admin_dashboard_page.dart' show levelTone;
import 'data_page_helpers.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key, required this.repo});

  final AdminRepository repo;

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  late Future<List<LogEntry>> _future = widget.repo.fetchLogs();
  String _q = '', _level = 'Semua Level';

  void _reload() => setState(() => _future = widget.repo.fetchLogs());

  Future<void> _clear() async {
    if (!await confirmDialog(context, title: 'Bersihkan semua log?', message: 'Seluruh log aktivitas akan dihapus permanen dan tidak dapat dikembalikan.', confirmLabel: 'Bersihkan')) return;
    if (!mounted) return;
    final ok = await runAction(context, widget.repo.clearLogs, success: 'Log dibersihkan.');
    if (ok) _reload();
  }

  void _metadata(LogEntry l) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.aksi, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: SelectableText(const JsonEncoder.withIndent('  ').convert(l.metadata.isEmpty ? {'info': 'Tidak ada metadata'} : l.metadata), style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return PageBody(
      onRefresh: () async => _reload(),
      children: [
        AsyncBody<List<LogEntry>>(
          future: _future,
          onRetry: _reload,
          builder: (all) {
            final rows = all.where((l) => matches(_q, [l.aksi, l.email, l.ip, l.role]) && (_level == 'Semua Level' || l.level == _level)).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ToolbarCard(
                search: SearchBox(hint: 'Cari aksi, email, atau IP...', onChanged: (v) => setState(() => _q = v)),
                filters: [FilterDropdown(value: _level, items: const ['Semua Level', 'INFO', 'WARN', 'ERROR'], onChanged: (v) => setState(() => _level = v))],
                count: '${rows.length} Log',
                action: PrimaryAction(label: 'Bersihkan Log', icon: Icons.delete_outline, color: c.destructive, onPressed: all.isEmpty ? null : _clear),
              ),
              const SizedBox(height: 24),
              AdminTable<LogEntry>(
                mobilePrimary: 2,
                selectable: false,
                minWidth: 1000,
                emptyText: 'Belum ada log aktivitas.',
                columns: [
                  Col('Waktu', (l) => Text(waktuLengkap(l.waktu), style: const TextStyle(fontSize: 13)), flex: 2),
                  Col('Level', (l) => Pill(l.level, tone: levelTone(l.level)), flex: 1),
                  Col('Aksi', (l) => Text(l.aksi, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace')), flex: 2),
                  Col(
                    'Aktor',
                    (l) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(l.email, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(l.role, style: TextStyle(fontSize: 12, color: c.mutedForeground)),
                    ]),
                    flex: 2.4,
                  ),
                  Col('IP Address', (l) => Text(l.ip, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')), flex: 1.5),
                  Col('Metadata', (l) => TextButton(onPressed: () => _metadata(l), child: const Text('Lihat')), flex: 1),
                ],
                rows: rows,
              ),
            ]);
          },
        ),
      ],
    );
  }
}

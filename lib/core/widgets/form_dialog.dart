import 'package:flutter/material.dart';

import '../theme/simmas_colors.dart';

class Option {
  const Option(this.value, this.label);
  final String value;
  final String label;
}

enum FieldType { text, number, email, multiline, dropdown, date }

class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.type = FieldType.text,
    this.required = false,
    this.options = const [],
    this.hint,
  });

  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final List<Option> options;
  final String? hint;
}

/// Dialog form generik. Mengembalikan map nilai (number -> int, kosong -> null)
/// atau null bila dibatalkan.
Future<Map<String, dynamic>?> showFormDialog(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  Map<String, dynamic> initial = const {},
  String submitLabel = 'Simpan',
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _FormDialog(title: title, fields: fields, initial: initial, submitLabel: submitLabel),
  );
}

class _FormDialog extends StatefulWidget {
  const _FormDialog({required this.title, required this.fields, required this.initial, required this.submitLabel});

  final String title;
  final List<FieldSpec> fields;
  final Map<String, dynamic> initial;
  final String submitLabel;

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _ctrl = {
    for (final f in widget.fields.where((f) => f.type != FieldType.dropdown))
      f.key: TextEditingController(text: widget.initial[f.key]?.toString() ?? ''),
  };
  late final Map<String, String?> _drop = {
    for (final f in widget.fields.where((f) => f.type == FieldType.dropdown)) f.key: widget.initial[f.key]?.toString(),
  };

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final out = <String, dynamic>{};
    for (final f in widget.fields) {
      if (f.type == FieldType.dropdown) {
        out[f.key] = _drop[f.key];
      } else {
        final t = _ctrl[f.key]!.text.trim();
        out[f.key] = t.isEmpty ? null : (f.type == FieldType.number ? int.tryParse(t) : t);
      }
    }
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    OutlineInputBorder border([Color? color]) => OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color ?? c.border));

    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in widget.fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: f.type == FieldType.dropdown
                        ? DropdownButtonFormField<String>(
                            initialValue: _drop[f.key],
                            isExpanded: true,
                            decoration: InputDecoration(labelText: f.label, border: border(), enabledBorder: border()),
                            items: [for (final o in f.options) DropdownMenuItem(value: o.value, child: Text(o.label, overflow: TextOverflow.ellipsis))],
                            validator: (v) => f.required && v == null ? '${f.label} wajib dipilih' : null,
                            onChanged: (v) => _drop[f.key] = v,
                          )
                        : TextFormField(
                            controller: _ctrl[f.key],
                            maxLines: f.type == FieldType.multiline ? 3 : 1,
                            readOnly: f.type == FieldType.date,
                            onTap: f.type == FieldType.date
                                ? () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: now,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      String two(int n) => n.toString().padLeft(2, '0');
                                      _ctrl[f.key]!.text = '${picked.year}-${two(picked.month)}-${two(picked.day)}';
                                    }
                                  }
                                : null,
                            keyboardType: switch (f.type) {
                              FieldType.number => TextInputType.number,
                              FieldType.email => TextInputType.emailAddress,
                              FieldType.multiline => TextInputType.multiline,
                              _ => TextInputType.text,
                            },
                            decoration: InputDecoration(labelText: f.label, hintText: f.hint, border: border(), enabledBorder: border(), suffixIcon: f.type == FieldType.date ? const Icon(Icons.calendar_today_outlined, size: 18) : null),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (f.required && t.isEmpty) return '${f.label} wajib diisi';
                              if (f.type == FieldType.email && t.isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(t)) {
                                return 'Format email tidak valid';
                              }
                              if (f.type == FieldType.number && t.isNotEmpty && int.tryParse(t) == null) return 'Harus berupa angka';
                              return null;
                            },
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String message, String confirmLabel = 'Hapus', bool danger = true}) async {
  final c = context.sc;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: danger ? FilledButton.styleFrom(backgroundColor: c.destructive) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

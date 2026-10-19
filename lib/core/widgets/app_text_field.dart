import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/simmas_colors.dart';

/// Input bergaya situs asli: label 10px uppercase tracking 0.15em, tinggi ±44,
/// border `--border`, fokus `--primary`, error `--destructive`.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.labelTrailing,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final Widget? labelTrailing;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: c.mutedForeground,
                ),
              ),
              if (labelTrailing != null) labelTrailing!,
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          inputFormatters: inputFormatters,
          cursorColor: c.primary,
          style: TextStyle(fontSize: 14, color: c.foreground),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: c.mutedForeground),
            isDense: true,
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            suffixIcon: suffix,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            border: border(c.border),
            enabledBorder: border(c.border),
            disabledBorder: border(c.border),
            focusedBorder: border(c.primary, 1.5),
            errorBorder: border(c.destructive),
            focusedErrorBorder: border(c.destructive, 1.5),
            errorStyle: TextStyle(fontSize: 12, color: c.destructive),
          ),
        ),
      ],
    );
  }
}

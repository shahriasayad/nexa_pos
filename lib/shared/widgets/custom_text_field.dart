import 'package:flutter/material.dart';

import 'package:nexa_pos/core/theme/app_spacing.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool readOnly;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? hintText;
  final String? helperText;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.helperText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      enabled: enabled,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
      ),
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
    );
  }
}

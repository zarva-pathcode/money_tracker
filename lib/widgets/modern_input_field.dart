import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ModernInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final dynamic icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final String? prefixText;
  final TextStyle? textStyle;
  final TextInputAction? textInputAction;

  const ModernInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.readOnly = false,
    this.onTap,
    this.onSubmitted,
    this.focusNode,
    this.prefixText,
    this.textStyle,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      onTap: onTap,
      onFieldSubmitted: onSubmitted,
      textInputAction: textInputAction,
      style:
          textStyle ??
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontWeight: FontWeight.normal,
          fontSize: 15,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }
}

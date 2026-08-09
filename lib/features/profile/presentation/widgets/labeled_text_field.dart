import 'package:flutter/material.dart';

/// Standard labeled, validated text field used across every edit
/// screen — keeps required-field asterisks and error styling
/// consistent without repeating boilerplate in each screen.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            decoration: InputDecoration(hintText: hintText),
          ),
        ],
      ),
    );
  }
}

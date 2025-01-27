import 'package:burtonaletrail_app/AppColors.dart';
import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    Key? key,
    required this.hint,
    this.controller,
    this.suffix,
    this.validator,
    this.maxLines,
    this.keyboardType,
    this.isPassword =
        false, // New Field to indicate if this is a password Field
    this.isEmail = false, // New Field to indicate if this is an email Field
  }) : super(key: key);

  final String hint;
  final TextEditingController? controller;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final int? maxLines;
  final TextInputType? keyboardType;
  final bool isPassword; // To toggle the lock icon for password Fields
  final bool isEmail; // To toggle the envelope icon for email Fields

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return TextFormField(
      validator: validator,
      cursorColor: AppColors.primaryColor,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText:
          isPassword, // To handle password obscuring if it's a password field
      decoration: InputDecoration(
        filled: true, // Enable background color
        fillColor: const Color(0xFFFAFAFA), // Set the background color to #FAFAFA
        constraints: BoxConstraints(maxWidth: size.width, minWidth: size.width),
        suffixIcon: suffix,
        hintText: hint,
        prefixIcon: isEmail
            ? const Icon(Icons.email, color: AppColors.primaryColor)
            : isPassword
                ? const Icon(Icons.lock, color: AppColors.primaryColor)
                : null, // No prefix icon if neither isEmail nor isPassword

        // Remove all borders but keep the rounded corners
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none, // No border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none, // No border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none, // No border
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none, // No border
        ),
      ),
    );
  }
}

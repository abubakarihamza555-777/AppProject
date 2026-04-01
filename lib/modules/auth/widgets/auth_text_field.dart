import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool isPassword;
  final bool isEmail;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  
  const AuthTextField({
    super.key,
    required this.label,
    this.controller,
    this.isPassword = false,
    this.isEmail = false,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      validator: validator ?? _getDefaultValidator(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
  
  String? Function(String?)? _getDefaultValidator() {
    if (isEmail) {
      return (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Enter a valid email';
        }
        return null;
      };
    }
    if (isPassword) {
      return (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      };
    }
    return (value) {
      if (value == null || value.isEmpty) {
        return 'This field is required';
      }
      return null;
    };
  }
} 

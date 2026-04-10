import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../localization/language_provider.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _step = 1; // 1: email, 2: OTP, 3: new password
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _sendOTP() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = AuthService();
      await authService.resetPassword(_emailController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _step = 2;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _verifyOTP() async {
    setState(() => _isLoading = true);
    
    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _step = 3;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _resetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authService = AuthService();
      await authService.confirmPasswordReset(
        _emailController.text.trim(),
        _otpController.text,
        _newPasswordController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(height: 20),
                Text(
                  _step == 1 ? 'Reset Password' : 
                  _step == 2 ? 'Enter OTP' : 'Create New Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _step == 1 ? 'Enter your email to receive OTP' :
                  _step == 2 ? 'Enter the 6-digit code sent to your email' :
                  'Create your new password',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                if (_step == 1)
                  _buildEmailStep(),
                if (_step == 2)
                  _buildOTPStep(),
                if (_step == 3)
                  _buildNewPasswordStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmailStep() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade200,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Send OTP', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
  
  Widget _buildOTPStep() {
    return Column(
      children: [
        OtpTextField(
          numberOfFields: 6,
          borderColor: Colors.blue,
          focusedBorderColor: Colors.blue.shade800,
          showFieldAsBox: true,
          onCodeChanged: (code) {
            // Handle code changes
          },
          onSubmit: (code) {
            _otpController.text = code;
            _verifyOTP();
          },
        ),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade200,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Verify OTP', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            setState(() => _step = 1);
          },
          child: Text(
            'Back to Email',
            style: TextStyle(color: Colors.blue.shade600),
          ),
        ),
      ],
    );
  }
  
  Widget _buildNewPasswordStep() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: TextField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() => _obscureNewPassword = !_obscureNewPassword);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade200,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Reset Password', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

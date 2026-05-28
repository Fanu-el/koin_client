import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_notifications.dart';
import '../../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showAppSnackBar(context, 'Enter a valid email');
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(email);
    setState(() => _loading = false);
    if (ok && mounted) {
      setState(() => _codeSent = true);
    } else if (mounted) {
      showErrorSnackBar(context, auth.error ?? 'Failed to send code');
    }
  }

  Future<void> _resetPassword() async {
    final code = _codeCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (code.isEmpty || password.length < 8) {
      showAppSnackBar(context, 'Enter code and new password (min 8 chars)');
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(
      email: _emailCtrl.text.trim(),
      code: code,
      newPassword: password,
    );
    setState(() => _loading = false);
    if (ok && mounted) {
      showAppSnackBar(context, 'Password reset successfully');
      context.pop();
    } else if (mounted) {
      showErrorSnackBar(context, auth.error ?? 'Reset failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forgot your password?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your email and we'll send you a reset code.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !_codeSent,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              if (!_codeSent) ...[
                const SizedBox(height: 24),
                AppButton(
                  label: 'Send Reset Code',
                  onPressed: _sendCode,
                  loading: _loading,
                ),
              ] else ...[
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 10,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Reset Code',
                    counterText: '',
                    hintText: '------',
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'New Password',
                  controller: _passwordCtrl,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Reset Password',
                  onPressed: _resetPassword,
                  loading: _loading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

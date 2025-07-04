import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _codeSent = false;
  String _message = '';
  bool _loading = false;

  Future<void> _sendResetCode() async {
    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      await Amplify.Auth.resetPassword(username: _emailController.text.trim());
      setState(() {
        _codeSent = true;
        _message = 'Verification code sent. Check your email.';
      });
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmReset() async {
    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      final result = await Amplify.Auth.confirmResetPassword(
        username: _emailController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmationCode: _codeController.text.trim(),
      );
      if (result.isPasswordReset) {
        setState(() => _message = 'Password reset successful! Please log in.');
      } else {
        setState(() => _message = 'Password reset not complete. Try again.');
      }
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                if (_codeSent) ...[
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _confirmReset,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Confirm Reset'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: _loading ? null : _sendResetCode,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Send Reset Code'),
                  ),
                ],
                const SizedBox(height: 16),
                if (_message.isNotEmpty)
                  Text(
                    _message,
                    style: TextStyle(
                      color: _message.contains('successful')
                          ? Colors.green
                          : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

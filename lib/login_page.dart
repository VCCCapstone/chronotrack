import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'user/upload_page.dart';
import 'admin/admin_dashboard.dart';
import 'new_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _loading = false;

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT token');
    }
    final payload = base64.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return json.decode(decoded) as Map<String, dynamic>;
  }

  Future<bool> _isUserInAdminGroup() async {
    final session = await Amplify.Auth.fetchAuthSession();
    if (session is CognitoAuthSession && session.isSignedIn) {
      final idToken = session.userPoolTokensResult.value.idToken.raw;
      final payload = _decodeJwtPayload(idToken);
      final groups = payload['cognito:groups'];
      if (groups is List && groups.contains('admin')) {
        return true;
      }
    }
    return false;
  }

  Future<void> _signIn() async {
    setState(() {
      _errorMessage = '';
      _loading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (result.isSignedIn) {
        final isAdmin = await _isUserInAdminGroup();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                isAdmin ? const AdminDashboard() : UploadPage(userEmail: email),
          ),
        );
      } else if (result.nextStep.signInStep ==
          AuthSignInStep.confirmSignInWithNewPassword) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NewPasswordPage(userEmail: email),
          ),
        );
      } else {
        setState(() => _errorMessage =
            "Sign in failed. Step: ${result.nextStep.signInStep}");
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Unexpected error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ChronoTrack Login")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text("Sign in to continue", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter your email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter your password' : null,
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _signIn();
                            }
                          },
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text("Sign In"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

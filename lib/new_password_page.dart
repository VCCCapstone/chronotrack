import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'user/upload_page.dart';
import 'admin/admin_dashboard.dart';

class NewPasswordPage extends StatefulWidget {
  final String userEmail;
  const NewPasswordPage({super.key, required this.userEmail});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  String _errorMessage = '';
  bool _loading = false;

  Future<void> _confirmNewPassword() async {
    setState(() {
      _errorMessage = '';
      _loading = true;
    });

    try {
      final result = await Amplify.Auth.confirmSignIn(
        confirmationValue: _newPasswordController.text,
      );

      if (result.isSignedIn) {
        final attributes = await Amplify.Auth.fetchUserAttributes();
        final groupsAttr = attributes.firstWhere(
          (attr) => attr.userAttributeKey.key == 'custom:groups',
          orElse: () => const AuthUserAttribute(
            userAttributeKey: CognitoUserAttributeKey.email,
            value: '',
          ),
        );

        final isAdmin = groupsAttr.value.toLowerCase().contains('admin');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => isAdmin
                ? const AdminDashboard()
                : UploadPage(userEmail: widget.userEmail),
          ),
        );
      } else {
        setState(() => _errorMessage = "Could not confirm password.");
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
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set New Password")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Set a new password",
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(labelText: 'New Password'),
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter your new password' : null,
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty)
                    Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _confirmNewPassword();
                            }
                          },
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text("Confirm Password"),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SignupUserPage extends StatefulWidget {
  const SignupUserPage({super.key});

  @override
  State<SignupUserPage> createState() => _SignupUserPageState();
}

class _SignupUserPageState extends State<SignupUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedRole = 'user';

  bool _loading = false;
  String _statusMessage = '';

  Future<void> _createUser() async {
    setState(() {
      _loading = true;
      _statusMessage = '';
    });

    const apiUrl =
        "https://ocabzq1gce.execute-api.ca-central-1.amazonaws.com/prod/admin/create-user";

    final body = jsonEncode({
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "name": _nameController.text.trim(),
      "group": _selectedRole ?? 'user',
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/userCreated',
          (route) => false,
        );
      } else {
        final errorMsg = jsonDecode(response.body)["message"] ?? "Unknown error";
        setState(() {
          _statusMessage = "Failed: $errorMsg";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error occurred: $e";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Employee")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Enter employee details",
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter an email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration:
                        const InputDecoration(labelText: 'Temporary Password'),
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter a password' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text("User")),
                      DropdownMenuItem(value: 'admin', child: Text("Admin")),
                    ],
                    onChanged: (val) => setState(() => _selectedRole = val),
                    decoration: const InputDecoration(labelText: "Assign Role"),
                  ),
                  const SizedBox(height: 24),
                  if (_statusMessage.isNotEmpty)
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusMessage.startsWith("Failed")
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _createUser();
                            }
                          },
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text("Create User"),
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

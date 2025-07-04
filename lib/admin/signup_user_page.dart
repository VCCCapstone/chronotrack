// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupUserPage extends StatefulWidget {
  const SignupUserPage({super.key});

  @override
  State<SignupUserPage> createState() => _SignupUserPageState();
}

class _SignupUserPageState extends State<SignupUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _dob = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _reportsTo = TextEditingController();

  String? _selectedDepartment;
  String? _selectedRole;

  final List<String> departments = [
    'Transit',
    'NEMT',
    'HR',
    'Operations',
    'Schools Division',
    'Management',
    'Maintenance',
    'Other',
  ];

  final List<String> roles = ['user', 'admin'];

  final String createUrl =
      'https://t3ivt5ycc4.execute-api.ca-central-1.amazonaws.com/prod/employee/add';

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _dob.dispose();
    _phone.dispose();
    _address.dispose();
    _reportsTo.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year - 14, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: lastDate,
      firstDate: DateTime(1900),
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _dob.text =
            '${picked.day.toString().padLeft(2, '0')}-${_monthAbbr(picked.month)}-${picked.year}';
      });
    }
  }

  String _monthAbbr(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    final user = {
      "fullName": _fullName.text,
      "email": _email.text.toLowerCase().trim(),
      "password": _password.text,
      "dob": _dob.text,
      "phoneNumber": _phone.text,
      "address": _address.text,
      "department": _selectedDepartment ?? '',
      "reportsTo": _reportsTo.text,
      "role": _selectedRole ?? '',
      "profilePictureUrl": "", // Optional for now
    };

    final response = await http.post(
      Uri.parse(createUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );
      Navigator.pop(context);
    } else {
      print("❌ Failed: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create user: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New User'),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField("Full Name", _fullName),
                    _buildTextField("Email", _email, email: true),
                    _buildTextField("Password", _password, obscure: true),
                    GestureDetector(
                      onTap: _pickDob,
                      child: AbsorbPointer(
                        child: _buildTextField("DOB (DD-MMM-YYYY)", _dob),
                      ),
                    ),
                    _buildTextField("Phone Number", _phone),
                    _buildTextField("Address", _address),
                    _buildDropdown(
                      "Department",
                      departments,
                      _selectedDepartment,
                      (val) => setState(() => _selectedDepartment = val),
                    ),
                    _buildTextField("Reporting Manager", _reportsTo),
                    _buildDropdown(
                      "Role",
                      roles,
                      _selectedRole,
                      (val) => setState(() => _selectedRole = val),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _createUser,
                      child: const Text('Create User'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool email = false,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> options,
    String? value,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
      ),
    );
  }
}

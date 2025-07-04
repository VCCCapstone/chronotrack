// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminViewEditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const AdminViewEditProfilePage({super.key, required this.profile});

  @override
  State<AdminViewEditProfilePage> createState() =>
      _AdminViewEditProfilePageState();
}

class _AdminViewEditProfilePageState extends State<AdminViewEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController fullNameController;
  late TextEditingController dobController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController reportsToController;

  String? selectedDepartment;
  String? selectedRole;

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

  final String updateUrl =
      'https://t3ivt5ycc4.execute-api.ca-central-1.amazonaws.com/prod/employee/update';

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    fullNameController = TextEditingController(text: p['fullName'] ?? '');
    dobController = TextEditingController(text: p['dob'] ?? '');
    phoneController = TextEditingController(text: p['phoneNumber'] ?? '');
    addressController = TextEditingController(text: p['address'] ?? '');
    reportsToController = TextEditingController(text: p['reportsTo'] ?? '');
    selectedDepartment = departments.contains(p['department'])
        ? p['department']
        : departments.first;
    selectedRole = roles.contains(p['role']) ? p['role'] : roles.first;
  }

  Future<void> _pickDob() async {
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 20),
    );
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now().subtract(const Duration(days: 365 * 14));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        dobController.text =
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = {
      "email": widget.profile['email'],
      "fullName": fullNameController.text.trim(),
      "dob": dobController.text.trim(),
      "phoneNumber": phoneController.text.trim(),
      "address": addressController.text.trim(),
      "department": selectedDepartment?.trim() ?? '',
      "reportsTo": reportsToController.text.trim(),
      "role": selectedRole?.trim() ?? '',
    };

    final response = await http.post(
      Uri.parse(updateUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(profile),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    } else {
      print("❌ Failed to update: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.profile['email'] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Email: $email",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildField(fullNameController, "Full Name"),
              GestureDetector(
                onTap: _pickDob,
                child: AbsorbPointer(
                  child: _buildField(
                    dobController,
                    "Date of Birth (DD-MMM-YYYY)",
                  ),
                ),
              ),
              _buildField(phoneController, "Phone Number"),
              _buildField(addressController, "Address"),
              _buildDropdown("Department", departments, selectedDepartment, (
                val,
              ) {
                setState(() => selectedDepartment = val);
              }),
              _buildField(reportsToController, "Reporting Manager"),
              _buildDropdown("Role (Cognito Group)", roles, selectedRole, (
                val,
              ) {
                setState(() => selectedRole = val);
              }),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: options
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }
}

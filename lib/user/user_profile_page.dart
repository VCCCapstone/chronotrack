// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> profile = {};
  String status = '';
  String? _previewImageUrl;

  final List<String> departments = [
    'NEMT',
    'Transit',
    'School Division',
    'HR',
    'IT',
    'Management',
    'Operations',
    'Marketing',
  ];

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final email = attributes
          .firstWhere((a) => a.userAttributeKey.key == 'email')
          .value;

      final response = await http.get(
        Uri.parse(
          'https://t3ivt5ycc4.execute-api.ca-central-1.amazonaws.com/prod/employee/get?email=$email',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profile = data;
          _previewImageUrl = data['profilePictureUrl'];
        });
      } else {
        setState(() => status = 'Failed to load profile.');
      }
    } catch (e) {
      setState(() => status = 'Error fetching profile: $e');
    }
  }

  Future<void> uploadProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg'],
    );
    if (result == null || result.files.single.bytes == null) return;

    final fileBytes = result.files.single.bytes!;
    final email = profile['email']?.toString().toLowerCase();
    if (email == null || email.isEmpty) return;

    final extension = 'jpg';

    final presignUri = Uri.parse(
      'https://01c0sut2b7.execute-api.ca-central-1.amazonaws.com/prod/profile-pic-url?email=${Uri.encodeComponent(email)}&extension=$extension',
    );

    final presignRes = await http.get(presignUri);

    if (presignRes.statusCode == 200) {
      final body = jsonDecode(presignRes.body);
      final uploadUrl = body['upload_url'];
      final fileUrl = body['file_url'];

      final putRes = await http.put(
        Uri.parse(uploadUrl),
        body: fileBytes,
        headers: {'Content-Type': 'image/jpeg'},
      );

      if (putRes.statusCode == 200) {
        setState(() {
          _previewImageUrl = fileUrl;
        });

        final updatedProfile = {...profile, 'profilePictureUrl': fileUrl};

        final updateRes = await http.post(
          Uri.parse(
            'https://t3ivt5ycc4.execute-api.ca-central-1.amazonaws.com/prod/employee/update-picture',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updatedProfile),
        );

        setState(() {
          status = updateRes.statusCode == 200
              ? '✅ Profile picture updated.'
              : '❌ Failed to update picture.';
        });
      } else {
        setState(() => status = '❌ Upload to S3 failed.');
      }
    } else {
      setState(() => status = '❌ Failed to get pre-signed URL.');
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      final response = await http.post(
        Uri.parse(
          'https://t3ivt5ycc4.execute-api.ca-central-1.amazonaws.com/prod/employee/update',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile),
      );

      setState(() {
        status = response.statusCode == 200
            ? '✅ Profile updated successfully.'
            : '❌ Failed to update profile.';
      });
    } catch (e) {
      setState(() => status = 'Error saving profile: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      setState(() => status = 'Sign out failed: $e');
    }
  }

  Widget _buildInitialAvatar(String initials) {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.purple,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildField(String key, String label, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: profile[key]?.toString() ?? '',
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSaved: (val) => profile[key] = val,
      ),
    );
  }

  Widget _buildDropdownField(String key, String label, List<String> items) {
    final currentValue = items.firstWhere(
      (item) =>
          item.toLowerCase() == (profile[key]?.toString().toLowerCase() ?? ''),
      orElse: () => "Other",
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (val) => setState(() => profile[key] = val),
        onSaved: (val) => profile[key] = val,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purple = theme.colorScheme.primary;

    final initials = (profile['fullName'] ?? '')
        .toString()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: profile.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _previewImageUrl != null && _previewImageUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: NetworkImage(_previewImageUrl!),
                            )
                          : _buildInitialAvatar(initials),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: uploadProfilePicture,
                          child: CircleAvatar(
                            backgroundColor: purple,
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildField('fullName', 'Full Name', enabled: false),
                        _buildField('dob', 'Date of Birth', enabled: false),
                        _buildField('phoneNumber', 'Phone Number'),
                        _buildField('address', 'Address'),
                        _buildDropdownField(
                          'department',
                          'Department',
                          departments,
                        ),
                        _buildField('reportsTo', 'Reporting Manager'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(status),
                ],
              ),
            ),
    );
  }
}

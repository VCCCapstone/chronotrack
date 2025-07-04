import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminSelfProfilePage extends StatefulWidget {
  const AdminSelfProfilePage({super.key});

  @override
  State<AdminSelfProfilePage> createState() => _AdminSelfProfilePageState();
}

class _AdminSelfProfilePageState extends State<AdminSelfProfilePage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> profile = {};
  String status = '';
  String? _previewImageUrl;
  bool _loading = true;

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
  final _apiBase =
      'https://t3ivt5ycc4.execute-api.ca-central-1.amazonaws.com/prod';

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

      final uri = Uri.parse('$_apiBase/employee/get?email=$email');
      final res = await http.get(uri);
      final data = json.decode(res.body);

      setState(() {
        profile = data;
        final url = (data['profilePictureUrl'] ?? '').toString();
        _previewImageUrl = url.isNotEmpty ? url : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        status = '❌ Failed to fetch profile';
        _loading = false;
      });
    }
  }

  Future<void> updateProfile() async {
    final uri = Uri.parse('$_apiBase/employee/update');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(profile),
    );
    setState(() {
      status = res.statusCode == 200
          ? '✅ Profile updated'
          : '❌ Failed to update profile';
    });
  }

  Future<void> uploadProfilePicture() async {
    final fileResult = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (fileResult == null) return;

    final file = fileResult.files.first;
    final email = profile['email'];
    final filename =
        email.replaceAll(RegExp(r'[^\w]'), '_') + '_ProfilePic.png';

    final urlRes = await http.get(
      Uri.parse('$_apiBase/profile-pic-url?email=$email'),
    );
    final url = json.decode(urlRes.body)['uploadUrl'];

    await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'image/png'},
      body: file.bytes,
    );

    final updateRes = await http.post(
      Uri.parse('$_apiBase/employee/update-picture'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'profilePictureUrl':
            'https://employee-profile-pictures-bucket.s3.ca-central-1.amazonaws.com/$filename',
      }),
    );

    if (updateRes.statusCode == 200) {
      setState(() {
        _previewImageUrl =
            'https://employee-profile-pictures-bucket.s3.ca-central-1.amazonaws.com/$filename';
        status = '✅ Profile picture updated';
      });
    } else {
      setState(() => status = '❌ Failed to upload picture');
    }
  }

  Widget buildAvatar() {
    final name = profile['fullName']?.trim();
    final initials = (name != null && name.isNotEmpty)
        ? name
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .join()
              .toUpperCase()
        : 'AD';

    if (_previewImageUrl != null && _previewImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(_previewImageUrl!),
      );
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.deepPurple,
        child: Text(
          initials,
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      );
    }
  }

  Widget buildTextField(String key, String label, {bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: profile[key] ?? '',
        readOnly: isReadOnly,
        onChanged: (val) => profile[key] = val,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildDatePickerField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        readOnly: true,
        controller: TextEditingController(text: profile[key] ?? ''),
        onTap: () async {
          final now = DateTime.now();
          final minDate = DateTime(now.year - 14, now.month, now.day);
          final picked = await showDatePicker(
            context: context,
            initialDate: minDate,
            firstDate: DateTime(1900),
            lastDate: minDate,
          );
          if (picked != null) {
            setState(
              () => profile[key] =
                  '${picked.day.toString().padLeft(2, '0')}-'
                  '${_monthName(picked.month)}-${picked.year}',
            );
          }
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
      ),
    );
  }

  String _monthName(int month) {
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

  Widget buildDropdown(String key, String label, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: profile[key] != '' ? profile[key] : null,
        onChanged: (val) => setState(() => profile[key] = val),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map((dep) => DropdownMenuItem(value: dep, child: Text(dep)))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purple = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Profile',
            onPressed: updateProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      buildAvatar(),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: InkWell(
                          onTap: uploadProfilePicture,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: purple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
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
                        buildTextField('fullName', 'Full Name'),
                        buildTextField('email', 'Email', isReadOnly: true),
                        buildDatePickerField('dob', 'Date of Birth'),
                        buildTextField('phoneNumber', 'Phone Number'),
                        buildTextField('address', 'Address'),
                        buildDropdown('department', 'Department', departments),
                        buildTextField('reportsTo', 'Reporting Manager'),
                        //buildTextField('role', 'Role', isReadOnly: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    status,
                    style: TextStyle(
                      color: status.startsWith('✅') ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

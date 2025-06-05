import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class UserProfilePage extends StatefulWidget {
  final String userEmail;
  const UserProfilePage({super.key, required this.userEmail});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _departmentController = TextEditingController();
  final _reportsToController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageUrl;
  bool _loading = false;
  String _statusMessage = '';

  Future<void> _pickAndUploadProfilePic() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowedExtensions: ['jpg', 'png'],
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;

      setState(() {
        _imageBytes = bytes;
        _statusMessage = 'Uploading image...';
      });

      final urlEndpoint =
          "https://01c0sut2b7.execute-api.ca-central-1.amazonaws.com/prod/profile-pic-url?filename=$name";

      try {
        final urlResponse = await http.get(Uri.parse(urlEndpoint));
        final uploadUrl = jsonDecode(urlResponse.body)['upload_url'];

        final uploadResponse = await http.put(
          Uri.parse(uploadUrl),
          headers: {"Content-Type": "image/jpeg"},
          body: bytes,
        );

        if (uploadResponse.statusCode == 200) {
          final finalImageUrl =
              uploadUrl.split('?').first; // strip signed query
          setState(() {
            _imageUrl = finalImageUrl;
            _statusMessage = "Profile picture uploaded!";
          });
        } else {
          setState(() => _statusMessage = "Upload failed");
        }
      } catch (e) {
        setState(() => _statusMessage = "Upload error: $e");
      }
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _statusMessage = '';
    });

    final profileData = {
      "email": widget.userEmail,
      "fullName": _fullNameController.text,
      "dob": _dobController.text,
      "phoneNumber": _phoneController.text,
      "address": _addressController.text,
      "department": _departmentController.text,
      "reportsTo": _reportsToController.text,
      "role": "user",
      "profilePictureUrl": _imageUrl ?? "",
    };

    const apiUrl =
        "https://t3ivt5ycc4.execute-api.ca-central-1.amazonaws.com/prod/employee/add";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = "Profile saved successfully!";
        });
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Unknown error';
        setState(() => _statusMessage = "Failed: $errorMsg");
      }
    } catch (e) {
      setState(() => _statusMessage = "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _departmentController.dispose();
    _reportsToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Profile")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_imageBytes!, height: 150),
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _pickAndUploadProfilePic,
                  icon: const Icon(Icons.photo),
                  label: const Text("Upload Profile Picture"),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your name' : null,
                ),
                TextFormField(
                  controller: _dobController,
                  decoration:
                      const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                TextFormField(
                  controller: _reportsToController,
                  decoration:
                      const InputDecoration(labelText: 'Reporting Manager'),
                ),
                const SizedBox(height: 24),
                if (_statusMessage.isNotEmpty)
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.startsWith("Failed") ||
                              _statusMessage.contains("error")
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _submitProfile,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text("Save Profile"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

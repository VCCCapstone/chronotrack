// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:chronotrack/user/user_list_expense_page.dart';
import 'package:chronotrack/widgets/vendor_dropdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class UploadExpensePage extends StatefulWidget {
  const UploadExpensePage({super.key});

  @override
  State<UploadExpensePage> createState() => _UploadExpensePageState();
}

class _UploadExpensePageState extends State<UploadExpensePage> {
  String status = "Select a receipt and vendor to upload";
  bool loading = false;
  final TextEditingController _vendorController = TextEditingController();

  String sanitizeEmail(String email) {
    return email.replaceAll('@', '~').replaceAll('.', '^').replaceAll(' ', '`');
  }

  String sanitizeVendor(String vendor) {
    return vendor.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  Future<String?> _getUserEmail() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      return attributes
          .firstWhere((a) => a.userAttributeKey.key == 'email')
          .value;
    } catch (e) {
      setState(() => status = "❌ Failed to fetch user email");
      return null;
    }
  }

  String getContentTypeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _pickAndUploadFile() async {
    final vendorInput = _vendorController.text.trim();
    if (vendorInput.isEmpty) {
      setState(() => status = "❌ Please select a vendor");
      return;
    }

    final email = await _getUserEmail();
    if (email == null) return;

    final fileResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (fileResult == null || fileResult.files.single.bytes == null) return;

    final fileBytes = fileResult.files.single.bytes!;
    final extension = fileResult.files.single.extension!;
    final contentType = getContentTypeFromExtension(extension);
    final sanitizedEmail = sanitizeEmail(email);
    final sanitizedVendor = sanitizeVendor(vendorInput);
    final datePart = DateFormat('dd-MMM-yyyy').format(DateTime.now());
    final filename =
        "$sanitizedEmail-EXPENSE-$sanitizedVendor-$datePart.$extension";

    setState(() {
      loading = true;
      status = "Uploading $filename...";
    });

    final presignedUrlEndpoint =
        "https://b93r46mokk.execute-api.ca-central-1.amazonaws.com/prod/expense/presigned-url?filename=$filename";

    try {
      final presignedResponse = await http.get(Uri.parse(presignedUrlEndpoint));
      if (presignedResponse.statusCode != 200) {
        throw Exception("Failed to get pre-signed URL");
      }

      final body = jsonDecode(presignedResponse.body);
      final uploadUrl = body['url'];

      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        body: fileBytes,
        headers: {
          'Content-Type': contentType,
          'x-amz-acl': 'bucket-owner-full-control',
        },
      );

      if (uploadResponse.statusCode == 200) {
        setState(() => status = "✅ Uploaded successfully: $filename");
      } else {
        setState(
          () => status =
              "❌ Upload failed with status ${uploadResponse.statusCode}",
        );
      }
    } catch (e) {
      setState(() => status = "❌ Error: ${e.toString()}");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Expense Receipt'),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'View Submitted Expenses',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserListExpensePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  VendorDropdown(controller: _vendorController),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choose Receipt File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007ACC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                    ),
                    onPressed: loading ? null : _pickAndUploadFile,
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

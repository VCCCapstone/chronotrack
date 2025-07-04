// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'user_profile_page.dart';
import 'timesheet_form_page.dart';
import 'upload_expense_page.dart';
import 'user_list_expense_page.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String status = "Waiting for action";
  bool loading = false;

  String sanitizeEmail(String email) {
    return email.replaceAll('@', '~').replaceAll('.', '^').replaceAll(' ', '`');
  }

  Future<String?> _getUserEmail() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final email = attributes
          .firstWhere((a) => a.userAttributeKey.key == 'email')
          .value;
      debugPrint("Fetched user email: $email");
      return email;
    } catch (e) {
      debugPrint("Error fetching user email: $e");
      return null;
    }
  }

  String _generateStandardFilename(String email, String extension) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    int daysUntilSunday = (7 - monthStart.weekday % 7) % 7;
    final firstSunday = monthStart.add(Duration(days: daysUntilSunday));
    int weekOfMonth = ((now.difference(firstSunday).inDays) ~/ 7) + 1;
    final paddedWeek = weekOfMonth.toString().padLeft(2, '0');
    final monthAbbr = DateFormat('MMM').format(now).toUpperCase();
    final year = now.year;
    final sanitizedEmail = sanitizeEmail(email);
    return "incoming/$sanitizedEmail-WEEK$paddedWeek-$monthAbbr-$year.$extension";
  }

  Future<void> pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'xls', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final fileBytes = result.files.single.bytes!;
    final fileExtension = result.files.single.extension ?? 'jpg';

    final rawEmail = await _getUserEmail();
    if (rawEmail == null || rawEmail.trim().isEmpty) {
      setState(
        () => status =
            "❌ Could not fetch your email. Please ensure your profile is complete.",
      );
      return;
    }

    final email = rawEmail.trim();
    final fileName = _generateStandardFilename(email, fileExtension);

    setState(() {
      loading = true;
      status = "Uploading $fileName...";
    });

    final apiUrl =
        "https://fwwuilivmf.execute-api.ca-central-1.amazonaws.com/prod/generate-url?filename=$fileName";

    try {
      final presignResponse = await http.get(Uri.parse(apiUrl));
      if (presignResponse.statusCode == 200) {
        final jsonBody = jsonDecode(presignResponse.body);
        final uploadUrl = jsonBody["url"];
        final contentType = jsonBody["contentType"];
        if (uploadUrl == null || uploadUrl.toString().isEmpty) {
          setState(
            () => status = "❌ Error: Pre-signed URL was empty or invalid.",
          );
          return;
        }

        final uploadResponse = await http.put(
          Uri.parse(uploadUrl),
          body: fileBytes,
          headers: {
            'Content-Type': contentType,
            'x-amz-acl': 'bucket-owner-full-control',
          },
        );

        setState(() {
          status = uploadResponse.statusCode == 200
              ? "✅ Upload successful: $fileName"
              : "❌ Upload failed: ${uploadResponse.statusCode}";
        });
      } else {
        setState(() => status = "❌ Error getting pre-signed URL");
      }
    } catch (e) {
      setState(() => status = "❌ Upload error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void goToProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserProfilePage()),
    );
  }

  void goToFormPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimesheetFormPage()),
    );
  }

  void goToUploadExpensePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadExpensePage()),
    );
  }

  void goToUserExpenseListPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserListExpensePage()),
    );
  }

  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Timesheet"),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: "My Profile",
            onPressed: goToProfilePage,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sign Out",
            onPressed: signOut,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Upload your weekly timesheet",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              /// Upload Timesheet
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: loading ? null : pickAndUploadFile,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 28,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.upload_file, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Upload Timesheet File",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// Timesheet Form
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: goToFormPage,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 28,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit_document, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Fill Timesheet Form",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// Upload Expense Receipt
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: goToUploadExpensePage,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 28,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.receipt_long, color: Colors.teal),
                        SizedBox(width: 12),
                        Text(
                          "Upload Expense Receipt",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// Show Submitted Expenses
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: goToUserExpenseListPage,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 28,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.list_alt, color: Colors.orange),
                        SizedBox(width: 12),
                        Text(
                          "Show Submitted Expenses",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              SelectableText(status, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:chronotrack/login_page.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import for date formatting and week number calculation
import 'package:mime/mime.dart'; // Import for MIME type lookup by file extension

import 'timesheet_form_page.dart';
import 'user_profile_page.dart';
import 'sign_out_button.dart';

class UploadPage extends StatefulWidget {
  final String userEmail;

  const UploadPage({super.key, required this.userEmail});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String status = "Waiting for action";
  bool loading = false;

  // Fields for building file name
  // final _employeeNameController = TextEditingController(); // <<< REMOVED: No longer needed for dynamic naming

  // No longer needed: selectedWeek, selectedMonth, selectedYear
  // No longer needed: weeks, months, years lists

  // Helper to calculate week number within the month
  // e.g., Day 1-7 = Week 1, Day 8-14 = Week 2, etc.
  int getWeekNumberInMonth(DateTime date) {
    return (date.day / 7).ceil();
  }

  // Helper to calculate ISO week number (from previous logic, keeping for reference if needed)
  // int getWeekNumber(DateTime date) {
  //   final jan4 = DateTime(date.year, 1, 4);
  //   final week1Start = jan4.subtract(Duration(days: jan4.weekday - 1));
  //   return ((date.difference(week1Start).inDays / 7)).ceil();
  // }

  Future<void> pickAndUploadFile() async {
    setState(() {
      status = "Picking file...";
      loading = true;
    });

    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes!;
      final fileExtension = result.files.single.extension ?? 'jpg';
      final fileMimeType = lookupMimeType(result.files.single.name) ?? 'image/jpeg';

      // --- Dynamic Filename Components ---
      DateTime now = DateTime.now();

      // 1. Process User Email for Username Part
      // Example: "john.doe@example.com" -> "john_doe_at_example_com"
      String usernamePart = widget.userEmail
          .replaceAll('@', '_at_')
          .replaceAll('.', '_')
          .toLowerCase();

      // 2. Calculate Week Number in Month
      int weekNumber = getWeekNumberInMonth(now);

      // 3. Format Month (MM)
      String monthName = DateFormat('MMMM').format(now); // e.g., "June"

      // 4. Format Year (YYYY)
      String year = DateFormat('yyyy').format(now); // e.g., "2025"

      // Construct the dynamic file name: 'username_at_domain_com-Weeknumber-MM-YYYY.fileextention'
      // <<< MODIFIED: Changed monthDigits to monthName
      final fileName =
          "${usernamePart}-Week$weekNumber-$monthName-$year.${fileExtension}";

      setState(() {
        loading = true;
        status = "Generating pre-signed URL for $fileName...";
      });

      final apiUrl =
          "https://fwwuilivmf.execute-api.ca-central-1.amazonaws.com/prod/generate-url?filename=$fileName";

      try {
        final presignResponse = await http.get(Uri.parse(apiUrl));
        if (presignResponse.statusCode == 200) {
          final uploadUrl = jsonDecode(presignResponse.body)["uploadUrl"];

          if (uploadUrl == null || uploadUrl.isEmpty) {
            setState(() {
              status = "Error: Backend did not provide a valid uploadUrl. Response: ${presignResponse.body}";
            });
            debugPrint("Backend response for pre-signed URL was missing 'uploadUrl': ${presignResponse.body}");
            return;
          }

          setState(() {
            status = "Uploading file to S3...";
          });

          final uploadResponse =
              await http.put(Uri.parse(uploadUrl), body: fileBytes, headers: {
            'x-amz-acl': 'bucket-owner-full-control',
            'Content-Type': fileMimeType,
          },);

          if (uploadResponse.statusCode == 200) {
            setState(() {
              status = "Upload successful: $fileName";
            });
          } else {
            setState(() {
              status = "Upload failed: ${uploadResponse.statusCode}. Response: ${uploadResponse.body}";
            });
            debugPrint("S3 upload failed: ${uploadResponse.statusCode} - ${uploadResponse.body}");
          }
        } else {
          setState(() {
            status = "Error getting pre-signed URL. Status: ${presignResponse.statusCode}. Body: ${presignResponse.body}";
          });
          debugPrint("Failed to get pre-signed URL: ${presignResponse.statusCode} - ${presignResponse.body}");
        }
      } catch (e) {
        setState(() {
          status = "Upload error: $e";
        });
        debugPrint("Caught upload error: $e");
      } finally {
        setState(() {
          loading = false;
        });
      }
    } else {
      setState(() {
        status = "File picking cancelled or no file selected.";
        loading = false;
      });
    }
  }

  void goToFormPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimesheetFormPage()),
    );
  }

  void goToProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(userEmail: widget.userEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Timesheet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: "My Profile",
            onPressed: goToProfilePage,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sign Out",
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Submit your timesheet before Saturday 23:59",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // TextFormField for employee name is removed as it's now dynamic
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: loading ? null : pickAndUploadFile,
                icon: const Icon(Icons.upload),
                label: Text(loading ? "Uploading..." : "Upload Timesheet Image"),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: goToFormPage,
                icon: const Icon(Icons.edit_document),
                label: const Text("Fill Timesheet Form"),
              ),
              const SizedBox(height: 20),
              Text(status, textAlign: TextAlign.center,),
            ],
          ),
        ),
      ),
    );
  }
}

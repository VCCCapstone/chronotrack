import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // <<< ADDED: Import for date formatting and week number calculation
import 'package:mime/mime.dart'; // <<< ADDED: Import for MIME type lookup by file extension

import 'timesheet_form_page.dart';
import 'user_profile_page.dart';

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
  final _employeeNameController = TextEditingController();
  // String? selectedWeek; // <<< REMOVED: No longer needed for dynamic naming
  // String? selectedMonth; // <<< REMOVED: No longer needed for dynamic naming
  // String? selectedYear;  // <<< REMOVED: No longer needed for dynamic naming

  // final List<String> weeks = ['1', '2', '3', '4', '5']; // <<< REMOVED: No longer needed
  // final List<String> months = [ // <<< REMOVED: No longer needed
  //   'January', 'February', 'March', 'April', 'May', 'June', 'July',
  //   'August', 'September', 'October', 'November', 'December'
  // ];
  // final List<String> years = [ // <<< REMOVED: No longer needed
  //   for (int y = DateTime.now().year - 1; y <= DateTime.now().year + 2; y++) '$y'
  // ];

  // <<< ADDED: Helper to calculate ISO week number
  int getWeekNumber(DateTime date) {
    final jan4 = DateTime(date.year, 1, 4);
    final week1Start = jan4.subtract(Duration(days: jan4.weekday - 1));
    return ((date.difference(week1Start).inDays / 7)).ceil();
  }

  Future<void> pickAndUploadFile() async {
    // <<< MODIFIED: Set loading true immediately for feedback
    setState(() {
      status = "Picking file...";
      loading = true;
    });

    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes!;
      final fileExtension = result.files.single.extension ?? 'jpg';
      // <<< MODIFIED: Get the MIME type using the 'mime' package from the file extension
      final fileMimeType = lookupMimeType(result.files.single.name) ?? 'image/jpeg';


      // Validate fields
      // <<< MODIFIED: Only validate employee name now, as date fields are dynamic
      if (_employeeNameController.text.isEmpty) {
        setState(() {
          status = "Please enter Employee Name.";
          loading = false; // <<< ADDED: Stop loading if validation fails
        });
        return;
      }

      // <<< ADDED: Dynamic Date Calculation
      DateTime now = DateTime.now();
      String year = DateFormat('yyyy').format(now); // e.g., "2025"
      String monthName = DateFormat('MMMM').format(now); // e.g., "June"
      int weekNumber = getWeekNumber(now); // Calculate ISO week number

      // <<< MODIFIED: Construct the dynamic file name
      final fileName =
          "${_employeeNameController.text}-Week$weekNumber-$monthName-$year-TimeSheet.$fileExtension";

      setState(() {
        loading = true; // Ensure loading is true before API call
        status = "Generating pre-signed URL for $fileName..."; // More specific status
      });

      final apiUrl =
          "https://fwwuilivmf.execute-api.ca-central-1.amazonaws.com/prod/generate-url?filename=$fileName";

      try {
        final presignResponse = await http.get(Uri.parse(apiUrl));
        if (presignResponse.statusCode == 200) {
          // <<< FIXED: Changed from "upload_url" to "uploadUrl" (matching Lambda output)
          final uploadUrl = jsonDecode(presignResponse.body)["uploadUrl"];

          // <<< ADDED: Robust check for uploadUrl before using
          if (uploadUrl == null || uploadUrl.isEmpty) {
            setState(() {
              status = "Error: Backend did not provide a valid uploadUrl. Response: ${presignResponse.body}";
            });
            debugPrint("Backend response for pre-signed URL was missing 'uploadUrl': ${presignResponse.body}");
            return;
          }

          setState(() {
            status = "Uploading file to S3..."; // More specific status
          });

          final uploadResponse =
              await http.put(Uri.parse(uploadUrl), body: fileBytes, headers: {
            'x-amz-acl': 'bucket-owner-full-control',
            'Content-Type': fileMimeType, // <<< FIXED: Added Content-Type header
          },);

          if (uploadResponse.statusCode == 200) {
            setState(() {
              status = "Upload successful: $fileName";
            });
          } else {
            // <<< MODIFIED: Improved error message for S3 upload failure
            setState(() {
              status = "Upload failed: ${uploadResponse.statusCode}. Response: ${uploadResponse.body}";
            });
            debugPrint("S3 upload failed: ${uploadResponse.statusCode} - ${uploadResponse.body}");
          }
        } else {
          // <<< MODIFIED: Improved error message for pre-signed URL error
          setState(() {
            status = "Error getting pre-signed URL. Status: ${presignResponse.statusCode}. Body: ${presignResponse.body}";
          });
          debugPrint("Failed to get pre-signed URL: ${presignResponse.statusCode} - ${presignResponse.body}");
        }
      } catch (e) {
        setState(() {
          status = "Upload error: $e";
        });
        debugPrint("Caught upload error: $e"); // <<< ADDED: Debug print for generic errors
      } finally {
        setState(() {
          loading = false;
        });
      }
    } else {
      // <<< ADDED: Status for cancelled picking
      setState(() {
        status = "File picking cancelled or no file selected.";
        loading = false; // <<< ADDED: Stop loading if file picking is cancelled
      });
    }
  }

  void goToFormPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TimesheetFormPage(),
      ),
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
          )
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
              TextFormField(
                controller: _employeeNameController,
                decoration: const InputDecoration(labelText: "Employee Name"),
              ),
              // <<< REMOVED: Dropdowns for Week, Month, Year
              // const SizedBox(height: 12),
              // DropdownButtonFormField<String>(
              //   value: selectedWeek,
              //   items: weeks
              //       .map((w) => DropdownMenuItem(value: w, child: Text("Week $w")))
              //       .toList(),
              //   onChanged: (val) => setState(() => selectedWeek = val),
              //   decoration: const InputDecoration(labelText: "Week"),
              // ),
              // const SizedBox(height: 12),
              // DropdownButtonFormField<String>(
              //   value: selectedMonth,
              //   items: months
              //       .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              //       .toList(),
              //   onChanged: (val) => setState(() => selectedMonth = val),
              //   decoration: const InputDecoration(labelText: "Month"),
              // ),
              // const SizedBox(height: 12),
              // DropdownButtonFormField<String>(
              //   value: selectedYear,
              //   items: years
              //       .map((y) => DropdownMenuItem(value: y, child: Text(y)))
              //       .toList(),
              //   onChanged: (val) => setState(() => selectedYear = val),
              //   decoration: const InputDecoration(labelText: "Year"),
              // ),
              const SizedBox(height: 20), // Adjusted spacing
              ElevatedButton.icon(
                onPressed: loading ? null : pickAndUploadFile,
                icon: const Icon(Icons.upload),
                // <<< MODIFIED: Dynamic button label based on loading state
                label: Text(loading ? "Uploading..." : "Upload Timesheet Image"),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: goToFormPage,
                icon: const Icon(Icons.edit_document),
                label: const Text("Fill Timesheet Form"),
              ),
              const SizedBox(height: 20),
              // <<< MODIFIED: Center align status text for better presentation
              Text(status, textAlign: TextAlign.center,),
            ],
          ),
        ),
      ),
    );
  }
}

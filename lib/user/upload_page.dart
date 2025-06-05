import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String? selectedWeek;
  String? selectedMonth;
  String? selectedYear;

  final List<String> weeks = ['1', '2', '3', '4', '5'];
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  final List<String> years = [
    for (int y = DateTime.now().year - 1; y <= DateTime.now().year + 2; y++) '$y'
  ];

  Future<void> pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes!;
      final fileExtension = result.files.single.extension ?? 'jpg';

      // Validate fields
      if (_employeeNameController.text.isEmpty ||
          selectedWeek == null ||
          selectedMonth == null ||
          selectedYear == null) {
        setState(() {
          status = "Please fill all fields to generate filename.";
        });
        return;
      }

      final fileName =
          "${_employeeNameController.text}-Week$selectedWeek-$selectedMonth-$selectedYear-TimeSheet.$fileExtension";

      setState(() {
        loading = true;
        status = "Uploading...";
      });

      final apiUrl =
          "https://fwwuilivmf.execute-api.ca-central-1.amazonaws.com/prod/generate-url?filename=$fileName";

      try {
        final presignResponse = await http.get(Uri.parse(apiUrl));
        if (presignResponse.statusCode == 200) {
          final uploadUrl = jsonDecode(presignResponse.body)["upload_url"];
          final uploadResponse =
              await http.put(Uri.parse(uploadUrl), body: fileBytes, headers: {
    'x-amz-acl': 'bucket-owner-full-control',
  },);

          if (uploadResponse.statusCode == 200) {
            setState(() {
              status = "Upload successful: $fileName";
            });
          } else {
            setState(() {
              status = "Upload failed: ${uploadResponse.statusCode}";
            });
          }
        } else {
          setState(() {
            status = "Error getting pre-signed URL";
          });
        }
      } catch (e) {
        setState(() {
          status = "Upload error: $e";
        });
      } finally {
        setState(() {
          loading = false;
        });
      }
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedWeek,
                items: weeks
                    .map((w) => DropdownMenuItem(value: w, child: Text("Week $w")))
                    .toList(),
                onChanged: (val) => setState(() => selectedWeek = val),
                decoration: const InputDecoration(labelText: "Week"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMonth,
                items: months
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => selectedMonth = val),
                decoration: const InputDecoration(labelText: "Month"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedYear,
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: (val) => setState(() => selectedYear = val),
                decoration: const InputDecoration(labelText: "Year"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: loading ? null : pickAndUploadFile,
                icon: const Icon(Icons.upload),
                label: const Text("Upload Timesheet Image"),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: goToFormPage,
                icon: const Icon(Icons.edit_document),
                label: const Text("Fill Timesheet Form"),
              ),
              const SizedBox(height: 20),
              Text(status),
            ],
          ),
        ),
      ),
    );
  }
}

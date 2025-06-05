import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'admin_employee_list_page.dart';
import 'signup_user_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<String> allFiles = [];
  List<String> filteredFiles = [];

  final _nameFilterController = TextEditingController();
  String? selectedMonth;
  String? selectedYear;

  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> years = [
    for (int y = DateTime.now().year - 1; y <= DateTime.now().year + 5; y++) '$y'
  ];

  @override
  void initState() {
    super.initState();
    fetchFileList();
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } on AuthException catch (e) {
      debugPrint("Sign out failed: ${e.message}");
    }
  }

  Future<void> fetchFileList() async {
    const apiUrl =
        "https://5ul39j72jj.execute-api.ca-central-1.amazonaws.com/prod/list-timesheets?prefix=";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<String> files = List<String>.from(data["files"]);
        setState(() {
          allFiles = files;
          filteredFiles = files;
        });
      } else {
        debugPrint("Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
  }

  void applyFilters() {
    final name = _nameFilterController.text.trim().toLowerCase();
    setState(() {
      filteredFiles = allFiles.where((file) {
        final lowerFile = file.toLowerCase();
        final matchName = name.isEmpty || lowerFile.contains(name);
        final matchMonth =
            selectedMonth == null || lowerFile.contains(selectedMonth!.toLowerCase());
        final matchYear =
            selectedYear == null || lowerFile.contains(selectedYear!);
        return matchName && matchMonth && matchYear;
      }).toList();
    });
  }

  Future<void> downloadFile(String fileName) async {
    final presignUrl =
        "https://fwwuilivmf.execute-api.ca-central-1.amazonaws.com/prod/generate-url?filename=$fileName&action=download";

    try {
      final response = await http.get(Uri.parse(presignUrl));
      if (response.statusCode == 200) {
        final downloadUrl = jsonDecode(response.body)['download_url'];
        html.AnchorElement anchor = html.AnchorElement(href: downloadUrl)
          ..target = 'blank'
          ..download = fileName;
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
      } else {
        debugPrint("Failed to get download URL: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Download error: $e");
    }
  }

  void _goToEmployeeList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminEmployeeListPage()),
    );
  }

  void _goToSignupUserPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupUserPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'View All Employees',
            onPressed: _goToEmployeeList,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Create New User',
            onPressed: _goToSignupUserPage,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Filter Timesheets", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameFilterController,
                    decoration: const InputDecoration(labelText: "Employee Name"),
                    onChanged: (_) => applyFilters(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedMonth,
                    items: months
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) => setState(() {
                      selectedMonth = val;
                      applyFilters();
                    }),
                    decoration: const InputDecoration(labelText: "Month"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedYear,
                    items: years
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (val) => setState(() {
                      selectedYear = val;
                      applyFilters();
                    }),
                    decoration: const InputDecoration(labelText: "Year"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredFiles.isEmpty
                  ? const Center(child: Text("No files match the selected filters."))
                  : ListView.builder(
                      itemCount: filteredFiles.length,
                      itemBuilder: (context, index) {
                        final file = filteredFiles[index];
                        return ListTile(
                          title: Text(file),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => downloadFile(file),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

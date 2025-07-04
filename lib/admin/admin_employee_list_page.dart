// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_view_edit_profile_page.dart';

class AdminEmployeeListPage extends StatefulWidget {
  const AdminEmployeeListPage({super.key});

  @override
  State<AdminEmployeeListPage> createState() => _AdminEmployeeListPageState();
}

class _AdminEmployeeListPageState extends State<AdminEmployeeListPage> {
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> filteredEmployees = [];
  bool isLoading = true;
  String searchQuery = '';

  final String listUrl =
      'https://vi41frt3o0.execute-api.ca-central-1.amazonaws.com/listEmployees';
  final String deleteUrl =
      'https://t3ivt5ycc4.execute-api.ca-central-1.amazonaws.com/prod/employee/delete';

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      final response = await http.get(Uri.parse(listUrl));
      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> loaded =
            List<Map<String, dynamic>>.from(json.decode(response.body));
        setState(() {
          employees = loaded;
          filteredEmployees = loaded;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      print('❌ Error fetching employees: $e');
      setState(() => isLoading = false);
    }
  }

  void filterEmployees(String query) {
    final lower = query.toLowerCase();
    setState(() {
      searchQuery = query;
      filteredEmployees = employees.where((employee) {
        final name = (employee['fullName'] ?? '').toLowerCase();
        final email = (employee['email'] ?? '').toLowerCase();
        return name.contains(lower) || email.contains(lower);
      }).toList();
    });
  }

  Future<void> deleteEmployee(String email) async {
    final response = await http.post(
      Uri.parse(deleteUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee deleted successfully')),
      );
      fetchEmployees();
    } else {
      print("❌ Failed to delete: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: ${response.body}')),
      );
    }
  }

  void viewOrEditProfile(Map<String, dynamic> profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminViewEditProfilePage(profile: profile),
      ),
    );
  }

  Widget buildEmployeeCard(Map<String, dynamic> employee) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              employee['fullName'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Email: ${employee['email'] ?? ''}'),
            Text('Phone: ${employee['phoneNumber'] ?? ''}'),
            Text('Department: ${employee['department'] ?? ''}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  onPressed: () => viewOrEditProfile(employee),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteEmployee(employee['email']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Employees'),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
          ? const Center(child: Text("No employees found."))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search by name or email...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: filterEmployees,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.count(
                          crossAxisCount: isMobile
                              ? 1
                              : (constraints.maxWidth ~/ 300).clamp(1, 4),
                          childAspectRatio: 1.4,
                          physics: const BouncingScrollPhysics(),
                          children: filteredEmployees
                              .map(buildEmployeeCard)
                              .toList(),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminEmployeeListPage extends StatefulWidget {
  const AdminEmployeeListPage({super.key});

  @override
  State<AdminEmployeeListPage> createState() => _AdminEmployeeListPageState();
}

class _AdminEmployeeListPageState extends State<AdminEmployeeListPage> {
  List<Map<String, dynamic>> employeeProfiles = [];
  bool loading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchEmployeeProfiles();
  }

  Future<void> fetchEmployeeProfiles() async {
    const apiUrl =
        'https://t3ivt5ycc4.execute-api.ca-central-1.amazonaws.com/prod/employee/list';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['employees'];
        setState(() {
          employeeProfiles =
              data.map((e) => Map<String, dynamic>.from(e)).toList();
          loading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error occurred: $e';
        loading = false;
      });
    }
  }

  void _showDetails(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(employee['fullName'] ?? 'Employee Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (employee['profilePictureUrl'] != null)
                  Image.network(
                    employee['profilePictureUrl'],
                    height: 120,
                  ),
                Text("Email: ${employee['email']}"),
                Text("DOB: ${employee['dob'] ?? 'N/A'}"),
                Text("Phone: ${employee['phoneNumber'] ?? 'N/A'}"),
                Text("Address: ${employee['address'] ?? 'N/A'}"),
                Text("Department: ${employee['department'] ?? 'N/A'}"),
                Text("Reports To: ${employee['reportsTo'] ?? 'N/A'}"),
                Text("Role: ${employee['role'] ?? 'user'}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Employees")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : ListView.builder(
                  itemCount: employeeProfiles.length,
                  itemBuilder: (context, index) {
                    final employee = employeeProfiles[index];
                    return ListTile(
                      title: Text(employee['fullName'] ?? 'No Name'),
                      subtitle: Text(employee['email']),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDetails(employee),
                    );
                  },
                ),
    );
  }
}

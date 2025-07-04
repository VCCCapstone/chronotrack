import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserListExpensePage extends StatefulWidget {
  const UserListExpensePage({super.key});

  @override
  State<UserListExpensePage> createState() => _UserListExpensePageState();
}

class _UserListExpensePageState extends State<UserListExpensePage> {
  List<dynamic> _expenses = [];
  bool _loading = true;
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _loading = true);

    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      _currentEmail = attributes
          .firstWhere((a) => a.userAttributeKey.key == 'email')
          .value;

      final url =
          'https://b93r46mokk.execute-api.ca-central-1.amazonaws.com/prod/expense/list?email=${Uri.encodeComponent(_currentEmail!)}';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() => _expenses = jsonDecode(res.body));
      } else {
        setState(() => _expenses = []);
      }
    } catch (e) {
      setState(() => _expenses = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text("${item['vendor']} — \$${item['amount']}"),
        subtitle: Text(
          "Date: ${item['date']}\nCategory: ${item['category'] ?? 'N/A'}\nStatus: ${item['status']}",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Submitted Expenses"),
        backgroundColor: const Color(0xFF3C3C3C),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
          ? const Center(
              child: Text("You have not submitted any expenses yet."),
            )
          : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) => _buildCard(_expenses[index]),
            ),
    );
  }
}

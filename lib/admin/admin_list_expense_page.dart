// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_expense_page.dart';

class AdminListExpensePage extends StatefulWidget {
  const AdminListExpensePage({super.key});

  @override
  State<AdminListExpensePage> createState() => _AdminListExpensePageState();
}

class _AdminListExpensePageState extends State<AdminListExpensePage> {
  List<Map<String, dynamic>> _allExpenses = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _selectedEmail = '';
  String _selectedMonthYear = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    setState(() => _loading = true);
    final uri = Uri.parse(
      'https://b93r46mokk.execute-api.ca-central-1.amazonaws.com/prod/expense/list',
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          _allExpenses = List<Map<String, dynamic>>.from(jsonData);
          _filtered = _allExpenses;
          _loading = false;
        });
      } else {
        throw Exception('Failed to load expenses');
      }
    } catch (e) {
      debugPrint("Error fetching expenses: $e");
      setState(() => _loading = false);
    }
  }

  void _filterData() {
    setState(() {
      _filtered = _allExpenses.where((item) {
        final email = item['email'] ?? '';
        final monthYear = item['monthYear'] ?? '';
        final matchesEmail = _selectedEmail.isEmpty || email == _selectedEmail;
        final matchesMonthYear =
            _selectedMonthYear.isEmpty || monthYear == _selectedMonthYear;
        final matchesSearch =
            _searchQuery.isEmpty ||
            email.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesEmail && matchesMonthYear && matchesSearch;
      }).toList();
    });
  }

  Future<void> _deleteExpense(String expenseId, String email) async {
    final uri = Uri.parse(
      'https://b93r46mokk.execute-api.ca-central-1.amazonaws.com/prod/expense/delete',
    );
    final response = await http.post(
      uri,
      body: json.encode({'expenseId': expenseId, 'email': email}),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      setState(
        () => _allExpenses.removeWhere(
          (item) => item['expenseId'] == expenseId && item['email'] == email,
        ),
      );
      _filterData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete expense')));
    }
  }

  Widget _buildFilterDropdowns() {
    final emailOptions =
        _allExpenses.map((e) => e['email'] ?? '').toSet().toList()..sort();
    final monthOptions =
        _allExpenses.map((e) => e['monthYear'] ?? '').toSet().toList()..sort();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<String>(
          hint: const Text("Filter by Email"),
          value: _selectedEmail.isEmpty ? null : _selectedEmail,
          items: emailOptions
              .map(
                (value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _selectedEmail = value ?? '');
            _filterData();
          },
        ),
        DropdownButton<String>(
          hint: const Text("Filter by Month-Year"),
          value: _selectedMonthYear.isEmpty ? null : _selectedMonthYear,
          items: monthOptions
              .map(
                (value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _selectedMonthYear = value ?? '');
            _filterData();
          },
        ),
        SizedBox(
          width: 250,
          child: TextField(
            decoration: const InputDecoration(labelText: 'Search by Email'),
            onChanged: (val) {
              _searchQuery = val;
              _filterData();
            },
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedEmail = '';
              _selectedMonthYear = '';
              _searchQuery = '';
              _filtered = _allExpenses;
            });
          },
          child: const Text("Clear Filters"),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> item) {
    final lastModifiedStr = item['lastModified'] ?? '';
    final lastModified = DateTime.tryParse(lastModifiedStr)?.toLocal();
    final formattedTime = lastModified != null
        ? DateFormat.yMd().add_jm().format(lastModified)
        : 'N/A';

    final email = item['email'] ?? '';
    final vendor = (item['vendor'] ?? '')
        .replaceAll(RegExp(r'[*]+'), '')
        .trim();
    final expenseId = item['expenseId'] ?? '';
    final total = (item['total_amount'] ?? item['total'] ?? 'N/A')
        .toString()
        .replaceAll(RegExp(r'[*]+'), '')
        .trim();
    final tax = (item['tax_amount'] ?? '')
        .toString()
        .replaceAll('*', '')
        .trim();
    final currency = (item['currency'] ?? 'CAD').replaceAll('*', '').trim();
    final location = (item['location'] ?? '').replaceAll('*', '').trim();
    final purchaseDate = (item['purchase_date'] ?? '')
        .replaceAll('*', '')
        .trim();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vendor: $vendor'),
            Text('Purchase Date: $purchaseDate'),
            Text('Location: $location'),
            Text('Tax: $tax'),
            Text('Total: $total $currency'),
            Text('Expense ID: $expenseId'),
            Text('Last Modified: $formattedTime'),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditExpensePage(expense: item),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteExpense(item['expenseId'], item['email']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Expense Receipts (Admin)"),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchExpenses,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilterDropdowns(),
                  const SizedBox(height: 12),
                  ..._filtered.map(_buildExpenseCard),
                ],
              ),
            ),
    );
  }
}

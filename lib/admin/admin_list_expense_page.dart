// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:html' as html;
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:chronotrack/widgets/generate_expense_report_pdf.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
        final List<Map<String, dynamic>> processedData =
            List<Map<String, dynamic>>.from(jsonData).map((e) {
              // Compute fallback monthYear
              if ((e['monthYear'] ?? '').isEmpty &&
                  e['purchase_date'] != null) {
                try {
                  final parts = e['purchase_date'].split("-");
                  e['monthYear'] = "${parts[1]}-${parts[2]}";
                } catch (_) {}
              }
              return e;
            }).toList();

        setState(() {
          _allExpenses = processedData;
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

  Widget _buildSummaryTotals() {
    double filteredTotal = 0;
    double filteredWithTax = 0;
    double allTotal = 0;
    double allWithTax = 0;

    for (var item in _filtered) {
      final total =
          double.tryParse('${item['total_amount'] ?? item['total'] ?? 0}') ?? 0;
      final withTax =
          double.tryParse('${item['totalAmountWithTax'] ?? 0}') ?? 0;
      filteredTotal += total;
      filteredWithTax += withTax;
    }

    for (var item in _allExpenses) {
      final total =
          double.tryParse('${item['total_amount'] ?? item['total'] ?? 0}') ?? 0;
      final withTax =
          double.tryParse('${item['totalAmountWithTax'] ?? 0}') ?? 0;
      allTotal += total;
      allWithTax += withTax;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6A0DAD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary Totals',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Filtered: Total = \$${filteredTotal.toStringAsFixed(2)}, With Tax = \$${filteredWithTax.toStringAsFixed(2)}',
          ),
          Text(
            'All: Total = \$${allTotal.toStringAsFixed(2)}, With Tax = \$${allWithTax.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
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
          (e) => e['expenseId'] == expenseId && e['email'] == email,
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

  void _exportToCSV() {
    final headers = [
      'Email',
      'Vendor',
      'Purchase Date',
      'Location',
      'Currency',
      'Total',
      'GST/HST',
      'PST',
      'Tip',
      'Total with Tax',
      'Expense ID',
      'Last Modified',
    ];

    final rows = [
      headers.join(','),
      ..._filtered.map((item) {
        return [
          item['email'] ?? '',
          item['vendor'] ?? '',
          item['purchase_date'] ?? '',
          item['location'] ?? '',
          item['currency'] ?? 'CAD',
          item['total_amount'] ?? item['total'] ?? 0,
          item['gsthstPaidTotal'] ?? item['tax_amount'] ?? 0,
          item['pstPaidTotal'] ?? 0,
          item['tipAmount'] ?? 0,
          item['totalAmountWithTax'] ?? 0,
          item['expenseId'] ?? '',
          item['lastModified'] ?? '',
        ].map((e) => '"$e"').join(',');
      }),
    ].join('\n');

    final blob = html.Blob([rows], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'expenses_export.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void refresh() {
    setState(() {
      _filtered = List.from(_allExpenses);
      _searchQuery = "";
    });
  }

  Future<String?> getCurrentUserEmail() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final emailAttr = attributes.firstWhere(
        (attr) => attr.userAttributeKey.key == 'email',
        orElse: () => const AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.email,
          value: '',
        ),
      );
      return emailAttr.value.isNotEmpty ? emailAttr.value : null;
    } catch (e) {
      print("Error fetching email: $e");
      return null;
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
    final vendor = (item['vendor'] ?? '').replaceAll('*', '').trim();
    final expenseId = item['expenseId'] ?? '';
    final purchaseDate = (item['purchase_date'] ?? '')
        .replaceAll('*', '')
        .trim();
    final location = (item['location'] ?? '').replaceAll('*', '').trim();
    final currency = (item['currency'] ?? 'CAD').replaceAll('*', '').trim();
    final total = (item['total_amount'] ?? item['total'] ?? 0).toString();
    final gst = (item['gsthstPaidTotal'] ?? item['tax_amount'] ?? 0).toString();
    final pst = (item['pstPaidTotal'] ?? 0).toString();
    final tip = (item['tipAmount'] ?? 0).toString();
    final totalWithTax = (item['totalAmountWithTax'] ?? 0).toString();

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
            Text('Total: $total $currency'),
            Text('GST/HST: $gst, PST: $pst, Tip: $tip'),
            Text('Total with Tax: $totalWithTax $currency'),
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
        actions: [
          IconButton(
            tooltip: 'Export to CSV',
            icon: const Icon(Icons.grid_on),
            onPressed: _filtered.isEmpty ? null : _exportToCSV,
          ),
          IconButton(
            tooltip: 'Export to PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _filtered.isEmpty
                ? null
                : () async {
                    final email = await getCurrentUserEmail();
                    if (email != null) {
                      await generateExpenseReportPdf(_filtered, email);
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
            tooltip: 'Refresh',
          ),
        ],
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
                  _buildSummaryTotals(), // <-- Add here
                  const SizedBox(height: 12),
                  ..._filtered.map(_buildExpenseCard),
                ],
              ),
            ),
    );
  }
}

import 'dart:convert';
import 'dart:html' as html;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:chronotrack/widgets/generate_expense_report_pdf.dart';

class UserListExpensePage extends StatefulWidget {
  const UserListExpensePage({super.key});

  @override
  State<UserListExpensePage> createState() => _UserListExpensePageState();
}

class _UserListExpensePageState extends State<UserListExpensePage> {
  List<Map<String, dynamic>> allExpenses = [];
  List<Map<String, dynamic>> filteredExpenses = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    try {
      final email = await getCurrentUserEmail();
      if (email == null) {
        print('User email not available');
        return;
      }

      final uri = Uri.parse(
        'https://b93r46mokk.execute-api.ca-central-1.amazonaws.com/prod/expense/list?email=$email',
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final List<Map<String, dynamic>> fetchedExpenses = jsonList
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        setState(() {
          allExpenses = fetchedExpenses;
          filteredExpenses = List.from(allExpenses);
        });
      } else {
        print('Failed to fetch expenses. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching expenses: $e');
    }
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

  double getTotal(bool withTax) {
    return filteredExpenses.fold(0.0, (prev, el) {
      final val = withTax
          ? el['totalWithTax'] ?? el['totalAmountWithTax'] ?? el['total_amount']
          : el['amount'] ?? el['total_amount'];
      return prev + (val is num ? val : double.tryParse(val.toString()) ?? 0);
    });
  }

  void exportToCSV() {
    List<List<String>> rows = [
      ['Date', 'Vendor', 'Amount', 'GST/HST', 'PST', 'Tip', 'Total With Tax'],
      ...filteredExpenses.map(
        (e) => [
          e['date'] ?? e['purchase_date'] ?? '',
          e['vendor'] ?? '',
          (e['amount'] ?? e['total_amount'] ?? '').toString(),
          (e['gstHst'] ?? e['gsthstPaidTotal'] ?? '').toString(),
          (e['pst'] ?? e['pstPaidTotal'] ?? '').toString(),
          (e['tip'] ?? e['tipAmount'] ?? '').toString(),
          (e['totalWithTax'] ??
                  e['totalAmountWithTax'] ??
                  e['total_amount'] ??
                  '')
              .toString(),
        ],
      ),
    ];
    String csv = const ListToCsvConverter().convert(rows);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "expenses.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void refresh() {
    setState(() {
      filteredExpenses = List.from(allExpenses);
      searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final withoutTax = getTotal(false);
    final withTax = getTotal(true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Submitted Expenses'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final email = await getCurrentUserEmail();
              if (email != null) {
                await generateExpenseReportPdf(filteredExpenses, email);
              }
            },
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.grid_on),
            onPressed: exportToCSV,
            tooltip: 'Export to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Vendor or Category',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final query = searchController.text.toLowerCase();
                    setState(() {
                      filteredExpenses = allExpenses.where((e) {
                        final vendor = (e['vendor'] ?? '')
                            .toString()
                            .toLowerCase();
                        final category = (e['category'] ?? '')
                            .toString()
                            .toLowerCase();
                        return vendor.contains(query) ||
                            category.contains(query);
                      }).toList();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Total Expenses (Without Tax): \$${withoutTax.toStringAsFixed(2)}',
            ),
            Text('Total Expenses (With Tax): \$${withTax.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filteredExpenses.length,
                itemBuilder: (context, index) {
                  final e = filteredExpenses[index];
                  final amount = e['amount'] ?? e['total_amount'] ?? 0;
                  final gst = e['gstHst'] ?? e['gsthstPaidTotal'] ?? 0;
                  final pst = e['pst'] ?? e['pstPaidTotal'] ?? 0;
                  final tip = e['tip'] ?? e['tipAmount'] ?? 0;
                  final totalWithTax =
                      e['totalWithTax'] ??
                      e['totalAmountWithTax'] ??
                      e['total_amount'] ??
                      (amount + gst + pst + tip);

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${e['vendor'] ?? 'Vendor'} – \$${amount.toString()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Purchase Date: ${e['date'] ?? e['purchase_date'] ?? 'N/A'}',
                          ),
                          Text('Location: ${e['location'] ?? 'N/A'}'),
                          Text('Category: ${e['category'] ?? 'N/A'}'),
                          Text('Status: ${e['status'] ?? 'N/A'}'),
                          Text('GST/HST: \$${gst.toString()}'),
                          Text('PST: \$${pst.toString()}'),
                          Text('Tip: \$${tip.toString()}'),
                          Text('Total with Tax: \$${totalWithTax.toString()}'),
                          Text(
                            'Expense ID: ${e['expenseId'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditExpensePage extends StatefulWidget {
  final Map<String, dynamic> expense;

  const EditExpensePage({super.key, required this.expense});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vendorController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _notesController;
  bool _loading = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _vendorController = TextEditingController(
      text: widget.expense['vendor'] ?? '',
    );
    _amountController = TextEditingController(
      text: widget.expense['amount']?.toString() ?? '',
    );
    _dateController = TextEditingController(text: widget.expense['date'] ?? '');
    _notesController = TextEditingController(
      text: widget.expense['notes'] ?? '',
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final updatedData = {
      'expenseId': widget.expense['expenseId'],
      'email': widget.expense['email'],
      'vendor': _vendorController.text.trim(),
      'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
      'date': _dateController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    final url = Uri.parse(
      'https://b93r46mokk.execute-api.ca-central-1.amazonaws.com/prod/expense/update',
    );
    final res = await http.post(
      url,
      body: jsonEncode(updatedData),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200) {
      setState(() {
        _status = '✅ Expense updated successfully';
        _loading = false;
      });
    } else {
      setState(() {
        _status = '❌ Update failed: ${res.body}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Expense Record"),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(labelText: 'Vendor'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (\$)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (DD-MMM-YYYY)',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: _loading
                    ? const CircularProgressIndicator()
                    : const Text("Save Changes"),
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A0DAD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_status.isNotEmpty)
                Text(
                  _status,
                  style: TextStyle(
                    color: _status.startsWith('✅') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

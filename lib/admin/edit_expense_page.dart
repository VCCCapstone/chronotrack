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
  late TextEditingController _locationController;
  late TextEditingController _gsthstController;
  late TextEditingController _pstController;
  late TextEditingController _tipController;
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
      text: (widget.expense['total_amount'] ?? widget.expense['total'] ?? '')
          .toString(),
    );
    _dateController = TextEditingController(
      text: widget.expense['purchase_date'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.expense['location'] ?? '',
    );
    _gsthstController = TextEditingController(
      text:
          (widget.expense['gsthstPaidTotal'] ??
                  widget.expense['tax_amount'] ??
                  '0')
              .toString(),
    );
    _pstController = TextEditingController(
      text: (widget.expense['pstPaidTotal'] ?? '0').toString(),
    );
    _tipController = TextEditingController(
      text: (widget.expense['tipAmount'] ?? '0').toString(),
    );
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
      'total_amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
      'purchase_date': _dateController.text.trim(),
      'location': _locationController.text.trim(),
      'gsthstPaidTotal': double.tryParse(_gsthstController.text.trim()) ?? 0.0,
      'pstPaidTotal': double.tryParse(_pstController.text.trim()) ?? 0.0,
      'tipAmount': double.tryParse(_tipController.text.trim()) ?? 0.0,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) => value == null || value.isEmpty ? 'Required' : null,
      keyboardType: keyboardType,
    );
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
            children: [
              _buildTextField(controller: _vendorController, label: 'Vendor'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _amountController,
                label: 'Total Amount (\$)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _gsthstController,
                label: 'GST/HST (\$)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _pstController,
                label: 'PST (\$)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _tipController,
                label: 'Tip (\$)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _dateController,
                label: 'Purchase Date (DD-MMM-YYYY)',
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _notesController,
                label: 'Notes',
                keyboardType: TextInputType.multiline,
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

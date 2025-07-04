import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditTimesheetDataPage extends StatefulWidget {
  final Map<String, dynamic> record;

  const EditTimesheetDataPage({super.key, required this.record});

  @override
  State<EditTimesheetDataPage> createState() => _EditTimesheetDataPageState();
}

class _EditTimesheetDataPageState extends State<EditTimesheetDataPage> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _formData;
  bool _loading = false;

  // Cache controllers for date fields to preserve text
  final _weekStartController = TextEditingController();
  final _weekEndController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _formData = Map<String, dynamic>.from(widget.record);
    _weekStartController.text = _formData['weekStartDate'] ?? '';
    _weekEndController.text = _formData['weekEndDate'] ?? '';
  }

  Future<void> _updateRecord() async {
    setState(() => _loading = true);
    const url =
        'https://0lypmz70il.execute-api.ca-central-1.amazonaws.com/prod/timesheets/update-data-record';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_formData),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Record updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to update');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error updating record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildReadOnlyField(String label, String key) {
    return TextFormField(
      initialValue: _formData[key]?.toString() ?? '',
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String key, {
    bool isNumber = false,
    bool multiline = false,
  }) {
    return TextFormField(
      initialValue: _formData[key]?.toString() ?? '',
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: multiline ? 3 : 1,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (val) => _formData[key] = val,
    );
  }

  Widget _buildDatePickerField(
    String label,
    String key,
    TextEditingController controller,
  ) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final initialDate = _parseDate(controller.text) ?? now;
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) {
          final formatted =
              "${picked.day.toString().padLeft(2, '0')}-${_monthAbbr(picked.month)}-${picked.year}";
          setState(() {
            _formData[key] = formatted;
            controller.text = formatted;
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
        ),
      ),
    );
  }

  DateTime? _parseDate(String value) {
    try {
      final parts = value.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = _monthNum(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  String _monthAbbr(int month) {
    const months = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MAY",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
      "OCT",
      "NOV",
      "DEC",
    ];
    return months[month - 1];
  }

  int _monthNum(String abbr) {
    const months = {
      "JAN": 1,
      "FEB": 2,
      "MAR": 3,
      "APR": 4,
      "MAY": 5,
      "JUN": 6,
      "JUL": 7,
      "AUG": 8,
      "SEP": 9,
      "OCT": 10,
      "NOV": 11,
      "DEC": 12,
    };
    return months[abbr.toUpperCase()] ?? DateTime.now().month;
  }

  @override
  Widget build(BuildContext context) {
    final vsPurple = const Color(0xFF6A0DAD);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Timesheet Record'),
        backgroundColor: vsPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildReadOnlyField('Week ID (Read-Only)', 'weekId'),
                    const SizedBox(height: 10),
                    _buildReadOnlyField('Email (Read-Only)', 'email'),
                    const SizedBox(height: 10),
                    _buildDatePickerField(
                      'Week Start Date',
                      'weekStartDate',
                      _weekStartController,
                    ),
                    const SizedBox(height: 10),
                    _buildDatePickerField(
                      'Week End Date',
                      'weekEndDate',
                      _weekEndController,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField('Vehicle Number', 'vehicleNumber'),
                    const SizedBox(height: 10),
                    _buildTextField('KM Start', 'kmStart', isNumber: true),
                    const SizedBox(height: 10),
                    _buildTextField('KM End', 'kmEnd', isNumber: true),
                    const SizedBox(height: 10),
                    _buildTextField(
                      'Total Weekly Hours',
                      'totalHours',
                      isNumber: true,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      'Special Notes',
                      'specialNotes',
                      multiline: true,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vsPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _updateRecord,
                      child: const Text('Update Record'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

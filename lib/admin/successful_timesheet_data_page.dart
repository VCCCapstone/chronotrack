// ignore_for_file: control_flow_in_finally

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'edit_timesheet_data_page.dart';

class SuccessfulTimesheetDataPage extends StatefulWidget {
  const SuccessfulTimesheetDataPage({super.key});

  @override
  State<SuccessfulTimesheetDataPage> createState() =>
      _SuccessfulTimesheetDataPageState();
}

class _SuccessfulTimesheetDataPageState
    extends State<SuccessfulTimesheetDataPage> {
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  String _selectedEmail = '';
  String _selectedMonthYear = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchTimesheetRecords();
  }

  Future<void> fetchTimesheetRecords() async {
    setState(() => _loading = true);
    const url =
        'https://0lypmz70il.execute-api.ca-central-1.amazonaws.com/prod/timesheets/data';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        _allRecords = data.cast<Map<String, dynamic>>();

        _allRecords.sort((a, b) {
          try {
            final aTime = DateTime.parse(a['lastModified'] ?? '').toUtc();
            final bTime = DateTime.parse(b['lastModified'] ?? '').toUtc();
            return bTime.compareTo(aTime);
          } catch (_) {
            return 0;
          }
        });

        _applyFilters();
      } else {
        throw Exception('Failed to fetch');
      }
    } catch (e) {
      debugPrint('❌ Error fetching data: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Set<String> getAvailableEmails() =>
      _allRecords.map((e) => e['email'] ?? '').whereType<String>().toSet();

  Set<String> getAvailableMonthYears() =>
      _allRecords.map((e) => e['monthYear'] ?? '').whereType<String>().toSet();

  void _applyFilters() {
    setState(() {
      _filtered = _allRecords.where((entry) {
        final email = entry['email']?.toLowerCase() ?? '';
        final emailMatch = _selectedEmail.isEmpty || email == _selectedEmail;
        final monthMatch =
            _selectedMonthYear.isEmpty ||
            entry['monthYear'] == _selectedMonthYear;
        final searchMatch =
            _searchQuery.isEmpty || email.contains(_searchQuery.toLowerCase());

        return emailMatch && monthMatch && searchMatch;
      }).toList();
    });
  }

  Future<void> _deleteRecord(String weekId) async {
    const url =
        'https://0lypmz70il.execute-api.ca-central-1.amazonaws.com/prod/timesheets/delete-data-record';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'weekId': weekId}),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await fetchTimesheetRecords();
      } else {
        throw Exception('Delete failed');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error deleting record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editRecord(Map<String, dynamic> record) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTimesheetDataPage(record: record),
      ),
    );

    if (result == true) {
      await fetchTimesheetRecords();
    }
  }

  String _formatLocalDateTime(String utcString) {
    try {
      final utcDateTime = DateTime.parse(utcString).toUtc();
      final local = utcDateTime.toLocal();
      return "${local.day.toString().padLeft(2, '0')} ${_monthAbbr(local.month)} ${local.year}, "
          "${local.hour % 12 == 0 ? 12 : local.hour % 12}:${local.minute.toString().padLeft(2, '0')} "
          "${local.hour >= 12 ? 'PM' : 'AM'}";
    } catch (_) {
      return utcString;
    }
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildDropdown({
    required String hint,
    required String value,
    required Set<String> items,
    required Function(String?) onChanged,
  }) {
    const vsPurple = Color(0xFF6A0DAD);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: vsPurple, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: Text(hint),
          items: items.map((val) {
            return DropdownMenuItem(value: val, child: Text(val));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const vsPurple = Color(0xFF6A0DAD);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: vsPurple,
        foregroundColor: Colors.white,
        title: const Text("Successful Timesheet Data"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTimesheetRecords,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by Email',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 20,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildDropdown(
                      hint: "Filter by Email",
                      value: _selectedEmail,
                      items: getAvailableEmails(),
                      onChanged: (val) {
                        _selectedEmail = val ?? '';
                        _applyFilters();
                      },
                    ),
                    _buildDropdown(
                      hint: "Filter by Month-Year",
                      value: _selectedMonthYear,
                      items: getAvailableMonthYears(),
                      onChanged: (val) {
                        _selectedMonthYear = val ?? '';
                        _applyFilters();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final entry = _filtered[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            entry['email'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Week ID: ${entry['weekId'] ?? 'N/A'}"),
                              Text(
                                "Week Start: ${entry['weekStartDate'] ?? 'N/A'}",
                              ),
                              Text(
                                "Week End: ${entry['weekEndDate'] ?? 'N/A'}",
                              ),
                              Text(
                                "Vehicle: ${entry['vehicleNumber'] ?? 'N/A'}",
                              ),
                              Text(
                                "KM Start: ${entry['kmStart'] ?? 'N/A'}   KM End: ${entry['kmEnd'] ?? 'N/A'}",
                              ),
                              Text("KM Total: ${entry['kmTotal'] ?? 'N/A'}"),
                              Text(
                                "Total Weekly Hours: ${entry['totalHours'] ?? 'N/A'}",
                              ),
                              Text(
                                "Special Notes: ${entry['specialNotes'] ?? ''}",
                              ),
                              Text(
                                "Last Modified: ${_formatLocalDateTime(entry['lastModified'] ?? '')}",
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 10,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: "Edit",
                                onPressed: () => _editRecord(entry),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                tooltip: "Delete",
                                onPressed: () => _deleteRecord(entry['weekId']),
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
    );
  }
}

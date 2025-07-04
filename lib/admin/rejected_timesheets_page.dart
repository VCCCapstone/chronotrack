// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class RejectedTimesheetsPage extends StatefulWidget {
  const RejectedTimesheetsPage({super.key});

  @override
  State<RejectedTimesheetsPage> createState() => _RejectedTimesheetsPageState();
}

class _RejectedTimesheetsPageState extends State<RejectedTimesheetsPage> {
  List<Map<String, dynamic>> _timesheets = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _selectedEmail = '';
  String _selectedMonthYear = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchTimesheets();
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) =>
                  const Center(child: CircularProgressIndicator()),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchTimesheets() async {
    setState(() => _loading = true);
    const url =
        'https://0lypmz70il.execute-api.ca-central-1.amazonaws.com/prod/timesheets/rejected';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _timesheets = data.cast<Map<String, dynamic>>();
        _applyFilters();
      } else {
        print('Failed to load timesheets: ${response.body}');
      }
    } catch (e) {
      print('Error fetching timesheets: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Set<String> getAvailableEmails() {
    return _timesheets.map((e) => e['email'] as String).toSet();
  }

  Set<String> getAvailableMonthYears() {
    return _timesheets.map((e) => e['monthYear'] as String).toSet();
  }

  void _applyFilters() {
    setState(() {
      _filtered = _timesheets.where((entry) {
        final emailMatch =
            _selectedEmail.isEmpty || entry['email'] == _selectedEmail;
        final monthMatch =
            _selectedMonthYear.isEmpty ||
            entry['monthYear'] == _selectedMonthYear;
        final searchMatch =
            _searchQuery.isEmpty ||
            entry['email'].toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
        return emailMatch && monthMatch && searchMatch;
      }).toList();
    });
  }

  Future<void> _deleteTimesheet(String key) async {
    final url =
        'https://0lypmz70il.execute-api.ca-central-1.amazonaws.com/prod/timesheet/delete';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'key': key}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Timesheet deleted successfully."),
            backgroundColor: Colors.green,
          ),
        );
        await fetchTimesheets();
      } else {
        throw Exception('Delete failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error deleting timesheet: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vsPurple = const Color(0xFF6A0DAD);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: vsPurple,
        foregroundColor: Colors.white,
        title: const Text("Rejected Timesheets"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTimesheets,
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
                    decoration: const InputDecoration(
                      labelText: 'Search by Email',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: _selectedEmail.isEmpty ? null : _selectedEmail,
                      hint: const Text("Filter by Email"),
                      items: getAvailableEmails()
                          .map(
                            (email) => DropdownMenuItem(
                              value: email,
                              child: Text(email),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedEmail = val ?? '';
                          _applyFilters();
                        });
                      },
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      dropdownColor: Colors.white,
                    ),
                    DropdownButton<String>(
                      value: _selectedMonthYear.isEmpty
                          ? null
                          : _selectedMonthYear,
                      hint: const Text("Filter by Month-Year"),
                      items: getAvailableMonthYears()
                          .map(
                            (my) =>
                                DropdownMenuItem(value: my, child: Text(my)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedMonthYear = val ?? '';
                          _applyFilters();
                        });
                      },
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      dropdownColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final entry = _filtered[index];
                      final lastModified = DateTime.tryParse(
                        entry['lastModified'] ?? '',
                      );
                      final localTime = lastModified != null
                          ? DateFormat(
                              'dd-MMM-yyyy hh:mm a',
                            ).format(lastModified.toLocal())
                          : 'N/A';

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
                          title: Text(entry['email']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Week: ${entry['week']}"),
                              Text(
                                "Month-Year: ${entry['month']}-${entry['year']}",
                              ),
                              Text("Last Modified: $localTime"),
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 10,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye),
                                tooltip: "Preview",
                                onPressed: () => _showImagePreview(
                                  context,
                                  entry['previewUrl'],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.download),
                                tooltip: "Download",
                                onPressed: () =>
                                    _download(entry['downloadUrl']),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                tooltip: "Delete",
                                onPressed: () => _deleteTimesheet(entry['key']),
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

  void _preview(String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Preview"),
        content: Image.network(
          url,
          errorBuilder: (_, __, ___) => const Text("Cannot preview image."),
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _download(String url) {
    print("⬇️ Download URL: $url");
  }
}

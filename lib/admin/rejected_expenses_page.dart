// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';

class RejectedExpensesPage extends StatefulWidget {
  const RejectedExpensesPage({super.key});

  @override
  State<RejectedExpensesPage> createState() => _RejectedExpensesPageState();
}

class _RejectedExpensesPageState extends State<RejectedExpensesPage> {
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    setState(() => _loading = true);
    final url = Uri.parse(
      'https://b93r46mokk.execute-api.ca-central-1.amazonaws.com/prod/expense/list-images?folder=rejected',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _expenses = data.cast<Map<String, dynamic>>();
        _filtered = _expenses;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      debugPrint('Failed to fetch rejected expenses: ${response.body}');
    }
  }

  void _filter(String search) {
    setState(() {
      _search = search.toLowerCase();
      _filtered = _expenses.where((e) {
        final email = e['email']?.toLowerCase() ?? '';
        final vendor = e['vendor']?.toLowerCase() ?? '';
        return email.contains(_search) || vendor.contains(_search);
      }).toList();
    });
  }

  Future<void> _deleteFile(Map<String, dynamic> expense) async {
    final filename = expense['filename'] ?? '';

    final url = Uri.parse(
      'https://b93r46mokk.execute-api.ca-central-1.amazonaws.com/prod/expense/delete',
    );

    final response = await http.post(
      url,
      body: jsonEncode({
        'filename': filename,
        'folder': 'rejected', // Only send the S3 file name
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File deleted successfully')),
      );
      fetchExpenses();
    } else {
      debugPrint('Delete failed: ${response.body}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete file')));
    }
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejected Expense Receipts'),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by email or vendor...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('No rejected receipts found.'),
                          )
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final expense = _filtered[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    expense['vendor'] ?? 'Unknown Vendor',
                                  ),
                                  subtitle: Text(
                                    expense['email'] ?? 'Unknown Email',
                                  ),
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_red_eye_outlined,
                                        ),
                                        tooltip: 'Preview',
                                        onPressed: () => _showImagePreview(
                                          context,
                                          expense['previewUrl'],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        tooltip: 'Download',
                                        onPressed: () =>
                                            _openUrl(expense['downloadUrl']),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Delete',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                'Confirm Deletion',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this expense?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            _deleteFile(expense);
                                          }
                                        },
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

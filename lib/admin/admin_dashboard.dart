// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:chronotrack/admin/admin_self_profile_page.dart';
import 'package:chronotrack/admin/manage_users_page.dart';
import 'package:chronotrack/admin/rejected_timesheets_page.dart';
import 'package:chronotrack/admin/successful_timesheet_data_page.dart';
import 'package:chronotrack/admin/successful_timesheets_page.dart';
import 'package:chronotrack/admin/admin_list_expense_page.dart';
import 'package:chronotrack/admin/rejected_expenses_page.dart';
import 'package:chronotrack/admin/successful_expenses_page.dart';
import 'package:chronotrack/user/upload_expense_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _signOut(BuildContext context) async {
    try {
      await Amplify.Auth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
        actions: [
          Tooltip(
            message: 'Manage Employees',
            child: IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageUsersPage()),
                );
              },
            ),
          ),
          Tooltip(
            message: 'Admin Profile',
            child: IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminSelfProfilePage(),
                  ),
                );
              },
            ),
          ),
          Tooltip(
            message: 'Sign Out',
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _signOut(context),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildDashboardCard(
                    context,
                    title: 'Successful Timesheet Files',
                    icon: Icons.check_circle_outline,
                    color: theme.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuccessfulTimesheetsPage(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Successful Timesheet Data',
                    icon: Icons.folder_copy_sharp,
                    color: theme.secondary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuccessfulTimesheetDataPage(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Rejected Timesheets',
                    icon: Icons.error_outline,
                    color: Colors.red.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RejectedTimesheetsPage(),
                        ),
                      );
                    },
                  ),

                  // New Admin Expense Cards
                  _buildDashboardCard(
                    context,
                    title: 'Show All Expenses (Edit/Delete)',
                    icon: Icons.receipt_long,
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminListExpensePage(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Upload Expense (Admin)',
                    icon: Icons.upload_file,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UploadExpensePage(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Rejected Expense Receipts',
                    icon: Icons.report_gmailerrorred_outlined,
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RejectedExpensesPage(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Successful Expense Receipts',
                    icon: Icons.task_alt,
                    color: Colors.blueGrey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuccessfulExpensesPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280,
          height: 160,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                offset: const Offset(2, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

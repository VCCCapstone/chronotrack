// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import 'amplifyconfiguration.dart'; // ← required
import 'login_page.dart';
import 'user/upload_page.dart';
import 'user/user_profile_page.dart';
import 'user/timesheet_form_page.dart';
import 'admin/admin_dashboard.dart';
import 'admin/manage_users_page.dart';
import 'admin/signup_user_page.dart';
import 'admin/edit_user_profile_page.dart';
import 'admin/rejected_timesheets_page.dart';
import 'admin/successful_timesheet_data_page.dart';
import 'admin/admin_employee_list_page.dart';
import 'admin/admin_self_profile_page.dart';
import 'admin/successful_timesheets_page.dart';

void main() {
  runApp(const ChronoTrackApp());
}

class ChronoTrackApp extends StatefulWidget {
  const ChronoTrackApp({super.key});

  @override
  State<ChronoTrackApp> createState() => _ChronoTrackAppState();
}

class _ChronoTrackAppState extends State<ChronoTrackApp> {
  Widget _initialScreen = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  bool _amplifyConfigured = false;

  @override
  void initState() {
    super.initState();
    _configureAmplify().then((_) => _checkAuthSession());
  }

  Future<void> _configureAmplify() async {
    if (_amplifyConfigured) return;

    try {
      final authPlugin = AmplifyAuthCognito();
      await Amplify.addPlugin(authPlugin);
      await Amplify.configure(amplifyconfig);
      _amplifyConfigured = true;
      print('✅ Amplify configured');
    } catch (e) {
      print('⚠️ Amplify already configured or failed: $e');
    }
  }

  Future<void> _checkAuthSession() async {
    try {
      final result =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      final tokens = result.userPoolTokensResult.valueOrNull;
      final idTokenRaw = tokens?.idToken.raw;

      if (idTokenRaw != null) {
        final decoded = _decodeJwt(idTokenRaw);
        final groups = decoded['cognito:groups'] ?? [];

        setState(() {
          _initialScreen = groups.contains('admin')
              ? const AdminDashboard()
              : const UploadPage();
        });
        return;
      }
    } catch (e) {
      print("🔴 Auth session check failed: $e");
    }

    setState(() {
      _initialScreen = const LoginPage();
    });
  }

  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = base64.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return json.decode(decoded);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChronoTrack',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _initialScreen,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/upload':
            return MaterialPageRoute(builder: (_) => const UploadPage());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const UserProfilePage());
          case '/timesheet-form':
            return MaterialPageRoute(builder: (_) => const TimesheetFormPage());
          case '/admin-dashboard':
            return MaterialPageRoute(builder: (_) => const AdminDashboard());
          case '/manage-users':
            return MaterialPageRoute(builder: (_) => const ManageUsersPage());
          case '/employee-list':
            return MaterialPageRoute(
              builder: (_) => const AdminEmployeeListPage(),
            );
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupUserPage());
          case '/rejected-timesheets':
            return MaterialPageRoute(
              builder: (_) => const RejectedTimesheetsPage(),
            );
          case '/successful-timesheets-data':
            return MaterialPageRoute(
              builder: (_) => const SuccessfulTimesheetDataPage(),
            );
          case '/admin-profile':
            return MaterialPageRoute(
              builder: (_) => const AdminSelfProfilePage(),
            );
          case '/edit-profile':
            final userData = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => EditUserProfilePage(userData: userData),
            );
          case '/successful-timesheets':
            return MaterialPageRoute(
              builder: (_) => const SuccessfulTimesheetsPage(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('404 – Page Not Found')),
              ),
            );
        }
      },
    );
  }
}

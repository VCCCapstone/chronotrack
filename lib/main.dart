import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import 'amplifyconfiguration.dart';
import 'login_page.dart';
import 'user/upload_page.dart';
import 'admin/admin_dashboard.dart';

void main() {
  runApp(const ChronoTrackApp());
}

class ChronoTrackApp extends StatefulWidget {
  const ChronoTrackApp({super.key});

  @override
  State<ChronoTrackApp> createState() => _ChronoTrackAppState();
}

class _ChronoTrackAppState extends State<ChronoTrackApp> {
  bool _amplifyConfigured = false;
  bool _isSignedIn = false;
  bool _isAdmin = false;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);
      await Amplify.configure(amplifyconfig);

      final session = await Amplify.Auth.fetchAuthSession();
      _isSignedIn = session.isSignedIn;

      if (_isSignedIn) {
        final attributes = await Amplify.Auth.fetchUserAttributes();
        final emailAttr = attributes.firstWhere(
          (attr) => attr.userAttributeKey == CognitoUserAttributeKey.email,
          orElse: () => const AuthUserAttribute(
            userAttributeKey: CognitoUserAttributeKey.email,
            value: '',
          ),
        );
        _userEmail = emailAttr.value;

        final groupsAttr = attributes.firstWhere(
          (attr) => attr.userAttributeKey.key == 'custom:groups',
          orElse: () => const AuthUserAttribute(
            userAttributeKey: CognitoUserAttributeKey.email,
            value: '',
          ),
        );
        _isAdmin = groupsAttr.value.toLowerCase().contains('admin');
      }

      setState(() => _amplifyConfigured = true);
    } catch (e) {
      debugPrint("Amplify config error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_amplifyConfigured) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChronoTrack Timesheet',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: _isSignedIn
          ? (_isAdmin ? const AdminDashboard() : UploadPage(userEmail: _userEmail))
          : const LoginPage(),
      routes: {
        '/upload': (context) => UploadPage(userEmail: _userEmail),
      },
    );
  }
}

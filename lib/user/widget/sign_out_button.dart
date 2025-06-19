import 'package:flutter/material.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../login_page.dart';

class SignOutButton extends StatelessWidget {
  const SignOutButton({Key? key}) : super(key: key);

  void _signOut(BuildContext context) async {
    try {
      await Amplify.Auth.signOut();
      //if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } on AuthException catch (e) {
      debugPrint("Sign out failed: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Sign Out',
      onPressed: () => _signOut(context),
    );
  }
}

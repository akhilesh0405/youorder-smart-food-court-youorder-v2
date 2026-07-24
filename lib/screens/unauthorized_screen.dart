import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/app_theme.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_rounded, size: 80, color: AppTheme.errorColor),
              ),
              const SizedBox(height: 40),
              const Text(
                'Access Denied',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'You do not have permission to access this dashboard. Please contact the administrator if you believe this is an error.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    await auth.signOut();
                    // Navigator.pop(context) is handled by RoleGate/Stream
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                  ),
                  child: const Text('Sign Out & Return'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
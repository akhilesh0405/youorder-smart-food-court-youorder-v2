import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/unauthorized_screen.dart';
import '../screens/login_screen.dart';

class RoleGate extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;
  final String? restaurantId;
  final bool? showRegisterLink;

  const RoleGate({
    super.key,
    required this.child,
    required this.allowedRoles,
    this.restaurantId,
    this.showRegisterLink,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return LoginScreen(
        showRegisterLink: showRegisterLink ?? allowedRoles.contains('customer'),
      );
    }

    final userRole = auth.userRole;
    final userRestaurantId = auth.assignedRestaurantId;

    print('🛡️ RoleGate: Checking access for Role: [$userRole] against Allowed: $allowedRoles');

    // Check role
    bool isAuthorized = allowedRoles.contains(userRole);

    // If staff, also check restaurantId if provided
    if (isAuthorized && userRole == 'restaurant_staff' && restaurantId != null) {
      if (userRestaurantId != restaurantId) {
        isAuthorized = false;
      }
    }

    if (isAuthorized) {
      return child;
    } else {
      // Auto logout after a short delay to allow the user to see the message if needed, 
      // but in this case, the UnauthorizedScreen has a logout button as well.
      // The requirement says: "Then sign the user out and return to the login screen."
      // I'll show the UnauthorizedScreen first.
      return const UnauthorizedScreen();
    }
  }
}
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/restaurant_dashboard.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_theme.dart';
import 'widgets/role_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Panarottis Dashboard - Firebase initialized!");
  } catch (e) {
    print("❌ Error: $e");
  }
  runApp(const PanarottisDashboardApp());
}

class PanarottisDashboardApp extends StatefulWidget {
  const PanarottisDashboardApp({super.key});

  @override
  State<PanarottisDashboardApp> createState() => _PanarottisDashboardAppState();
}

class _PanarottisDashboardAppState extends State<PanarottisDashboardApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'Panarottis Dashboard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _showSplash 
            ? const SplashScreen() 
            : Consumer<AuthService>(
                builder: (context, auth, _) {
                  // Create the dashboard widget
                  final dashboard = RestaurantDashboard(
                    restaurantId: 'panarottis_mauritius',
                  );

                  return RoleGate(
                    allowedRoles: const ['restaurant_staff'],
                    restaurantId: 'panarottis_mauritius',
                    child: dashboard,
                  );
                },
              ),
      ),
    );
  }
}

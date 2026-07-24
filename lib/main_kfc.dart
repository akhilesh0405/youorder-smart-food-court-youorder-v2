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
    print("✅ KFC Dashboard - Firebase initialized!");
  } catch (e) {
    print("❌ Error: $e");
  }
  runApp(const KFCDashboardApp());
}

class KFCDashboardApp extends StatefulWidget {
  const KFCDashboardApp({super.key});

  @override
  State<KFCDashboardApp> createState() => _KFCDashboardAppState();
}

class _KFCDashboardAppState extends State<KFCDashboardApp> {
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
        title: 'KFC Dashboard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _showSplash 
            ? const SplashScreen() 
            : Consumer<AuthService>(
                builder: (context, auth, _) {
                  final dashboard = RestaurantDashboard(
                    restaurantId: 'kfc_mauritius',
                  );

                  return RoleGate(
                    allowedRoles: const ['restaurant_staff'],
                    restaurantId: 'kfc_mauritius',
                    child: dashboard,
                  );
                },
              ),
      ),
    );
  }
}

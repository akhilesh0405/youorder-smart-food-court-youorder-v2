import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/restaurant_dashboard.dart';

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

class PanarottisDashboardApp extends StatelessWidget {
  const PanarottisDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          // Create the dashboard widget
          final dashboard = RestaurantDashboard(
            restaurantId: 'panarottis_mauritius',
          );

          return MaterialApp(
            title: 'Panarottis Dashboard',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),
            // 👇 Show LoginScreen if not authenticated, otherwise show dashboard
            home: auth.isAuthenticated
                ? dashboard
                : LoginScreen(destination: dashboard),
          );
        },
      ),
    );
  }
}
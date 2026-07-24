import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'providers/cart_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/restaurant_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_theme.dart';
import 'widgets/role_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully!");
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'YouOrder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // 👇 Switch the widget INSIDE home, don't make home null
        home: _showSplash 
            ? const SplashScreen() 
            : Consumer<AuthService>(
                builder: (context, auth, _) {
                  return const RoleGate(
                    allowedRoles: ['customer'],
                    child: HomeScreen(),
                  );
                },
              ),
        onGenerateRoute: (settings) {
          String route = settings.name ?? '/';
          if (route.startsWith('/#')) route = route.substring(2);
          
          print("🔍 Route requested: $route");
          
          // --- ADMIN DASHBOARD ---
          if (route == '/admin') {
            return MaterialPageRoute(
              builder: (context) => const RoleGate(
                allowedRoles: ['admin'],
                child: AdminDashboard(),
              ),
            );
          }
          
          // --- RESTAURANT DASHBOARDS ---
          if (route.startsWith('/restaurant/')) {
            final restaurantId = route.replaceFirst('/restaurant/', '');
            return MaterialPageRoute(
              builder: (context) => RoleGate(
                allowedRoles: const ['restaurant_staff'],
                restaurantId: restaurantId,
                child: RestaurantDashboard(restaurantId: restaurantId),
              ),
            );
          }

          // --- ORDER TRACKING ---
          if (route.startsWith('/order/')) {
            final orderId = route.replaceFirst('/order/', '');
            return MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(orderId: orderId),
            );
          }
          
          // --- DEFAULT/FALLBACK ---
          return null; // Let 'home' handle it
        },
      ),
    );
  }
}


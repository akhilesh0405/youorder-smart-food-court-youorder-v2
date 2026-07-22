import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'providers/cart_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/restaurant_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/order_tracking_screen.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'YouOrder',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              textTheme: GoogleFonts.robotoTextTheme(),
            ),
            // 👇 Remove `home` and `routes` – use `onGenerateRoute` exclusively
            onGenerateRoute: (settings) {
              // Get the route from the URL (including hash fragment)
              String route = settings.name ?? '/';
              
              // Remove the # if present
              if (route.startsWith('/#')) {
                route = route.substring(2); // Remove /#
              }
              
              print("🔍 Route requested: $route");
              
              // --- CUSTOMER APP (Default) ---
              if (route == '/' || route == '/home' || route.isEmpty) {
                return MaterialPageRoute(
                  builder: (context) => auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
                );
              }
              
              // --- LOGIN ---
              if (route == '/login') {
                return MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                );
              }
              
              // --- RESTAURANT DASHBOARD ---
              if (route.startsWith('/restaurant/')) {
                final restaurantId = route.replaceFirst('/restaurant/', '');
                print("🍕 Restaurant Dashboard: $restaurantId");
                
                // If not logged in, show login first, then dashboard
                if (!auth.isAuthenticated) {
                  return MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      destination: RestaurantDashboard(restaurantId: restaurantId),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => RestaurantDashboard(restaurantId: restaurantId),
                );
              }
              
              // --- ADMIN DASHBOARD ---
              if (route == '/admin') {
                print("📊 Admin Dashboard");
                if (!auth.isAuthenticated) {
                  return MaterialPageRoute(
                    builder: (context) => const LoginScreen(destination: AdminDashboard()),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => const AdminDashboard(),
                );
              }
              
              // --- ORDER TRACKING ---
              if (route.startsWith('/order/')) {
                final orderId = route.replaceFirst('/order/', '');
                print("📦 Order Tracking: $orderId");
                return MaterialPageRoute(
                  builder: (context) => OrderTrackingScreen(orderId: orderId),
                );
              }
              
              // --- FALLBACK: home ---
              print("⚠️ Unknown route: $route → going to home");
              return MaterialPageRoute(
                builder: (context) => auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
              );
            },
            // 👇 Set initial route so that `onGenerateRoute` runs on app start
            initialRoute: '/',
          );
        },
      ),
    );
  }
}
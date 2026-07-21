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
    print("✅ Project ID: ${Firebase.app().options.projectId}");
    print("✅ API Key: ${Firebase.app().options.apiKey}");
    print("✅ App ID: ${Firebase.app().options.appId}");
    print("✅ Auth available: ${FirebaseAuth.instance != null}");
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
            home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/restaurant_dashboard': (context) => const RestaurantDashboard(
                restaurantId: 'panarottis_mauritius',
              ),
              '/admin_dashboard': (context) => const AdminDashboard(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/order_tracking') {
                final orderId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) => OrderTrackingScreen(orderId: orderId),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
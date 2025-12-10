import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth/crown_screen.dart';
import 'pages/dashboard.dart';
import 'auth/forgot_password.dart';
import 'auth/register_page.dart';
import 'auth/login_page.dart';
import 'providers/cart_provider.dart';
import 'providers/user_provider.dart';
import 'favorite_service.dart';
import 'pages/delivery.dart';
import 'pages/history_payment.dart';
import 'pages/favorite.dart';
import 'pages/checkout.dart';
import 'pages/search_results.dart';
import 'pages/cart.dart';
import 'pages/all_product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    try {
      final user = FirebaseAuth.instance.currentUser;
      print('👤 Current user: ${user?.uid ?? "Not logged in"}');
    } catch (e) {
      print('⚠️ Firebase test error: $e');
    }

  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SkinCare Store',
        theme: ThemeData(
          primaryColor: Colors.pink[400],
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.pink,
            accentColor: Colors.pink[300],
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.pink[50],
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.pink),
            titleTextStyle: TextStyle(
              color: Colors.pink[700],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          fontFamily: 'Poppins',
        ),
        home: const SplashScreenWrapper(),
        routes: {
          '/dashboard': (context) => const Dashboard(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/forgot': (context) => const ForgotPasswordPage(),
          '/delivery': (context) => const DeliveryPage(),
          '/favorites': (context) => const FavoritesPage(),
          '/checkout': (context) => CheckoutFormPage(selectedItems: []),
          '/history': (context) => const PaymentHistoryPage(),
          '/cart': (context) => const CartPage(),
          '/products' : (context) => const AllProductsPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/search-results') {
            final args = settings.arguments as Map<String, dynamic>?;
            final query = args?['query'] ?? '';
            return MaterialPageRoute(
              builder: (_) => SearchResultsPage(searchQuery: query),
            );
          }
          return null;
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Page Not Found')),
              body: const Center(
                child: Text('The requested page was not found.'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Dashboard()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_page.dart';
import 'screens/wallet_screen.dart';
import 'screens/credit_card_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'providers/currency_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider(
          create: (_) => CurrencyProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Personal Finance Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Poppins',
        ),
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const HomePage(),
          '/creditcard': (context) => const CreditCardScreen(),
          '/budget': (context) => const BudgetScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/reports': (context) => const ReportScreen(),
          '/add-transaction': (context) => const AddTransactionScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        // Show loading indicator while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If there's an error or no user, show login screen
        if (snapshot.hasError || snapshot.data == null) {
          return const LoginScreen();
        }

        // User is authenticated, show HomePage with initial index 0 (WalletScreen)
        return const HomePage();
      },
    );
  }
}

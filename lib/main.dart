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

// import 'package:flutter/material.dart';
// import 'package:device_preview/device_preview.dart';
// import 'screens/home_page.dart';
// import 'screens/wallet_screen.dart';
// import 'screens/credit_card_screen.dart';
// import 'screens/budget_screen.dart';
// import 'screens/profile_screen.dart';
// import 'screens/report_screen.dart';
//
// void main() {
//   runApp(
//     DevicePreview(
//       enabled: true, // Enable device preview
//       tools: [
//         ...DevicePreview.defaultTools,
//       ],
//       builder: (context) => ExpenseTrackerApp(),
//     ),
//   );
// }
//
// class ExpenseTrackerApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Expense Tracker',
//       useInheritedMediaQuery: true, // For device preview
//       locale: DevicePreview.locale(context), // For device preview
//       builder: DevicePreview.appBuilder, // For device preview
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         scaffoldBackgroundColor: Colors.grey[100],
//         fontFamily: 'SF Pro Display',
//       ),
//       home: HomePage(),
//       routes: {
//         '/home': (context) => HomePage(),
//         '/wallet': (context) => WalletScreen(),
//         '/creditcard': (context) => CreditCardScreen(),
//         '/budget': (context) => BudgetScreen(),
//         '/profile': (context) => ProfileScreen(),
//         '/report': (context) => ReportScreen(),
//       },
//     );
//   }
// }
//

// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(const FinanceTrackerApp());
// }
//
// class FinanceTrackerApp extends StatelessWidget {
//   const FinanceTrackerApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: const HomeScreen(),
//     );
//   }
// }
//
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       bottomNavigationBar: BottomNavigationBar(
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
//           BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 20),
//             const Text(
//               'Hey George!',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             // Card Section
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'VISA **** 3854',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//                   const SizedBox(height: 10),
//                   const Text(
//                     'Due Date 10th Oct',
//                     style: TextStyle(color: Colors.grey, fontSize: 14),
//                   ),
//                   const SizedBox(height: 10),
//                   const Text(
//                     '\$5,001.86',
//                     style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 10),
//                   ElevatedButton(
//                     onPressed: () {},
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//                     child: const Text('PAY'),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Bill Payments',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             GridView.count(
//               shrinkWrap: true,
//               crossAxisCount: 4,
//               children: const [
//                 Icon(Icons.electric_bolt),
//                 Icon(Icons.wifi),
//                 Icon(Icons.tv),
//                 Icon(Icons.phone_android),
//               ],
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Active Loans',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             ListTile(
//               leading: const Icon(Icons.directions_car, size: 40),
//               title: const Text('Model X'),
//               subtitle: const Text('\$399/M - 48/60'),
//               trailing: const Text('Next: 5th Oct'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Let me know if you'd like me to tweak the layout or add more details! 🚀

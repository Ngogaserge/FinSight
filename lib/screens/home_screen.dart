// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../models/transaction_model.dart';
// import '../services/auth_service.dart';
// import '../services/database_service.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   final AuthService _authService = AuthService();
//   late DatabaseService _databaseService;
//   bool _isLoading = true;
//   String? _error;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }
//
//   Future<void> _initializeData() async {
//     if (_authService.currentUserId == null) {
//       Navigator.pushReplacementNamed(context, '/login');
//       return;
//     }
//
//     _databaseService = DatabaseService(userId: _authService.currentUserId!);
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : CustomScrollView(
//               slivers: [
//                 // Custom App Bar with Balance
//                 SliverAppBar(
//                   expandedHeight: 200,
//                   floating: false,
//                   pinned: true,
//                   flexibleSpace: FlexibleSpaceBar(
//                     background: Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: [
//                             Theme.of(context).primaryColor,
//                             Theme.of(context).primaryColor.withOpacity(0.8),
//                           ],
//                         ),
//                       ),
//                       child: StreamBuilder<double>(
//                         stream: _databaseService.getTotalBalance(),
//                         builder: (context, snapshot) {
//                           if (snapshot.hasError) {
//                             return const Center(
//                               child: Text(
//                                 'Error loading balance',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             );
//                           }
//
//                           final balance = snapshot.data ?? 0.0;
//                           final isPositive = balance >= 0;
//
//                           return Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               const Text(
//                                 'Total Balance',
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 NumberFormat.currency(symbol: '\$')
//                                     .format(balance.abs()),
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 36,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                   vertical: 6,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: isPositive
//                                       ? Colors.green.withOpacity(0.2)
//                                       : Colors.red.withOpacity(0.2),
//                                   borderRadius: BorderRadius.circular(20),
//                                 ),
//                                 child: Text(
//                                   isPositive ? 'Positive' : 'Negative',
//                                   style: TextStyle(
//                                     color: isPositive
//                                         ? Colors.green[100]
//                                         : Colors.red[100],
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 // Quick Actions
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         _buildQuickActionButton(
//                           icon: Icons.add,
//                           label: 'Add Transaction',
//                           onTap: () =>
//                               Navigator.pushNamed(context, '/add-transaction'),
//                           color: Theme.of(context).primaryColor,
//                         ),
//                         _buildQuickActionButton(
//                           icon: Icons.account_balance_wallet,
//                           label: 'Wallets',
//                           onTap: () => Navigator.pushNamed(context, '/wallets'),
//                           color: Colors.blue,
//                         ),
//                         _buildQuickActionButton(
//                           icon: Icons.pie_chart,
//                           label: 'Reports',
//                           onTap: () => Navigator.pushNamed(context, '/reports'),
//                           color: Colors.orange,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 // Recent Transactions
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             const Text(
//                               'Recent Transactions',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             TextButton.icon(
//                               onPressed: () =>
//                                   Navigator.pushNamed(context, '/transactions'),
//                               icon: const Icon(Icons.arrow_forward),
//                               label: const Text('View All'),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         StreamBuilder<List<Transaction>>(
//                           stream: _databaseService.getRecentTransactions(),
//                           builder: (context, snapshot) {
//                             if (snapshot.hasError) {
//                               return Center(
//                                 child: Text('Error: ${snapshot.error}'),
//                               );
//                             }
//
//                             if (!snapshot.hasData) {
//                               return _buildEmptyState();
//                             }
//
//                             final transactions = snapshot.data!;
//
//                             if (transactions.isEmpty) {
//                               return _buildEmptyState();
//                             }
//
//                             return ListView.builder(
//                               shrinkWrap: true,
//                               physics: const NeverScrollableScrollPhysics(),
//                               itemCount: transactions.length,
//                               itemBuilder: (context, index) {
//                                 final transaction = transactions[index];
//                                 final isIncome =
//                                     transaction.type == TransactionType.income;
//
//                                 return Card(
//                                   elevation: 2,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   margin: const EdgeInsets.only(bottom: 8),
//                                   child: ListTile(
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 16,
//                                       vertical: 8,
//                                     ),
//                                     leading: Container(
//                                       padding: const EdgeInsets.all(8),
//                                       decoration: BoxDecoration(
//                                         color: isIncome
//                                             ? Colors.green.withOpacity(0.1)
//                                             : Colors.red.withOpacity(0.1),
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       child: Icon(
//                                         isIncome
//                                             ? Icons.arrow_upward
//                                             : Icons.arrow_downward,
//                                         color: isIncome
//                                             ? Colors.green
//                                             : Colors.red,
//                                       ),
//                                     ),
//                                     title: Text(
//                                       transaction.title,
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                     subtitle: Text(
//                                       DateFormat('MMM dd, yyyy')
//                                           .format(transaction.date),
//                                       style: const TextStyle(
//                                         color: Colors.grey,
//                                       ),
//                                     ),
//                                     trailing: Column(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.end,
//                                       children: [
//                                         Text(
//                                           NumberFormat.currency(symbol: '\$')
//                                               .format(transaction.amount),
//                                           style: TextStyle(
//                                             color: isIncome
//                                                 ? Colors.green
//                                                 : Colors.red,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                         Text(
//                                           transaction.category,
//                                           style: const TextStyle(
//                                             color: Colors.grey,
//                                             fontSize: 12,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     onTap: () {
//                                       Navigator.pushNamed(
//                                         context,
//                                         '/transaction-details',
//                                         arguments: transaction,
//                                       );
//                                     },
//                                   ),
//                                 );
//                               },
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           Navigator.pushNamed(context, '/add-transaction');
//         },
//         icon: const Icon(Icons.add),
//         label: const Text('Add Transaction'),
//       ),
//     );
//   }
//
//   Widget _buildQuickActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//     required Color color,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 12,
//         ),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: color),
//             const SizedBox(height: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.receipt_long,
//             size: 64,
//             color: Colors.grey,
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'No Transactions Yet',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Add a transaction to get started',
//             style: TextStyle(
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: () {
//               Navigator.pushNamed(context, '/add-transaction');
//             },
//             icon: const Icon(Icons.add),
//             label: const Text('Add Transaction'),
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 24,
//                 vertical: 12,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/transaction_model.dart' as models;

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late DatabaseService _databaseService;
  late AuthService _authService;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'This Month',
    'Last Month',
    'This Year',
    'Last Year'
  ];

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      _authService = Provider.of<AuthService>(context, listen: false);
      final userId = _authService.currentUserId;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Please sign in to view reports';
          _isLoading = false;
        });
        return;
      }

      _databaseService = DatabaseService(userId: userId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing database: $e';
        _isLoading = false;
      });
    }
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'Last Month':
        return DateTime(now.year, now.month - 1, 1);
      case 'This Year':
        return DateTime(now.year, 1, 1);
      case 'Last Year':
        return DateTime(now.year - 1, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime _getEndDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Month':
        return DateTime(now.year, now.month + 1, 0);
      case 'Last Month':
        return DateTime(now.year, now.month, 0);
      case 'This Year':
        return DateTime(now.year, 12, 31);
      case 'Last Year':
        return DateTime(now.year - 1, 12, 31);
      default:
        return DateTime(now.year, now.month + 1, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String period) {
              setState(() {
                _selectedPeriod = period;
              });
            },
            itemBuilder: (BuildContext context) {
              return _periods.map((String period) {
                return PopupMenuItem<String>(
                  value: period,
                  child: Text(period),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<models.Transaction>>(
        stream: _databaseService.getTransactionsByDateRange(
          _getStartDate(),
          _getEndDate(),
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!;
          if (transactions.isEmpty) {
            return const Center(
              child: Text('No transactions found for this period.'),
            );
          }

          final income = transactions
              .where((t) => t.type == models.TransactionType.income)
              .fold(0.0, (sum, t) => sum + t.amount);

          final expenses = transactions
              .where((t) => t.type == models.TransactionType.expense)
              .fold(0.0, (sum, t) => sum + t.amount);

          final netIncome = income - expenses;

          // Group transactions by category
          final Map<String, double> categoryTotals = {};
          for (var transaction in transactions) {
            if (transaction.type == models.TransactionType.expense) {
              categoryTotals[transaction.category] =
                  (categoryTotals[transaction.category] ?? 0) +
                      transaction.amount;
            }
          }

          // Sort categories by amount
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final currencyFormat = NumberFormat.currency(symbol: '\$');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  income: income,
                  expenses: expenses,
                  netIncome: netIncome,
                  currencyFormat: currencyFormat,
                ),
                const SizedBox(height: 24),
                Text(
                  'Expenses by Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ...sortedCategories.map((category) => _buildCategoryCard(
                      category: category.key,
                      amount: category.value,
                      totalExpenses: expenses,
                      currencyFormat: currencyFormat,
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required double income,
    required double expenses,
    required double netIncome,
    required NumberFormat currencyFormat,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedPeriod,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  label: 'Income',
                  amount: income,
                  color: Colors.green,
                  currencyFormat: currencyFormat,
                ),
                _buildSummaryItem(
                  label: 'Expenses',
                  amount: expenses,
                  color: Colors.red,
                  currencyFormat: currencyFormat,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Income',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currencyFormat.format(netIncome),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: netIncome >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required double amount,
    required Color color,
    required NumberFormat currencyFormat,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String category,
    required double amount,
    required double totalExpenses,
    required NumberFormat currencyFormat,
  }) {
    final percentage = totalExpenses > 0 ? amount / totalExpenses : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currencyFormat.format(amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}% of total expenses',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


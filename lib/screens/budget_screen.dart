import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_model.dart';
import '../providers/currency_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/budget_progress_card.dart';
import 'add_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final AuthService _authService = AuthService();
  late DatabaseService _databaseService;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      setState(() {
        _errorMessage = 'Please sign in to view your budgets';
        _isLoading = false;
      });
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    _databaseService = DatabaseService(userId: userId);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddBudgetScreen(),
            ),
          );
        },
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(_errorMessage!)
              : SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildBudgetSummary(),
                      _buildBudgetList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget Planner',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                'Set limits, stay on track',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary() {
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        return StreamBuilder<List<Budget>>(
          stream: _databaseService.getBudgets(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingSummaryCard();
            }

            if (snapshot.hasError) {
              return Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  'Error loading budget summary: ${snapshot.error}',
                  style: TextStyle(color: Colors.red[800]),
                ),
              );
            }

            final budgets = snapshot.data ?? [];
            if (budgets.isEmpty) {
              return _buildEmptySummaryCard();
            }

            // Calculate total budget and spent amounts
            double totalBudget = 0;
            double totalSpent = 0;
            for (final budget in budgets) {
              totalBudget += budget.total;
              totalSpent += budget.spent;
            }

            // Calculate percentage spent
            final percentageSpent =
                totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;
            final remaining = totalBudget - totalSpent;

            final formattedTotalBudget = NumberFormat.currency(
              symbol: currencyProvider.currency,
              decimalDigits: 2,
            ).format(totalBudget);

            final formattedRemaining = NumberFormat.currency(
              symbol: currencyProvider.currency,
              decimalDigits: 2,
            ).format(remaining);

            // Determine status color
            final Color statusColor;
            if (percentageSpent >= 100) {
              statusColor = Colors.red;
            } else if (percentageSpent >= 80) {
              statusColor = Colors.orange;
            } else {
              statusColor = Colors.green;
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Budget',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pie_chart,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    formattedTotalBudget,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: percentageSpent / 100,
                      minHeight: 12,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${percentageSpent.toStringAsFixed(1)}% spent',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Remaining: $formattedRemaining',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingSummaryCard() {
    return Container(
      width: double.infinity,
      height: 180,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildEmptySummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No Budgets Yet',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first budget to start tracking your spending limits',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList() {
    return Expanded(
      child: StreamBuilder<List<Budget>>(
        stream: _databaseService.getBudgets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red[800]),
              ),
            );
          }

          final budgets = snapshot.data ?? [];
          if (budgets.isEmpty) {
            return _buildEmptyBudgetList();
          }

          return Consumer<CurrencyProvider>(
            builder: (context, currencyProvider, child) {
              return RefreshIndicator(
                onRefresh: _initializeDatabase,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    return BudgetProgressCard(
                      budget: budget,
                      currencySymbol: currencyProvider.currency,
                      onTap: () => _showBudgetOptions(budget),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyBudgetList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_chart,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Budgets Created',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tap the + button to create a new budget and start managing your spending',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddBudgetScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Budget'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetOptions(Budget budget) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) => Consumer<CurrencyProvider>(
        builder: (context, currencyProvider, _) {
          final formattedAmount = NumberFormat.currency(
            symbol: currencyProvider.currency,
            decimalDigits: 2,
          ).format(budget.total);

          final formattedSpent = NumberFormat.currency(
            symbol: currencyProvider.currency,
            decimalDigits: 2,
          ).format(budget.spent);

          final formattedRemaining = NumberFormat.currency(
            symbol: currencyProvider.currency,
            decimalDigits: 2,
          ).format(budget.total - budget.spent);

          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _getCategoryColor(budget.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(budget.category),
                        color: _getCategoryColor(budget.category),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.category,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Created on ${DateFormat('MMM dd, yyyy').format(budget.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Budget Amount:', formattedAmount),
                const SizedBox(height: 12),
                _buildDetailRow('Spent So Far:', formattedSpent),
                const SizedBox(height: 12),
                _buildDetailRow('Remaining:', formattedRemaining,
                    textColor: budget.spent > budget.total
                        ? Colors.red
                        : Colors.green),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddBudgetScreen(budget: budget),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side:
                              BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(budget);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: textColor ?? Colors.grey[800],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Budget',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete the budget for ${budget.category}? This action cannot be undone.',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey[700],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                await _databaseService.deleteBudget(budget.id);
                setState(() {
                  _isLoading = false;
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Budget deleted successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete budget: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeDatabase,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food & Dining': Colors.orange,
      'Transportation': Colors.blue,
      'Shopping': Colors.pink,
      'Entertainment': Colors.purple,
      'Bills & Utilities': Colors.red,
      'Health & Medical': Colors.green,
      'Travel': Colors.teal,
      'Education': Colors.indigo,
      'Personal Care': Colors.amber,
      'Gifts & Donations': Colors.cyan,
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'Food & Dining': Icons.restaurant,
      'Transportation': Icons.directions_car,
      'Shopping': Icons.shopping_bag,
      'Entertainment': Icons.movie,
      'Bills & Utilities': Icons.receipt_long,
      'Health & Medical': Icons.medical_services,
      'Travel': Icons.flight,
      'Education': Icons.school,
      'Personal Care': Icons.spa,
      'Gifts & Donations': Icons.card_giftcard,
      'Other': Icons.category,
    };
    return icons[category] ?? Icons.category;
  }
}

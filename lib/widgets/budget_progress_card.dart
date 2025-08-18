import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';

class BudgetProgressCard extends StatelessWidget {
  final Budget budget;
  final String currencySymbol;
  final VoidCallback onTap;

  const BudgetProgressCard({
    super.key,
    required this.budget,
    required this.currencySymbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = budget.spent / budget.total;
    final remaining = budget.total - budget.spent;
    final formattedTotal = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    ).format(budget.total);

    final formattedSpent = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    ).format(budget.spent);

    final formattedRemaining = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    ).format(remaining);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budget.category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    formattedTotal,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0
                        ? Colors.red
                        : progress >= 0.8
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: $formattedSpent',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Remaining: $formattedRemaining',
                    style: TextStyle(
                      color: remaining < 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

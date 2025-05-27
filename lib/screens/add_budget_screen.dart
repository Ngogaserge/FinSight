import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget_model.dart';
import '../providers/currency_provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? budget;

  const AddBudgetScreen({super.key, this.budget});

  @override
  _AddBudgetScreenState createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  late DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(userId: AuthService().currentUserId!);
    if (widget.budget != null) {
      _categoryController.text = widget.budget!.category;
      _amountController.text = widget.budget!.total.toString();
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final budget = Budget(
        id: widget.budget?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        category: _categoryController.text,
        total: double.parse(_amountController.text),
        spent: widget.budget?.spent ?? 0.0,
        userId: AuthService().currentUserId!,
        createdAt: widget.budget?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.budget == null) {
        await _databaseService.addBudget(budget);
      } else {
        await _databaseService.updateBudget(budget);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget == null ? 'Add Budget' : 'Edit Budget'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: const OutlineInputBorder(),
                prefixText: '${context.watch<CurrencyProvider>().currency} ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveBudget,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      widget.budget == null ? 'Add Budget' : 'Update Budget'),
            ),
          ],
        ),
      ),
    );
  }
}

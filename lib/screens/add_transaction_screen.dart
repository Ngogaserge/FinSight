import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../providers/currency_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  late AuthService _authService;
  late DatabaseService _databaseService;

  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  String? _walletId;
  List<Wallet> _wallets = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _expenseCategories = [
    'Food',
    'Transportation',
    'Bills',
    'Entertainment',
    'Shopping',
    'Health',
    'Education',
    'Other'
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Business',
    'Investment',
    'Gift',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _initializeData();

    if (widget.transaction != null) {
      // Editing mode
      _amountController.text = widget.transaction!.amount.toString();
      _categoryController.text = widget.transaction!.category;
      _descriptionController.text = widget.transaction!.description;
      _type = widget.transaction!.type;
      _date = widget.transaction!.date;
      _walletId = widget.transaction!.walletId;
    }
  }

  Future<void> _initializeData() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Please sign in to add a transaction';
          _isLoading = false;
        });
        return;
      }

      _databaseService = DatabaseService(userId: userId);
      final wallets = await _databaseService.wallets.first;

      setState(() {
        _wallets = wallets;
        if (wallets.isNotEmpty && _walletId == null) {
          _walletId = wallets.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _showCategoryDialog() async {
    final categories = _type == TransactionType.expense
        ? _expenseCategories
        : _incomeCategories;

    final String? selectedCategory = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Category',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).pop(category);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _getCategoryColor(category).withOpacity(0.1),
                    border: Border.all(
                      color: _getCategoryColor(category).withOpacity(0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: _getCategoryColor(category),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      ),
    );

    if (selectedCategory != null) {
      setState(() {
        _categoryController.text = selectedCategory;
      });
    }
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': Colors.orange,
      'Transportation': Colors.blue,
      'Shopping': Colors.purple,
      'Bills': Colors.red,
      'Entertainment': Colors.pink,
      'Health': Colors.green,
      'Education': Colors.teal,
      'Salary': Colors.indigo,
      'Business': Colors.amber,
      'Investment': Colors.lightGreen,
      'Gift': Colors.deepPurple,
      'Other': Colors.grey,
    };

    return colors[category] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'Food': Icons.restaurant,
      'Transportation': Icons.directions_car,
      'Shopping': Icons.shopping_bag,
      'Bills': Icons.receipt,
      'Entertainment': Icons.movie,
      'Health': Icons.healing,
      'Education': Icons.school,
      'Salary': Icons.work,
      'Business': Icons.business,
      'Investment': Icons.trending_up,
      'Gift': Icons.card_giftcard,
      'Other': Icons.category,
    };

    return icons[category] ?? Icons.category;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final amount = double.parse(_amountController.text);
        final category = _categoryController.text;
        final description = _descriptionController.text;

        if (_walletId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a wallet'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final transaction = Transaction(
          id: widget.transaction?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          amount: amount,
          type: _type,
          category: category,
          description: description,
          date: _date,
          walletId: _walletId!,
          title: category,
          userId: _authService.currentUserId!,
          createdAt: widget.transaction?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.transaction != null) {
          await _databaseService.updateTransaction(transaction);
        } else {
          await _databaseService.addTransaction(transaction);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transaction != null
                ? 'Transaction updated successfully'
                : 'Transaction added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              widget.transaction != null
                  ? 'Edit Transaction'
                  : 'Add Transaction',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            elevation: 0,
            centerTitle: true,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorState(_errorMessage!)
                  : SafeArea(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTransactionTypeSwitch(),
                              const SizedBox(height: 24),
                              _buildAmountField(currencyProvider),
                              const SizedBox(height: 24),
                              _buildCategoryField(),
                              const SizedBox(height: 24),
                              _buildDescriptionField(),
                              const SizedBox(height: 24),
                              _buildDateField(),
                              const SizedBox(height: 24),
                              _buildWalletSelector(),
                              const SizedBox(height: 36),
                              _buildSubmitButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildTransactionTypeSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: _buildTransactionTypeButton(
                title: 'Expense',
                icon: Icons.arrow_upward,
                isSelected: _type == TransactionType.expense,
                color: Colors.red,
                onTap: () => setState(() {
                  _type = TransactionType.expense;
                  _categoryController.clear();
                }),
              ),
            ),
            Expanded(
              child: _buildTransactionTypeButton(
                title: 'Income',
                icon: Icons.arrow_downward,
                isSelected: _type == TransactionType.income,
                color: Colors.green,
                onTap: () => setState(() {
                  _type = TransactionType.income;
                  _categoryController.clear();
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField(CurrencyProvider currencyProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color:
                  _type == TransactionType.income ? Colors.green : Colors.red,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixIcon: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  currencyProvider.currency,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(value) <= 0) {
                return 'Amount must be greater than zero';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showCategoryDialog(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                if (_categoryController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      _getCategoryIcon(_categoryController.text),
                      color: _getCategoryColor(_categoryController.text),
                      size: 22,
                    ),
                  ),
                Expanded(
                  child: Text(
                    _categoryController.text.isEmpty
                        ? 'Select category'
                        : _categoryController.text,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: _categoryController.text.isEmpty
                          ? Colors.grey[400]
                          : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
        if (_formKey.currentState?.validate() == false &&
            _categoryController.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              'Please select a category',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter description (optional)',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormat('MMMM dd, yyyy').format(_date),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.edit_calendar,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletSelector() {
    if (_wallets.isEmpty) {
      return const Center(
        child: Text('No wallets available'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _walletId,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryColor),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Colors.black87,
              ),
              items: _wallets.map((wallet) {
                return DropdownMenuItem<String>(
                  value: wallet.id,
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        wallet.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _walletId = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
        ),
        child: Text(
          widget.transaction != null ? 'Update Transaction' : 'Add Transaction',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
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
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initializeData,
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
    );
  }
}

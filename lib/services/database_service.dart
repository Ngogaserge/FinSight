import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart' as models;
import '../models/wallet_model.dart';
import '../models/budget_model.dart';
import '../models/user_profile_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  DatabaseService({required this.userId})
      : _budgetsCollection = FirebaseFirestore.instance.collection('budgets');

  // Collection references
  CollectionReference get _transactionsCollection =>
      _firestore.collection('users').doc(userId).collection('transactions');

  CollectionReference get _walletsCollection =>
      _firestore.collection('users').doc(userId).collection('wallets');

  // Budgets Collection Reference
  final CollectionReference _budgetsCollection;

  // Validate amount
  void _validateAmount(double amount) {
    if (amount < 0) {
      throw 'Amount cannot be negative';
    }
    if (amount.isInfinite || amount.isNaN) {
      throw 'Invalid amount value';
    }
  }

  // TRANSACTIONS

  // Get all transactions
  Stream<List<models.Transaction>> getAllTransactions() {
    try {
      return _transactionsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return models.Transaction.fromMap(data);
        }).toList();
      });
    } catch (e) {
      if (e.toString().contains('failed-precondition')) {
        // If index is not ready, return empty list temporarily
        return Stream.value([]);
      }
      rethrow;
    }
  }

  // Get transaction by ID
  Future<models.Transaction?> getTransaction(String id) async {
    try {
      DocumentSnapshot doc = await _transactionsCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return models.Transaction.fromMap(data);
      }
      return null;
    } on FirebaseException catch (e) {
      debugPrint(
          'Firebase Error getting transaction: ${e.code} - ${e.message}');
      throw 'Failed to get transaction: ${e.message}';
    } catch (e) {
      debugPrint('Error getting transaction: $e');
      throw 'An unexpected error occurred while getting transaction';
    }
  }

  // Add a new transaction
  Future<void> addTransaction(models.Transaction transaction) async {
    try {
      // Add the transaction
      await _transactionsCollection
          .doc(transaction.id)
          .set(transaction.toMap());

      // Update wallet balance
      double amountChange = transaction.type == models.TransactionType.income
          ? transaction.amount
          : -transaction.amount;
      await updateWalletBalance(transaction.walletId, amountChange);

      // If it's an expense, update the corresponding budget
      if (transaction.type == models.TransactionType.expense) {
        await updateBudgetSpent(transaction.category, transaction.amount);
      }
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  // Update a transaction
  Future<void> updateTransaction(models.Transaction transaction) async {
    try {
      // Get the old transaction to calculate balance changes
      final oldTransaction = await getTransaction(transaction.id);
      if (oldTransaction != null) {
        // Reverse the old transaction's effect on wallet balance
        double oldAmountChange =
            oldTransaction.type == models.TransactionType.income
                ? -oldTransaction.amount
                : oldTransaction.amount;
        await updateWalletBalance(oldTransaction.walletId, oldAmountChange);

        // If it was an expense, reverse the budget spent amount
        if (oldTransaction.type == models.TransactionType.expense) {
          await updateBudgetSpent(
              oldTransaction.category, -oldTransaction.amount);
        }
      }

      // Apply the new transaction's effect
      double newAmountChange = transaction.type == models.TransactionType.income
          ? transaction.amount
          : -transaction.amount;
      await updateWalletBalance(transaction.walletId, newAmountChange);

      // If it's an expense, update the budget spent amount
      if (transaction.type == models.TransactionType.expense) {
        await updateBudgetSpent(transaction.category, transaction.amount);
      }

      // Update the transaction
      await _transactionsCollection
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      rethrow;
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(models.Transaction transaction) async {
    try {
      // Reverse the wallet balance change
      double amountChange = transaction.type == models.TransactionType.income
          ? -transaction.amount
          : transaction.amount;
      await updateWalletBalance(transaction.walletId, amountChange);

      // If it was an expense, reverse the budget spent amount
      if (transaction.type == models.TransactionType.expense) {
        await updateBudgetSpent(transaction.category, -transaction.amount);
      }

      // Delete the transaction
      await _transactionsCollection.doc(transaction.id).delete();
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  // Get transactions by category
  Stream<List<models.Transaction>> getTransactionsByCategory(String category) {
    try {
      return _transactionsCollection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return models.Transaction.fromMap(data);
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting transactions by category: $e');
      return Stream.value([]);
    }
  }

  // Get transactions by type
  Stream<List<models.Transaction>> getTransactionsByType(
      models.TransactionType type) {
    try {
      return _transactionsCollection
          .where('userId', isEqualTo: userId)
          .where('type',
              isEqualTo:
                  type == models.TransactionType.income ? 'income' : 'expense')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return models.Transaction.fromMap(data);
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting transactions by type: $e');
      return Stream.value([]);
    }
  }

  // Get transactions by date range
  Stream<List<models.Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return models.Transaction.fromMap(data);
      }).toList();
    });
  }

  // Get transactions for a specific wallet
  Stream<List<models.Transaction>> getTransactionsByWallet(String walletId) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('walletId', isEqualTo: walletId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return models.Transaction.fromMap(data);
      }).toList();
    });
  }

  // Get summary of transactions (total balance, income, expenses)
  Stream<Map<String, double>> getSummary() {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        final transaction = models.Transaction.fromMap(data);
        if (transaction.type == models.TransactionType.income) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }

      return {
        'totalBalance': totalIncome - totalExpense,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
      };
    });
  }

  // Get transactions within a date range
  Stream<List<models.Transaction>> getTransactions({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return models.Transaction.fromMap(data);
      }).toList();
    });
  }

  // Get recent transactions
  Stream<List<models.Transaction>> getRecentTransactions() {
    return _transactionsCollection
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              models.Transaction.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // WALLETS

  // Get all wallets
  Stream<List<Wallet>> get wallets {
    return _walletsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Wallet.fromMap(data);
      }).toList();
    });
  }

  // Get wallet by ID
  Future<Wallet?> getWallet(String id) async {
    try {
      DocumentSnapshot doc = await _walletsCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Wallet.fromMap(data);
      }
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error getting wallet: ${e.code} - ${e.message}');
      throw 'Failed to get wallet: ${e.message}';
    } catch (e) {
      debugPrint('Error getting wallet: $e');
      throw 'An unexpected error occurred while getting wallet';
    }
  }

  // Add wallet
  Future<String> addWallet(Wallet wallet) async {
    try {
      if (wallet.name.trim().isEmpty) {
        throw 'Wallet name cannot be empty';
      }
      await _walletsCollection.doc(wallet.id).set(wallet.toMap());
      return wallet.id;
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error adding wallet: ${e.code} - ${e.message}');
      throw 'Failed to add wallet: ${e.message}';
    } catch (e) {
      debugPrint('Error adding wallet: $e');
      throw 'An unexpected error occurred while adding wallet';
    }
  }

  // Update wallet
  Future<void> updateWallet(Wallet wallet) async {
    try {
      if (wallet.name.trim().isEmpty) {
        throw 'Wallet name cannot be empty';
      }
      await _walletsCollection.doc(wallet.id).update(wallet.toMap());
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error updating wallet: ${e.code} - ${e.message}');
      throw 'Failed to update wallet: ${e.message}';
    } catch (e) {
      debugPrint('Error updating wallet: $e');
      throw 'An unexpected error occurred while updating wallet';
    }
  }

  // Delete wallet
  Future<void> deleteWallet(String walletId) async {
    try {
      // First check if there are any transactions associated with this wallet
      QuerySnapshot transactionSnapshot = await _transactionsCollection
          .where('walletId', isEqualTo: walletId)
          .limit(1)
          .get();

      if (transactionSnapshot.docs.isNotEmpty) {
        throw 'Cannot delete wallet with existing transactions';
      }

      await _walletsCollection.doc(walletId).delete();
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error deleting wallet: ${e.code} - ${e.message}');
      throw 'Failed to delete wallet: ${e.message}';
    } catch (e) {
      debugPrint('Error deleting wallet: $e');
      throw 'An unexpected error occurred while deleting wallet';
    }
  }

  // Update wallet balance
  Future<void> updateWalletBalance(String walletId, double amountChange) async {
    try {
      // Get current wallet
      DocumentSnapshot walletDoc = await _walletsCollection.doc(walletId).get();
      if (!walletDoc.exists) {
        throw 'Wallet not found';
      }

      final data = walletDoc.data() as Map<String, dynamic>;
      data['id'] = walletDoc.id;
      Wallet wallet = Wallet.fromMap(data);
      double newBalance = wallet.balance + amountChange;

      // Prevent negative balance
      if (newBalance < 0) {
        throw 'Insufficient funds in wallet';
      }

      // Update wallet with new balance
      await _walletsCollection.doc(walletId).update({
        'balance': newBalance,
        'updatedAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      debugPrint(
          'Firebase Error updating wallet balance: ${e.code} - ${e.message}');
      throw 'Failed to update wallet balance: ${e.message}';
    } catch (e) {
      debugPrint('Error updating wallet balance: $e');
      throw 'An unexpected error occurred while updating wallet balance';
    }
  }

  // Create default wallet if no wallets exist
  Future<String> createDefaultWalletIfNeeded() async {
    try {
      QuerySnapshot walletSnapshot = await _walletsCollection.limit(1).get();

      if (walletSnapshot.docs.isEmpty) {
        String walletId = const Uuid().v4();
        Wallet defaultWallet = Wallet(
          id: walletId,
          name: 'Cash',
          balance: 0.0,
          userId: userId,
          currency: '\$',
          description: 'Default cash wallet',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await addWallet(defaultWallet);
        return walletId;
      }

      return walletSnapshot.docs.first.id;
    } on FirebaseException catch (e) {
      debugPrint(
          'Firebase Error creating default wallet: ${e.code} - ${e.message}');
      throw 'Failed to create default wallet: ${e.message}';
    } catch (e) {
      debugPrint('Error creating default wallet: $e');
      throw 'An unexpected error occurred while creating default wallet';
    }
  }

  // Get total balance across all wallets
  Stream<double> getTotalBalance() {
    return _walletsCollection.snapshots().map((snapshot) {
      double totalBalance = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        Wallet wallet = Wallet.fromMap(data);
        totalBalance += wallet.balance;
      }
      return totalBalance;
    }).distinct();
  }

  // Stream of budgets
  Stream<List<Budget>> getBudgets() {
    debugPrint('Getting budgets for user: $userId');
    return _budgetsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      debugPrint('Received ${snapshot.docs.length} budgets');
      return snapshot.docs
          .map((doc) => Budget.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    }).handleError((error) {
      debugPrint('Error getting budgets: $error');
      throw error;
    });
  }

  // Add a new budget
  Future<void> addBudget(Budget budget) async {
    debugPrint('Adding budget for user: $userId');
    try {
      await _budgetsCollection.doc(budget.id).set(budget.toMap());
      debugPrint('Budget added successfully');
    } catch (e) {
      debugPrint('Error adding budget: $e');
      rethrow;
    }
  }

  // Update a budget
  Future<void> updateBudget(Budget budget) async {
    debugPrint('Updating budget for user: $userId');
    try {
      await _budgetsCollection.doc(budget.id).update(budget.toMap());
      debugPrint('Budget updated successfully');
    } catch (e) {
      debugPrint('Error updating budget: $e');
      rethrow;
    }
  }

  // Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    debugPrint('Deleting budget for user: $userId');
    try {
      await _budgetsCollection.doc(budgetId).delete();
      debugPrint('Budget deleted successfully');
    } catch (e) {
      debugPrint('Error deleting budget: $e');
      rethrow;
    }
  }

  // Update budget spent amount based on transactions
  Future<void> updateBudgetSpent(String category, double amount) async {
    try {
      final budgets = await _budgetsCollection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .get();

      for (var doc in budgets.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        final budget = Budget.fromMap(data);
        final newSpent = budget.spent + amount;

        await _budgetsCollection.doc(doc.id).update({
          'spent': newSpent,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      debugPrint('Error updating budget spent: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = userId;
        return UserProfile.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      throw 'Failed to get user profile';
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(userId).set(profile.toMap());
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw 'Failed to update user profile';
    }
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:uuid/uuid.dart';
// import '../models/transaction_model.dart';
//
// class DatabaseService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String _userId;
//   final _uuid = Uuid();
//
//   // Collection references
//   CollectionReference get _transactionsCollection =>
//       _firestore.collection('users').doc(_userId).collection('transactions');
//
//   DatabaseService(this._userId);
//
//   // Add a new transaction
//   Future<String> addTransaction({
//     required String type,
//     required String category,
//     required double amount,
//     required String note,
//     required DateTime date,
//   }) async {
//     final String id = _uuid.v4();
//
//     final Transaction transaction = Transaction(
//       id: id,
//       type: type,
//       category: category,
//       amount: amount,
//       note: note,
//       date: date,
//       userId: _userId,
//     );
//
//     await _transactionsCollection.doc(id).set(transaction.toMap());
//     return id;
//   }
//
//   // Get all transactions
//   Stream<List<Transaction>> getTransactions() {
//     return _transactionsCollection
//         .orderBy('date', descending: true)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         return Transaction.fromMap(doc.data() as Map<String, dynamic>);
//       }).toList();
//     });
//   }
//
//   // Get transactions for a specific date range
//   Stream<List<Transaction>> getTransactionsByDateRange({
//     required DateTime startDate,
//     required DateTime endDate,
//   }) {
//     return _transactionsCollection
//         .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
//         .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
//         .orderBy('date', descending: true)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         return Transaction.fromMap(doc.data() as Map<String, dynamic>);
//       }).toList();
//     });
//   }
//
//   // Update an existing transaction
//   Future<void> updateTransaction(Transaction transaction) async {
//     await _transactionsCollection.doc(transaction.id).update(transaction.toMap());
//   }
//
//   // Delete a transaction
//   Future<void> deleteTransaction(String id) async {
//     await _transactionsCollection.doc(id).delete();
//   }
//
//   // Get summary data (total balance, total income, total expense)
//   Stream<Map<String, double>> getSummary() {
//     return _transactionsCollection.snapshots().map((snapshot) {
//       double totalIncome = 0;
//       double totalExpense = 0;
//
//       for (var doc in snapshot.docs) {
//         final transaction = Transaction.fromMap(doc.data() as Map<String, dynamic>);
//         if (transaction.type == 'Income') {
//           totalIncome += transaction.amount;
//         } else {
//           totalExpense += transaction.amount;
//         }
//       }
//
//       return {
//         'totalBalance': totalIncome - totalExpense,
//         'totalIncome': totalIncome,
//         'totalExpense': totalExpense,
//       };
//     });
//   }
// }

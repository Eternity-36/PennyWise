import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/hive_transaction_repository.dart';
import '../repositories/firestore_transaction_repository.dart';

class MoneyProvider extends ChangeNotifier {
  late TransactionRepository _repository;
  final Box _settingsBox = Hive.box('settings');
  late Box<Budget> _budgetBox;
  String _userName = 'User';
  String _currencySymbol = '₹';
  String? _userId;
  String? _photoURL;
  Budget? _currentBudget;
  List<Transaction> _transactions = [];

  String get userName => _userName;
  String get currencySymbol => _currencySymbol;
  String? get userId => _userId;
  String? get photoURL => _photoURL;
  Budget? get currentBudget => _currentBudget;
  Box get settingsBox => _settingsBox;
  List<Transaction> get transactions => _transactions;

  MoneyProvider() {
    _initRepository();
    _loadSettings();
    _initBudget();
  }

  void _initRepository() {
    final isGuest = _settingsBox.get('isGuest', defaultValue: true);
    final userId = _settingsBox.get('userId');

    if (!isGuest && userId != null) {
      _repository = FirestoreTransactionRepository(userId);
    } else {
      final box = Hive.box<Transaction>('transactions');
      _repository = HiveTransactionRepository(box);
    }
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final allTransactions = await _repository.getTransactions();
      if (_userId != null) {
        _transactions = allTransactions
            .where((t) => t.userId == _userId)
            .toList();
      } else {
        _transactions = [];
      }
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      _transactions = [];
    }
    notifyListeners();
  }

  void _loadSettings() {
    _userName = _settingsBox.get('userName', defaultValue: 'User');
    _currencySymbol = _settingsBox.get('currencySymbol', defaultValue: '₹');
    _userId = _settingsBox.get('userId');
    _photoURL = _settingsBox.get('photoURL');
    notifyListeners();
  }

  Future<void> _initBudget() async {
    _budgetBox = await Hive.openBox<Budget>('budgets');
    _loadCurrentBudget();
  }

  void _loadCurrentBudget() {
    if (_userId == null) {
      _currentBudget = null;
      notifyListeners();
      return;
    }
    final now = DateTime.now();
    _currentBudget = _budgetBox.values.firstWhere(
      (b) =>
          b.month == now.month &&
          b.year == now.year &&
          b.accountId == _userId, // Using accountId to store userId for now
      orElse: () => Budget(
        monthlyLimit: 0,
        month: now.month,
        year: now.year,
        accountId: _userId!,
      ),
    );
    notifyListeners();
  }

  Future<void> setBudget(double limit) async {
    if (_userId == null) return;

    final now = DateTime.now();
    final existing = _budgetBox.values.where(
      (b) =>
          b.month == now.month && b.year == now.year && b.accountId == _userId,
    );

    if (existing.isNotEmpty) {
      final budget = existing.first;
      budget.monthlyLimit = limit;
      await budget.save();
    } else {
      await _budgetBox.add(
        Budget(
          monthlyLimit: limit,
          month: now.month,
          year: now.year,
          accountId: _userId!,
        ),
      );
    }
    _loadCurrentBudget();
  }

  double get budgetProgress {
    if (_currentBudget == null || _currentBudget!.monthlyLimit == 0) return 0;
    final now = DateTime.now();
    final monthExpenses = _transactions
        .where(
          (t) =>
              t.isExpense &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    return (monthExpenses / _currentBudget!.monthlyLimit).clamp(0.0, 1.0);
  }

  double get monthlySpent {
    final now = DateTime.now();
    return _transactions
        .where(
          (t) =>
              t.isExpense &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    await _settingsBox.put('userName', name);
    notifyListeners();
  }

  Future<void> setCurrency(String symbol) async {
    _currencySymbol = symbol;
    await _settingsBox.put('currencySymbol', symbol);
    notifyListeners();
  }

  double get totalBalance {
    return _transactions.fold(0, (sum, item) {
      return sum + (item.isExpense ? -item.amount : item.amount);
    });
  }

  double get totalIncome {
    return _transactions
        .where((item) => !item.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((item) => item.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
  }

  Future<void> addTransaction(Transaction transaction) async {
    if (_userId == null) return;

    // Ensure the transaction has the correct userId
    final newTransaction = Transaction(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      isExpense: transaction.isExpense,
      category: transaction.category,
      accountId:
          _userId!, // Using accountId for now, ideally should use userId field
      userId: _userId,
    );

    await _repository.addTransaction(newTransaction);
    await _loadTransactions();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await _repository.deleteTransaction(transaction.id);
    await _loadTransactions();
  }

  Future<void> updateTransaction(
    Transaction oldTransaction,
    Transaction newTransaction,
  ) async {
    await _repository.updateTransaction(newTransaction);
    await _loadTransactions();
  }

  Future<void> initializeUser({
    required String name,
    required String currency,
    required bool isGuest,
    required String? userId,
    String? photoURL,
  }) async {
    _userName = name;
    _currencySymbol = currency;
    _userId = userId;
    _photoURL = photoURL;

    // Persist to Hive (local settings)
    await _settingsBox.put('userName', name);
    await _settingsBox.put('currencySymbol', currency);
    await _settingsBox.put('isGuest', isGuest);
    await _settingsBox.put('userId', userId);
    if (photoURL != null) {
      await _settingsBox.put('photoURL', photoURL);
    } else {
      await _settingsBox.delete('photoURL');
    }

    // If Guest, save backup credentials for re-login
    if (isGuest) {
      await _settingsBox.put('guestUserId', userId);
      await _settingsBox.put('guestUserName', name);
      await _settingsBox.put('guestCurrency', currency);
    }

    // Switch Repository based on user type
    if (!isGuest && userId != null) {
      _repository = FirestoreTransactionRepository(userId);
    } else {
      final box = Hive.box<Transaction>('transactions');
      _repository = HiveTransactionRepository(box);
    }

    // Reload transactions from the new repository
    await _loadTransactions();

    // Ensure budget box is open before accessing it
    if (!Hive.isBoxOpen('budgets')) {
      _budgetBox = await Hive.openBox<Budget>('budgets');
    } else {
      _budgetBox = Hive.box<Budget>('budgets');
    }

    // Initialize default budget if not exists
    final now = DateTime.now();
    final existingBudget = _budgetBox.values.where(
      (b) =>
          b.month == now.month && b.year == now.year && b.accountId == userId,
    );

    if (existingBudget.isEmpty) {
      await _budgetBox.add(
        Budget(
          monthlyLimit: 0,
          month: now.month,
          year: now.year,
          accountId: userId!,
        ),
      );
    }

    _loadCurrentBudget();
    notifyListeners();
  }

  Future<void> logout() async {
    _userName = 'User';
    _currencySymbol = '₹';
    _userId = null;

    await _settingsBox.delete('userName');
    await _settingsBox.delete('currencySymbol');
    await _settingsBox.delete('isGuest');
    await _settingsBox.delete('userId');
    await _settingsBox.delete('photoURL');

    // NOTE: We do NOT delete 'guestUserId', 'guestUserName', etc.
    // This allows guests to "log back in" and restore their data.

    _transactions = [];
    _currentBudget = null;

    notifyListeners();
  }
}

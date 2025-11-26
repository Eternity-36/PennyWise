import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

class MoneyProvider extends ChangeNotifier {
  final Box<Transaction> _box = Hive.box<Transaction>('transactions');
  final Box _settingsBox = Hive.box('settings');
  late Box<Budget> _budgetBox;
  String _userName = 'User';
  String _currencySymbol = '₹';
  Budget? _currentBudget;

  String get userName => _userName;
  String get currencySymbol => _currencySymbol;
  Budget? get currentBudget => _currentBudget;
  Box get settingsBox => _settingsBox;

  MoneyProvider() {
    _loadSettings();
    _initBudget();
  }

  void _loadSettings() {
    _userName = _settingsBox.get('userName', defaultValue: 'User');
    _currencySymbol = _settingsBox.get('currencySymbol', defaultValue: '₹');
    notifyListeners();
  }

  Future<void> _initBudget() async {
    _budgetBox = await Hive.openBox<Budget>('budgets');
    _loadCurrentBudget();
  }

  void _loadCurrentBudget() {
    final now = DateTime.now();
    _currentBudget = _budgetBox.values.firstWhere(
      (b) => b.month == now.month && b.year == now.year,
      orElse: () => Budget(monthlyLimit: 0, month: now.month, year: now.year),
    );
    notifyListeners();
  }

  Future<void> setBudget(double limit) async {
    final now = DateTime.now();
    final existing = _budgetBox.values.where(
      (b) => b.month == now.month && b.year == now.year,
    );

    if (existing.isNotEmpty) {
      final budget = existing.first;
      budget.monthlyLimit = limit;
      await budget.save();
    } else {
      await _budgetBox.add(
        Budget(monthlyLimit: limit, month: now.month, year: now.year),
      );
    }
    _loadCurrentBudget();
  }

  double get budgetProgress {
    if (_currentBudget == null || _currentBudget!.monthlyLimit == 0) return 0;
    final now = DateTime.now();
    final monthExpenses = transactions
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
    return transactions
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

  List<Transaction> get transactions {
    final List<Transaction> list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double get totalBalance {
    return transactions.fold(0, (sum, item) {
      return sum + (item.isExpense ? -item.amount : item.amount);
    });
  }

  double get totalIncome {
    return transactions
        .where((item) => !item.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return transactions
        .where((item) => item.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _box.add(transaction);
    notifyListeners();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await transaction.delete();
    notifyListeners();
  }

  Future<void> updateTransaction(
    Transaction oldTransaction,
    Transaction newTransaction,
  ) async {
    final index = _box.values.toList().indexOf(oldTransaction);
    if (index != -1) {
      await _box.putAt(index, newTransaction);
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/loan.dart';
import '../models/goal.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/hive_transaction_repository.dart';
import '../repositories/firestore_transaction_repository.dart';
import '../services/sms_service.dart';

class MoneyProvider extends ChangeNotifier {
  late TransactionRepository _repository;
  final Box _settingsBox = Hive.box('settings');
  late Box<Budget> _budgetBox;
  String _userName = 'User';
  String _cardName = 'VISA';
  String _currencySymbol = '₹';
  String? _userId;
  String? _photoURL;
  Budget? _currentBudget;
  List<Transaction> _transactions = [];
  bool _smsTrackingEnabled = false;

  String get userName => _userName;
  String get cardName => _cardName;
  String get currencySymbol => _currencySymbol;
  String? get userId => _userId;
  String? get photoURL => _photoURL;
  Budget? get currentBudget => _currentBudget;
  Box get settingsBox => _settingsBox;
  List<Transaction> get transactions => _transactions;
  bool get smsTrackingEnabled => _smsTrackingEnabled;

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
    _cardName = _settingsBox.get('cardName', defaultValue: 'VISA');
    _currencySymbol = _settingsBox.get('currencySymbol', defaultValue: '₹');
    _userId = _settingsBox.get('userId');
    _photoURL = _settingsBox.get('photoURL');
    _smsTrackingEnabled = _settingsBox.get(
      'smsTrackingEnabled',
      defaultValue: false,
    );
    if (_smsTrackingEnabled) {
      syncSmsTransactions();
    }
    notifyListeners();
  }

  Future<void> setSmsTracking(bool enabled) async {
    _smsTrackingEnabled = enabled;
    await _settingsBox.put('smsTrackingEnabled', enabled);
    notifyListeners();
  }

  late Box<Category> _categoryBox;
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  late Box<Loan> _loanBox;
  List<Loan> _loans = [];
  List<Loan> get loans => _loans;

  late Box<Goal> _goalBox;
  List<Goal> _goals = [];
  List<Goal> get goals => _goals;

  Future<void> _initBudget() async {
    _budgetBox = await Hive.openBox<Budget>('budgets');
    _categoryBox = await Hive.openBox<Category>('categories');
    _loanBox = await Hive.openBox<Loan>('loans');
    _goalBox = await Hive.openBox<Goal>('goals');
    await _initCategories();
    _loadCurrentBudget();
    _loadLoans();
    _loadGoals();
  }

  void _loadLoans() {
    _loans = _loanBox.values.toList();
    notifyListeners();
  }

  void _loadGoals() {
    _goals = _goalBox.values.toList();
    notifyListeners();
  }

  Future<void> _initCategories() async {
    if (_categoryBox.isEmpty) {
      final defaultCategories = [
        Category(
          id: 'food',
          name: 'Food',
          iconCode: Icons.fastfood.codePoint,
          colorValue: Colors.orange.toARGB32(),
          isCustom: false,
        ),
        Category(
          id: 'transport',
          name: 'Transport',
          iconCode: Icons.directions_bus.codePoint,
          colorValue: Colors.blue.toARGB32(),
          isCustom: false,
        ),
        Category(
          id: 'shopping',
          name: 'Shopping',
          iconCode: Icons.shopping_bag.codePoint,
          colorValue: Colors.purple.toARGB32(),
          isCustom: false,
        ),
        Category(
          id: 'entertainment',
          name: 'Entertainment',
          iconCode: Icons.movie.codePoint,
          colorValue: Colors.red.toARGB32(),
          isCustom: false,
        ),
        Category(
          id: 'health',
          name: 'Health',
          iconCode: Icons.local_hospital.codePoint,
          colorValue: Colors.green.toARGB32(),
          isCustom: false,
        ),
        Category(
          id: 'education',
          name: 'Education',
          iconCode: Icons.school.codePoint,
          colorValue: Colors.yellow.shade700.toARGB32(),
          isCustom: false,
        ),
        Category(
          id: 'bills',
          name: 'Bills',
          iconCode: Icons.receipt.codePoint,
          colorValue: Colors.grey.toARGB32(),
          isCustom: false,
        ),
        Category(
          id: 'salary',
          name: 'Salary',
          iconCode: Icons.attach_money.codePoint,
          colorValue: Colors.green.shade800.toARGB32(),
          isCustom: false,
        ),
        Category(
          id: 'other',
          name: 'Other',
          iconCode: Icons.category.codePoint,
          colorValue: Colors.grey.shade400.toARGB32(),
          isCustom: false,
        ),
      ];
      await _categoryBox.addAll(defaultCategories);
    }
    _categories = _categoryBox.values.toList();
    notifyListeners();
  }

  Future<void> addCategory(String name, IconData icon, Color color) async {
    final newCategory = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      iconCode: icon.codePoint,
      colorValue: color.toARGB32(),
      isCustom: true,
    );
    await _categoryBox.add(newCategory);
    _categories = _categoryBox.values.toList();
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    final categoryToDelete = _categoryBox.values.firstWhere((c) => c.id == id);
    await categoryToDelete.delete();
    _categories = _categoryBox.values.toList();
    notifyListeners();
  }

  Future<void> addLoan(Loan loan) async {
    await _loanBox.add(loan);
    _loadLoans();
  }

  Future<void> updateLoan(Loan loan) async {
    await loan.save();
    _loadLoans();
  }

  Future<void> deleteLoan(String id) async {
    final loanToDelete = _loanBox.values.firstWhere((l) => l.id == id);
    await loanToDelete.delete();
    _loadLoans();
  }

  double get totalLent {
    return _loans
        .where((l) => l.type == LoanType.given)
        .fold(0.0, (sum, item) => sum + item.remainingAmount);
  }

  double get totalBorrowed {
    return _loans
        .where((l) => l.type == LoanType.taken)
        .fold(0.0, (sum, item) => sum + item.remainingAmount);
  }

  Future<void> addGoal(Goal goal) async {
    await _goalBox.add(goal);
    _loadGoals();
  }

  Future<void> updateGoal(Goal goal) async {
    await goal.save();
    _loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    final goalToDelete = _goalBox.values.firstWhere((g) => g.id == id);
    await goalToDelete.delete();
    _loadGoals();
  }

  Future<void> addSavingsToGoal(String id, double amount) async {
    final goal = _goalBox.values.firstWhere((g) => g.id == id);
    goal.savedAmount += amount;
    if (goal.savedAmount > goal.targetAmount) {
      goal.savedAmount = goal.targetAmount;
    }
    await goal.save();
    _loadGoals();
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
      _currentBudget = budget;
    } else {
      final newBudget = Budget(
        monthlyLimit: limit,
        month: now.month,
        year: now.year,
        accountId: _userId!,
      );
      await _budgetBox.add(newBudget);
      _currentBudget = newBudget;
    }
    notifyListeners();
  }

  Future<void> setCategoryLimit(String categoryName, double limit) async {
    if (_userId == null) return;

    if (_currentBudget == null) {
      await setBudget(0);
    }

    if (_currentBudget != null) {
      _currentBudget!.categoryLimits[categoryName] = limit;
      await _currentBudget!.save();
      notifyListeners();
    }
  }

  double getCategoryLimit(String categoryName) {
    return _currentBudget?.categoryLimits[categoryName] ?? 0;
  }

  double getCategorySpent(String categoryName) {
    final now = DateTime.now();
    return _transactions
        .where(
          (t) =>
              !t.isExcluded &&
              t.isExpense &&
              t.category == categoryName &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get budgetProgress {
    if (_currentBudget == null || _currentBudget!.monthlyLimit == 0) return 0;
    final now = DateTime.now();
    final monthExpenses = _transactions
        .where(
          (t) =>
              !t.isExcluded &&
              t.isExpense &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
    return monthExpenses / _currentBudget!.monthlyLimit;
  }

  double get monthlySpent {
    final now = DateTime.now();
    return _transactions
        .where(
          (t) =>
              !t.isExcluded &&
              t.isExpense &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    await _settingsBox.put('userName', name);
    notifyListeners();
  }

  final SmsService _smsService = SmsService();

  Future<void> syncSmsTransactions() async {
    if (!_smsTrackingEnabled) return;

    // Use a default user ID for now as auth is not fully implemented or use a placeholder
    final userId =
        _userId ??
        'guest_user'; // Use actual userId if available, else a guest placeholder

    final smsTransactions = await _smsService.syncMessages(userId);

    int addedCount = 0;
    for (final transaction in smsTransactions) {
      // Check for duplicates based on ID (Ref No)
      final index = _transactions.indexWhere((t) => t.id == transaction.id);

      if (index == -1) {
        // New transaction
        await _repository.addTransaction(transaction);
        addedCount++;
      } else {
        // Existing transaction, check if we need to update SMS details
        final existing = _transactions[index];
        if (existing.smsBody == null && transaction.smsBody != null) {
          // Create updated transaction preserving user edits (title, category)
          final updated = Transaction(
            id: existing.id,
            title: existing.title,
            amount: existing.amount,
            date: existing.date,
            isExpense: existing.isExpense,
            category: existing.category,
            accountId: existing.accountId,
            userId: existing.userId,
            smsBody: transaction.smsBody,
            referenceNumber: transaction.referenceNumber,
            bankName: transaction.bankName,
            accountLast4: transaction.accountLast4,
            isExcluded: existing.isExcluded,
          );

          await _repository.updateTransaction(updated);
          addedCount++; // Count as update to trigger reload
        }
      }
    }

    if (addedCount > 0) {
      await _loadTransactions(); // Reload all transactions from the repository
    }
  }

  Future<void> setCardName(String name) async {
    _cardName = name;
    await _settingsBox.put('cardName', name);
    notifyListeners();
  }

  Future<void> setCurrency(String symbol) async {
    _currencySymbol = symbol;
    await _settingsBox.put('currencySymbol', symbol);
    notifyListeners();
  }

  double get totalBalance {
    return _transactions.where((item) => !item.isExcluded).fold(0, (sum, item) {
      return sum + (item.isExpense ? -item.amount : item.amount);
    });
  }

  double get totalIncome {
    return _transactions
        .where((item) => !item.isExcluded && !item.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((item) => !item.isExcluded && item.isExpense)
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

  Future<void> updateTransaction(Transaction newTransaction) async {
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

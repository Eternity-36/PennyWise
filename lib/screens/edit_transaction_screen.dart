import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import '../models/transaction.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  String _amount = '';
  late bool _isExpense;
  late String _selectedCategory;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _amount = widget.transaction.amount.toStringAsFixed(0);
    _isExpense = widget.transaction.isExpense;
    _selectedCategory = widget.transaction.category;
    _notesController.text = widget.transaction.title;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 10);
    }
  }

  void _onKeyTap(String value) {
    _vibrate();
    setState(() {
      if (value == '⌫') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (value == 'C') {
        _amount = '';
      } else {
        if (_amount.length < 10) {
          _amount += value;
        }
      }
    });
  }

  void _saveTransaction() async {
    if (_amount.isEmpty || _notesController.text.isEmpty) return;

    final updatedTransaction = Transaction(
      id: widget.transaction.id,
      title: _notesController.text,
      amount: double.parse(_amount),
      date: widget.transaction.date,
      isExpense: _isExpense,
      category: _selectedCategory,
    );

    await Provider.of<MoneyProvider>(
      context,
      listen: false,
    ).updateTransaction(widget.transaction, updatedTransaction);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Transaction',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Amount Display (without container)
              Column(
                children: [
                  Text(
                    _isExpense ? 'Expense' : 'Income',
                    style: TextStyle(
                      color: _isExpense ? AppTheme.expense : AppTheme.income,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${_amount.isEmpty ? "0" : _amount}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate(key: ValueKey(_amount)).fadeIn(duration: 100.ms),
                ],
              ),
              const SizedBox(height: 16),

              // Type Toggle
              Row(
                children: [
                  const Text('Expense', style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  Switch(
                    value: !_isExpense,
                    onChanged: (value) {
                      setState(() {
                        _isExpense = !value;
                      });
                    },
                    activeThumbColor: AppTheme.income,
                    inactiveThumbColor: AppTheme.expense,
                  ),
                  const Text('Income', style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),

              // Category Selector
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    return GestureDetector(
                      onTap: () {
                        _vibrate();
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate(delay: (50 * index).ms).fadeIn().scale();
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Notes Input
              TextField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add notes',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Keypad
              _buildKeypad(),
              const SizedBox(height: 12),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'UPDATE TRANSACTION',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () => _onKeyTap(key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

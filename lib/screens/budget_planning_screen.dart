import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

class BudgetPlanningScreen extends StatefulWidget {
  const BudgetPlanningScreen({super.key});

  @override
  State<BudgetPlanningScreen> createState() => _BudgetPlanningScreenState();
}

class _BudgetPlanningScreenState extends State<BudgetPlanningScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final currency = provider.currencySymbol;
    final totalBudget = provider.currentBudget?.monthlyLimit ?? 0;
    final totalSpent = provider.monthlySpent;
    final categories = provider.categories;

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Budget Planning',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F111A),
              const Color(0xFF1A1F38),
              const Color(0xFF0F111A),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Budget Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.2),
                      const Color(0xFF2D3459).withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Budget',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              NumberFormat.currency(
                                symbol: currency,
                                decimalDigits: 0,
                              ).format(totalBudget),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _showSetBudgetDialog(
                            context,
                            provider,
                            'Total Budget',
                            totalBudget,
                            (val) => provider.setBudget(val),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 150,
                          width: 150,
                          child: CircularProgressIndicator(
                            value: totalBudget > 0
                                ? (totalSpent / totalBudget).clamp(0.0, 1.0)
                                : 0,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              totalSpent > totalBudget
                                  ? AppTheme.expense
                                  : AppTheme.primary,
                            ),
                            strokeWidth: 12,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${((totalBudget > 0 ? totalSpent / totalBudget : 0) * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Spent',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem(
                          'Spent',
                          totalSpent,
                          AppTheme.expense,
                          currency,
                        ),
                        _buildSummaryItem(
                          'Remaining',
                          totalBudget - totalSpent,
                          AppTheme.income,
                          currency,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 32),

              Text(
                'Category Budgets',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final limit = provider.getCategoryLimit(category.name);
                  final spent = provider.getCategorySpent(category.name);
                  final progress = limit > 0
                      ? (spent / limit).clamp(0.0, 1.0)
                      : 0.0;

                  Color progressColor = AppTheme.income;
                  if (progress > 0.8) {
                    progressColor = AppTheme.expense;
                  } else if (progress > 0.5) {
                    progressColor = Colors.orange;
                  }

                  return GestureDetector(
                    onTap: () => _showSetBudgetDialog(
                      context,
                      provider,
                      category.name,
                      limit,
                      (val) => provider.setCategoryLimit(category.name, val),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: category.color.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      category.icon,
                                      color: category.color,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                limit > 0
                                    ? '${NumberFormat.compactCurrency(symbol: currency).format(spent)} / ${NumberFormat.compactCurrency(symbol: currency).format(limit)}'
                                    : 'Set Limit',
                                style: TextStyle(
                                  color: limit > 0
                                      ? Colors.white
                                      : AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: limit > 0
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (limit > 0) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (300 + index * 50).ms).slideX();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    Color color,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(
            symbol: currency,
            decimalDigits: 0,
          ).format(value),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showSetBudgetDialog(
    BuildContext context,
    MoneyProvider provider,
    String title,
    double currentLimit,
    Function(double) onSave,
  ) {
    String amount = currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Set $title',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${provider.currencySymbol}${amount.isEmpty ? "0" : amount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildKeypad(setState, (val) {
                setState(() {
                  if (val == '⌫') {
                    if (amount.isNotEmpty) {
                      amount = amount.substring(0, amount.length - 1);
                    }
                  } else if (val == '.') {
                    if (!amount.contains('.')) {
                      amount += val;
                    }
                  } else {
                    if (amount.length < 10) {
                      amount += val;
                    }
                  }
                });
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (amount.isNotEmpty) {
                  onSave(double.parse(amount));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(StateSetter setState, Function(String) onTap) {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3'], onTap),
        const SizedBox(height: 12),
        _buildKeyRow(['4', '5', '6'], onTap),
        const SizedBox(height: 12),
        _buildKeyRow(['7', '8', '9'], onTap),
        const SizedBox(height: 12),
        _buildKeyRow(['.', '0', '⌫'], onTap),
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys, Function(String) onTap) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

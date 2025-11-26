import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F38), // Dark Blue
            const Color(0xFF2D3459), // Lighter Blue
            AppTheme.primary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.4, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Chip and Visa Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChip(),
              const Text(
                'VISA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Balance Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                    NumberFormat.currency(
                      symbol: provider.currencySymbol,
                      decimalDigits: 0,
                    ).format(provider.totalBalance),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  )
                  .animate(key: ValueKey(provider.totalBalance))
                  .fadeIn(duration: 200.ms),
            ],
          ),
          const SizedBox(height: 10),

          // Cardholder Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARD HOLDER',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.userName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              // Mini Stats for Income/Expense
              Row(
                children: [
                  _buildMiniStat(
                    context,
                    provider.totalIncome,
                    AppTheme.income,
                    Icons.arrow_downward,
                    provider.currencySymbol,
                  ),
                  const SizedBox(width: 12),
                  _buildMiniStat(
                    context,
                    provider.totalExpense,
                    AppTheme.expense,
                    Icons.arrow_upward,
                    provider.currencySymbol,
                  ),
                ],
              ),
            ],
          ),

          // Budget Progress (if set)
          if (provider.currentBudget != null &&
              provider.currentBudget!.monthlyLimit > 0) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Budget',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showBudgetDialog(context, provider),
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: provider.budgetProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      provider.budgetProgress > 0.8
                          ? AppTheme.expense
                          : AppTheme.income,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.currencySymbol}${NumberFormat.compact().format(provider.monthlySpent)} / ${provider.currencySymbol}${NumberFormat.compact().format(provider.currentBudget!.monthlyLimit)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => _showBudgetDialog(context, provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Set Monthly Budget',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  void _showBudgetDialog(BuildContext context, MoneyProvider provider) {
    final controller = TextEditingController(
      text: provider.currentBudget?.monthlyLimit.toStringAsFixed(0) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Set Monthly Budget',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter amount',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            prefixText: '${provider.currencySymbol} ',
            prefixStyle: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                provider.setBudget(amount);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildChip() {
    return Container(
      width: 45,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFF7EF8A), Color(0xFFD4AF37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 14,
            height: 1,
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 14,
            width: 1,
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 14,
            width: 1,
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    double amount,
    Color color,
    IconData icon,
    String currencySymbol,
  ) {
    final currencyFormat = NumberFormat.compactCurrency(symbol: currencySymbol);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

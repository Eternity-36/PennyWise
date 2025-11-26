import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import '../providers/money_provider.dart';
import '../models/transaction.dart';
import '../utils/app_theme.dart';
import '../screens/edit_transaction_screen.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final transactions = provider.transactions;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(context, transaction, index);
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Transaction transaction,
    int index,
  ) {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final dateFormat = DateFormat('MMM d, y');

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.edit, color: Colors.black),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - Edit
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EditTransactionScreen(transaction: transaction),
            ),
          );
          return false; // Don't dismiss
        } else {
          // Swipe left - Delete
          if (await Vibration.hasVibrator() == true) {
            Vibration.vibrate(duration: 50);
          }
          return true; // Dismiss and delete
        }
      },
      onDismissed: (direction) {
        if (context.mounted) {
          Provider.of<MoneyProvider>(
            context,
            listen: false,
          ).deleteTransaction(transaction);
        }
      },
      child:
          Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (transaction.isExpense
                                    ? AppTheme.expense
                                    : AppTheme.income)
                                .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        transaction.isExpense
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: transaction.isExpense
                            ? AppTheme.expense
                            : AppTheme.income,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            dateFormat.format(transaction.date),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${transaction.isExpense ? '-' : '+'}${provider.currencySymbol}${transaction.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: transaction.isExpense
                            ? AppTheme.expense
                            : AppTheme.income,
                      ),
                    ),
                  ],
                ),
              )
              .animate(delay: (100 * index).ms)
              .slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuad)
              .fadeIn(),
    );
  }
}

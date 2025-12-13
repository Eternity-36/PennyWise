import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import '../providers/money_provider.dart';
import '../models/transaction.dart';
import '../utils/app_theme.dart';
import '../screens/edit_transaction_screen.dart';
import '../screens/transaction_detail_screen.dart';
import 'skeleton_loading.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  List<Transaction> _localTransactions = [];
  final Set<String> _animatedItems = {}; // Track items that have already animated
  bool _isDeleting = false; // Prevent rebuilds during delete

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only sync if not in the middle of deleting
    if (!_isDeleting) {
      final provider = Provider.of<MoneyProvider>(context);
      if (_localTransactions.isEmpty || 
          _shouldSync(provider.transactions) ||
          _isAccountChange(provider.transactions)) {
        _localTransactions = List.from(provider.transactions);
        _animatedItems.clear(); // Reset animations when account changes
      }
    }
  }

  bool _isAccountChange(List<Transaction> providerTransactions) {
    // Detect account change: if the lists are completely different (no overlap)
    // or if the provider has fewer transactions (switched to empty account)
    if (_localTransactions.isEmpty || providerTransactions.isEmpty) {
      return _localTransactions.length != providerTransactions.length;
    }
    
    final localIds = _localTransactions.map((t) => t.id).toSet();
    final providerIds = providerTransactions.map((t) => t.id).toSet();
    
    // If there's no overlap OR significant difference, it's likely an account change
    final overlap = localIds.intersection(providerIds);
    if (overlap.isEmpty && (localIds.isNotEmpty || providerIds.isNotEmpty)) {
      return true;
    }
    
    // If provider has fewer items (switched from SMS account to non-SMS)
    if (providerTransactions.length < _localTransactions.length) {
      return true;
    }
    
    return false;
  }

  bool _shouldSync(List<Transaction> providerTransactions) {
    // Only sync if there are new items (additions), not deletions
    // This prevents the list from rebuilding after we delete
    if (providerTransactions.length > _localTransactions.length) {
      return true;
    }
    // Check if completely different list (e.g., filter changed)
    if (_localTransactions.isNotEmpty && providerTransactions.isNotEmpty) {
      final localIds = _localTransactions.map((t) => t.id).toSet();
      final providerIds = providerTransactions.map((t) => t.id).toSet();
      // If provider has items we don't have, sync
      if (providerIds.difference(localIds).isNotEmpty) {
        return true;
      }
      // Check if any existing transaction has been updated
      for (final providerTx in providerTransactions) {
        final localTx = _localTransactions.where((t) => t.id == providerTx.id).firstOrNull;
        if (localTx != null && _hasTransactionChanged(localTx, providerTx)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _hasTransactionChanged(Transaction local, Transaction provider) {
    return local.title != provider.title ||
           local.amount != provider.amount ||
           local.category != provider.category ||
           local.isExpense != provider.isExpense ||
           local.date != provider.date;
  }

  void _removeTransaction(int index, Transaction transaction) {
    _isDeleting = true;
    setState(() {
      _localTransactions.removeAt(index);
    });
    
    // Delete in background
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    provider.deleteTransaction(transaction).then((_) {
      if (mounted) {
        _isDeleting = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);

    // Show skeleton loading while data is being fetched
    if (provider.isLoading) {
      return const TransactionListSkeleton(itemCount: 5);
    }

    if (_localTransactions.isEmpty) {
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
      itemCount: _localTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _localTransactions[index];
        return _buildTransactionItem(context, transaction, index, provider);
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Transaction transaction,
    int index,
    MoneyProvider provider,
  ) {
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
        child: Row(
          children: [
            const Icon(Icons.edit, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete, color: Colors.white, size: 24),
          ],
        ),
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
          return true; // Allow dismiss animation
        }
      },
      onDismissed: (direction) {
        print('');
        print('>>>>>> SWIPE DELETE TRIGGERED <<<<<<');
        print('Transaction: ${transaction.title}');
        print('');
        
        // Remove from local list immediately (already animated out)
        _removeTransaction(index, transaction);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main transaction container
          GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TransactionDetailScreen(transaction: transaction),
                    ),
                  );
                },
                child: Container(
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
                ),
              )
              .animate(
                // Only animate if this item hasn't been shown before
                autoPlay: !_animatedItems.contains(transaction.id),
                onComplete: (_) => _animatedItems.add(transaction.id),
              )
              .slideX(
                begin: _animatedItems.contains(transaction.id) ? 0 : 0.2,
                end: 0,
                curve: Curves.easeOutQuad,
                delay: _animatedItems.contains(transaction.id) ? Duration.zero : (100 * index).ms,
              )
              .fadeIn(
                begin: _animatedItems.contains(transaction.id) ? 1 : 0,
                delay: _animatedItems.contains(transaction.id) ? Duration.zero : (100 * index).ms,
              ),
        ],
      ),
    );
  }
}

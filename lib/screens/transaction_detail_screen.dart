import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/money_provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late bool _isExpense;
  late String _category;
  late String _accountId;
  late String _bankName;
  late String _accountLast4;
  late bool _isExcluded;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.transaction.isExpense;
    _category = widget.transaction.category;
    _accountId = widget.transaction.accountId;
    _bankName = widget.transaction.bankName ?? 'Bank';
    _accountLast4 = widget.transaction.accountLast4 ?? 'XXXX';
    _isExcluded = widget.transaction.isExcluded;
  }

  void _updateTransaction() {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final updatedTransaction = Transaction(
      id: widget.transaction.id,
      title: widget.transaction.title,
      amount: widget.transaction.amount,
      date: widget.transaction.date,
      isExpense: _isExpense,
      category: _category,
      accountId: _accountId,
      userId: widget.transaction.userId,
      smsBody: widget.transaction.smsBody,
      referenceNumber: widget.transaction.referenceNumber,
      bankName: widget.transaction.bankName,
      accountLast4: widget.transaction.accountLast4,
      isExcluded: _isExcluded,
    );
    provider.updateTransaction(updatedTransaction);
  }

  @override
  Widget build(BuildContext context) {
    final isSmsTransaction =
        widget.transaction.smsBody != null &&
        widget.transaction.smsBody!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1C1C), // Dark background from image
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isExpense ? 'Debit transaction' : 'Credit transaction',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show options like Edit/Delete
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF2C2424), const Color(0xFF1A1515)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Payee Name
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.transaction.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isExpense)
                          const Icon(
                            Icons.arrow_outward,
                            color: Colors.white70,
                            size: 20,
                          ),
                        if (!_isExpense)
                          const Icon(
                            Icons.arrow_downward,
                            color: Colors.green,
                            size: 20,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${widget.transaction.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Category Pill with Edit Icon
                    Consumer<MoneyProvider>(
                      builder: (context, provider, child) {
                        final categoryObj = provider.categories.firstWhere(
                          (c) => c.name == _category,
                          orElse: () => Category(
                            id: 'unknown',
                            name: _category,
                            iconCode: Icons.category.codePoint,
                            colorValue: Colors.grey.value,
                            isCustom: false,
                          ),
                        );

                        return GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: const Color(0xFF1E1C1C),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Select Category',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: provider.categories.length,
                                        itemBuilder: (context, index) {
                                          final cat =
                                              provider.categories[index];
                                          return ListTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: cat.color.withValues(
                                                  alpha: 0.2,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                cat.icon,
                                                color: cat.color,
                                                size: 20,
                                              ),
                                            ),
                                            title: Text(
                                              cat.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            onTap: () {
                                              setState(() {
                                                _category = cat.name;
                                                _updateTransaction();
                                              });
                                              Navigator.pop(context);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: categoryObj.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: categoryObj.color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  categoryObj.icon,
                                  color: categoryObj.color,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.edit,
                                  color: categoryObj.color.withValues(
                                    alpha: 0.7,
                                  ),
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Date
                    Text(
                      DateFormat(
                        'EEE, d MMM, h:mm a',
                      ).format(widget.transaction.date),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Account Card (Dropdown & Toggle)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2F48), // Blue-ish grey from image
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.orange, // Placeholder for bank logo
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _accountId == 'cash' ? 'Cash' : 'Bank',
                          dropdownColor: const Color(0xFF2C2F48),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'Bank',
                              child: Text('$_bankName $_accountLast4'),
                            ),
                            const DropdownMenuItem(
                              value: 'Cash',
                              child: Text('Cash'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _accountId = value == 'Cash'
                                  ? 'cash'
                                  : widget.transaction.accountId;
                              _updateTransaction();
                            });
                          },
                        ),
                      ),
                    ),
                    Text(
                      !_isExcluded ? 'Included' : 'Excluded',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: !_isExcluded,
                      onChanged: (val) {
                        setState(() {
                          _isExcluded = !val;
                          _updateTransaction();
                        });
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.red.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Notes Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sticky_note_2_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Notes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Actions Row (Split / Attach)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Avatars placeholder
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAvatar(),
                              Transform.translate(
                                offset: const Offset(-10, 0),
                                child: _buildAvatar(),
                              ),
                              Transform.translate(
                                offset: const Offset(-20, 0),
                                child: _buildAvatar(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Split expense with friends or family',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Split',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            color: Colors.white70,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add a photo of a receipt/warranty',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Attach',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Tags
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.label_outline,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Tags',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.add, color: Colors.white),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              // Other Info (SMS Details) - Only if SMS transaction
              if (isSmsTransaction) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.list,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Other info',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // UPI Ref No
                      if (widget.transaction.referenceNumber != null) ...[
                        Text(
                          'UPI Ref No',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.transaction.referenceNumber!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // SMS Body
                      Text(
                        'SMS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.transaction.smsBody!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2A2A2A), width: 2),
      ),
      child: const Icon(Icons.person, size: 20, color: Colors.white54),
    );
  }
}

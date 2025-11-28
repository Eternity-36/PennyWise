import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

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
  late String? _notes;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.transaction.isExpense;
    _category = widget.transaction.category;
    _accountId = widget.transaction.accountId;
    _bankName = widget.transaction.bankName ?? 'Bank';
    _accountLast4 = widget.transaction.accountLast4 ?? 'XXXX';
    _isExcluded = widget.transaction.isExcluded;
    _notes = widget.transaction.notes;
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
      notes: _notes,
    );
    provider.updateTransaction(updatedTransaction);
  }

  @override
  Widget build(BuildContext context) {
    final isSmsTransaction =
        widget.transaction.smsBody != null &&
        widget.transaction.smsBody!.isNotEmpty;
    final provider = Provider.of<MoneyProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isExpense ? 'Expense Details' : 'Income Details',
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
            onPressed: () {
              _showOptionsSheet(context, provider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Amount Card - Glassmorphism Style
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (_isExpense ? AppTheme.expense : AppTheme.income).withValues(alpha: 0.15),
                          AppTheme.surface.withValues(alpha: 0.4),
                          AppTheme.primary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Transaction Type Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_isExpense ? AppTheme.expense : AppTheme.income).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                color: _isExpense ? AppTheme.expense : AppTheme.income,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isExpense ? 'EXPENSE' : 'INCOME',
                                style: TextStyle(
                                  color: _isExpense ? AppTheme.expense : AppTheme.income,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        // Amount
                        Text(
                          '${provider.currencySymbol}${NumberFormat('#,##0').format(widget.transaction.amount)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: (_isExpense ? AppTheme.expense : AppTheme.income).withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        
                        // Payee Name
                        Text(
                          widget.transaction.title,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Category Pill with Edit Icon
                        _buildCategorySelector(provider),

                        const SizedBox(height: 20),

                        // Date & Time
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: AppTheme.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('EEE, d MMM yyyy • h:mm a').format(widget.transaction.date),
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 16),

              // Account Card
              _buildGlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.3),
                            AppTheme.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _accountId == 'cash' ? 'Cash' : 'Bank',
                              dropdownColor: AppTheme.surface,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.primary,
                              ),
                              isDense: true,
                              items: [
                                DropdownMenuItem(
                                  value: 'Bank',
                                  child: Text('$_bankName ••$_accountLast4'),
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
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          !_isExcluded ? 'Included' : 'Excluded',
                          style: TextStyle(
                            color: !_isExcluded ? AppTheme.income : AppTheme.expense,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: !_isExcluded,
                            onChanged: (val) {
                              setState(() {
                                _isExcluded = !val;
                                _updateTransaction();
                              });
                            },
                            activeColor: AppTheme.income,
                            activeTrackColor: AppTheme.income.withValues(alpha: 0.3),
                            inactiveThumbColor: AppTheme.expense,
                            inactiveTrackColor: AppTheme.expense.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),

              const SizedBox(height: 16),

              // Notes Card
              GestureDetector(
                onTap: () => _showNotesSheet(context),
                child: _buildGlassCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.sticky_note_2_rounded,
                          color: Colors.amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _notes != null && _notes!.isNotEmpty
                                  ? _notes!
                                  : 'Tap to add a note...',
                              style: TextStyle(
                                color: _notes != null && _notes!.isNotEmpty
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _notes != null && _notes!.isNotEmpty
                            ? Icons.edit_rounded
                            : Icons.add_rounded,
                        color: Colors.amber.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.05),

              const SizedBox(height: 16),

              // Actions Row (Split / Attach)
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.people_alt_rounded,
                      iconColor: AppTheme.primary,
                      title: 'Split',
                      subtitle: 'Split with friends',
                      onTap: () => _showSplitSheet(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.attach_file_rounded,
                      iconColor: Colors.teal,
                      title: 'Attach',
                      subtitle: 'Add receipt/photo',
                      onTap: () {
                        // TODO: Implement attach
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Tags Card
              _buildGlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.label_rounded,
                        color: Colors.pink,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Tags',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.05),

              // SMS Details - Only if SMS transaction
              if (isSmsTransaction) ...[
                const SizedBox(height: 16),
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.sms_rounded,
                              color: Colors.cyan,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Transaction Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      
                      if (widget.transaction.referenceNumber != null) ...[
                        const SizedBox(height: 20),
                        _buildInfoRow('Reference No.', widget.transaction.referenceNumber!),
                      ],
                      
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Original SMS',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.transaction.smsBody!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(MoneyProvider provider) {
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
      onTap: () => _showCategorySheet(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: categoryObj.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: categoryObj.color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(categoryObj.icon, color: categoryObj.color, size: 18),
            const SizedBox(width: 10),
            Text(
              _category,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit_rounded,
              color: categoryObj.color.withValues(alpha: 0.7),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<bool> _requestPermissions() async {
    // Request both contacts and SMS permissions
    final contactsStatus = await Permission.contacts.status;
    final smsStatus = await Permission.sms.status;
    
    bool contactsGranted = contactsStatus.isGranted;
    bool smsGranted = smsStatus.isGranted;
    
    if (!contactsGranted || !smsGranted) {
      // Show permission dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.2),
                        AppTheme.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.people_alt_rounded,
                    color: AppTheme.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Permissions Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'To split bills with friends, we need access to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                // Permission items
                _buildPermissionItem(
                  icon: Icons.contacts_rounded,
                  title: 'Contacts',
                  description: 'Pick friends to split with',
                  isGranted: contactsGranted,
                ),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  icon: Icons.sms_rounded,
                  title: 'SMS',
                  description: 'Send split request messages',
                  isGranted: smsGranted,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary,
                                AppTheme.primary.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Allow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (result != true) return false;

      // Request permissions
      if (!contactsGranted) {
        final status = await Permission.contacts.request();
        contactsGranted = status.isGranted;
        if (!contactsGranted && status.isPermanentlyDenied) {
          _showSettingsDialog('Contacts');
          return false;
        }
      }

      if (!smsGranted) {
        final status = await Permission.sms.request();
        smsGranted = status.isGranted;
        if (!smsGranted && status.isPermanentlyDenied) {
          _showSettingsDialog('SMS');
          return false;
        }
      }
    }

    return contactsGranted && smsGranted;
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGranted 
            ? AppTheme.income.withValues(alpha: 0.1)
            : AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted
              ? AppTheme.income.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted
                  ? AppTheme.income.withValues(alpha: 0.2)
                  : AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isGranted ? AppTheme.income : AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isGranted ? AppTheme.income : AppTheme.textSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings_rounded,
                color: Colors.amber,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '$permission Permission Required',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enable $permission permission in Settings to use this feature.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Open Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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

  Future<void> _showSplitSheet(BuildContext context) async {
    // Request permissions first
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) return;

    // Get contacts
    List<Contact> contacts = [];
    try {
      contacts = await FlutterContacts.getContacts(withProperties: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load contacts: $e'),
            backgroundColor: AppTheme.expense,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final List<_SplitContact> selectedContacts = [];
    final searchController = TextEditingController();
    List<Contact> filteredContacts = contacts;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Split Bill',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.expense.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              NumberFormat.currency(
                                symbol: '₹',
                                decimalDigits: 0,
                              ).format(widget.transaction.amount),
                              style: const TextStyle(
                                color: AppTheme.expense,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.transaction.title,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Selected contacts chips
                if (selectedContacts.isNotEmpty) ...[
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: selectedContacts.length,
                      itemBuilder: (context, index) {
                        final contact = selectedContacts[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                contact.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    selectedContacts.removeAt(index);
                                  });
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  color: AppTheme.primary,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search contacts...',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          filteredContacts = contacts.where((c) {
                            final name = c.displayName.toLowerCase();
                            return name.contains(value.toLowerCase());
                          }).toList();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Contacts list
                Expanded(
                  child: filteredContacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                color: AppTheme.textSecondary,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No contacts found',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = filteredContacts[index];
                            final phone = contact.phones.isNotEmpty
                                ? contact.phones.first.number
                                : null;
                            final isSelected = selectedContacts.any(
                              (c) => c.phone == phone,
                            );

                            if (phone == null) return const SizedBox.shrink();

                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  if (isSelected) {
                                    selectedContacts.removeWhere(
                                      (c) => c.phone == phone,
                                    );
                                  } else {
                                    selectedContacts.add(_SplitContact(
                                      name: contact.displayName,
                                      phone: phone,
                                    ));
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(alpha: 0.15)
                                      : AppTheme.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.primary.withValues(alpha: 0.3),
                                            AppTheme.primary.withValues(alpha: 0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          contact.displayName.isNotEmpty
                                              ? contact.displayName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            contact.displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            phone,
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.textSecondary,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Split summary and send button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (selectedContacts.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Split between ${selectedContacts.length + 1} people',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(widget.transaction.amount / (selectedContacts.length + 1))} each',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      GestureDetector(
                        onTap: selectedContacts.isEmpty
                            ? null
                            : () => _sendSplitMessages(
                                  context,
                                  selectedContacts,
                                  widget.transaction.amount /
                                      (selectedContacts.length + 1),
                                ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: selectedContacts.isEmpty
                                ? null
                                : LinearGradient(
                                    colors: [
                                      AppTheme.primary,
                                      AppTheme.primary.withValues(alpha: 0.8),
                                    ],
                                  ),
                            color: selectedContacts.isEmpty
                                ? Colors.white.withValues(alpha: 0.1)
                                : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: selectedContacts.isEmpty
                                ? null
                                : [
                                    BoxShadow(
                                      color:
                                          AppTheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                color: selectedContacts.isEmpty
                                    ? AppTheme.textSecondary
                                    : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedContacts.isEmpty
                                    ? 'Select contacts to split'
                                    : 'Send Split Request',
                                style: TextStyle(
                                  color: selectedContacts.isEmpty
                                      ? AppTheme.textSecondary
                                      : Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendSplitMessages(
    BuildContext context,
    List<_SplitContact> contacts,
    double amountPerPerson,
  ) async {
    Navigator.pop(context); // Close the sheet

    final amountFormatted = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    ).format(amountPerPerson);

    final message = 'Hey! We split the bill for "${widget.transaction.title}". '
        'Your share is $amountFormatted. '
        'Please pay when you can. - Sent via PennyWise';

    // Show sending snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text('Sending to ${contacts.length} contact${contacts.length > 1 ? 's' : ''}...'),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );

    int successCount = 0;

    for (final contact in contacts) {
      try {
        const platform = MethodChannel('pennywise/sms');
        await platform.invokeMethod('sendSMS', {
          'phone': contact.phone,
          'message': message,
        });
        successCount++;
      } catch (e) {
        // Failed to send
      }
    }

    if (!mounted) return;

    // Show result
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              successCount == contacts.length
                  ? Icons.check_circle_rounded
                  : Icons.warning_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              successCount == contacts.length
                  ? 'Split requests sent to ${contacts.length} contact${contacts.length > 1 ? 's' : ''}!'
                  : 'Sent to $successCount/${contacts.length} contacts',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: successCount == contacts.length ? AppTheme.income : Colors.amber.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showNotesSheet(BuildContext context) {
    final controller = TextEditingController(text: _notes ?? '');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Notes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 4,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter notes about this transaction...',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_notes != null && _notes!.isNotEmpty)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _notes = null;
                            _updateTransaction();
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.expense.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.expense.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: AppTheme.expense,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_notes != null && _notes!.isNotEmpty)
                    const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final newNotes = controller.text.trim();
                        setState(() {
                          _notes = newNotes.isEmpty ? null : newNotes;
                          _updateTransaction();
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary,
                              AppTheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context, MoneyProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
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
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: provider.categories.length,
                itemBuilder: (context, index) {
                  final cat = provider.categories[index];
                  final isSelected = cat.name == _category;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _category = cat.name;
                        _updateTransaction();
                      });
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? cat.color.withValues(alpha: 0.3)
                                : cat.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected 
                                ? Border.all(color: cat.color, width: 2)
                                : null,
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 26),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context, MoneyProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.expense.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delete_rounded, color: AppTheme.expense),
              ),
              title: const Text(
                'Delete Transaction',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'This action cannot be undone',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, provider);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MoneyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Transaction?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete this transaction?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteTransaction(widget.transaction);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expense,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Helper class for split contacts
class _SplitContact {
  final String name;
  final String phone;

  _SplitContact({required this.name, required this.phone});
}

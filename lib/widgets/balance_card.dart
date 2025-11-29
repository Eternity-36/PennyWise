import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../models/account.dart';
import '../utils/app_theme.dart';
import 'animated_digit_text.dart';
import 'skeleton_loading.dart';

class BalanceCard extends StatefulWidget {
  final VoidCallback? onBudgetTap;
  
  const BalanceCard({super.key, this.onBudgetTap});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showCreateAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    bool showSmsTransactions = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_card, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Create Account',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: 'Account Name',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  hintText: 'e.g., Business, Family, Savings',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.account_balance_wallet, color: AppTheme.primary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // SMS Transactions Toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: showSmsTransactions 
                        ? AppTheme.primary.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: showSmsTransactions
                            ? AppTheme.primary.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.sms_outlined,
                        color: showSmsTransactions ? AppTheme.primary : Colors.white54,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SMS Transactions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Show bank SMS in this account',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: showSmsTransactions,
                      onChanged: (value) {
                        setDialogState(() {
                          showSmsTransactions = value;
                        });
                      },
                      activeColor: AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  
                  // Create account via provider with SMS setting
                  final account = await provider.createAccount(
                    nameController.text.trim(),
                    colorValue: _getAccountColor(provider.accounts.length),
                    showSmsTransactions: showSmsTransactions,
                  );
                  
                  if (account != null && mounted) {
                    // Navigate to the new account card
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (_pageController.hasClients) {
                        _pageController.animateToPage(
                          provider.accounts.length - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Account "${nameController.text.trim()}" created!'),
                        backgroundColor: AppTheme.income,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  int _getAccountColor(int index) {
    final colors = [
      0xFF6C5CE7, // Purple
      0xFF00B894, // Green
      0xFFE17055, // Orange
      0xFF0984E3, // Blue
      0xFFD63031, // Red
      0xFFFDAA3D, // Yellow
    ];
    return colors[index % colors.length];
  }

  void _switchToAccount(BuildContext context, Account account) async {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    
    await provider.switchAccount(account.id);
    
    // Navigate to the main card (page 0)
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Switched to "${account.name}"'),
            ],
          ),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final accounts = provider.accounts;
    final activeAccount = provider.activeAccount;
    
    // Show skeleton loading while data is loading
    if (provider.isLoading) {
      return const BalanceCardSkeleton();
    }
    
    // Check if user is a guest
    final isGuest = provider.userId == null || provider.settingsBox.get('isGuest', defaultValue: true);
    
    // Guest users don't have multi-account feature - show simple card
    if (isGuest) {
      return _buildMainCardWithoutAccount(context, provider);
    }
    
    // For logged-in users, always show swipeable interface
    // If accounts are still loading, show loading state or at least the add card
    if (accounts.isEmpty || activeAccount == null) {
      // Show swipeable with just the "Add Account" card while loading
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: _buildAddAccountCard(context),
          ),
          const SizedBox(height: 12),
          // Single dot indicator
          Container(
            width: 20,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      );
    }

    // Get other accounts (not active)
    final otherAccounts = accounts.where((a) => a.id != activeAccount.id).toList();
    final totalPages = 1 + otherAccounts.length + 1; // active + others + add card

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // PageView for cards
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: totalPages,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Main card (active account)
                    return _buildMainCard(context, provider, activeAccount);
                  } else if (index <= otherAccounts.length) {
                    // Other account cards
                    return _buildAccountCard(context, otherAccounts[index - 1]);
                  }
                  // Add new account card (last page)
                  return _buildAddAccountCard(context);
                },
              ),
            ),

            // Swipe hint arrow (only on first page)
            if (_currentPage == 0 && accounts.length > 1 || _currentPage == 0)
              Positioned(
                right: 16,
                top: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chevron_left,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Swipe',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .fadeIn(duration: 800.ms)
              .slideX(begin: 0.2, end: 0, duration: 1500.ms),
          ],
        ),

        // Page indicator dots (below the card)
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            totalPages,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppTheme.primary
                    : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build main card when no account system is active (guest mode)
  Widget _buildMainCardWithoutAccount(BuildContext context, MoneyProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                    const Color(0xFF1A1F38).withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildChip(),
                      GestureDetector(
                        onTap: () => _showCardNameDialog(context, provider),
                        child: Row(
                          children: [
                            Text(
                              provider.cardName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDigitText(
                        value: NumberFormat.currency(
                          symbol: provider.currencySymbol,
                          decimalDigits: 0,
                        ).format(provider.totalBalance),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        duration: const Duration(milliseconds: 600),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD HOLDER',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider.userName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildMiniStat(
                            provider.totalIncome,
                            AppTheme.income,
                            Icons.arrow_downward,
                            provider.currencySymbol,
                          ),
                          const SizedBox(width: 16),
                          _buildMiniStat(
                            provider.totalExpense,
                            AppTheme.expense,
                            Icons.arrow_upward,
                            provider.currencySymbol,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildMainCard(BuildContext context, MoneyProvider provider, Account account) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                account.color.withValues(alpha: 0.3),
                const Color(0xFF1A1F38).withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 25,
                spreadRadius: -5,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Chip and Card Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildChip(),
                  GestureDetector(
                    onTap: () => _showCardNameDialog(context, provider),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: account.color.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            account.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.cardName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Balance Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDigitText(
                    value: NumberFormat.currency(
                      symbol: provider.currencySymbol,
                      decimalDigits: 0,
                    ).format(provider.totalBalance),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 600),
                  ),
                ],
              ),
              const Spacer(),

              // Bottom Row: Cardholder & Income/Expense
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARD HOLDER',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.userName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  // Income/Expense Stats
                  Row(
                    children: [
                      _buildMiniStat(
                        provider.totalIncome,
                        AppTheme.income,
                        Icons.arrow_downward,
                        provider.currencySymbol,
                      ),
                      const SizedBox(width: 16),
                      _buildMiniStat(
                        provider.totalExpense,
                        AppTheme.expense,
                        Icons.arrow_upward,
                        provider.currencySymbol,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildAccountCard(BuildContext context, Account account) {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    
    return GestureDetector(
      onLongPress: () => _showAccountOptionsDialog(context, account),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  account.color.withValues(alpha: 0.3),
                  const Color(0xFF1A1F38).withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 25,
                  spreadRadius: -5,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Chip and Account Name with options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildChip(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: account.color.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            account.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Options button (delete, etc.)
                        GestureDetector(
                          onTap: () => _showAccountOptionsDialog(context, account),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.more_vert,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),

                // Balance Section (placeholder - balance shown when switched)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Switch to view',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Bottom Row: Switch Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.userName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    // Switch Button
                    ElevatedButton.icon(
                      onPressed: () => _switchToAccount(context, account),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Switch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: account.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  void _showAccountOptionsDialog(BuildContext context, Account account) {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Account name header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: account.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.account_balance_wallet, color: account.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        account.showSmsTransactions ? 'SMS enabled' : 'SMS disabled',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Toggle SMS option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.sms_outlined, color: AppTheme.primary, size: 20),
              ),
              title: const Text('SMS Transactions', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                account.showSmsTransactions ? 'Tap to disable' : 'Tap to enable',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              trailing: Switch(
                value: account.showSmsTransactions,
                onChanged: (value) async {
                  await provider.updateAccountSmsEnabled(account.id, value);
                  if (mounted) Navigator.pop(context);
                },
                activeColor: AppTheme.primary,
              ),
              onTap: () async {
                await provider.updateAccountSmsEnabled(account.id, !account.showSmsTransactions);
                if (mounted) Navigator.pop(context);
              },
            ),
            
            const Divider(color: Colors.white12),
            
            // Delete option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.expense.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_outline, color: AppTheme.expense, size: 20),
              ),
              title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Remove this account and all its data',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAccountConfirmation(context, account);
              },
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, Account account) {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.expense.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: AppTheme.expense, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Account?',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${account.name}"?',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.expense.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.expense.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.expense, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This will permanently delete all transactions, budgets, loans, and goals in this account.',
                      style: TextStyle(
                        color: AppTheme.expense.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await provider.deleteAccount(account.id);
              
              if (mounted) {
                if (success) {
                  // Navigate back to first page
                  if (_pageController.hasClients) {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account "${account.name}" deleted'),
                      backgroundColor: AppTheme.expense,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot delete this account'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expense,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCreateAccountDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1F38).withValues(alpha: 0.5),
              const Color(0xFF2D3459).withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: AppTheme.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add New Account',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to create',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  void _showCardNameDialog(BuildContext context, MoneyProvider provider) {
    final cardNameController = TextEditingController(text: provider.cardName);
    final cardHolderController = TextEditingController(text: provider.userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Edit Card Details',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cardNameController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: 'Card Name',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                hintText: 'e.g., VISA, MASTERCARD',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                counterStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cardHolderController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                hintText: 'e.g., John Doe',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                counterStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (cardNameController.text.isNotEmpty) {
                provider.setCardName(cardNameController.text.toUpperCase());
              }
              if (cardHolderController.text.isNotEmpty) {
                provider.setUserName(cardHolderController.text);
              }
              Navigator.pop(context);
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
    double amount,
    Color color,
    IconData icon,
    String currencySymbol,
  ) {
    final currencyFormat = NumberFormat.compactCurrency(symbol: currencySymbol);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          AnimatedDigitText(
            value: currencyFormat.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            duration: const Duration(milliseconds: 500),
          ),
        ],
      ),
    );
  }
}

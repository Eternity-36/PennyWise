import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import 'animated_digit_text.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // PageView for cards
        SizedBox(
          height: 200, // Reduced height since budget is removed
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildMainCard(context, provider),
              _buildAddCardPlaceholder(context),
            ],
          ),
        ),

        // Swipe hint arrow (only on first page)
        if (_currentPage == 0)
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
    );
  }

  Widget _buildMainCard(BuildContext context, MoneyProvider provider) {
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
                const Color(0xFF2D3459).withValues(alpha: 0.4),
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

              // Balance Section - Centered
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

  Widget _buildAddCardPlaceholder(BuildContext context) {
    return Container(
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
          color: Colors.white.withValues(alpha: 0.1),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.add,
                color: Colors.white.withValues(alpha: 0.6),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add New Card',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coming Soon',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
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

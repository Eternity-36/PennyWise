import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import 'sms_tracking_screen.dart';
import 'net_worth_screen.dart';
import 'category_management_screen.dart';
import 'budget_planning_screen.dart';
import 'loans_screen.dart';
import 'goals_screen.dart';
import 'currency_converter_screen.dart';

class AdvanceScreen extends StatelessWidget {
  const AdvanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Advanced Features',
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildFeatureTile(
              context,
              'SMS Transaction Tracking',
              'Automatically track transactions from SMS messages',
              Icons.sms_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SmsTrackingScreen(),
                ),
              ),
              isEnabled: Provider.of<MoneyProvider>(context).smsTrackingEnabled,
            ),
            _buildFeatureTile(
              context,
              'Net Worth Analysis',
              'Visualize your financial growth over time',
              Icons.show_chart_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NetWorthScreen()),
              ),
            ),
            _buildFeatureTile(
              context,
              'Category Management',
              'Create and customize transaction categories',
              Icons.category_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManagementScreen(),
                ),
              ),
            ),
            _buildFeatureTile(
              context,
              'Budget Planning',
              'Set monthly limits for categories',
              Icons.account_balance_wallet_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetPlanningScreen(),
                ),
              ),
            ),
            _buildFeatureTile(
              context,
              'Loans Management',
              'Track money lent and borrowed',
              Icons.handshake_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoansScreen()),
              ),
            ),
            _buildFeatureTile(
              context,
              'Financial Goals',
              'Set and track savings goals',
              Icons.flag_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GoalsScreen()),
              ),
            ),
            _buildFeatureTile(
              context,
              'Currency Converter',
              'Convert between world currencies with live rates',
              Icons.currency_exchange_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CurrencyConverterScreen()),
              ),
            ),
            // Add more advanced features here in the future
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool? isEnabled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled == true
                ? AppTheme.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled == true
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isEnabled == true ? AppTheme.primary : Colors.white54,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  if (isEnabled != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? AppTheme.income.withValues(alpha: 0.1)
                            : AppTheme.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isEnabled ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isEnabled ? AppTheme.income : AppTheme.expense,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

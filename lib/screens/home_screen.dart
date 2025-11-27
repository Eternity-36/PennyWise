import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_list.dart';
import '../widgets/profile_dialog.dart';
import 'add_transaction_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Deep dark background
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
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
            ),
          ),

          // Decorative Circle
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back,',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ).animate().fadeIn().slideX(begin: -0.2),
                          const SizedBox(height: 4),
                          Text(
                            provider.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false,
                              barrierDismissible: true,
                              barrierColor: Colors.black.withValues(alpha: 0.5),
                              transitionDuration: const Duration(
                                milliseconds: 800,
                              ),
                              reverseTransitionDuration: const Duration(
                                milliseconds: 600,
                              ),
                              pageBuilder: (context, _, __) =>
                                  const ProfileDialog(),
                              transitionsBuilder:
                                  (context, animation, _, child) {
                                    const curve = Curves.fastOutSlowIn;
                                    final curvedAnimation = CurvedAnimation(
                                      parent: animation,
                                      curve: curve,
                                      reverseCurve: curve.flipped,
                                    );
                                    return ScaleTransition(
                                      scale: curvedAnimation,
                                      alignment: Alignment.topRight,
                                      child: FadeTransition(
                                        opacity: curvedAnimation,
                                        child: child,
                                      ),
                                    );
                                  },
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'profile_ring',
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF2D3459),
                              backgroundImage: provider.photoURL != null
                                  ? NetworkImage(provider.photoURL!)
                                  : null,
                              child: provider.photoURL == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ).animate().scale(delay: 200.ms),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Balance Card
                  const BalanceCard()
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.2),

                  const SizedBox(height: 32),

                  // Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(
                        context,
                        Icons.arrow_upward_rounded,
                        'Expense',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTransactionScreen(
                              initialIsExpense: true,
                            ),
                          ),
                        ),
                        heroTag: 'hero_action_expense',
                      ),
                      _buildQuickAction(
                        context,
                        Icons.arrow_downward_rounded,
                        'Income',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTransactionScreen(
                              initialIsExpense: false,
                            ),
                          ),
                        ),
                        heroTag: 'hero_action_income',
                      ),
                      _buildQuickAction(
                        context,
                        Icons.history_rounded,
                        'History',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AnalyticsScreen(),
                          ),
                        ),
                        heroTag: 'hero_action_history',
                      ),
                      _buildQuickAction(
                        context,
                        Icons.more_horiz_rounded,
                        'More',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        ),
                        heroTag: 'hero_action_more',
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                  const SizedBox(height: 32),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 16),

                  // Transaction List
                  const Expanded(child: TransactionList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    String? heroTag,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Hero(
            tag: heroTag ?? UniqueKey().toString(),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F38),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

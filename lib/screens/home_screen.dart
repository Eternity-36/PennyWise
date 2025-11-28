import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_list.dart';
import '../widgets/profile_dialog.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'add_transaction_screen.dart';
import 'analytics_screen.dart';
import 'advance_screen.dart';
import 'net_worth_screen.dart';
import 'settings_screen.dart';
import 'all_transactions_screen.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to transparent with light icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // For iOS
      ),
    );

    final provider = Provider.of<MoneyProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
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

          // PageView
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildHomePage(provider),
              const AnalyticsScreen(),
              const AdvanceScreen(),
              const SettingsScreen(),
            ],
          ),

          // Floating Navigation Bar
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: CustomBottomNavBar(
                selectedIndex: _currentPage,
                onItemSelected: _onNavItemTapped,
              ).animate().fadeIn(delay: 1000.ms).slideY(begin: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(MoneyProvider provider) {
    return Stack(
      children: [
        // Fixed Background Gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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

        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20.0,
                MediaQuery.of(context).padding.top + 16,
                20.0,
                100.0,
              ),
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
                                milliseconds: 400,
                              ),
                              reverseTransitionDuration: const Duration(
                                milliseconds: 300,
                              ),
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const ProfileDialog(),
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
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
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickAction(
                        context,
                        icon: Icons.arrow_upward_rounded,
                        label: 'Expense',
                        color: AppTheme.expense,
                        delay: 500,
                        heroTag: 'hero_action_expense',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddTransactionScreen(
                                initialIsExpense: true,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.arrow_downward_rounded,
                        label: 'Income',
                        color: AppTheme.income,
                        delay: 600,
                        heroTag: 'hero_action_income',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddTransactionScreen(
                                initialIsExpense: false,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.history_rounded,
                        label: 'History',
                        color: const Color(0xFF6366F1),
                        delay: 700,
                        heroTag: 'hero_action_history',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AllTransactionsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.show_chart_rounded,
                        label: 'Net Worth',
                        color: Colors.cyan,
                        delay: 800,
                        heroTag: 'hero_action_net_worth',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NetWorthScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Recent Transactions
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 900.ms),
                  const SizedBox(height: 16),

                  // Transaction List with fade-out gradient
                  SizedBox(
                    height: 400,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.8, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: const TransactionList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required int delay,
    required VoidCallback onTap,
    required String heroTag,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Hero(
            tag: heroTag,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2);
  }
}

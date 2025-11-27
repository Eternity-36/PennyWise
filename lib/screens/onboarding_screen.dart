import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../providers/money_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();

  int _currentPage = 0;
  bool _isAnimating = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isAnimating = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && mounted) {
        final user = userCredential.user!;
        await _initializeAndNavigate(
          name: user.displayName ?? 'User',
          currency: '₹',
          isGuest: false,
          userId: user.uid,
          photoURL: user.photoURL,
        );
      } else {
        setState(() => _isAnimating = false);
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      if (mounted) {
        setState(() => _isAnimating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login Failed: $e')));
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isAnimating = true);

    // Check if there is a previous guest session to restore
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final prevGuestId = provider.settingsBox.get('guestUserId');
    final prevGuestName = provider.settingsBox.get('guestUserName');
    final prevGuestCurrency = provider.settingsBox.get('guestCurrency');

    if (prevGuestId != null) {
      // RESTORE PREVIOUS GUEST SESSION
      await _initializeAndNavigate(
        name: prevGuestName ?? _nameController.text.trim(),
        currency: prevGuestCurrency ?? '₹',
        isGuest: true,
        userId: prevGuestId,
      );
    } else {
      // CREATE NEW GUEST SESSION
      if (_nameController.text.trim().isEmpty) {
        setState(() => _isAnimating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
        return;
      }

      await _initializeAndNavigate(
        name: _nameController.text.trim(),
        currency: '₹',
        isGuest: true,
        userId: const Uuid().v4(),
      );
    }
  }

  Future<void> _initializeAndNavigate({
    required String name,
    required String currency,
    required bool isGuest,
    required String? userId,
    String? photoURL,
  }) async {
    try {
      final provider = Provider.of<MoneyProvider>(context, listen: false);
      await provider.initializeUser(
        name: name,
        currency: currency,
        isGuest: isGuest,
        userId: userId,
        photoURL: photoURL,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Initialization Error: $e');
      if (mounted) {
        setState(() => _isAnimating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildPage(
                title: 'Track Your\nExpenses',
                subtitle: 'Keep track of every penny you spend with ease.',
                icon: Icons.account_balance_wallet_outlined,
              ),
              _buildPage(
                title: 'Smart\nAnalytics',
                subtitle:
                    'Visualize your spending habits with beautiful charts.',
                icon: Icons.pie_chart_outline,
              ),
              _buildSetupPage(),
            ],
          ),

          // Page Indicators
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primary
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: AppTheme.primary,
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().fadeIn().slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'NEXT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85, // Occupy more height
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 3), // Push content down
            // Decorative Icon
            Icon(
              Icons.rocket_launch_outlined,
              size: 80,
              color: AppTheme.primary.withValues(alpha: 0.8),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            const Text(
              'Let\'s Get\nStarted',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0),

            const SizedBox(height: 48),

            // Google Sign In Button
            ElevatedButton.icon(
              onPressed: _isAnimating ? null : _handleGoogleLogin,
              icon: const Icon(
                Icons.g_mobiledata,
                size: 32,
                color: Colors.black,
              ),
              label: const Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

            const SizedBox(height: 32),

            const Row(
              children: [
                Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white24)),
              ],
            ),

            const SizedBox(height: 32),

            // Guest Setup
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Colors.white70,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isAnimating ? null : _handleGuestLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppTheme.primary.withValues(alpha: 0.4),
              ),
              child: _isAnimating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'CONTINUE AS GUEST',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),

            const Spacer(flex: 1), // Reduced bottom spacer
          ],
        ),
      ),
    );
  }
}

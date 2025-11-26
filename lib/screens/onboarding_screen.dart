import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isAnimating = false;
  String _selectedCountry = 'India';

  final Map<String, String> _countries = {
    'India': '₹',
    'United States': '\$',
    'United Kingdom': '£',
    'Europe': '€',
    'Japan': '¥',
    'Australia': 'A\$',
    'Canada': 'C\$',
    'China': '¥',
    'Russia': '₽',
    'Brazil': 'R\$',
  };

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() {
      _isAnimating = true;
    });

    try {
      // Save name and currency
      final provider = Provider.of<MoneyProvider>(context, listen: false);
      await provider.setUserName(_nameController.text.trim());
      await provider.setCurrency(_countries[_selectedCountry]!);

      // Wait for animation to finish then navigate
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error saving user name: $e');
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome to\nPennyWise',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 16),
                  Text(
                    'Your premium expense tracker.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 48),

                  // Card Animation Container
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The Card (Visible when NOT animating exit)
                        if (!_isAnimating)
                          _buildVisaCard().animate().slideX(
                            begin: -1.5,
                            end: 0,
                            duration: 800.ms,
                            curve: Curves.easeOutBack,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Input Field
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
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),

                  // Country Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountry,
                        isExpanded: true,
                        dropdownColor: AppTheme.surface,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white70,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        items: _countries.keys.map((String country) {
                          return DropdownMenuItem<String>(
                            value: country,
                            child: Row(
                              children: [
                                Text('${_countries[country]} '),
                                Text(country),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCountry = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 24),

                  // Continue Button
                  ElevatedButton(
                    onPressed: _isAnimating ? null : _startAnimation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppTheme.primary.withValues(alpha: 0.5),
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
                            'CONTINUE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0),
                ],
              ),
            ),
          ),

          // Exit Animation Overlay (Trail + Card)
          if (_isAnimating) ...[
            // Trail Layer 1 (Faded Purple)
            Positioned.fill(
              child: Center(
                child:
                    Transform.translate(
                      offset: const Offset(-40, 0), // Slight lag
                      child: Opacity(
                        opacity: 0.3,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.purple,
                            BlendMode.srcATop,
                          ),
                          child: _buildVisaCard(),
                        ),
                      ),
                    ).animate().moveX(
                      begin: 0,
                      end: 500,
                      duration: 700.ms,
                      curve: Curves.easeIn,
                    ),
              ),
            ),
            // Trail Layer 2 (Less Faded Purple)
            Positioned.fill(
              child: Center(
                child:
                    Transform.translate(
                      offset: const Offset(-20, 0), // Slight lag
                      child: Opacity(
                        opacity: 0.5,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.purpleAccent,
                            BlendMode.srcATop,
                          ),
                          child: _buildVisaCard(),
                        ),
                      ),
                    ).animate().moveX(
                      begin: 0,
                      end: 500,
                      duration: 650.ms,
                      curve: Curves.easeIn,
                    ),
              ),
            ),
            // Main Card
            Positioned.fill(
              child: Center(
                child: _buildVisaCard().animate().moveX(
                  begin: 0,
                  end: 500,
                  duration: 600.ms,
                  curve: Curves.easeIn,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisaCard() {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F38),
            const Color(0xFF2D3459),
            AppTheme.primary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 45,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFD4AF37),
                      Color(0xFFF7EF8A),
                      Color(0xFFD4AF37),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Text(
                'VISA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            _nameController.text.isEmpty
                ? 'YOUR NAME'
                : _nameController.text.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

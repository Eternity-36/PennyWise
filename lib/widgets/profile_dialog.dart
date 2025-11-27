import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur Effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          Center(
            child: Material(
              color: const Color(0xFF1A1F38),
              borderRadius: BorderRadius.circular(32),
              elevation: 20,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar
                        Hero(
                          tag: 'profile_ring',
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF2D3459),
                              backgroundImage: provider.photoURL != null
                                  ? NetworkImage(provider.photoURL!)
                                  : null,
                              child: provider.photoURL == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // User Name
                        Text(
                          provider.userName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                        const SizedBox(height: 8),

                        // Email/Account Type
                        Text(
                          provider.userId != null &&
                                  !provider.settingsBox.get(
                                    'isGuest',
                                    defaultValue: true,
                                  )
                              ? 'Google Account'
                              : 'Guest Account',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                        const SizedBox(height: 40),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Close dialog first
                              Navigator.pop(context);

                              // Sign out logic
                              await AuthService().signOut();
                              if (context.mounted) {
                                await provider.logout();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/onboarding',
                                    (route) => false,
                                  );
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'LOGOUT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.expense,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                      ],
                    ),

                    // Close Button
                    Positioned(
                      top: -16,
                      right: -16,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white54),
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

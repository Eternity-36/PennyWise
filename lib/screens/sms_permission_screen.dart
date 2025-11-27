import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

class SmsPermissionScreen extends StatelessWidget {
  const SmsPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      body: SafeArea(
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
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hero Icon
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.security,
                          size: 64,
                          color: AppTheme.primary,
                        ),
                      ).animate().scale(
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      ),

                      const SizedBox(height: 40),

                      // Title
                      const Text(
                        'SMS Permission',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ).animate().fadeIn().slideY(begin: 0.3),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'PennyWise needs access to your SMS messages to automatically track your expenses and bill reminders.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),

                      const SizedBox(height: 48),

                      // Features List
                      _buildFeatureRow(
                        Icons.lock_outline,
                        'Private & Secure',
                        'Your data never leaves your device',
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),

                      const SizedBox(height: 24),

                      _buildFeatureRow(
                        Icons.notifications_off_outlined,
                        'No Spam',
                        'We only read transactional messages',
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),

                      const SizedBox(height: 24),

                      _buildFeatureRow(
                        Icons.battery_charging_full,
                        'Battery Efficient',
                        'Optimized for minimal battery usage',
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                    ],
                  ),
                ),
              ),

              // Bottom Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grant Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Consumer<MoneyProvider>(
                        builder: (context, provider, _) {
                          return ElevatedButton(
                            onPressed: () async {
                              final status = await Permission.sms.request();

                              if (context.mounted) {
                                if (status.isGranted) {
                                  provider.setSmsTracking(true);
                                  // Start syncing SMS immediately
                                  provider.syncSmsTransactions();

                                  Navigator.pop(
                                    context,
                                  ); // Close permission screen
                                  Navigator.pop(
                                    context,
                                  ); // Close tracking screen to return to advanced settings
                                } else if (status.isPermanentlyDenied) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppTheme.surface,
                                      title: const Text(
                                        'Permission Required',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        'SMS permission is required to track transactions. Please enable it in settings.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            openAppSettings();
                                          },
                                          child: const Text('Open Settings'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: AppTheme.primary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            child: const Text(
                              'GRANT PERMISSION',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 1.0),

                    const SizedBox(height: 16),

                    // Footer Text
                    Text(
                      'You can revoke this permission at any time in settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
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
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

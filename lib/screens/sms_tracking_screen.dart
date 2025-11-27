import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import 'sms_permission_screen.dart';

class SmsTrackingScreen extends StatelessWidget {
  const SmsTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SMS Tracking',
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
        child: Consumer<MoneyProvider>(
          builder: (context, provider, _) {
            final isEnabled = provider.smsTrackingEnabled;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Spacer(),
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isEnabled
                              ? AppTheme.primary.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isEnabled
                                ? AppTheme.primary.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sms_outlined,
                        size: 64,
                        color: isEnabled ? AppTheme.primary : Colors.white54,
                      ),
                    ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),

                    const SizedBox(height: 40),

                    // Title
                    Text(
                      'SMS Transaction Tracking',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn().slideY(begin: 0.3),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Automatically read transaction SMS messages from banks and add them to your expenses. This feature requires SMS read permission.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),

                    const SizedBox(height: 32),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? AppTheme.income.withValues(alpha: 0.1)
                            : AppTheme.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isEnabled
                              ? AppTheme.income.withValues(alpha: 0.3)
                              : AppTheme.expense.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isEnabled
                                  ? AppTheme.income
                                  : AppTheme.expense,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEnabled ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: isEnabled
                                  ? AppTheme.income
                                  : AppTheme.expense,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const Spacer(),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isEnabled) {
                            provider.setSmsTracking(false);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SmsPermissionScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEnabled
                              ? AppTheme.expense
                              : AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isEnabled ? 'DISABLE FEATURE' : 'ENABLE FEATURE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isEnabled ? Colors.white : Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 1.0),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'models/budget.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/app_theme.dart';
import 'providers/money_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(BudgetAdapter());
  await Hive.openBox<Transaction>('transactions');
  final settingsBox = await Hive.openBox('settings');
  final userName = settingsBox.get('userName');

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MoneyProvider())],
      child: PennyWiseApp(
        initialRoute: userName != null ? '/home' : '/onboarding',
      ),
    ),
  );
}

class PennyWiseApp extends StatelessWidget {
  final String initialRoute;
  const PennyWiseApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PennyWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: initialRoute,
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

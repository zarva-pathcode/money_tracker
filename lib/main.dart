import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/budget_provider.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'providers/settings_provider.dart';
import 'providers/widget_provider.dart';
import 'package:home_widget/home_widget.dart';
import 'screens/add_expense_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  await NotificationService.init();
  await initializeDateFormatting('id_ID', null);

  final bool isFirstTime = HiveService.isFirstTime();

  runApp(MyApp(isFirstTime: isFirstTime));
}

class MyApp extends StatefulWidget {
  final bool isFirstTime;

  const MyApp({super.key, required this.isFirstTime});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupHomeWidget();
  }

  void _setupHomeWidget() {
    HomeWidget.widgetClicked.listen(_handleWidgetClick);
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetClick);
  }

  void _handleWidgetClick(Uri? uri) {
    if (uri != null && uri.scheme == 'expenseTracker' && uri.host == 'add') {
      final category = uri.queryParameters['category'];
      
      // Navigate to AddExpenseScreen
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(
            preSelectedCategory: category == 'empty' ? null : category,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => WidgetProvider()..initialSync()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Expense Tracker',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child:
                  widget.isFirstTime ? const OnboardingScreen() : const MainScreen(),
            );
          },
        ),
      ),
    );
  }
}

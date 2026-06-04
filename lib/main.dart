import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'providers/analysis_provider.dart';
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
Uri? pendingWidgetUri;
void Function()? onWidgetVoiceTrigger;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveService = HiveService();
  await hiveService.init();
  await NotificationService.init();
  await initializeDateFormatting('id_ID', null);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final bool isFirstTime = hiveService.isFirstTime();

  runApp(MyApp(isFirstTime: isFirstTime, hiveService: hiveService));
}

class MyApp extends StatefulWidget {
  final bool isFirstTime;
  final HiveService hiveService;

  const MyApp({
    super.key,
    required this.isFirstTime,
    required this.hiveService,
  });

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
    if (uri == null || uri.scheme != 'expensetracker') return;

    if (uri.host == 'widget' && uri.queryParameters['action'] == 'page') {
      final page = uri.queryParameters['value'] ?? '0';
      HomeWidget.saveWidgetData('recent_page', page).then((_) {
        HomeWidget.updateWidget(
          name: 'QuickRecentWidget',
          androidName: 'QuickRecentWidget',
          iOSName: 'QuickRecentWidget',
        );
      });
      return;
    }

    if (uri.host == 'add') {
      if (navigatorKey.currentState == null) {
        pendingWidgetUri = uri;
        return;
      }

      final voice = uri.queryParameters['voice'];
      if (voice == 'true') {
        final trigger = onWidgetVoiceTrigger;
        if (trigger != null) {
          trigger();
        } else {
          pendingWidgetUri = uri;
        }
        return;
      }

      final category = uri.queryParameters['category'];
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder:
              (context) => AddExpenseScreen(
                preSelectedCategory: category == 'empty' ? null : category,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hs = widget.hiveService;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider(hiveService: hs)),
        ChangeNotifierProvider(create: (ctx) => AnalysisProvider(expenseProvider: ctx.read<ExpenseProvider>())),
        ChangeNotifierProvider(create: (_) => PlanProvider(hiveService: hs)),
        ChangeNotifierProvider(create: (_) => BudgetProvider(hiveService: hs)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(hiveService: hs)),
        ChangeNotifierProvider(create: (_) => WidgetProvider(hiveService: hs)..initialSync()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Expense Tracker',
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child:
                  widget.isFirstTime
                      ? const OnboardingScreen()
                      : const MainScreen(),
            );
          },
        ),
      ),
    );
  }
}

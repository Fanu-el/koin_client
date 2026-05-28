import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/api_client.dart';
import 'data/services/auth_service.dart';
import 'data/services/budget_service.dart';
import 'data/services/chat_service.dart';
import 'data/services/finance_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/savings_goal_service.dart';
import 'data/services/token_service.dart';
import 'data/services/transaction_service.dart';
import 'providers/auth_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/savings_goal_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  debugPrint('Loaded .env API_BASE_URL=${dotenv.env['API_BASE_URL']}');
  debugPrint('Using API base URL: ${AppConstants.baseUrl}');

  // Configure cached_query global defaults
  CachedQuery.instance.configFlutter(
    config: QueryConfigFlutter(
      refetchOnResume: true,
      refetchOnConnection: true,
    ),
  );

  runApp(const KoinApp());
}

class KoinApp extends StatelessWidget {
  const KoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenService = TokenService();
    final apiClient = ApiClient(tokenService);

    return MultiProvider(
      providers: [
        // ── Services ────────────────────────────────────────────────────────
        Provider<TokenService>.value(value: tokenService),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>(
          create: (_) => AuthService(apiClient, tokenService),
        ),
        Provider<TransactionService>(
          create: (_) => TransactionService(apiClient),
        ),
        Provider<BudgetService>(
          create: (_) => BudgetService(apiClient),
        ),
        Provider<SavingsGoalService>(
          create: (_) => SavingsGoalService(apiClient),
        ),
        Provider<FinanceService>(
          create: (_) => FinanceService(apiClient),
        ),
        Provider<ChatService>(
          create: (_) => ChatService(apiClient),
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(apiClient),
        ),

        // ── State providers ──────────────────────────────────────────────────
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider()..initialize(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) => AuthProvider(
            ctx.read<AuthService>(),
            ctx.read<TokenService>(),
          )..initialize(),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (ctx) => DashboardProvider(ctx.read<FinanceService>()),
        ),
        ChangeNotifierProvider<TransactionProvider>(
          create: (ctx) => TransactionProvider(ctx.read<TransactionService>()),
        ),
        ChangeNotifierProvider<BudgetProvider>(
          create: (ctx) => BudgetProvider(ctx.read<BudgetService>()),
        ),
        ChangeNotifierProvider<SavingsGoalProvider>(
          create: (ctx) => SavingsGoalProvider(ctx.read<SavingsGoalService>()),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (ctx) => ChatProvider(ctx.read<ChatService>()),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (ctx) => NotificationProvider(ctx.read<NotificationService>()),
        ),
      ],
      child: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  late final _router = createRouter(context.read<AuthProvider>());
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  VoidCallback? _authListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final api = context.read<ApiClient>();
      final authService = context.read<AuthService>();
      final authProvider = context.read<AuthProvider>();

      api.setRefreshHandler(() async {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Refreshing session...'),
            duration: Duration(days: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        try {
          await authService.refreshToken();
          _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          return true;
        } catch (_) {
          _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          await authProvider.logout();
          return false;
        }
      });

      _authListener = () {
        if (authProvider.isAuthenticated) {
          try {
            context.read<DashboardProvider>().load(force: true);
          } catch (_) {}
          try {
            context.read<TransactionProvider>().load(refresh: true);
          } catch (_) {}
          try {
            context.read<BudgetProvider>().load();
          } catch (_) {}
          try {
            context.read<SavingsGoalProvider>().load();
          } catch (_) {}
          try {
            context.read<ChatProvider>().loadSessions();
          } catch (_) {}
          try {
            context.read<NotificationProvider>().load();
          } catch (_) {}
        }
      };
      authProvider.addListener(_authListener!);
    });
  }

  @override
  void dispose() {
    try {
      final authProvider = context.read<AuthProvider>();
      if (_authListener != null) authProvider.removeListener(_authListener!);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'Koin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

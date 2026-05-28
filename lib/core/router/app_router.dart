import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/auth/register_screen.dart';
import '../../ui/screens/auth/verify_email_screen.dart';
import '../../ui/screens/auth/forgot_password_screen.dart';
import '../../ui/screens/dashboard/dashboard_screen.dart';
import '../../ui/screens/transactions/transactions_screen.dart';
import '../../ui/screens/transactions/add_transaction_screen.dart';
import '../../ui/screens/budgets/budgets_screen.dart';
import '../../ui/screens/goals/goals_screen.dart';
import '../../ui/screens/chat/chat_list_screen.dart';
import '../../ui/screens/chat/chat_screen.dart';
import '../../ui/screens/profile/profile_screen.dart';
import '../../ui/screens/home/shell_screen.dart';

// Route name constants
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const dashboard = '/home/dashboard';
  static const transactions = '/home/transactions';
  static const addTransaction = '/home/transactions/add';
  static const budgets = '/home/budgets';
  static const goals = '/home/goals';
  static const chat = '/home/chat';
  static const chatSession = '/home/chat/:sessionId';
  static const profile = '/profile';
}

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final status = authProvider.status;
      final loc = state.matchedLocation;

      // Still initializing — stay on splash
      if (status == AuthStatus.unknown) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuth = status == AuthStatus.authenticated;
      final isPending = status == AuthStatus.pendingVerification;

      // Once resolved, redirect away from splash
      if (loc == AppRoutes.splash) {
        if (isAuth) return AppRoutes.dashboard;
        if (isPending) return AppRoutes.verifyEmail;
        return AppRoutes.login;
      }

      final isOnAuth = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgotPassword;
      final isOnVerify = loc == AppRoutes.verifyEmail;
      final isOnHome = loc.startsWith('/home') || loc == AppRoutes.profile;

      if (isAuth && (isOnAuth || isOnVerify)) return AppRoutes.dashboard;
      if (isPending && !isOnVerify) return AppRoutes.verifyEmail;
      if (!isAuth && !isPending && isOnHome) return AppRoutes.login;

      return null;
    },
    routes: [
      // ── Splash ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashScreen(),
      ),

      // ── Auth routes ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) {
          final email = context.read<AuthProvider>().pendingEmail ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // ── Profile (outside shell — has its own back button) ────────────────
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),

      // ── Shell: bottom nav ────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (_, __) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TransactionsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, __) => const AddTransactionScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.budgets,
            pageBuilder: (_, __) => const NoTransitionPage(
              child: BudgetsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.goals,
            pageBuilder: (_, __) => const NoTransitionPage(
              child: GoalsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.chat,
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ChatListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':sessionId',
                builder: (_, state) => ChatScreen(
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
            ],
          ),
        ],
      ),

      // Redirect bare /home → /home/dashboard
      GoRoute(
        path: AppRoutes.home,
        redirect: (_, __) => AppRoutes.dashboard,
      ),
    ],
  );
}

// Shown only while AuthProvider.initialize() is running
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logos/logo.png', width: 140),
                const SizedBox(height: 28),
                const Text(
                  'Koin',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your personal finance advisor for smarter spending, budgeting, and savings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_bloc_observer.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/services/auth_service.dart';

import 'features/candidate/ui/candidate_navigation.dart';
import 'features/root/ui/main_root_page.dart';
import 'features/auth/ui/login_page.dart';
import 'features/onboarding/ui/onboarding_page.dart';
import 'features/splash/ui/splash_screen.dart';
import 'core/theme/theme_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dnmtpwbfnptybciyqlcp.supabase.co',
    anonKey: 'sb_publishable_YdoBJ9r2kBi6kEgVF3LNtg_a39wBdvl',
  );

  Bloc.observer = AppBlocObserver();

  // Check onboarding status
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  // Initialize ThemeService
  await ThemeService().init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(authService: AuthService())..add(AuthCheckRequested()),
        ),
      ],
      child: MyApp(seenOnboarding: seenOnboarding),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool seenOnboarding;

  const MyApp({super.key, required this.seenOnboarding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Humana',
          navigatorKey: _navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: AuthWrapper(seenOnboarding: widget.seenOnboarding),
          routes: AppRouter.routes,
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final bool seenOnboarding;

  const AuthWrapper({super.key, required this.seenOnboarding});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late bool _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _hasSeenOnboarding = widget.seenOnboarding;
  }

  void _completeOnboarding() {
    setState(() {
      _hasSeenOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        // Only trigger if we were authenticated and now we are not
        return previous.status == AuthStatus.authenticated &&
            current.status == AuthStatus.unauthenticated;
      },
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green, // or a neutral color
            ),
          );
        }
      },
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildScreen(state),
        );
      },
    );
  }

  Widget _buildScreen(AuthState state) {
    if (state.status == AuthStatus.initial) {
      return const SplashScreen(key: ValueKey('splash'));
    }

    // If we have a user, stay in the authenticated view even during loading or error states
    // This prevents "flicking" to login page during profile updates
    if (state.user != null &&
        (state.status == AuthStatus.authenticated ||
            state.status == AuthStatus.loading ||
            state.status == AuthStatus.error)) {
      if (state.user!.role == 'candidate') {
        return CandidateNavigation(
          key: ValueKey('candidate_${state.user!.id}'),
        );
      }
      return MainRootPage(key: ValueKey('authenticated_${state.user!.id}'));
    }

    // Unauthenticated
    if (!_hasSeenOnboarding) {
      return OnboardingPage(
        key: const ValueKey('onboarding'),
        onDone: _completeOnboarding,
      );
    }

    return const LoginPage(key: ValueKey('login'));
  }
}

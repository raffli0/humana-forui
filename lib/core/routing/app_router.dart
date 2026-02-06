import 'package:flutter/material.dart';
import '../../features/onboarding/ui/onboarding_page.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/auth/ui/register_page.dart';
import '../../features/auth/ui/change_password_page.dart';

import '../../features/home/ui/profile_page.dart';
import '../../features/home/ui/settings_page.dart';

import '../../features/root/ui/main_root_page.dart';

import '../../features/attendance/ui/check_in_page.dart';
import '../../features/attendance/ui/attendance_history_page.dart';

import '../../features/notifications/ui/notifications_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String checkIn = '/check-in';
  static const String history = '/history';
  static const String notifications = '/notif';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String changePassword = '/change-password';
  static const String userReports = '/user-reports';

  static Map<String, WidgetBuilder> get routes => {
    onboarding: (context) => const OnboardingPage(),
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    home: (context) => const MainRootPage(),
    notifications: (context) => const NotificationPage(),
    profile: (context) => const ProfilePage(),
    settings: (context) => const SettingsPage(),
    changePassword: (context) => const ChangePasswordPage(),
    checkIn: (context) => const CheckInActionPage(),
    history: (context) => const AttendanceHistoryPage(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return null;
  }
}

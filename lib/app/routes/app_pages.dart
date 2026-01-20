import 'package:get/get.dart';
import 'package:grim_app/app/modules/auth/views/login_screen.dart';
import 'package:grim_app/app/modules/auth/views/signup_screen.dart';
import 'package:grim_app/app/modules/year_analytics/bindings/year_analytics_binding.dart';
import 'package:grim_app/app/modules/year_analytics/views/year_analytics_view.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/execution/bindings/execution_binding.dart';
import '../modules/execution/views/execution_view.dart';
import '../modules/goals/bindings/goals_binding.dart';
import '../modules/goals/views/goals_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/quarter/bindings/quarter_binding.dart';
import '../modules/quarter/views/quarter_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.onboarding;

  static final routes = [
    GetPage(
      name: _Paths.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: _Paths.auth,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.signUp,
      page: () => SignupScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: _Paths.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.goals,
      page: () => const GoalsView(),
      binding: GoalsBinding(),
    ),
    GetPage(
      name: _Paths.execution,
      page: () => const ExecutionSheetView(),
      binding: ExecutionBinding(),
    ),
    GetPage(
      name: _Paths.quarter,
      page: () => const QuarterView(),
      binding: QuarterBinding(),
    ),
    GetPage(
      name: _Paths.yearAnalytics,
      page: () => const YearAnalyticsView(),
      binding: YearAnalyticsBinding(),
    ),
  ];
}

import 'package:careerai_coach/data/models/models.dart';
import 'package:careerai_coach/features/analysis/career_analysis_screen.dart';
import 'package:careerai_coach/features/auth/auth_screen.dart';
import 'package:careerai_coach/features/auth/role_selection_screen.dart';
import 'package:careerai_coach/features/auth/splash_screen.dart';
import 'package:careerai_coach/features/dashboard/home_dashboard_screen.dart';
import 'package:careerai_coach/features/feedback/feedback_screen.dart';
import 'package:careerai_coach/features/pricing/pricing_screen.dart';
import 'package:careerai_coach/features/profile/profile_setup_screen.dart';
import 'package:careerai_coach/features/resume/resume_upload_screen.dart';
import 'package:careerai_coach/features/roadmap/roadmap_screen.dart';
import 'package:careerai_coach/features/roadmap/weekly_tasks_screen.dart';
import 'package:careerai_coach/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';

class CareerAiCoachApp extends StatelessWidget {
  const CareerAiCoachApp({super.key});

  static const String splashRoute = '/';
  static const String roleRoute = '/role';
  static const String authRoute = '/auth';
  static const String profileRoute = '/profile';
  static const String dashboardRoute = '/dashboard';
  static const String resumeRoute = '/resume';
  static const String analysisRoute = '/analysis';
  static const String roadmapRoute = '/roadmap';
  static const String weeklyRoute = '/weekly';
  static const String feedbackRoute = '/feedback';
  static const String settingsRoute = '/settings';
  static const String pricingRoute = '/pricing';

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B0B16);
    const surface = Color(0xFF151528);
    const surfaceSoft = Color(0xFF1B1B33);
    const primary = Color(0xFF9B30FF);
    const secondary = Color(0xFFD946EF);
    const tertiary = Color(0xFF5B5FE8);
    const outline = Color(0xFF303050);
    const text = Color(0xFFF5F1FF);
    const muted = Color(0xFFA7A0C8);

    final colorScheme = const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      onSurface: text,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      outline: outline,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceSoft,
        contentTextStyle: const TextStyle(color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: outline),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          shadowColor: const Color(0x889B30FF),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          backgroundColor: surfaceSoft.withValues(alpha: 0.6),
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: baseChipTheme(),
      dividerTheme: const DividerThemeData(
        color: outline,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        labelStyle: const TextStyle(
          color: muted,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: muted),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: 0.96),
        indicatorColor: primary.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        height: 78,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? text : muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
      ),
    );

    return MaterialApp(
      title: 'CareerAI Coach',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w700,
            color: text,
          ),
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w700,
            color: text,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w700,
            color: text,
            height: 1.05,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w700,
            color: text,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: text,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: text,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            color: muted,
            height: 1.5,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            color: muted,
            height: 1.45,
          ),
        ),
      ),
      initialRoute: splashRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case splashRoute:
            return _page(const SplashScreen());
          case roleRoute:
            return _page(const RoleSelectionScreen());
          case authRoute:
            return _page(const AuthScreen());
          case profileRoute:
            return _page(const ProfileSetupScreen());
          case dashboardRoute:
            return _page(const HomeDashboardScreen());
          case resumeRoute:
            return _page(const ResumeUploadScreen());
          case analysisRoute:
            return _page(const CareerAnalysisScreen());
          case roadmapRoute:
            return _page(const RoadmapScreen());
          case weeklyRoute:
            return _page(const WeeklyTasksScreen());
          case feedbackRoute:
            return _page(const FeedbackScreen());
          case settingsRoute:
            return _page(const SettingsScreen());
          case pricingRoute:
            return _page(const PricingScreen());
        }
        return _page(const SplashScreen());
      },
    );
  }

  PageRouteBuilder<void> _page(Widget child) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder:
          (context, animation, secondaryAnimation, transitionChild) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: transitionChild,
              ),
            );
          },
    );
  }
}

ChipThemeData baseChipTheme() {
  return ChipThemeData(
    backgroundColor: const Color(0xFF1C1C35),
    disabledColor: const Color(0xFF16162A),
    selectedColor: const Color(0x339B30FF),
    secondarySelectedColor: const Color(0x339B30FF),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    side: const BorderSide(color: Color(0xFF303050)),
    labelStyle: const TextStyle(
      color: Color(0xFFF5F1FF),
      fontWeight: FontWeight.w600,
    ),
    secondaryLabelStyle: const TextStyle(
      color: Color(0xFFF5F1FF),
      fontWeight: FontWeight.w600,
    ),
    brightness: Brightness.dark,
  );
}

String roleLabel(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'Студент';
    case UserRole.jobSeeker:
      return 'Соискатель';
    case UserRole.employerHr:
      return 'Работодатель / HR';
    case UserRole.university:
      return 'Университет / Карьерный центр';
  }
}

String planLabel(UserPlan plan) {
  switch (plan) {
    case UserPlan.free:
      return 'БЕСПЛАТНЫЙ';
    case UserPlan.premium:
      return 'ПРЕМИУМ';
    case UserPlan.b2b:
      return 'B2B';
  }
}

String taskStatusLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return 'В процессе';
    case TaskStatus.completed:
      return 'Выполнено';
  }
}

String taskPriorityLabel(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return 'Высокий';
    case TaskPriority.medium:
      return 'Средний';
    case TaskPriority.low:
      return 'Низкий';
  }
}

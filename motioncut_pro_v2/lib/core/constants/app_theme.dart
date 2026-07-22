import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceLight = Color(0xFF2A2A2A);
  static const primary = Color(0xFF00D4AA);
  static const primaryDark = Color(0xFF00A884);
  static const accent = Color(0xFFFF6B6B);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAA);
  static const divider = Color(0xFF333333);
  static const timelineBg = Color(0xFF111111);
  static const playhead = Color(0xFFFF4444);
  static const keyframe = Color(0xFFFFD700);
  static const effect = Color(0xFF9B59B6);
  static const filter = Color(0xFF3498DB);
  static const velocity = Color(0xFFE67E22);
  static const vector = Color(0xFF1ABC9C);
  static const shake = Color(0xFFE74C3C);
}

class AppDimens {
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const paddingSm = 8.0;
  static const paddingMd = 16.0;
  static const paddingLg = 24.0;
  static const toolbarHeight = 56.0;
  static const timelineHeight = 200.0;
  static const layerTrackHeight = 48.0;
  static const playheadWidth = 2.0;
}

class AppTheme {
  static ThemeData get dark => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          background: AppColors.background,
          onSurface: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardTheme(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.divider,
          thumbColor: AppColors.primary,
          overlayColor: AppColors.primary.withOpacity(0.2),
        ),
      );
}

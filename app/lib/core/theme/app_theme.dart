import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static String fontFor(Locale locale) =>
      locale.languageCode == 'ar' ? 'NotoKufiArabic' : 'Sen';

  /// Builds the theme for [locale]. Call [AppColors.setDark] first: the
  /// tokens below read the current palette.
  static ThemeData build(Locale locale, {bool dark = false}) {
    final font = fontFor(locale);
    final fallback = font == 'Sen' ? ['NotoKufiArabic'] : ['Sen'];
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      fontFamily: font,
      fontFamilyFallback: fallback,
      scaffoldBackgroundColor: AppColors.surface,
      canvasColor: AppColors.surface,
      cardColor: AppColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.danger,
      ),
      splashFactory: InkSparkle.splashFactory,
    );

    TextStyle t(double size, FontWeight w, Color c, {double? height}) =>
        TextStyle(fontSize: size, fontWeight: w, color: c, height: height);

    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            // "Spicy Restaurant", "Pizza Calzone European"
            headlineSmall: t(20, FontWeight.w700, AppColors.ink),
            // "Burger (10)", "20 Running Orders"
            titleLarge: t(20, FontWeight.w400, AppColors.ink),
            // page header title "Restaurant View"
            titleMedium: t(17, FontWeight.w400, AppColors.ink),
            // product card name
            titleSmall: t(15, FontWeight.w700, AppColors.ink),
            bodyLarge: t(16, FontWeight.w400, AppColors.ink),
            // descriptions
            bodyMedium: t(14, FontWeight.w400, AppColors.muted, height: 1.7),
            bodySmall: t(13, FontWeight.w400, AppColors.muted),
            // uppercase field labels "EMAIL", "ADDRESS"
            labelMedium: t(
              13,
              FontWeight.w400,
              AppColors.inkSoft,
            ).copyWith(letterSpacing: 0.6),
            labelLarge: t(
              14,
              FontWeight.w700,
              Colors.white,
            ).copyWith(letterSpacing: 0.4),
          )
          // Custom styles above don't carry a family; apply it to all.
          .apply(fontFamily: font, fontFamilyFallback: fallback),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        hintStyle: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          fontFamily: font,
          fontFamilyFallback: fallback,
        ),
        labelStyle: TextStyle(color: AppColors.body),
        // 62px tall fields, text inset 19-20px (Figma).
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 19,
          vertical: 21,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
      ),
      dividerTheme: DividerThemeData(color: AppColors.border),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        titleTextStyle: t(18, FontWeight.w700, AppColors.ink),
        contentTextStyle: t(15, FontWeight.w400, AppColors.ink, height: 1.4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      // Snack bars sit on the dark pill in both modes: white text.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.pill,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: font,
          fontFamilyFallback: fallback,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(color: AppColors.surface),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surface),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: AppColors.ink,
        iconColor: AppColors.inkSoft,
      ),
      iconTheme: IconThemeData(color: AppColors.ink),
    );
  }
}

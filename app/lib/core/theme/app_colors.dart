import 'package:flutter/material.dart';

/// Colour tokens from the Figma "Food Delivery App (Community)" kit, with
/// a dark variant for each one that changes in dark mode.
///
/// The brand colours (orange, red, green) are the same in both modes and
/// stay `const`. Every other token is a getter that reads the mode set by
/// [AppColors.setDark], which `FoodApp` calls before building the theme.
abstract final class AppColors {
  static bool _dark = false;

  /// True while the app shows the dark palette.
  static bool get isDark => _dark;

  /// Switches the palette. Called by `FoodApp` on every build, before the
  /// theme and the pages are built.
  static void setDark(bool dark) => _dark = dark;

  static Color _c(int light, int dark) => Color(_dark ? dark : light);

  // ---- brand, same in both modes ------------------------------------

  /// Main CTA: "ADD TO CART", "LOG IN", "SAVE LOCATION".
  static const primary = Color(0xFFFF7622);

  /// Selected chip, "+" on product cards, active tab.
  static const accent = Color(0xFFF58D1D);

  /// Auth/onboarding header background (Figma #121223). Dark in both modes.
  static const night = Color(0xFF121223);

  /// "Cancel" outline button on Running Orders, and errors.
  static const danger = Color(0xFFFF3326);
  static const success = Color(0xFF1DB954);

  // ---- text ----------------------------------------------------------

  /// Headings and main text (Figma #181C2E).
  static Color get ink => _c(0xFF181C2E, 0xFFF3F4F8);

  /// Field labels, onboarding titles, input text (Figma #32343E).
  static Color get inkSoft => _c(0xFF32343E, 0xFFE2E4EB);

  /// Body copy on onboarding / auth ("Don't have an account?", "Or").
  static Color get body => _c(0xFF646982, 0xFFA6ABBF);

  /// "Remember me" label.
  static Color get subtle => _c(0xFF7E8A97, 0xFF8A90A6);

  /// Secondary text, descriptions, placeholders.
  static Color get muted => _c(0xFFA0A5BA, 0xFF7B8197);

  // ---- surfaces ------------------------------------------------------

  /// Page background and cards.
  static Color get surface => _c(0xFFFFFFFF, 0xFF1B1F2A);

  /// Dashboard page background behind the cards (Seller Dashboard Home).
  static Color get canvas => _c(0xFFF6F8FA, 0xFF12151D);

  /// Input fill, unselected size chips, cart footer.
  static Color get field => _c(0xFFF0F5FA, 0xFF262B3A);

  static Color get border => _c(0xFFEBEBEB, 0xFF323849);

  /// Image placeholder grey used throughout the kit.
  static Color get placeholder => _c(0xFF98A8B8, 0xFF333A4D);

  /// Dark pill behind white text (quantity stepper, dark round buttons,
  /// snack bars). Stays dark in dark mode, just a little lighter.
  static Color get pill => _c(0xFF181C2E, 0xFF2A3042);

  // ---- tints ---------------------------------------------------------

  /// Soft orange used behind ingredient icons and selected tabs.
  static Color get primarySoft => _c(0xFFFFEBE4, 0xFF3B2A20);

  /// Inactive onboarding dot.
  static Color get primaryPale => _c(0xFFFFE1CE, 0xFF4A3427);

  /// Soft red behind warnings (cash overdue, cancelled order).
  static Color get dangerSoft => _c(0xFFFFE8E6, 0xFF3E2325);

  /// Checkbox border.
  static Color get checkboxBorder => _c(0xFFE3EBF2, 0xFF3A4152);
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 12.0; // inputs, buttons
  static const lg = 15.0; // cards
  static const xl = 24.0; // hero image, bottom sheets
  static const pill = 999.0;
}

abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0; // screen side padding in the design
  static const xxl = 32.0;
}

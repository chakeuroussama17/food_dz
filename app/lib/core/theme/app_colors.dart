import 'package:flutter/material.dart';

/// Colour tokens from the Figma "Food Delivery App (Community)" kit.
/// Auth/onboarding values are exact (from Figma design context); the rest
/// were measured from screen renders.
abstract final class AppColors {
  /// Main CTA: "ADD TO CART", "LOG IN", "SAVE LOCATION".
  static const primary = Color(0xFFFF7622);

  /// Selected chip, "+" on product cards, active tab.
  static const accent = Color(0xFFF58D1D);

  /// Headings, dark back button, login header, quantity stepper.
  static const ink = Color(0xFF181C2E);

  /// Field labels, onboarding titles, input text (Figma #32343E).
  static const inkSoft = Color(0xFF32343E);

  /// Auth/onboarding header background (Figma #121223).
  static const night = Color(0xFF121223);

  /// Body copy on onboarding / auth ("Don't have an account?", "Or").
  static const body = Color(0xFF646982);

  /// "Remember me" label.
  static const subtle = Color(0xFF7E8A97);

  /// Inactive onboarding dot.
  static const primaryPale = Color(0xFFFFE1CE);

  /// Checkbox border.
  static const checkboxBorder = Color(0xFFE3EBF2);

  /// Secondary text, descriptions, placeholders.
  static const muted = Color(0xFFA0A5BA);

  /// Input fill, unselected size chips, cart footer.
  static const field = Color(0xFFF0F5FA);

  /// Dashboard page background (Seller Dashboard Home).
  static const canvas = Color(0xFFF6F8FA);

  static const surface = Colors.white;
  static const border = Color(0xFFEBEBEB);

  /// Image placeholder grey used throughout the kit.
  static const placeholder = Color(0xFF98A8B8);

  /// "Cancel" outline button on Running Orders, and errors.
  static const danger = Color(0xFFFF3326);
  static const success = Color(0xFF1DB954);

  /// Soft orange used behind ingredient icons.
  static const primarySoft = Color(0xFFFFEBE4);
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

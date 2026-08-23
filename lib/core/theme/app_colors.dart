import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors — charcoal/near-black (Shopcart-style, monochrome)
  static const Color primary = Color(0xFF1A1A1A);
  static const Color primaryDark = Color(0xFF000000);
  static const Color primaryLight = Color(0xFF383838);
  static const Color primaryContainer = Color(0xFFEAEAEA);

  // Secondary — dark neutral (used for inverse surfaces, snackbars)
  static const Color secondary = Color(0xFF262626);
  static const Color secondaryDark = Color(0xFF121212);
  static const Color secondaryLight = Color(0xFF404040);
  static const Color secondaryContainer = Color(0xFFECECEC);

  // Accent — kept monochrome so the palette stays black-on-light
  static const Color accent = Color(0xFF333333);
  static const Color accentDark = Color(0xFF1A1A1A);
  static const Color accentLight = Color(0xFF4D4D4D);

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // Neutrals - Light Mode
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF4F4F5);
  static const Color onBackground = Color(0xFF111827);
  static const Color onSurface = Color(0xFF1F2937);
  static const Color onSurfaceVariant = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFE2E2E5);
  static const Color shadow = Color(0x14000000);

  // Neutrals - Dark Mode
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceVariant = Color(0xFF242424);
  static const Color darkOnBackground = Color(0xFFF9FAFB);
  static const Color darkOnSurface = Color(0xFFF3F4F6);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
  static const Color darkDivider = Color(0xFF2E2E2E);
  static const Color darkBorder = Color(0xFF3A3A3A);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Dark Text Colors
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextTertiary = Color(0xFF6B7280);

  // Special
  static const Color gold = Color(0xFFF5A623); // rating stars
  static const Color flash = Color(0xFFEF4444);
  static const Color new_ = Color(0xFF10B981);
  static const Color sale = Color(0xFFE11D48);
  static const Color shimmerBase = Color(0xFFEDEDED);
  static const Color shimmerHighlight = Color(0xFFF8F8F8);

  // Shopcart-style surfaces
  static const Color heroBackground = Color(0xFFFBEEE6); // warm cream/peach
  static const Color heroBackgroundAlt = Color(0xFFEFF1F0); // soft warm gray
  static const Color productImageBg = Color(0xFFF4F4F5); // product tile bg
  static const Color goldEdge = Color(0xFFE7B84B); // thin accent edge

  // Glassmorphism Presets
  static const Color glassBackgroundLight = Color(0x26FFFFFF);
  static const Color glassBackgroundDark = Color(0x1A000000);
  static const Color glassBorderLight = Color(0x4DFFFFFF);
  static const Color glassBorderDark = Color(0x26FFFFFF);

  static const LinearGradient glassGradientLight = LinearGradient(
    colors: [Color(0x4DFFFFFF), Color(0x1AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [Color(0x33000000), Color(0x0D000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient flashGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

import 'package:flutter/material.dart';
import '../brand/brand.dart';

/// The per-brand accent colours, read at runtime.
///
/// This exists alongside [AppColors] rather than replacing it. `AppColors` holds
/// 64 `static const` tokens with ~829 call sites, 63 of them inside `const`
/// expressions, plus two `const ColorScheme(...)` blocks — making those per-brand
/// would mean stripping `const` and fixing the cascade through every enclosing
/// const widget tree. So the shared monochrome palette stays exactly as it is and
/// only the handful of genuinely brand-coloured surfaces come from here.
///
/// Getters, not constants, because the value depends on which brand booted.
abstract final class BrandColors {
  /// The brand colour: logo tile, announcement bar, sale badges.
  static Color get accent => Brand.current.accents.accent;

  /// Pale tint of [accent], for containers and chips.
  static Color get accentSoft => Brand.current.accents.accentSoft;

  /// Text and icons drawn on [accent].
  static Color get onAccent => Brand.current.accents.onAccent;

  /// Wash behind the home hero.
  static Color get heroSurface => Brand.current.accents.heroSurface;
}

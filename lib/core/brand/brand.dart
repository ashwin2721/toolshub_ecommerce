import 'package:flutter/material.dart';

/// Which storefront this build is. Brand is fixed at launch by the entry point
/// (`lib/main.dart` for Apex Deals, `lib/main_toolshub.dart` for ToolsHub) and
/// never changes while the app runs.
enum BrandId { apexDeals, toolsHub }

/// Features that only make sense for some brands. Everything here is a *feature*
/// switch, not a wording switch — wording lives in [BrandCopy].
@immutable
class BrandFlags {
  /// The tool servicing / calibration booking screen, its route and its entry in
  /// the profile menu.
  final bool toolServiceBooking;

  /// The 46-entry tool-brand spellcheck dictionary in FuzzySearchHelper. When
  /// off, a shorter generic-commerce dictionary is used instead.
  final bool toolBrandTypoDictionary;

  /// The AI assistant acts as a contractor suggesting tools for a project, and
  /// maps keywords in its reply to tool product ids.
  final bool projectAssistant;

  const BrandFlags({
    required this.toolServiceBooking,
    required this.toolBrandTypoDictionary,
    required this.projectAssistant,
  });
}

/// The small set of colours that differ per brand.
///
/// Everything else comes from the shared monochrome palette in [AppColors],
/// which stays `static const` and untouched — see `lib/core/theme/brand_colors.dart`
/// for how these are read.
@immutable
class BrandAccents {
  /// The single brand colour: logo tile, announcement bar, sale badges.
  final Color accent;

  /// A pale tint of [accent] for containers and chips.
  final Color accentSoft;

  /// Text and icons drawn on top of [accent].
  final Color onAccent;

  /// Background wash behind the home hero.
  final Color heroSurface;

  const BrandAccents({
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.heroSurface,
  });
}

/// Brand wording. Anything a copywriter might change without a developer.
///
/// Deliberately NOT here: the announcement bar text and the hero title/subtitle/CTA.
/// Those already come from `storeSettingsProvider` and are editable in the admin
/// panel, so only their *fallbacks* appear below.
@immutable
class BrandCopy {
  final String tagline;
  final String footerBlurb;
  final List<String> footerShopLinks;
  final String aboutBlurb;
  final String registerPitch;

  /// Emoji used next to the register heading.
  final String emoji;

  final String searchHint;
  final String forYouHeading;
  final String allCategoriesLabel;
  final String categoryFilterLabel;

  /// Label for the quantity-break pricing table ("Contractor Bulk" vs "Bulk Buy").
  final String bulkPricingLabel;

  /// Shown only when the backend has no storeSettings row yet.
  final String heroTitleFallback;
  final String announcementFallback;

  /// Emoji and image used for a category the storefront has no artwork for.
  final String categoryFallbackEmoji;
  final String categoryFallbackImageUrl;

  final String assistantGreeting;
  final String assistantOfflineMessage;

  const BrandCopy({
    required this.tagline,
    required this.footerBlurb,
    required this.footerShopLinks,
    required this.aboutBlurb,
    required this.registerPitch,
    required this.emoji,
    required this.searchHint,
    required this.forYouHeading,
    required this.allCategoriesLabel,
    required this.categoryFilterLabel,
    required this.bulkPricingLabel,
    required this.heroTitleFallback,
    required this.announcementFallback,
    required this.categoryFallbackEmoji,
    required this.categoryFallbackImageUrl,
    required this.assistantGreeting,
    required this.assistantOfflineMessage,
  });
}

/// Everything that makes this build one storefront rather than another.
///
/// Adding a third brand means adding one const [Brand] in `brands.dart`, one
/// entry point, and one Gradle product flavour — no hunting for string literals.
/// Because every field is `required`, the compiler refuses a brand that forgets one.
@immutable
class Brand {
  final BrandId id;

  /// Token used by the Gradle product flavour, the web build script and the
  /// `brand` field sent to the AI assistant endpoint.
  final String key;

  /// Human name, e.g. 'Apex Deals'. Used for the window/tab title.
  final String displayName;

  /// All-caps wordmark drawn in the header, footer, login and admin sidebar.
  final String wordmark;

  /// Icon standing in for the logo and for products with no image.
  final IconData markIcon;

  final String legalEntity;
  final String supportEmail;
  final String privacyEmail;
  final String supportPhone;
  final String postalAddress;
  final String businessHours;

  /// Each brand is a separate shop with its own catalogue, so each has its own
  /// backend. Two named fields rather than a map, so this stays const and the
  /// compiler enforces that both are supplied.
  final String apiBaseUrlDev;
  final String apiBaseUrlProd;

  final String currencySymbol;

  final BrandAccents accents;
  final BrandFlags flags;
  final BrandCopy copy;

  const Brand({
    required this.id,
    required this.key,
    required this.displayName,
    required this.wordmark,
    required this.markIcon,
    required this.legalEntity,
    required this.supportEmail,
    required this.privacyEmail,
    required this.supportPhone,
    required this.postalAddress,
    required this.businessHours,
    required this.apiBaseUrlDev,
    required this.apiBaseUrlProd,
    required this.currencySymbol,
    required this.accents,
    required this.flags,
    required this.copy,
  });

  /// The copyright line, composed so the year and entity cannot drift apart.
  String copyrightLine(int year) =>
      '© $year $legalEntity — ${copy.tagline}.';

  // ── The active brand ──────────────────────────────────────────────────────
  //
  // A plain static rather than a Riverpod provider: the brand is fixed by the
  // entry point before runApp and cannot change at runtime, so there is nothing
  // for a provider to react to. Several read sites sit in static lists and
  // helper methods with no BuildContext in scope, and routing them through a
  // provider would mean converting a dozen const StatelessWidgets for a value
  // that never moves.
  static Brand? _current;

  /// Set once by `bootstrap()` before `runApp`. Tests assign it in `setUp`.
  static set current(Brand brand) => _current = brand;

  static Brand get current {
    final brand = _current;
    if (brand == null) {
      // Deliberately a hard failure rather than defaulting to a brand: silently
      // falling back is how the old AppConfig shipped the wrong storefront when
      // its FLAVOR value was unrecognised.
      throw StateError(
        'Brand.current was read before bootstrap() ran. Launch via '
        'lib/main.dart (Apex Deals) or lib/main_toolshub.dart (ToolsHub), '
        'or assign Brand.current in your test setUp.',
      );
    }
    return brand;
  }
}

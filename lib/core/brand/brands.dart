import 'package:flutter/material.dart';
import 'brand.dart';

// Both brands live in one file on purpose: "what differs between the storefronts"
// is the question you actually ask here, and side-by-side is the only layout that
// answers it. Adding a third brand means adding a third const below.

/// Apex Deals — general deals storefront. The DEFAULT brand (`lib/main.dart`).
const Brand kApexDeals = Brand(
  id: BrandId.apexDeals,
  key: 'apexdeals',
  displayName: 'Apex Deals',
  wordmark: 'APEX DEALS',
  markIcon: Icons.local_offer_rounded,

  legalEntity: 'Apex Deals Retail Pvt. Ltd.',
  supportEmail: 'support@apexdeals.com',
  privacyEmail: 'privacy@apexdeals.com',
  supportPhone: '+91 1800-XXX-XXXX',
  postalAddress: '123, Industrial Area, Mumbai - 400001',
  businessHours: 'Mon-Sat: 9AM to 6PM IST',

  // TODO(owner): point this at the Apex Deals backend once it is deployed. Until
  // then this brand reads the ToolsHub catalogue, which is wrong but harmless.
  apiBaseUrlDev: 'http://localhost:5005/api',
  apiBaseUrlProd: 'https://toolshub-ecommerce.onrender.com/api',

  currencySymbol: '₹',

  accents: BrandAccents(
    accent: Color(0xFFE11D48), // crimson — a deals shop reads as "sale"
    accentSoft: Color(0xFFFFE4E8),
    onAccent: Color(0xFFFFFFFF),
    heroSurface: Color(0xFFFFF1F2),
  ),

  // A general storefront has none of the tool-shop machinery.
  flags: BrandFlags(
    toolServiceBooking: false,
    toolBrandTypoDictionary: false,
    projectAssistant: false,
  ),

  copy: BrandCopy(
    tagline: 'Everyday Deals, Delivered Fast',
    footerBlurb:
        'Your everyday deals store. Great brands at great prices, delivered fast.',
    footerShopLinks: ['Top Deals', 'New Arrivals', 'Best Sellers', 'Clearance'],
    aboutBlurb:
        'Apex Deals is an online marketplace bringing you everyday essentials and '
        'standout offers across every category. We serve shoppers across the country.'
        '\n\nOur commitment is to provide quality products from trusted brands at the '
        'best prices, backed by excellent customer service.',
    registerPitch: 'Join APEX DEALS and shop the best offers',
    emoji: '🛒',
    searchHint: 'Search products, brands, categories...',
    forYouHeading: 'Picked For You!',
    allCategoriesLabel: 'All Deals',
    categoryFilterLabel: 'Category',
    bulkPricingLabel: 'Bulk Buy',
    heroTitleFallback: 'Grab Upto 50% Off On Selected Deals',
    announcementFallback: 'Get 50% Off on Selected Items',
    categoryFallbackEmoji: '🛍️',
    categoryFallbackImageUrl:
        'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=500&auto=format&fit=crop&q=80',
    assistantGreeting: 'Hello! I am your APEX DEALS Shopping Assistant.\n\n'
        'Tell me what you are shopping for and I will suggest what to buy.',
    assistantOfflineMessage:
        'I am offline right now. Please try again in a moment, or browse the '
        'categories on the home page.',
  ),
);

/// ToolsHub — tools & hardware storefront (`lib/main_toolshub.dart`).
///
/// Every string below is copied verbatim from what the app shipped before
/// flavours existed, so the ToolsHub build is a provable no-op on wording. The
/// accents are the one intentional change (previously the logo used the shared
/// charcoal).
const Brand kToolsHub = Brand(
  id: BrandId.toolsHub,
  key: 'toolshub',
  displayName: 'ToolsHub',
  wordmark: 'TOOLSHUB',
  markIcon: Icons.handyman_rounded,

  legalEntity: 'TOOLSHUB Technologies Pvt. Ltd.',
  supportEmail: 'support@toolshub.com',
  privacyEmail: 'privacy@toolshub.com',
  supportPhone: '+91 1800-XXX-XXXX',
  postalAddress: '123, Industrial Area, Mumbai - 400001',
  businessHours: 'Mon-Sat: 9AM to 6PM IST',

  apiBaseUrlDev: 'http://localhost:5005/api',
  apiBaseUrlProd: 'https://toolshub-ecommerce.onrender.com/api',

  currencySymbol: '₹',

  accents: BrandAccents(
    accent: Color(0xFFF59E0B), // amber — workshop/industrial
    accentSoft: Color(0xFFFEF3C7),
    onAccent: Color(0xFF1A1A1A),
    heroSurface: Color(0xFFFBEEE6), // the previous AppColors.heroBackground
  ),

  flags: BrandFlags(
    toolServiceBooking: true,
    toolBrandTypoDictionary: true,
    projectAssistant: true,
  ),

  copy: BrandCopy(
    tagline: 'Professional Tools & Hardware',
    footerBlurb:
        'Your professional tools & hardware store. Quality gear for every job, delivered fast.',
    footerShopLinks: ['Power Tools', 'Hand Tools', 'Safety Gear', 'Deals'],
    aboutBlurb:
        'TOOLSHUB is India\'s leading online marketplace for professional tools, '
        'hardware, and equipment. We serve millions of professionals, craftsmen, and '
        'DIY enthusiasts across the country.\n\nOur commitment is to provide the '
        'highest quality tools from top brands at the best prices, backed by '
        'excellent customer service.',
    registerPitch: 'Join TOOLSHUB and shop the best tools',
    emoji: '🛠️',
    searchHint: 'Search tools, brands, categories...',
    forYouHeading: 'Tools For You!',
    allCategoriesLabel: 'All Tools',
    categoryFilterLabel: 'Tool Type',
    bulkPricingLabel: 'Contractor Bulk',
    heroTitleFallback: 'Grab Upto 50% Off On Selected Power Tools',
    announcementFallback: 'Get 50% Off on Selected Items',
    categoryFallbackEmoji: '🛠️',
    categoryFallbackImageUrl:
        'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&auto=format&fit=crop&q=80',
    assistantGreeting: 'Hello! I am your TOOLSHUB Project Assistant.\n\n'
        'Describe your project and I will suggest the tools and materials you need.',
    assistantOfflineMessage:
        'I am offline right now. Please try again in a moment, or browse the '
        'categories on the home page.',
  ),
);

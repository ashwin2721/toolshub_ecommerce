import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class HeroBannerSlider extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  const HeroBannerSlider({super.key, required this.banners});

  @override
  State<HeroBannerSlider> createState() => _HeroBannerSliderState();
}

class _HeroBannerSliderState extends State<HeroBannerSlider> {
  int _current = 0;

  // Demo banners when no data from Firestore
  List<Map<String, dynamic>> get _effectiveBanners =>
      widget.banners.isNotEmpty
          ? widget.banners
          : [
              {
                'imageUrl': 'https://placehold.co/800x300/FF6B00/FFFFFF?text=Power+Tools+Sale+50%25+OFF',
                'title': 'Power Tools Sale',
                'subtitle': 'Up to 50% off on all power tools',
                'actionUrl': '/products?category=power_tools',
              },
              {
                'imageUrl': 'https://placehold.co/800x300/1A2340/FFFFFF?text=New+Arrivals+🆕',
                'title': 'New Arrivals',
                'subtitle': 'Fresh stock just added',
                'actionUrl': '/products?new=true',
              },
              {
                'imageUrl': 'https://placehold.co/800x300/1A1A1A/FFFFFF?text=Free+Shipping+Over+₹4999',
                'title': 'Free Shipping',
                'subtitle': 'On all orders above ₹4,999',
                'actionUrl': '/products',
              },
            ];

  @override
  Widget build(BuildContext context) {
    final banners = _effectiveBanners;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: banners.length,
            options: CarouselOptions(
              height: 180,
              viewportFraction: 0.92,
              enlargeCenterPage: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayCurve: Curves.easeInOut,
              onPageChanged: (i, _) => setState(() => _current = i),
            ),
            itemBuilder: (context, index, realIndex) {
              final banner = banners[index];
              return _BannerCard(
                banner: banner,
                onTap: () {
                  final url = banner['actionUrl'] as String?;
                  if (url != null) context.push(url);
                },
              );
            },
          ),
          const SizedBox(height: 10),
          AnimatedSmoothIndicator(
            activeIndex: _current,
            count: banners.length,
            effect: const ExpandingDotsEffect(
              dotHeight: 6,
              dotWidth: 6,
              activeDotColor: AppColors.primary,
              dotColor: AppColors.divider,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> banner;
  final VoidCallback onTap;

  const _BannerCard({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: banner['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.primary,
                  child: Center(
                    child: Text(banner['title'] ?? 'TOOLSHUB',
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (banner['title'] != null)
                        Text(banner['title'],
                            style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      if (banner['subtitle'] != null)
                        Text(banner['subtitle'],
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

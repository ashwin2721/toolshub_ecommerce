import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/category_entity.dart';

class CategoryGrid extends StatelessWidget {
  final List<CategoryEntity> categories;
  const CategoryGrid({super.key, required this.categories});

  static const _icons = {
    'power_tools': '⚡',
    'hand_tools': '🔨',
    'measuring_tools': '📏',
    'electrical_tools': '🔌',
    'safety_equipment': '🦺',
    'welding_equipment': '🔥',
    'plumbing_tools': '🔧',
    'gardening_tools': '🌱',
    'tool_storage': '📦',
    'industrial_equipment': '🏭',
  };

  static const _fallbackImages = {
    'power_tools': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80',
    'hand_tools': 'https://images.unsplash.com/photo-1530124566582-ab0510491570?w=500&auto=format&fit=crop&q=80',
    'measuring_tools': 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=500&auto=format&fit=crop&q=80',
    'safety_equipment': 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=500&auto=format&fit=crop&q=80',
    'tool_storage': 'https://images.unsplash.com/photo-1581244277943-fe4a9c777189?w=500&auto=format&fit=crop&q=80',
    'electrical_tools': 'https://images.unsplash.com/photo-1498084393753-b411b2d26b34?w=500&auto=format&fit=crop&q=80',
    'industrial_equipment': 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=500&auto=format&fit=crop&q=80',
  };

  @override
  Widget build(BuildContext context) {
    final effective = categories.isNotEmpty ? categories : _fallbackCategories;

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: effective.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = effective[i];
          final icon = _icons[cat.id] ?? '🛠️';
          final fallbackImg = _fallbackImages[cat.id] ?? 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&auto=format&fit=crop&q=80';
          final imageUrl = (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) ? cat.imageUrl! : fallbackImg;

          return _InteractiveCard(
            onTap: () => context.push('${AppRoutes.productList}?category=${cat.id}'),
            child: Container(
              width: 124,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // Background Image
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.shimmerBase,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.broken_image, color: Colors.white30),
                      ),
                    ),

                    // Dark Linear Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),

                    // Glassmorphic Emoji Badge (Top Left)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                            ),
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Category Details (Bottom Left)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.2,
                              height: 1.2,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            cat.productCount > 0 ? '${cat.productCount} Products' : 'View products',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                              fontSize: 9.5,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static final _fallbackCategories = [
    const CategoryEntity(
        id: 'power_tools',
        name: 'Power Tools',
        slug: 'power-tools',
        productCount: 6),
    const CategoryEntity(
        id: 'hand_tools',
        name: 'Hand Tools',
        slug: 'hand-tools',
        productCount: 6),
    const CategoryEntity(
        id: 'measuring_tools',
        name: 'Measuring Tools',
        slug: 'measuring-tools',
        productCount: 3),
    const CategoryEntity(
        id: 'safety_equipment',
        name: 'Safety Gear',
        slug: 'safety-equipment',
        productCount: 3),
    const CategoryEntity(
        id: 'tool_storage',
        name: 'Tool Storage',
        slug: 'tool-storage',
        productCount: 3),
  ];
}

class _InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _InteractiveCard({required this.child, required this.onTap});

  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

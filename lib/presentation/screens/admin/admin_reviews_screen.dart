import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Loads every product review (admin-only) from `GET /api/reviews`,
/// newest first.
final adminReviewsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/reviews');
  return response.data as List<dynamic>;
});

/// Admin screen listing all customer product reviews. Renders inside the
/// AdminShell.
class AdminReviewsScreen extends ConsumerWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(adminReviewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(adminReviewsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load reviews: $err',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(adminReviewsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return const Center(
              child: Text('No reviews yet',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = Map<String, dynamic>.from(reviews[index] as Map);
              return _ReviewCard(review: review);
            },
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productName = (review['productName'] ?? '').toString();
    final userName = (review['userName'] ?? '').toString();
    final comment = (review['comment'] ?? '').toString();
    final ratingRaw = review['rating'];
    final rating = (ratingRaw is num) ? ratingRaw.round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName.isEmpty ? 'Product' : productName,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final filled = i < rating;
              return Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppColors.gold,
                size: 20,
              );
            }),
          ),
          const SizedBox(height: 6),
          if (userName.isNotEmpty)
            Text(
              userName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
            ),
          ],
        ],
      ),
    );
  }
}

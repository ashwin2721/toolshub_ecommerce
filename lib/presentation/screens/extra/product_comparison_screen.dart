import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/store_chrome.dart';

// ── Shared back affordance ────────────────────────────────────────────────────
class _BackLink extends StatelessWidget {
  const _BackLink();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: const Text('Back'),
      ),
    );
  }
}

// ── Product Comparison Screen ──────────────────────────────────────────────────
class ProductComparisonScreen extends ConsumerWidget {
  const ProductComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(comparisonProvider);

    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackLink(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Compare Products',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                if (ids.isNotEmpty)
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(comparisonProvider.notifier).clear(),
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Clear all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (ids.isEmpty)
              const _CompareEmptyState()
            else
              _CompareBoard(ids: ids),
          ],
        ),
      ),
    );
  }
}

// Empty state shown when nothing has been added to the comparison yet.
class _CompareEmptyState extends StatelessWidget {
  const _CompareEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows_rounded,
                size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Add up to 3 products to compare',
                textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text('Tap the compare icon on any product to add it here.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// Horizontally-scrolling row of fixed-width comparison columns. The horizontal
// scroll keeps things from overflowing on both narrow phones and when all
// three columns are present on desktop.
class _CompareBoard extends StatelessWidget {
  final List<String> ids;

  const _CompareBoard({required this.ids});

  @override
  Widget build(BuildContext context) {
    final colWidth = context.isMobile ? 240.0 : 280.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final id in ids)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: colWidth,
                child: _CompareColumn(productId: id),
              ),
            ),
        ],
      ),
    );
  }
}

// A single product column: image, name/brand/price, rating, stock, a few spec
// rows, plus remove (X) and Add to Cart actions.
class _CompareColumn extends ConsumerWidget {
  final String productId;

  const _CompareColumn({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(productDetailProvider(productId));

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: async.when(
        loading: () => const SizedBox(
          height: 360,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) =>
            _message(context, ref, 'Failed to load product'),
        data: (product) => product == null
            ? _message(context, ref, 'Product not found')
            : _content(context, ref, theme, product),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, ThemeData theme,
      ProductEntity product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image on a light gray tile with a remove (X) affordance.
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.productImageBg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                  child: product.primaryImage != null
                      ? CachedNetworkImage(
                          imageUrl: product.primaryImage!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const _CompareImagePlaceholder(),
                        )
                      : const _CompareImagePlaceholder(),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _RemoveBtn(productId: product.id),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${product.effectivePrice.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (product.hasDiscount) ...[
                    const SizedBox(width: 6),
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '-${product.discountPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.flash,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  RatingBarIndicator(
                    rating: product.rating,
                    itemBuilder: (_, __) =>
                        const Icon(Icons.star, color: AppColors.gold),
                    itemCount: 5,
                    itemSize: 14,
                  ),
                  const SizedBox(width: 5),
                  Text('(${product.reviewCount})',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.textTertiary)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.inStock
                      ? AppColors.successContainer
                      : AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.inStock
                      ? (product.isLowStock
                          ? 'Only ${product.stockQuantity} left'
                          : 'In Stock')
                      : 'Out of Stock',
                  style: TextStyle(
                    color: product.inStock
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 10),
              _specRow('Category', product.categoryName),
              _specRow('Brand', product.brandName),
              _specRow('Price', '₹${product.price.toStringAsFixed(0)}'),
              if (product.rating > 0)
                _specRow('Rating', '${product.rating.toStringAsFixed(1)} / 5'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: product.inStock
                      ? () {
                          ref.read(cartProvider.notifier).addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to cart!'),
                              duration: Duration(seconds: 1),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                      product.inStock ? 'Add to Cart' : 'Out of Stock',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // Fallback card body for a product id that failed to load or no longer
  // exists — still offers a way to remove it from the comparison.
  Widget _message(BuildContext context, WidgetRef ref, String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _RemoveBtn(productId: productId),
          ),
          const SizedBox(height: 8),
          const Icon(Icons.error_outline_rounded,
              color: AppColors.textTertiary, size: 32),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// Small white circular X chip that removes a product from the comparison.
class _RemoveBtn extends ConsumerWidget {
  final String productId;

  const _RemoveBtn({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => ref.read(comparisonProvider.notifier).toggle(productId),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.close_rounded,
              size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _CompareImagePlaceholder extends StatelessWidget {
  const _CompareImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.productImageBg,
      child: const Center(
        child: Icon(Icons.handyman_outlined,
            size: 40, color: AppColors.textTertiary),
      ),
    );
  }
}

// ── Support Ticket Screen ─────────────────────────────────────────────────────
class SupportTicketScreen extends ConsumerStatefulWidget {
  const SupportTicketScreen({super.key});

  @override
  ConsumerState<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends ConsumerState<SupportTicketScreen> {
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';
  bool _submitting = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectCtrl.text.trim();
    final message = _descCtrl.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a subject and description.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/support-tickets', data: {
        'subject': subject,
        'message': message,
        'category': _priority,
      });
      final code = response.statusCode ?? 0;
      final ok = code >= 200 && code < 300;
      if (!mounted) return;
      if (ok) {
        final ticketId = response.data is Map ? response.data['ticketId'] : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ticketId != null
                ? 'Ticket submitted! Reference: $ticketId'
                : 'Ticket submitted! We\'ll get back to you soon.'),
            backgroundColor: AppColors.success,
          ),
        );
        _subjectCtrl.clear();
        _descCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit ticket. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit ticket. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackLink(),
            Text('Support Ticket',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Text('How can we help you?',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                  labelText: 'Subject', prefixIcon: Icon(Icons.subject)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                  labelText: 'Description', alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            Text('Priority',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['low', 'medium', 'high']
                  .map((p) => ChoiceChip(
                        label: Text(p.toUpperCase()),
                        selected: _priority == p,
                        onSelected: (_) => setState(() => _priority = p),
                        selectedColor: p == 'high'
                            ? AppColors.errorContainer
                            : AppColors.primaryContainer,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_submitting ? 'Submitting...' : 'Submit Ticket'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAQ Screen ────────────────────────────────────────────────────────────────
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faqs = [
    ('How do I track my order?', 'Go to My Orders → Order Details → Track Order to see live status updates.'),
    ('What is the return policy?', 'We offer 7-day easy returns on most products. Contact support to initiate.'),
    ('Which payment methods are accepted?', 'We accept Razorpay (cards/UPI/netbanking), Stripe, PayPal, UPI, and Cash on Delivery.'),
    ('How long does delivery take?', 'Standard: 5-7 business days. Express: 2-3 business days.'),
    ('Is GST invoice available?', 'Yes! You can download a GST invoice from your order details page.'),
    ('How do I apply a coupon?', 'Go to Cart → enter your coupon code and click Apply.'),
    ('Can I cancel my order?', 'Orders can be cancelled before they are shipped. Go to Order Details → Cancel Order.'),
    ('How do I contact support?', 'Use the Support Ticket system or email us at support@toolshub.com'),
  ];

  @override
  Widget build(BuildContext context) {
    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackLink(),
            Text(
              'FAQ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            for (final faq in _faqs)
              Card(
                child: ExpansionTile(
                  title: Text(faq.$1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(faq.$2,
                        style: const TextStyle(
                            color: AppColors.textSecondary, height: 1.5))
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Contact Screen ────────────────────────────────────────────────────────────
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackLink(),
            Text(
              'Contact Us',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 48),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Get in Touch',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18)),
                        Text('We\'re here to help you',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...[
              (Icons.email_outlined, 'Email', 'support@toolshub.com'),
              (Icons.phone_outlined, 'Phone', '+91 1800-XXX-XXXX'),
              (Icons.location_on_outlined, 'Address',
                  '123, Industrial Area, Mumbai - 400001'),
              (Icons.access_time_outlined, 'Hours', 'Mon-Sat: 9AM to 6PM IST'),
            ].map((item) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(item.$1, color: AppColors.primary, size: 20),
                  ),
                  title: Text(item.$2,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(item.$3),
                )),
          ],
        ),
      ),
    );
  }
}

// ── About Screen ──────────────────────────────────────────────────────────────
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackLink(),
            Text(
              'About TOOLSHUB',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Center(
                      child: Icon(Icons.handyman_outlined,
                          size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('TOOLSHUB',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: AppColors.primary)),
                  const Text('Professional Tools & Hardware Store',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  const Text('Version 1.0.0',
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('About Us',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'TOOLSHUB is India\'s leading online marketplace for professional tools, hardware, and equipment. We serve millions of professionals, craftsmen, and DIY enthusiasts across the country.\n\nOur commitment is to provide the highest quality tools from top brands at the best prices, backed by excellent customer service.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                _StatBadge('100K+', 'Products'),
                _StatBadge('1M+', 'Customers'),
                _StatBadge('500+', 'Brands'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value, label;
  const _StatBadge(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppColors.primary)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Privacy Policy Screen ─────────────────────────────────────────────────────
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackLink(),
            Text('Privacy Policy',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Last updated: June 2026',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            ...[
              ('Information We Collect', 'We collect personal information like name, email, phone, address, and payment information when you register or make purchases on our platform.'),
              ('How We Use Your Information', 'Your information is used to process orders, provide customer support, send order updates, and improve our services.'),
              ('Data Security', 'We use industry-standard encryption (SSL/TLS) to protect your data. Payment information is processed through secure third-party gateways.'),
              ('Cookies', 'We use cookies to enhance your experience, remember preferences, and analyze traffic. You can disable cookies in your browser settings.'),
              ('Contact', 'For privacy concerns, email us at privacy@toolshub.com'),
            ].map((section) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.$1,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(section.$2,
                        style: const TextStyle(
                            color: AppColors.textSecondary, height: 1.6)),
                    const SizedBox(height: 16),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

// ── Terms & Conditions Screen ─────────────────────────────────────────────────
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackLink(),
            Text('Terms & Conditions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('By using TOOLSHUB, you agree to these terms.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ...[
              ('1. Account', 'You must be 18+ to create an account. You are responsible for maintaining account confidentiality.'),
              ('2. Orders', 'Orders are subject to product availability. We reserve the right to cancel orders due to pricing errors.'),
              ('3. Returns', '7-day returns on most items. Products must be unused and in original packaging.'),
              ('4. Payments', 'All prices are in INR. Payment must be completed before order processing.'),
              ('5. Limitation of Liability', 'TOOLSHUB is not liable for indirect or incidental damages arising from use of our service.'),
            ].map((t) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$1,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(t.$2,
                        style: const TextStyle(
                            color: AppColors.textSecondary, height: 1.6)),
                    const SizedBox(height: 12),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/product_entity.dart';
import '../../widgets/common/store_chrome.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../../core/utils/external_link_helper.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String> recommendedProductIds;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.recommendedProductIds = const [],
  });
}

class GeminiAssistantScreen extends ConsumerStatefulWidget {
  const GeminiAssistantScreen({super.key});

  @override
  ConsumerState<GeminiAssistantScreen> createState() => _GeminiAssistantScreenState();
}

class _GeminiAssistantScreenState extends ConsumerState<GeminiAssistantScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;
  final _dio = Dio();

  // Client-side API Key fallback - can be set via --dart-define=GEMINI_API_KEY=xxx
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(ChatMessage(
      text: "Hello! I am your TOOLSHUB Project Assistant.\n\n"
          "Describe your construction or home improvement project (e.g. 'I need to mount a TV' or 'drywall partition installation'), and I will suggest the exact tools and materials you'll need, with direct links to add them to your cart!",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<String> _extractProductIds(String text) {
    final ids = <String>[];
    final lower = text.toLowerCase();
    
    if (lower.contains('drill') || lower.contains('drilling') || lower.contains('bosch drill')) {
      ids.add('prod-bosch-drill');
    }
    if (lower.contains('bit') || lower.contains('drill bits') || lower.contains('screwdriver bit') || lower.contains('attachment')) {
      ids.add('prod-bosch-bits');
    }
    if (lower.contains('dewalt drill') || lower.contains('cordless drill')) {
      ids.add('prod-dewalt-drill');
    }
    if (lower.contains('battery') || lower.contains('dewalt battery') || lower.contains('20v battery') || lower.contains('pack')) {
      ids.add('prod-dewalt-battery');
    }
    if (lower.contains('saw') || lower.contains('circular saw') || lower.contains('makita saw') || lower.contains('cutting')) {
      ids.add('prod-makita-saw');
    }
    if (lower.contains('blade') || lower.contains('saw blade') || lower.contains('carbide')) {
      ids.add('prod-makita-blade');
    }
    if (lower.contains('screwdriver') || lower.contains('screwdriver set') || lower.contains('stanley screwdriver')) {
      ids.add('prod-stanley-screwdriver');
    }
    if (lower.contains('spanner') || lower.contains('wrench') || lower.contains('adjustable') || lower.contains('taparia')) {
      ids.add('prod-taparia-spanner');
    }
    if (lower.contains('hammer') || lower.contains('claw hammer') || lower.contains('stanley hammer') || lower.contains('nails')) {
      ids.add('prod-stanley-hammer');
    }
    if (lower.contains('laser') || lower.contains('laser measure') || lower.contains('glm 50') || lower.contains('distance')) {
      ids.add('prod-bosch-laser');
    }
    if (lower.contains('tape') || lower.contains('tape measure') || lower.contains('tylon') || lower.contains('measuring tape')) {
      ids.add('prod-stanley-tape');
    }
    if (lower.contains('goggles') || lower.contains('safety glasses') || lower.contains('glasses') || lower.contains('3m') || lower.contains('protection')) {
      ids.add('prod-3m-goggles');
    }
    if (lower.contains('chest') || lower.contains('cabinet') || lower.contains('tool box') || lower.contains('storage')) {
      ids.add('prod-dewalt-chest');
    }

    return ids.toSet().toList(); // Unique list
  }

  String _getLocalFallbackResponse(String query) {
    final lower = query.toLowerCase();
    
    if (lower.contains('drywall') || lower.contains('partition') || lower.contains('gypsum') || lower.contains('wall')) {
      return "**Project Shopping List: Drywall Partition Installation**\n\n"
          "To set up a drywall partition, you will need to frame the studs, position the gypsum boards, and screw them in securely. Here are the recommended tools and materials:\n\n"
          "1. **Bosch Impact Drill GSB 13 RE**: For quick drilling into metal frames and brick walls.\n"
          "2. **Bosch 25-Piece Drill and Screwdriver Bit Set**: Essential for fastening drywalls with precision phillips/magnetic bits.\n"
          "3. **Stanley Cushion Grip Screwdriver Set**: Perfect for final manual adjustments and tight corners.\n"
          "4. **Stanley 5m Tylon Tape Measure**: For layout markings and checking dimensions.\n"
          "5. **3M Virtua AP Safety Glasses**: Essential safety goggles to protect from gypsum dust and drilling debris.\n\n"
          "Check the recommended products below to add them to your cart directly!";
    }
    
    if (lower.contains('wood') || lower.contains('deck') || lower.contains('furniture') || lower.contains('cut') || lower.contains('saw') || lower.contains('carpenter')) {
      return "**Project Shopping List: Woodworking / Deck Building**\n\n"
          "Building wooden structures, decks, or furniture requires clean cuts and secure fastening. Here is your required toolset:\n\n"
          "1. **Makita 7-1/4 Inch Circular Saw**: Heavy-duty saw that rips and cuts timber sheets with absolute ease.\n"
          "2. **Makita Carbide-Tipped Saw Blade (24T)**: High-quality thin-kerf replacement blade for rapid woodworking cuts.\n"
          "3. **Stanley Claw Hammer (16oz)**: Steel shaft claw hammer for driving nails and dismantling wood frames.\n"
          "4. **Stanley 5m Tylon Tape Measure**: For accurate lumber cutting layouts.\n"
          "5. **3M Virtua AP Safety Glasses**: Full wrap-around lens protecting your eyes from flying wood chips and saw dust.\n\n"
          "Scroll below to add these woodworking essentials to your cart!";
    }

    if (lower.contains('screw') || lower.contains('assemble') || lower.contains('assembly') || lower.contains('bolt') || lower.contains('tighten') || lower.contains('fixture')) {
      return "**Project Shopping List: Machinery/Furniture Assembly**\n\n"
          "For assembly work, fixing industrial pipes, or tightening heavy bolts, you need reliable hand tools with high torque capacity:\n\n"
          "1. **Stanley 10-Piece Cushion Grip Screwdriver Set**: Magnetized tips that grip screws perfectly during assembly.\n"
          "2. **Taparia Adjustable Spanner Wrench**: Left-hand thumb movement adjustability, suitable for tightening various sizes of bolts and pipe joints.\n"
          "3. **Bosch 25-Piece Drill and Screwdriver Bit Set**: Offers cross, slotted, and torx bits for all furniture fasteners.\n\n"
          "Check out these mechanical assembly tools below.";
    }

    if (lower.contains('measure') || lower.contains('laser') || lower.contains('layout') || lower.contains('align') || lower.contains('distance')) {
      return "**Project Shopping List: Precision Layout & Measuring**\n\n"
          "For aligning cabinets, measuring room layouts, or calculating wall distances, precision is key. Here are the tools to use:\n\n"
          "1. **Bosch Bluetooth Laser Measure GLM 50 C**: Color display laser tool that measures up to 50 meters and syncs with smartphone apps.\n"
          "2. **Stanley 5m Tylon Tape Measure**: Ergonomic, double-marked tape for quick physical readings.\n"
          "3. **3M Safety Glasses**: Comfortable eye protection while surveying active jobsites.\n\n"
          "Take a look at these layout tools below.";
    }

    // Default response
    return "**Project Shopping List: General Site Prep & Construction**\n\n"
        "Here is a professional contractor starter kit recommended for general site work, measuring, mounting, and protection:\n\n"
        "1. **Bosch Bluetooth Laser Measure GLM 50 C**: For precise laser distance measuring up to 50 meters.\n"
        "2. **Stanley Claw Hammer Steel Shaft 16oz**: Durable hammer built for high-performance nail driving and pulling.\n"
        "3. **3M Virtua AP Safety Glasses**: Essential wrap-around safety eyewear for any jobsite.\n"
        "4. **Stanley 5m Tylon Tape Measure**: Classic abrasion-resistant tape measure.\n\n"
        "Select the tools below to add them to your cart!";
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _loading = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    String reply = '';
    List<String> recIds = [];

    // 1. Try backend proxy first (loads GEMINI_API_KEY securely from server/.env)
    try {
      final response = await _dio.post(
        '${AppConfig.current.apiBaseUrl}/assistant/chat',
        data: {'message': text},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      
      if (response.statusCode == 200) {
        reply = response.data['reply'] ?? '';
      }
    } catch (e) {
      // 2. Fallback to client-side API call if GEMINI_API_KEY was passed as --dart-define
      if (_geminiApiKey.isNotEmpty) {
        try {
          final response = await _dio.post(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
            data: {
              "contents": [
                {
                  "parts": [
                    {
                      "text": "You are a professional contractor assistant. Suggest a detailed shopping list of tools and materials for the following project: '$text'. Be specific and mention tool brands like Bosch, Makita, DeWalt, Taparia, Stanley, 3M. Keep your response formatting clean and structured in Markdown."
                    }
                  ]
                }
              ]
            },
            options: Options(headers: {'Content-Type': 'application/json'}),
          );
          
          if (response.statusCode == 200) {
            final parts = response.data['candidates']?[0]?['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              reply = parts[0]['text'] ?? '';
            }
          }
        } catch (err) {
          // Silent fallback to local rules
        }
      }
    }

    // If API key is not configured, or if the API call failed, use the rules engine
    if (reply.isEmpty) {
      // Simulate typing delay
      await Future.delayed(const Duration(milliseconds: 800));
      reply = _getLocalFallbackResponse(text);
    }

    recIds = _extractProductIds(reply);

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        text: reply,
        isUser: false,
        recommendedProductIds: recIds,
      ));
      _loading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return StorePage(
      showFooter: false,
      body: MaxWidthContainer(
        maxWidth: 900,
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back link
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go(AppRoutes.home),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(height: 4),
            // Title
            Text(
              'Gemini AI Project Assistant',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Message List — bounded height with its own scroll
            Container(
              height: 560,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final msg = _messages[i];
                  return _ChatBubble(message: msg);
                },
              ),
            ),

          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text('Gemini is thinking...', style: theme.textTheme.bodySmall),
                ],
              ),
            ),

          // Suggestion Chips (only when chat has just started)
          if (_messages.length == 1)
            FadeInUp(
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested Projects:',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _SuggestionChip(
                            label: 'Drywall partition installation',
                            onTap: () => _sendMessage('Drywall partition installation'),
                          ),
                          const SizedBox(width: 8),
                          _SuggestionChip(
                            label: 'Wood decking / cutting lumber',
                            onTap: () => _sendMessage('I need tools to build a wood deck and cut lumber'),
                          ),
                          const SizedBox(width: 8),
                          _SuggestionChip(
                            label: 'Assemble steel racks',
                            onTap: () => _sendMessage('Mounting and assembly of heavy shelving units'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 12),

          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Describe your construction project...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(_msgCtrl.text),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.psychology_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppColors.primary
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 0),
                      bottomRight: Radius.circular(message.isUser ? 0 : 16),
                    ),
                    border: message.isUser
                        ? null
                        : Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : theme.colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.person_outline, color: Colors.white, size: 18),
                ),
              ],
            ],
          ),
          
          // Render recommended products if any
          if (!message.isUser && message.recommendedProductIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ChatRecommendations(productIds: message.recommendedProductIds),
          ],
        ],
      ),
    );
  }
}

class _ChatRecommendations extends ConsumerWidget {
  final List<String> productIds;

  const _ChatRecommendations({required this.productIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(compatibleProductsProvider(productIds));

    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 14),
              const SizedBox(width: 6),
              Text(
                'Shopping List Recommendations:',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final product = products[i];
                    return _MiniProductCard(product: product);
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('Error loading products: $e', style: const TextStyle(fontSize: 11, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _MiniProductCard extends ConsumerWidget {
  final ProductEntity product;

  const _MiniProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: product.primaryImage != null
                ? CachedNetworkImage(
                    imageUrl: product.primaryImage!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 50,
                      height: 50,
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 50,
                      height: 50,
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      child: const Icon(Icons.construction_outlined, size: 20, color: AppColors.textTertiary),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    child: const Icon(Icons.construction_outlined, size: 20, color: AppColors.textTertiary),
                  ),
          ),
          const SizedBox(width: 10),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  product.brandName,
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${product.effectivePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        // Externally-fulfilled products are bought on the
                        // partner's store, so this chip links out instead.
                        if (product.isExternalLink) {
                          final ok =
                              await openExternalLink(product.externalUrl);
                          if (!ok) {
                            messenger.showSnackBar(SnackBar(
                                content: Text('Couldn\'t open the '
                                    '${product.externalStoreLabel} link'),
                                backgroundColor: AppColors.error));
                          }
                          return;
                        }
                        ref
                            .read(cartProvider.notifier)
                            .addItem(product, quantity: 1);
                        messenger.clearSnackBars();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Added ${product.name} to cart!'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: product.isExternalLink
                              ? AppColors.warningContainer
                              : AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                            product.isExternalLink
                                ? Icons.open_in_new_rounded
                                : Icons.add_shopping_cart_outlined,
                            size: 14,
                            color: product.isExternalLink
                                ? AppColors.warning
                                : AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

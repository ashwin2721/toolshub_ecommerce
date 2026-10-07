import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/user_entity.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/store_chrome.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _step = 0;
  bool _placing = false;

  // Step 1 – Customer Info
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Step 2 – Address
  String? _selectedAddressId; // null = "add new"
  bool _userChoseAddNew = false;
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  bool _saveAddressToProfile = false;

  // Step 3 – Delivery
  String _delivery = 'standard';

  // Live distance-based delivery quote for the currently selected address.
  Map<String, dynamic>? _quote;
  bool _loadingQuote = false;

  // Step 4 – Payment
  String _payment = AppConstants.paymentCod;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      _nameCtrl.text = user.name;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phone ?? '';
      // Pre-select default address
      if (user.addresses.isNotEmpty) {
        final def = user.defaultAddress ?? user.addresses.first;
        _selectedAddressId = def.id;
        _streetCtrl.text = def.street;
        _cityCtrl.text = def.city;
        _stateCtrl.text = def.state;
        _pincodeCtrl.text = def.pinCode;
      }
    }
    // Fetch the delivery quote for any pre-filled address once mounted.
    if (_selectedAddressId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchQuote());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void _onAddressSelected(AddressEntity addr) {
    setState(() {
      _selectedAddressId = addr.id;
      _streetCtrl.text = addr.street;
      _cityCtrl.text = addr.city;
      _stateCtrl.text = addr.state;
      _pincodeCtrl.text = addr.pinCode;
    });
    _fetchQuote();
  }

  /// Fetch the distance-based delivery quote for the current address so the
  /// fee, distance and free/paid state shown match what the server will charge.
  Future<void> _fetchQuote() async {
    final street = _streetCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    if (street.isEmpty && city.isEmpty) return;
    setState(() => _loadingQuote = true);
    try {
      final cart = ref.read(cartProvider);
      final dio = ref.read(dioProvider);
      final addr = [street, city, _stateCtrl.text.trim(), _pincodeCtrl.text.trim(), 'India']
          .where((s) => s.isNotEmpty)
          .join(', ');
      final res = await dio.get('/delivery-quote', queryParameters: {
        'subtotal': cart.subtotal,
        'address': addr,
      });
      if (!mounted) return;
      setState(() => _quote = Map<String, dynamic>.from(res.data));
    } catch (_) {
      if (mounted) setState(() => _quote = null);
    } finally {
      if (mounted) setState(() => _loadingQuote = false);
    }
  }

  double get _standardDeliveryFee {
    // A free_shipping coupon zeroes delivery server-side, so the displayed fee
    // has to agree or the customer reviews a total we never charge.
    if (ref.read(cartProvider).couponType == 'free_shipping') return 0;
    return (_quote?['deliveryFee'] as num?)?.toDouble() ??
        ref.read(cartProvider).shippingFee;
  }

  double get _expressDeliveryFee =>
      (_quote?['expressSurcharge'] as num?)?.toDouble() ??
      AppConstants.expressShippingFee;

  /// Express is a premium ON TOP of the distance fee, which is what the "+₹199"
  /// label promises and what the server now charges. It used to replace it here,
  /// so the two disagreed.
  double get _deliveryFee =>
      _standardDeliveryFee +
      (_delivery == 'express' ? _expressDeliveryFee : 0);
  String? get _deliveryLabel => _quote?['label']?.toString();
  bool get _deliverable => _quote == null || _quote!['deliverable'] != false;

  void _onAddNewAddressSelected() {
    setState(() {
      _userChoseAddNew = true;
      _selectedAddressId = null;
      _streetCtrl.clear();
      _cityCtrl.clear();
      _stateCtrl.clear();
      _pincodeCtrl.clear();
    });
  }

  Future<void> _placeOrder() async {
    if (_streetCtrl.text.isEmpty ||
        _cityCtrl.text.isEmpty ||
        _stateCtrl.text.isEmpty ||
        _pincodeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all address fields before placing order.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_deliverable) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_deliveryLabel ?? 'Delivery is not available to this address.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _placing = true);
    try {
      final cart = ref.read(cartProvider);
      final dio = ref.read(dioProvider);

      // If user opted to save a new address to profile
      if (_selectedAddressId == null && _saveAddressToProfile) {
        try {
          await dio.post('/auth/addresses', data: {
            'type': 'home',
            'fullName': _nameCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'street': _streetCtrl.text.trim(),
            'city': _cityCtrl.text.trim(),
            'state': _stateCtrl.text.trim(),
            'pinCode': _pincodeCtrl.text.trim(),
            'isDefault': false,
          });
          ref.invalidate(authNotifierProvider);
        } catch (_) {}
      }

      final deliveryFee = _deliveryFee;
      final grandTotal =
          cart.subtotal - cart.discountAmount + cart.gstAmount + deliveryFee;

      final response = await dio.post('/orders', data: {
        'items': cart.activeItems
            .map((i) => {
                  'productId': i.productId,
                  'name': i.productName,
                  'price': i.effectivePrice,
                  'quantity': i.quantity,
                  'imageUrl': i.productImage,
                })
            .toList(),
        'shippingAddress': {
          'fullName': _nameCtrl.text,
          'phone': _phoneCtrl.text,
          'street': _streetCtrl.text,
          'city': _cityCtrl.text,
          'state': _stateCtrl.text,
          'pinCode': _pincodeCtrl.text,
        },
        'paymentMethod': _payment,
        // Without this the server never sees the express choice, so the customer
        // was shown the surcharge and charged the standard fee.
        'shippingMethod': _delivery,
        'couponCode': cart.couponCode,
        'totalAmount': grandTotal,
      });

      final orderId = response.data['id'];
      await ref.read(cartProvider.notifier).clearCart();

      if (mounted) context.go('/order-confirmation/$orderId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to place order: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;

    // Auto-select the default saved address so the user never has to type one
    // manually when they already have addresses (handles the profile loading
    // after this screen's initState).
    if (user != null &&
        !_userChoseAddNew &&
        _selectedAddressId == null &&
        user.addresses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _userChoseAddNew || _selectedAddressId != null) return;
        final def = user.defaultAddress ?? user.addresses.first;
        _onAddressSelected(def);
      });
    }

    final steps = [
      'Customer Info',
      'Shipping',
      'Delivery',
      'Payment',
      'Review',
    ];

    return StorePage(
      body: MaxWidthContainer(
        maxWidth: 900,
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Checkout',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _StepIndicator(currentStep: _step, totalSteps: steps.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              child: Text(
                'Step ${_step + 1}: ${steps[_step]}',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            _buildStep(cart, user),
            const SizedBox(height: 24),
            _NavigationBar(
              step: _step,
              totalSteps: steps.length,
              placing: _placing,
              onBack: () => setState(() => _step--),
              onNext: _step == 4
                  ? _placeOrder
                  : () {
                      // Refresh the delivery quote once the address is entered.
                      if (_step == 1) _fetchQuote();
                      setState(() => _step++);
                    },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(dynamic cart, UserEntity? user) {
    switch (_step) {
      case 0:
        return _Step1CustomerInfo(
          nameCtrl: _nameCtrl,
          emailCtrl: _emailCtrl,
          phoneCtrl: _phoneCtrl,
        );
      case 1:
        return _Step2Address(
          user: user,
          selectedAddressId: _selectedAddressId,
          streetCtrl: _streetCtrl,
          cityCtrl: _cityCtrl,
          stateCtrl: _stateCtrl,
          pincodeCtrl: _pincodeCtrl,
          saveToProfile: _saveAddressToProfile,
          onAddressSelected: _onAddressSelected,
          onAddNewSelected: _onAddNewAddressSelected,
          onSaveToProfileChanged: (v) =>
              setState(() => _saveAddressToProfile = v),
        );
      case 2:
        return _Step3Delivery(
          selected: _delivery,
          onChanged: (v) => setState(() => _delivery = v),
          standardFee: _standardDeliveryFee,
          expressFee: _expressDeliveryFee,
          distanceLabel: _deliveryLabel,
          loading: _loadingQuote,
        );
      case 3:
        return _Step4Payment(
          selected: _payment,
          onChanged: (v) => setState(() => _payment = v),
        );
      case 4:
        return _Step5Review(
          cart: cart,
          name: _nameCtrl.text,
          address:
              '${_streetCtrl.text}, ${_cityCtrl.text}, ${_stateCtrl.text} - ${_pincodeCtrl.text}',
          delivery: _delivery,
          payment: _payment,
          deliveryFee: _deliveryFee,
          deliveryLabel: _deliveryLabel,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= currentStep
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < totalSteps - 1)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.success
                          : isActive
                              ? AppColors.primary
                              : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Navigation Bar ────────────────────────────────────────────────────────────
class _NavigationBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final bool placing;
  final VoidCallback onBack;
  final VoidCallback onNext;
  const _NavigationBar({
    required this.step,
    required this.totalSteps,
    required this.placing,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          if (step > 0) ...[
            Expanded(
              child: CustomButton(
                label: 'Back',
                outlined: true,
                onPressed: onBack,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: CustomButton(
              label: step == totalSteps - 1 ? 'Place Order 🎉' : 'Continue',
              loading: placing,
              icon: step == totalSteps - 1
                  ? Icons.check_circle_outline
                  : Icons.arrow_forward_rounded,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1 – Customer Info ─────────────────────────────────────────────────────
class _Step1CustomerInfo extends StatelessWidget {
  final TextEditingController nameCtrl, emailCtrl, phoneCtrl;
  const _Step1CustomerInfo(
      {required this.nameCtrl,
      required this.emailCtrl,
      required this.phoneCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Information',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 16),
        CustomTextField(
            controller: nameCtrl,
            label: 'Full Name',
            prefixIcon: Icons.person_outline),
        const SizedBox(height: 12),
        CustomTextField(
            controller: emailCtrl,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined),
        const SizedBox(height: 12),
        CustomTextField(
            controller: phoneCtrl,
            label: 'Phone Number',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined),
      ],
    );
  }
}

// ── Step 2 – Shipping Address ──────────────────────────────────────────────────
class _Step2Address extends StatelessWidget {
  final UserEntity? user;
  final String? selectedAddressId;
  final TextEditingController streetCtrl, cityCtrl, stateCtrl, pincodeCtrl;
  final bool saveToProfile;
  final void Function(AddressEntity) onAddressSelected;
  final VoidCallback onAddNewSelected;
  final void Function(bool) onSaveToProfileChanged;

  const _Step2Address({
    required this.user,
    required this.selectedAddressId,
    required this.streetCtrl,
    required this.cityCtrl,
    required this.stateCtrl,
    required this.pincodeCtrl,
    required this.saveToProfile,
    required this.onAddressSelected,
    required this.onAddNewSelected,
    required this.onSaveToProfileChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addresses = user?.addresses ?? [];
    final isAddingNew = selectedAddressId == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Shipping Address',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 16),

        // ── Saved Addresses List ──
        if (addresses.isNotEmpty) ...[
          Text('Saved Addresses',
              style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          ...addresses.map((addr) => _AddressCard(
                addr: addr,
                isSelected: selectedAddressId == addr.id,
                onTap: () => onAddressSelected(addr),
              )),
          const SizedBox(height: 8),

          // ── Add New Address Option ──
          GestureDetector(
            onTap: onAddNewSelected,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isAddingNew ? AppColors.primary : AppColors.border,
                  width: isAddingNew ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isAddingNew
                    ? AppColors.primaryContainer
                    : theme.colorScheme.surface,
              ),
              child: Row(
                children: [
                  Icon(Icons.add_location_alt_outlined,
                      color: isAddingNew
                          ? AppColors.primary
                          : AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    'Add a New Address',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isAddingNew ? AppColors.primary : null,
                    ),
                  ),
                  const Spacer(),
                  if (isAddingNew)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        ],

        // ── Address Input Form (shown when adding new or no saved addresses) ──
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isAddingNew || addresses.isEmpty
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (addresses.isEmpty)
                const Text('Enter Delivery Address',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              if (addresses.isEmpty) const SizedBox(height: 12),
              CustomTextField(
                controller: streetCtrl,
                label: 'Street Address',
                hint: 'Flat/House No, Building, Street, Area',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: cityCtrl,
                      label: 'City',
                      hint: 'City',
                      prefixIcon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: pincodeCtrl,
                      label: 'PIN Code',
                      hint: '110001',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: stateCtrl,
                label: 'State',
                hint: 'State',
                prefixIcon: Icons.map_outlined,
              ),
              const SizedBox(height: 12),

              // Save to profile toggle (only for logged-in users)
              if (user != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_add_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Save this address to my profile',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch.adaptive(
                        value: saveToProfile,
                        onChanged: onSaveToProfileChanged,
                        activeTrackColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Address Card Widget ────────────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  final AddressEntity addr;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressCard({
    required this.addr,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primaryContainer
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                addr.type == 'work'
                    ? Icons.work_outline
                    : addr.type == 'other'
                        ? Icons.place_outlined
                        : Icons.home_outlined,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        addr.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (addr.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    addr.formatted,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    addr.phone,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 3 – Delivery ──────────────────────────────────────────────────────────
class _Step3Delivery extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  final double standardFee;
  final double expressFee;
  final String? distanceLabel;
  final bool loading;
  const _Step3Delivery({
    required this.selected,
    required this.onChanged,
    required this.standardFee,
    required this.expressFee,
    required this.distanceLabel,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final standardPrice = loading
        ? 'Calculating…'
        : (standardFee == 0 ? 'FREE' : '₹${standardFee.toStringAsFixed(0)}');
    final standardSubtitle =
        distanceLabel != null && distanceLabel!.isNotEmpty && !loading
            ? distanceLabel!
            : '5-7 business days';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Delivery Method',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Standard delivery is priced by distance from our store.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        _DeliveryOption(
          value: 'standard',
          selected: selected,
          title: 'Standard Delivery',
          subtitle: standardSubtitle,
          price: standardPrice,
          icon: Icons.local_shipping_outlined,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        _DeliveryOption(
          value: 'express',
          selected: selected,
          title: 'Express Delivery',
          subtitle: '1-2 business days',
          price: '+₹${expressFee.toStringAsFixed(0)}',
          icon: Icons.bolt_rounded,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final String value, selected, title, subtitle, price;
  final IconData icon;
  final void Function(String) onChanged;

  const _DeliveryOption({
    required this.value,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primaryContainer
              : Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(icon,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : null)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(price,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : null,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── Step 4 – Payment ───────────────────────────────────────────────────────────
class _Step4Payment extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _Step4Payment({required this.selected, required this.onChanged});

  static const _methods = [
    (AppConstants.paymentCod, 'Cash on Delivery', Icons.payments_outlined),
    (AppConstants.paymentRazorpay, 'Razorpay (Cards/UPI/Netbanking)',
        Icons.payment),
    (AppConstants.paymentStripe, 'Stripe (International Cards)',
        Icons.credit_card_outlined),
    (AppConstants.paymentUpi, 'UPI Payment',
        Icons.account_balance_wallet_outlined),
    (AppConstants.paymentPaypal, 'PayPal', Icons.paypal),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 16),
        // RadioListTile's own groupValue/onChanged are deprecated in favour of a
        // RadioGroup ancestor. The group wraps only the tiles, so the COD banner
        // below stays outside it.
        RadioGroup<String>(
          groupValue: selected,
          // RadioGroup hands back a nullable value, so guard rather than
          // reinstating the old `v!` bang.
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          child: Column(
            children: [
              ..._methods.map((m) => RadioListTile<String>(
                    value: m.$1,
                    title: Text(m.$2),
                    secondary: Icon(m.$3, color: AppColors.primary),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  )),
            ],
          ),
        ),
        if (selected == AppConstants.paymentCod)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💵 Pay in cash when your order arrives at your doorstep.',
                style: TextStyle(fontSize: 13),
              ),
            ),
      ],
    );
  }
}

// ── Step 5 – Order Review ──────────────────────────────────────────────────────
class _Step5Review extends StatelessWidget {
  final dynamic cart;
  final String name, address, delivery, payment;
  final double deliveryFee;
  final String? deliveryLabel;
  const _Step5Review(
      {required this.cart,
      required this.name,
      required this.address,
      required this.delivery,
      required this.payment,
      required this.deliveryFee,
      required this.deliveryLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double subtotal = cart.subtotal;
    final double discount = cart.discountAmount;
    final double gst = cart.gstAmount;
    final double grandTotal = subtotal - discount + gst + deliveryFee;
    final String deliveryText = delivery == 'express'
        ? 'Express (1-2 days) +₹${deliveryFee.toStringAsFixed(0)}'
        : (deliveryLabel != null && deliveryLabel!.isNotEmpty
            ? 'Standard · $deliveryLabel'
            : 'Standard (5-7 days)');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Summary',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _ReviewSection('Customer Details', [
          _ReviewRow(Icons.person_outline, name),
          _ReviewRow(Icons.location_on_outlined, address),
        ]),
        _ReviewSection('Delivery Method', [
          _ReviewRow(Icons.local_shipping_outlined, deliveryText),
        ]),
        _ReviewSection('Payment Method', [
          _ReviewRow(Icons.payment,
              payment.replaceAll('_', ' ').toUpperCase()),
        ]),
        _ReviewSection('Items (${cart.activeItems.length})', [
          ...cart.activeItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('${item.productName} × ${item.quantity}',
                            style: theme.textTheme.bodySmall)),
                    Text('₹${item.totalPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
        ]),
        // Pricing Breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _PriceRow(
                  label: 'Subtotal',
                  value: '₹${subtotal.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              if (discount > 0) ...[
                _PriceRow(
                  label: cart.couponCode != null
                      ? 'Discount (${cart.couponCode})'
                      : 'Discount',
                  value: '-₹${discount.toStringAsFixed(2)}',
                  valueColor: AppColors.success,
                ),
                const SizedBox(height: 6),
              ],
              _PriceRow(
                  label: 'GST (18%)', value: '₹${gst.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _PriceRow(
                label: 'Delivery',
                value: deliveryFee == 0
                    ? 'FREE'
                    : '₹${deliveryFee.toStringAsFixed(2)}',
                valueColor: deliveryFee == 0 ? AppColors.success : null,
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Payable',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    '₹${grandTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared Review Widgets ──────────────────────────────────────────────────────
class _ReviewSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ReviewSection(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ReviewRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}

// ── Pricing Breakdown Row ──────────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _PriceRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}

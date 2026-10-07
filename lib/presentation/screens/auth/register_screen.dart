import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/brand/brand.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/location_helper.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  bool _obscure = true;
  bool _confirmObscure = true;
  bool _loading = false;
  bool _agreed = false;
  bool _locating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms & Privacy Policy')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).registerWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          );
      
      // Registration succeeded — the user is now logged in. Saving the
      // address is optional and must NOT fail the whole flow; treat any
      // address error as a soft warning and keep the successful account.
      bool addressSaved = true;
      try {
        final dio = ref.read(dioProvider);
        await dio.post('/auth/addresses', data: {
          'type': 'home',
          'fullName': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim().isEmpty ? '9999999999' : _phoneCtrl.text.trim(),
          'street': _streetCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'pinCode': _pincodeCtrl.text.trim(),
          'isDefault': true,
        });
      } catch (_) {
        addressSaved = false;
      }

      ref.invalidate(authNotifierProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(addressSaved
                ? 'Account created! Address saved successfully.'
                : 'Account created! You can add your address later from your profile.'),
            backgroundColor: addressSaved ? AppColors.success : AppColors.warning,
          ),
        );
        final redirect =
            GoRouterState.of(context).uri.queryParameters['redirect'];
        context.go(redirect != null && redirect.isNotEmpty
            ? redirect
            : AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Detect the shopper's current location and auto-fill the address fields.
  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final addr = await resolveCurrentAddress(ref.read(dioProvider));
      if (!mounted) return;
      if (addr.street.isNotEmpty) _streetCtrl.text = addr.street;
      if (addr.city.isNotEmpty) _cityCtrl.text = addr.city;
      if (addr.state.isNotEmpty) _stateCtrl.text = addr.state;
      if (addr.pinCode.isNotEmpty) _pincodeCtrl.text = addr.pinCode;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Location detected — address filled in.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.warning,
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final glassBgColor = isDark ? AppColors.glassBackgroundDark : AppColors.glassBackgroundLight;
    final glassBorderColor = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background Fluid Circles ──
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: isDark ? 0.08 : 0.15),
              ),
            ),
          ),

          // ── Scrollable Content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button with FadeInDown
                    FadeInDown(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: glassBorderColor),
                        ),
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : AppColors.secondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Account ${Brand.current.copy.emoji}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.secondary)),
                          const SizedBox(height: 4),
                          Text(Brand.current.copy.registerPitch,
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Glassmorphic Card Form
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: glassBgColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: glassBorderColor, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Name
                                  CustomTextField(
                                    controller: _nameCtrl,
                                    label: 'Full Name',
                                    hint: 'John Doe',
                                    prefixIcon: Icons.person_outline,
                                    validator: (v) =>
                                        v == null || v.isEmpty ? 'Name required' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Email
                                  CustomTextField(
                                    controller: _emailCtrl,
                                    label: 'Email Address',
                                    hint: 'you@example.com',
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.email_outlined,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Email required'
                                        : !v.contains('@')
                                            ? 'Invalid email'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Phone
                                  CustomTextField(
                                    controller: _phoneCtrl,
                                    label: 'Phone Number (Optional)',
                                    hint: '+91 9876543210',
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icons.phone_outlined,
                                  ),
                                  const SizedBox(height: 16),

                                  // Use current location → auto-fills the
                                  // street / city / state / PIN fields below.
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _locating ? null : _useCurrentLocation,
                                      icon: _locating
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : const Icon(Icons.my_location_rounded,
                                              size: 18),
                                      label: Text(_locating
                                          ? 'Detecting location…'
                                          : 'Use my current location'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(
                                            color: AppColors.primary),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Street Address
                                  CustomTextField(
                                    controller: _streetCtrl,
                                    label: 'Street Address',
                                    hint: 'Flat/House No, Building, Street',
                                    prefixIcon: Icons.location_on_outlined,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Street address required'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // City & PIN Code
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(
                                          controller: _cityCtrl,
                                          label: 'City',
                                          hint: 'City name',
                                          prefixIcon: Icons.location_city_outlined,
                                          validator: (v) => v == null || v.isEmpty
                                              ? 'City required'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: CustomTextField(
                                          controller: _pincodeCtrl,
                                          label: 'PIN Code',
                                          hint: '110001',
                                          keyboardType: TextInputType.number,
                                          validator: (v) => v == null || v.length < 6
                                              ? 'Valid PIN required'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // State
                                  CustomTextField(
                                    controller: _stateCtrl,
                                    label: 'State',
                                    hint: 'State name',
                                    prefixIcon: Icons.map_outlined,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'State required'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Password
                                  CustomTextField(
                                    controller: _passwordCtrl,
                                    label: 'Password',
                                    hint: 'Min 6 characters',
                                    obscureText: _obscure,
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                    ),
                                    validator: (v) =>
                                        v == null || v.length < 6 ? 'Min 6 characters' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Confirm Password
                                  CustomTextField(
                                    controller: _confirmCtrl,
                                    label: 'Confirm Password',
                                    hint: 'Re-enter password',
                                    obscureText: _confirmObscure,
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _confirmObscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () =>
                                          setState(() => _confirmObscure = !_confirmObscure),
                                    ),
                                    validator: (v) => v != _passwordCtrl.text
                                        ? 'Passwords do not match'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Terms Checkbox
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _agreed,
                                        onChanged: (v) => setState(() => _agreed = v ?? false),
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            text: 'I agree to the ',
                                            style: theme.textTheme.bodySmall,
                                            children: const [
                                              TextSpan(
                                                text: 'Terms',
                                                style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w600),
                                              ),
                                              TextSpan(text: ' & '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Button
                                  CustomButton(
                                    label: 'Create Account',
                                    onPressed: _register,
                                    loading: _loading,
                                    icon: Icons.person_add_outlined,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Navigation Back to Login
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ',
                              style: theme.textTheme.bodyMedium),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'Sign In',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/app_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) {
        final redirect =
            GoRouterState.of(context).uri.queryParameters['redirect'];
        context.go(redirect != null && redirect.isNotEmpty
            ? redirect
            : AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final glassBgColor = isDark ? AppColors.glassBackgroundDark : AppColors.glassBackgroundLight;
    final glassBorderColor = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background Fluid Circles ──
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: isDark ? 0.08 : 0.15),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.35,
            left: size.width * 0.75,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: isDark ? 0.1 : 0.08),
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
                  children: [
                    const SizedBox(height: 12),
                    // Header Brand
                    FadeInDown(
                      duration: const Duration(milliseconds: 650),
                      child: Column(
                        children: [
                          const AppLogo(size: 68),
                          const SizedBox(height: 12),
                          Text(
                            'TOOLSHUB',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: isDark ? Colors.white : AppColors.secondary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'Professional Tools & Hardware',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Frosted Glassmorphism Login Container
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
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Welcome Back! 👋',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('Sign in to continue shopping',
                                      style: theme.textTheme.bodyMedium),
                                  const SizedBox(height: 28),

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

                                  // Password
                                  CustomTextField(
                                    controller: _passwordCtrl,
                                    label: 'Password',
                                    hint: '••••••••',
                                    obscureText: _obscure,
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    validator: (v) => v == null || v.length < 6
                                        ? 'Min 6 characters'
                                        : null,
                                  ),
                                  const SizedBox(height: 4),

                                  // Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () =>
                                          context.push(AppRoutes.forgotPassword),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                      ),
                                      child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Login Button
                                  CustomButton(
                                    label: 'Sign In',
                                    onPressed: _login,
                                    loading: _loading,
                                    icon: Icons.login_rounded,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register Navigation
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: theme.textTheme.bodyMedium),
                          GestureDetector(
                            onTap: () {
                              final redirect = GoRouterState.of(context)
                                  .uri
                                  .queryParameters['redirect'];
                              context.push(
                                  redirect != null && redirect.isNotEmpty
                                      ? '${AppRoutes.register}?redirect=${Uri.encodeComponent(redirect)}'
                                      : AppRoutes.register);
                            },
                            child: Text(
                              'Register Now',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          // ── Back Button ──
          // Kept as the LAST Stack child so it paints above the full-screen
          // scroll view and actually receives taps (otherwise the scroll view
          // on top swallows the tap and the button looks broken).
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: glassBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: glassBorderColor, width: 1.5),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 22),
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      // Go straight home. Popping could bounce back into a
                      // gated route (e.g. /checkout) and re-trigger the login
                      // redirect, which looks like a broken back button.
                      onPressed: () => context.go(AppRoutes.home),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

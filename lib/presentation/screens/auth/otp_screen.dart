import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _verificationId;
  int _resendSeconds = 60;

  void _startResendTimer() {
    _resendSeconds = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      return _resendSeconds > 0;
    });
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${_phoneCtrl.text.trim()}',
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          // TODO(phone-auth): The credential is auto-verified with Firebase, but
          // the app authenticates against the Postgres backend (auth_token in
          // SharedPreferences). There is no backend endpoint yet to exchange a
          // verified Firebase phone credential for a backend session, so do NOT
          // navigate home as if authenticated. Also clear the loading flag so
          // the Send-OTP button is not stuck.
          if (mounted) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Phone login is not available yet.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message ?? 'Verification failed'),
                  backgroundColor: AppColors.error),
            );
          }
        },
        codeSent: (vId, _) {
          setState(() {
            _verificationId = vId;
            _otpSent = true;
            _loading = false;
          });
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpCtrl.text.length != 6) return;
    setState(() => _loading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      // TODO(phone-auth): The OTP is verified with Firebase here, but the app
      // authenticates against the Postgres backend (auth_token in
      // SharedPreferences). There is no backend endpoint yet to exchange a
      // verified Firebase phone credential for a backend session, so phone
      // login cannot be completed. Do NOT navigate home as if authenticated.
      // Wire this up once the backend adds a phone-login endpoint (the
      // phone-login entry is disabled in login_screen until then).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone login is not available yet.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message ?? 'Invalid OTP'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: theme.textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Phone Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.phone_android_rounded,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              _otpSent ? 'Enter OTP' : 'Enter Phone Number',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent
                  ? 'We sent a 6-digit code to +91 ${_phoneCtrl.text}'
                  : 'We will send you a one-time verification code',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            if (!_otpSent) ...[
              // Phone input
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('+91',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        hintText: '9876543210',
                        labelText: 'Mobile Number',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: 'Send OTP',
                onPressed: _sendOtp,
                loading: _loading,
                icon: Icons.send_rounded,
              ),
            ] else ...[
              // OTP input
              Center(
                child: Pinput(
                  controller: _otpCtrl,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onCompleted: (_) => _verifyOtp(),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: 'Verify OTP',
                onPressed: _verifyOtp,
                loading: _loading,
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: 20),
              Center(
                child: _resendSeconds > 0
                    ? Text('Resend OTP in ${_resendSeconds}s',
                        style: theme.textTheme.bodyMedium)
                    : TextButton(
                        onPressed: _sendOtp,
                        child: const Text('Resend OTP'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

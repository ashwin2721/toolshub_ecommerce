import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/responsive.dart';
import '../../widgets/common/store_chrome.dart';
import '../../providers/auth_provider.dart';

class ToolServiceBookingScreen extends ConsumerStatefulWidget {
  const ToolServiceBookingScreen({super.key});

  @override
  ConsumerState<ToolServiceBookingScreen> createState() =>
      _ToolServiceBookingScreenState();
}

class _ToolServiceBookingScreenState extends ConsumerState<ToolServiceBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toolNameCtrl = TextEditingController();
  final _serialNoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _serviceType = 'Calibration';
  DateTime? _pickupDate;
  bool _submitting = false;

  @override
  void dispose() {
    _toolNameCtrl.dispose();
    _serialNoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _pickupDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a preferred pickup date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to book a tool service'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final dio = ref.read(dioProvider);
      final refId = 'SRV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      await dio.post('/tool-services', data: {
        'bookingId': refId,
        'userId': userId,
        'toolName': _toolNameCtrl.text.trim(),
        'serialNumber': _serialNoCtrl.text.trim(),
        'serviceType': _serviceType,
        'pickupDate': _pickupDate!.toIso8601String(),
        'description': _descCtrl.text.trim(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 64),
            title: const Text('Booking Successful'),
            content: Text(
              'Your service request has been registered.\n\n'
              'Booking ID: $refId\n'
              'Our executive will contact you for pickup coordination.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book service: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _backLink() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (user == null) {
      return StorePage(
        body: MaxWidthContainer(
          maxWidth: 800,
          verticalPadding: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backLink(),
              const SizedBox(height: 8),
              Text(
                'Book Tool Service',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.precision_manufacturing_outlined,
                          size: 80, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text('Sign In Required',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text(
                        'Please sign in to request maintenance, repair, or calibration services for your tools.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.push(AppRoutes.login),
                        child: const Text('Sign In Now'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StorePage(
      body: MaxWidthContainer(
        maxWidth: 800,
        verticalPadding: 24,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backLink(),
              const SizedBox(height: 8),
              Text(
                'Book Tool Service & Calibration',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.build_circle_outlined,
                        color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Professional Tool Servicing',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Get torque calibration, laser leveling alignment, or heavy repair scheduled instantly.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tool Name
              Text('Tool Model & Brand',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _toolNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g., Bosch GSB 13 RE or Makita Circular Saw',
                  prefixIcon: Icon(Icons.handyman_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Please enter tool details' : null,
              ),
              const SizedBox(height: 20),

              // Serial Number
              Text('Tool Serial Number',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _serialNoCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g., S/N 98218318239A',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter serial number'
                    : null,
              ),
              const SizedBox(height: 20),

              // Service Type
              Text('Service Type Required',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _serviceType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.settings_suggest_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Calibration', child: Text('Precision Calibration')),
                  DropdownMenuItem(value: 'Repair', child: Text('Heavy Repair / Component Replacement')),
                  DropdownMenuItem(value: 'Routine Maintenance', child: Text('Routine Maintenance & Cleaning')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _serviceType = v);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Preferred Pickup Date
              Text('Preferred Pickup Date',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _pickupDate == null
                            ? 'Select Pickup Date'
                            : DateFormat('EEEE, dd MMMM yyyy').format(_pickupDate!),
                        style: TextStyle(
                          color: _pickupDate == null
                              ? AppColors.textTertiary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Problem Description
              Text('Detailed Description of Issues/Requests',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe error codes, physical damage, or precise calibration tolerances needed...',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter detailed description'
                    : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Book Tool Service Now',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

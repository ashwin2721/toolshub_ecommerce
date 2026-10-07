import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/brand/brand.dart';
import '../../../core/utils/location_helper.dart';

/// Admin editor for the distance-based delivery-fee engine.
/// Renders inside the AdminShell. Saves to PUT /api/delivery-settings.
class AdminDeliveryScreen extends ConsumerStatefulWidget {
  const AdminDeliveryScreen({super.key});

  @override
  ConsumerState<AdminDeliveryScreen> createState() =>
      _AdminDeliveryScreenState();
}

class _AdminDeliveryScreenState extends ConsumerState<AdminDeliveryScreen> {
  final _shopName = TextEditingController();
  final _shopAddress = TextEditingController();
  final _shopLat = TextEditingController();
  final _shopLng = TextEditingController();
  final _freeRadius = TextEditingController();
  final _baseFee = TextEditingController();
  final _perKm = TextEditingController();
  final _maxRadius = TextEditingController();
  final _freeOrderValue = TextEditingController();
  final _thirdPartyName = TextEditingController();
  final _thirdPartyFee = TextEditingController();
  final _expressSurcharge = TextEditingController();

  final MapController _mapController = MapController();

  bool _enabled = true;
  bool _thirdPartyEnabled = true;
  String _currency = '₹';

  bool _loading = true;
  bool _saving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/delivery-settings');
      final s = Map<String, dynamic>.from(res.data);
      _enabled = s['enabled'] ?? true;
      _thirdPartyEnabled = s['thirdPartyEnabled'] ?? true;
      _currency = (s['currency'] ?? '₹').toString();
      _shopName.text = (s['shopName'] ?? '').toString();
      _shopAddress.text = (s['shopAddress'] ?? '').toString();
      _shopLat.text = _numToStr(s['shopLat']);
      _shopLng.text = _numToStr(s['shopLng']);
      _freeRadius.text = _numToStr(s['freeRadiusKm']);
      _baseFee.text = _numToStr(s['baseFee']);
      _perKm.text = _numToStr(s['perKmFee']);
      _maxRadius.text = _numToStr(s['maxRadiusKm']);
      _freeOrderValue.text = _numToStr(s['freeOrderValue']);
      _thirdPartyName.text = (s['thirdPartyName'] ?? '').toString();
      _thirdPartyFee.text = _numToStr(s['thirdPartyFee']);
      _expressSurcharge.text = _numToStr(s['expressSurcharge']);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _numToStr(dynamic v) {
    if (v == null) return '';
    final n = (v is num) ? v : num.tryParse(v.toString());
    if (n == null) return '';
    // Drop the trailing ".0" on whole numbers for a cleaner field.
    return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  }

  double _d(TextEditingController c, double fallback) =>
      double.tryParse(c.text.trim()) ?? fallback;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/delivery-settings', data: {
        'enabled': _enabled,
        'shopName': _shopName.text.trim(),
        'shopAddress': _shopAddress.text.trim(),
        'shopLat': _d(_shopLat, 0),
        'shopLng': _d(_shopLng, 0),
        'freeRadiusKm': _d(_freeRadius, 0),
        'baseFee': _d(_baseFee, 0),
        'perKmFee': _d(_perKm, 0),
        'maxRadiusKm': _d(_maxRadius, 0),
        'freeOrderValue': _d(_freeOrderValue, 0),
        'thirdPartyEnabled': _thirdPartyEnabled,
        'thirdPartyName': _thirdPartyName.text.trim(),
        'thirdPartyFee': _d(_thirdPartyFee, 0),
        'expressSurcharge': _d(_expressSurcharge, 0),
      });
      ref.invalidate(deliverySettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Delivery settings updated!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Set the shop's coordinates from the admin's current GPS location and
  /// reverse-geocode a readable address for the shop.
  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pos = await getCurrentPosition();
      _applyPoint(pos.latitude, pos.longitude);
      try {
        final addr = await reverseGeocode(
            ref.read(dioProvider), pos.latitude, pos.longitude);
        final parts = [addr.street, addr.city, addr.state, addr.pinCode]
            .where((p) => p.trim().isNotEmpty)
            .toList();
        if (parts.isNotEmpty) _shopAddress.text = parts.join(', ');
      } catch (_) {}
      if (mounted) setState(() {});
      messenger.showSnackBar(const SnackBar(
          content: Text('Shop location set from your current position.'),
          backgroundColor: AppColors.success));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.warning));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Resolve coordinates from the typed shop address.
  Future<void> _findCoords() async {
    final q = _shopAddress.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (q.isEmpty) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Enter the shop address first.'),
          backgroundColor: AppColors.warning));
      return;
    }
    setState(() => _locating = true);
    try {
      final hit = await forwardGeocodeAddress(ref.read(dioProvider), q);
      if (hit == null) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Could not find that address. Try a more specific one.'),
            backgroundColor: AppColors.warning));
      } else {
        _applyPoint(hit.lat, hit.lng);
        messenger.showSnackBar(const SnackBar(
            content: Text('Coordinates found from address.'),
            backgroundColor: AppColors.success));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Current shop point from the lat/lng fields (falls back to a default).
  LatLng get _shopPoint {
    final lat = double.tryParse(_shopLat.text.trim());
    final lng = double.tryParse(_shopLng.text.trim());
    if (lat != null && lng != null) return LatLng(lat, lng);
    return const LatLng(19.076, 72.8777);
  }

  /// Write a chosen point into the lat/lng fields (and recentre the map).
  void _applyPoint(double lat, double lng, {bool moveMap = true}) {
    _shopLat.text = lat.toStringAsFixed(6);
    _shopLng.text = lng.toStringAsFixed(6);
    if (moveMap) {
      try {
        _mapController.move(LatLng(lat, lng), 14);
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  /// Reverse-geocode a tapped point to fill the shop address for convenience.
  Future<void> _reverseFillAddress(double lat, double lng) async {
    try {
      final addr = await reverseGeocode(ref.read(dioProvider), lat, lng);
      final parts = [addr.street, addr.city, addr.state, addr.pinCode]
          .where((p) => p.trim().isNotEmpty)
          .toList();
      if (parts.isNotEmpty && mounted) {
        setState(() => _shopAddress.text = parts.join(', '));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [
      _shopName, _shopAddress, _shopLat, _shopLng, _freeRadius, _baseFee,
      _perKm, _maxRadius, _freeOrderValue, _thirdPartyName, _thirdPartyFee,
      _expressSurcharge,
    ]) {
      c.dispose();
    }
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delivery Fees',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                  'Charge delivery by distance from your shop. Free within a '
                  'radius (or above an order value), per-km beyond it, and hand '
                  'off to a partner courier for far deliveries.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              // Master switch
              _switchCard(
                title: 'Distance-based delivery',
                subtitle: _enabled
                    ? 'On — fees are calculated from the shop location below.'
                    : 'Off — a flat handling fee (Base fee) is charged instead.',
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              const SizedBox(height: 20),

              // ── Shop location (origin) ──
              _section('Shop Location', 'The origin all distances are measured from.'),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _locating ? null : _useCurrentLocation,
                      icon: _locating
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: const Text('Use current location'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _locating ? null : _findCoords,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Find from address'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _mapPicker(),
              const SizedBox(height: 14),
              _text('Shop name', _shopName),
              _text('Shop address', _shopAddress, maxLines: 2),
              Row(
                children: [
                  Expanded(child: _num('Latitude', _shopLat)),
                  const SizedBox(width: 12),
                  Expanded(child: _num('Longitude', _shopLng)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Free delivery ──
              _section('Free Delivery',
                  'Deliveries qualify for free shipping either way.'),
              _num('Free within radius (km)', _freeRadius, suffix: 'km'),
              _num('Free on orders above', _freeOrderValue, suffix: _currency),
              const SizedBox(height: 20),

              // ── Distance charges ──
              _section('Distance Charges',
                  'Applied beyond the free radius, up to the max distance.'),
              _num('Base fee (flat, beyond free radius)', _baseFee, suffix: _currency),
              _num('Per-km charge', _perKm, suffix: '$_currency/km'),
              _num('Max own-delivery distance', _maxRadius, suffix: 'km'),
              const SizedBox(height: 20),

              // ── Third-party ──
              _switchCard(
                title: 'Third-party courier (beyond max distance)',
                subtitle: _thirdPartyEnabled
                    ? 'Far orders are delivered by a partner at a flat fee.'
                    : 'Off — orders beyond the max distance are not deliverable.',
                value: _thirdPartyEnabled,
                onChanged: (v) => setState(() => _thirdPartyEnabled = v),
              ),
              const SizedBox(height: 14),
              if (_thirdPartyEnabled) ...[
                _text('Partner courier name', _thirdPartyName),
                _num('Partner flat fee', _thirdPartyFee, suffix: _currency),
              ],
              const SizedBox(height: 8),

              // ── Express ──
              _section('Express Delivery', 'Flat premium for 1–2 day delivery.'),
              _num('Express surcharge', _expressSurcharge, suffix: _currency),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save Delivery Settings'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Interactive map — tap to drop the shop pin; reverse-fills the address.
  Widget _mapPicker() {
    final point = _shopPoint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.touch_app_outlined,
                size: 15, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Expanded(
              child: Text('Tap the map to drop your shop pin',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 280,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: point,
                initialZoom: 12,
                onTap: (tapPos, p) {
                  _applyPoint(p.latitude, p.longitude, moveMap: false);
                  _reverseFillAddress(p.latitude, p.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // OSM tile usage policy asks for an identifying UA. Matches
                  // the bundle id each brand actually ships under.
                  userAgentPackageName: 'com.${Brand.current.key}.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 46,
                      height: 46,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_pin,
                          color: AppColors.primary, size: 46),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, [String? subtitle]) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
          ],
        ),
      );

  Widget _text(String label, TextEditingController c, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  Widget _num(String label, TextEditingController c, {String? suffix}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
          ],
          decoration: InputDecoration(
            labelText: label,
            suffixText: suffix,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  Widget _switchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(subtitle,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
      );
}

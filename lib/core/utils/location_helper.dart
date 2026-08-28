import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

/// Address components resolved from a GPS position.
class ResolvedAddress {
  final String street;
  final String city;
  final String state;
  final String pinCode;
  final double? lat;
  final double? lng;
  const ResolvedAddress({
    this.street = '',
    this.city = '',
    this.state = '',
    this.pinCode = '',
    this.lat,
    this.lng,
  });
}

/// Reads the device's current position, surfacing the browser/OS permission
/// prompt on first use. Throws an [Exception] with a human-readable message.
Future<Position> getCurrentPosition() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw Exception(
        'Location permission denied. Please allow access and try again.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception(
        'Location access is blocked. Enable it in your browser/site settings.');
  }
  return Geolocator.getCurrentPosition();
}

/// Reverse-geocode coordinates into an address via the backend (avoids browser
/// CORS on the geocoding provider and keeps the lookup server-side).
Future<ResolvedAddress> reverseGeocode(Dio dio, double lat, double lng) async {
  final res = await dio.get('/geocode', queryParameters: {
    'lat': lat,
    'lon': lng,
  });
  final data = Map<String, dynamic>.from(res.data as Map);
  return ResolvedAddress(
    street: (data['street'] ?? '').toString(),
    city: (data['city'] ?? '').toString(),
    state: (data['state'] ?? '').toString(),
    pinCode: (data['pinCode'] ?? '').toString(),
    lat: lat,
    lng: lng,
  );
}

/// Detects the current position and reverse-geocodes it into an address.
Future<ResolvedAddress> resolveCurrentAddress(Dio dio) async {
  final position = await getCurrentPosition();
  try {
    return await reverseGeocode(dio, position.latitude, position.longitude);
  } on DioException {
    // The geocoding provider can be unavailable (e.g. it blocks datacenter IPs
    // in production). Fail with a friendly, actionable message instead of a raw
    // Dio error dump so the user can just type their address.
    throw Exception(
        'Could not detect your address automatically. Please enter it manually.');
  }
}

/// Forward-geocode a free-text address into coordinates via the backend.
/// Returns null when no match is found.
Future<({double lat, double lng})?> forwardGeocodeAddress(
    Dio dio, String query) async {
  try {
    final res = await dio.get('/geocode-forward',
        queryParameters: {'q': query});
    final data = Map<String, dynamic>.from(res.data as Map);
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  } catch (_) {
    return null;
  }
}

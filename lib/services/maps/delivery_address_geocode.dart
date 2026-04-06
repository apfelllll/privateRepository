import 'dart:convert';

import 'package:http/http.dart' as http;

/// Ermittelt Koordinaten für einen präzisen Karten-Pin (Google Embed: `q=lat,lng`).
///
/// 1) Mit `GOOGLE_MAPS_EMBED_API_KEY`: Google Geocoding API (Geocoding in der Cloud Console aktivieren).
/// 2) Sonst: Nominatim (OpenStreetMap) als Fallback (Nutzungsrichtlinien beachten).
Future<({double lat, double lng})?> geocodeAddressForMapPin(String address) async {
  final trimmed = address.trim();
  if (trimmed.isEmpty) return null;

  const googleKey = String.fromEnvironment('GOOGLE_MAPS_EMBED_API_KEY');
  if (googleKey.isNotEmpty) {
    final google = await _geocodeGoogle(trimmed, googleKey);
    if (google != null) return google;
  }

  return _geocodeNominatim(trimmed);
}

Future<({double lat, double lng})?> _geocodeGoogle(
  String address,
  String apiKey,
) async {
  try {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'address': address,
      'key': apiKey,
      'language': 'de',
      'region': 'de',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;
    final loc = (results.first as Map<String, dynamic>)['geometry']
        as Map<String, dynamic>?;
    final location = loc?['location'] as Map<String, dynamic>?;
    if (location == null) return null;
    final lat = (location['lat'] as num).toDouble();
    final lng = (location['lng'] as num).toDouble();
    return (lat: lat, lng: lng);
  } catch (_) {
    return null;
  }
}

Future<({double lat, double lng})?> _geocodeNominatim(String address) async {
  try {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': address,
      'format': 'json',
      'limit': '1',
    });
    final res = await http.get(
      uri,
      headers: {
        'User-Agent': 'DoorDesk/1.0 (Flutter; Metisia Business Software)',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode != 200) return null;
    final list = jsonDecode(res.body) as List<dynamic>;
    if (list.isEmpty) return null;
    final first = list.first as Map<String, dynamic>;
    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;
    return (lat: lat, lng: lon);
  } catch (_) {
    return null;
  }
}

/// `lat,lng` für Google Embed / Such-URLs (englische Dezimalpunkte).
String formatLatLngForGoogleMaps(double lat, double lng) =>
    '${lat.toStringAsFixed(7)},${lng.toStringAsFixed(7)}';

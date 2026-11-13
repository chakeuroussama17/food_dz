import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// A place found by address search.
class Place {
  const Place({
    required this.label,
    required this.lat,
    required this.lng,
    this.area = '',
  });

  /// Full readable address ("12 Rue Didouche Mourad, Alger Centre…").
  final String label;

  /// Commune / neighbourhood, used for the "Area" field.
  final String area;
  final double lat;
  final double lng;
}

/// Address search on the map, and the address of a map point.
abstract interface class Geocoder {
  Future<List<Place>> search(String query, {required String lang});
  Future<Place?> reverse(double lat, double lng, {required String lang});
}

/// OpenStreetMap's free Nominatim service, limited to Algeria.
/// Fine for testing and small traffic (max ~1 request per second). Before a
/// big launch, switch to a paid geocoder (MapTiler, LocationIQ…).
class NominatimGeocoder implements Geocoder {
  NominatimGeocoder([http.Client? client]) : _http = client ?? http.Client();
  final http.Client _http;

  static const _host = 'nominatim.openstreetmap.org';

  Map<String, String> get _headers => {
    // Nominatim asks apps to identify themselves (browsers send their own).
    if (!kIsWeb) 'User-Agent': 'foodfennec/0.1 (dz.foodapp.food_app)',
  };

  static String _area(Map<String, dynamic>? a) {
    if (a == null) return '';
    for (final k in [
      'suburb',
      'neighbourhood',
      'city_district',
      'town',
      'city',
      'village',
      'municipality',
    ]) {
      final v = a[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return '';
  }

  static Place _place(Map<String, dynamic> j) => Place(
    label: (j['display_name'] as String?) ?? '',
    lat: double.parse(j['lat'].toString()),
    lng: double.parse(j['lon'].toString()),
    area: _area(j['address'] as Map<String, dynamic>?),
  );

  @override
  Future<List<Place>> search(String query, {required String lang}) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final res = await _http.get(
      Uri.https(_host, '/search', {
        'q': q,
        'format': 'jsonv2',
        'countrycodes': 'dz',
        'addressdetails': '1',
        'limit': '6',
        'accept-language': lang,
      }),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('search ${res.statusCode}');
    return [
      for (final j in jsonDecode(res.body) as List)
        _place(j as Map<String, dynamic>),
    ];
  }

  @override
  Future<Place?> reverse(double lat, double lng, {required String lang}) async {
    final res = await _http.get(
      Uri.https(_host, '/reverse', {
        'lat': '$lat',
        'lon': '$lng',
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '18',
        'accept-language': lang,
      }),
      headers: _headers,
    );
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['lat'] == null) return null;
    return _place(j);
  }
}

/// Overridden in tests.
final geocoderProvider = Provider<Geocoder>((ref) => NominatimGeocoder());

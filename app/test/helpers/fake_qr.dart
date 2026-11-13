import 'package:flutter/material.dart';
import 'package:food_app/features/qr/qr_repository.dart';

/// In-memory QR settings and scan log.
class FakeQrRepository implements QrRepository {
  String baseUrl = kDefaultPublicBaseUrl;
  final visits = <String>[];
  QrStats statsValue = const QrStats();

  @override
  Future<String> publicBaseUrl() async => baseUrl;

  @override
  Future<void> logVisit(String slug, String source) async =>
      visits.add('$slug:$source');

  @override
  Future<QrStats> stats(String restaurantId) async => statsValue;

  @override
  Future<String> setPublicBaseUrl(String url) async =>
      baseUrl = url.trim().replaceFirst(RegExp(r'/+$'), '').toLowerCase();
}

/// Stands in for the camera: a button per code to "scan".
class FakeCamera {
  final codes = <String>[];

  Widget build(BuildContext context, ValueChanged<String> onCode) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (final c in codes)
        TextButton(
          key: Key('scan:$c'),
          onPressed: () => onCode(c),
          child: Text(c),
        ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../l10n/app_localizations.dart';
import '../location/location_service.dart';
import '../theme/app_colors.dart';
import 'circle_icon_button.dart';
import 'snack.dart';

/// Map tiles source. Overridden in tests (no disk cache there).
/// Before launch, switch to a tile provider with a key (MapTiler, Stadia…):
/// the public OpenStreetMap servers are not for production traffic.
final mapTileProvider = Provider<TileProvider>((ref) => NetworkTileProvider());

/// Algiers centre, used when we don't know where the user is.
const algiersCenter = LatLng(36.7538, 3.0588);

/// Map with a fixed pin at its exact centre: the user moves the map to
/// place it. Includes a "my location" button and the "Move the map…" tip
/// (Add New Address design). [topStart] is drawn over the top-start corner
/// (e.g. a back button).
class MapPinPicker extends ConsumerStatefulWidget {
  const MapPinPicker({
    super.key,
    required this.initial,
    required this.onChanged,
    this.topStart,
    this.topPadding = 0,
    this.zoom = 16,
  });

  final LatLng initial;
  final ValueChanged<LatLng> onChanged;
  final Widget? topStart;

  /// Extra space at the top (status bar) for [topStart].
  final double topPadding;
  final double zoom;

  @override
  ConsumerState<MapPinPicker> createState() => _MapPinPickerState();
}

class _MapPinPickerState extends ConsumerState<MapPinPicker> {
  final _map = MapController();
  bool _locating = false;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _locateMe() async {
    final l = AppLocalizations.of(context);
    setState(() => _locating = true);
    final r = await ref.read(locationProvider.notifier).locate();
    if (!mounted) return;
    setState(() => _locating = false);
    final p = ref.read(locationProvider).position;
    if (r == LocationResult.granted && p != null) {
      final ll = LatLng(p.lat, p.lng);
      _map.move(ll, 17);
      widget.onChanged(ll);
    } else {
      showAppSnack(context, l.locationDenied, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: widget.initial,
              initialZoom: widget.zoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) widget.onChanged(camera.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dz.foodapp.food_app',
                tileProvider: ref.watch(mapTileProvider),
              ),
              const SimpleAttributionWidget(source: Text('OpenStreetMap')),
            ],
          ),
        ),
        // Pin exactly at the map centre (that point is what gets saved),
        // with the tip above it.
        IgnorePointer(
          child: Padding(
            padding: EdgeInsets.zero,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(
                          color: const Color(0x55FF7622),
                          width: 6,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 44,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inkSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l.moveMapHint,
                          softWrap: false,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.topStart != null)
          PositionedDirectional(
            start: 24,
            top: widget.topPadding + 16,
            child: widget.topStart!,
          ),
        PositionedDirectional(
          end: 16,
          bottom: 16,
          child: CircleIconButton(
            icon: _locating
                ? Icons.hourglass_top_rounded
                : Icons.my_location_rounded,
            background: Colors.white,
            foreground: AppColors.primary,
            tooltip: l.useMyLocation,
            onPressed: _locating ? null : _locateMe,
          ),
        ),
      ],
    );
  }
}

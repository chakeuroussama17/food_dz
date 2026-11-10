import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'dart:async';

import '../../l10n/app_localizations.dart';
import '../location/geocoding.dart';
import '../location/location_help.dart';
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
    this.onPlace,
  });

  final LatLng initial;
  final ValueChanged<LatLng> onChanged;

  /// A place picked in the search box (to fill the address fields).
  final ValueChanged<Place>? onPlace;
  final Widget? topStart;

  /// Extra space at the top (status bar) for [topStart].
  final double topPadding;
  final double zoom;

  @override
  ConsumerState<MapPinPicker> createState() => _MapPinPickerState();
}

class _MapPinPickerState extends ConsumerState<MapPinPicker> {
  final _map = MapController();
  final _search = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<Place> _results = const [];
  bool _searching = false;
  bool _locating = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _focus.dispose();
    _map.dispose();
    super.dispose();
  }

  /// Searches 600 ms after the last key (the free service allows about one
  /// request per second).
  void _onQuery(String q) {
    _debounce?.cancel();
    setState(() {});
    if (q.trim().length < 3) {
      setState(() => _results = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _run(q));
  }

  Future<void> _run(String q) async {
    final lang = Localizations.localeOf(context).languageCode;
    setState(() => _searching = true);
    try {
      final r = await ref.read(geocoderProvider).search(q, lang: lang);
      if (mounted && _search.text == q) setState(() => _results = r);
    } catch (_) {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _pick(Place p) {
    final ll = LatLng(p.lat, p.lng);
    _map.move(ll, 17);
    widget.onChanged(ll);
    widget.onPlace?.call(p);
    _focus.unfocus();
    setState(() {
      _results = const [];
      _search.clear();
    });
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
    } else if (r == LocationResult.granted) {
      showAppSnack(context, l.locationUnavailable, error: true);
    } else {
      showLocationProblem(context, r);
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
        // Address search over the map.
        PositionedDirectional(
          start: widget.topStart != null ? 24 + 45 + 12 : 16,
          end: 16,
          top: widget.topPadding + 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                elevation: 3,
                shadowColor: const Color(0x33000000),
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: TextField(
                  controller: _search,
                  focusNode: _focus,
                  onChanged: _onQuery,
                  onSubmitted: _run,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: l.searchAddressHint,
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.muted,
                    ),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : (_search.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() => _results = const []);
                                  },
                                )),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              if (_results.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Material(
                    color: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (_, i) => ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.place_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            _results[i].label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                          onTap: () => _pick(_results[i]),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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

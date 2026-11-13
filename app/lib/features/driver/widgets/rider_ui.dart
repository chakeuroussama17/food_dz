import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/map_pin_picker.dart';
import '../../../l10n/app_localizations.dart';

// Rider screens, after the "Panda-GO" rider prototype: a map behind, white
// rounded cards with a soft shadow, centred bold titles, and one big pill
// button per step. Our orange replaces the prototype's pink.

/// Soft shadow under every rider card.
List<BoxShadow> get riderShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: AppColors.isDark ? .35 : .10),
    blurRadius: 18,
    offset: const Offset(0, 6),
  ),
];

/// Light shadow for small things over the map (pills, tags).
List<BoxShadow> get riderSmallShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: AppColors.isDark ? .30 : .08),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
];

/// White rounded card with a soft shadow.
class RiderCard extends StatelessWidget {
  const RiderCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: riderShadow,
    ),
    child: Material(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

/// The big pill button of each step ("Start riding", "Delivered"…).
class RiderButton extends StatelessWidget {
  const RiderButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.secondary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  /// Light orange instead of filled ("I'm done for the day").
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final bg = secondary ? AppColors.primarySoft : AppColors.primary;
    final fg = secondary ? AppColors.primary : Colors.white;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled ? bg : bg.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: 54,
            child: Center(
              child: loading
                  ? SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: fg,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: fg, size: 24),
                            const SizedBox(width: 12),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: fg,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round orange action (call, directions) on the address cards.
class RoundAction extends StatelessWidget {
  const RoundAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 48,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, color: Colors.white, size: size * .5),
        ),
      ),
    ),
  );
}

/// Small white pill over the map: icon + value ("1.2 km", "2", "1 600 DA").
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;

  /// Read by screen readers.
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: riderSmallShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

/// What a pin on the rider map stands for.
enum RiderPinKind { restaurant, customer }

class RiderPin {
  const RiderPin(
    this.kind,
    this.lat,
    this.lng, {
    this.label,
    this.onTap,
    this.onRoute = true,
  });
  final RiderPinKind kind;

  /// Part of the dashed route (the restaurant is not, once picked up).
  final bool onRoute;
  final double lat;
  final double lng;

  /// Small tag above the pin (e.g. the fee of an available job).
  final String? label;
  final VoidCallback? onTap;
}

/// Map with the rider (blue dot), restaurants and customers. It frames all
/// the points; with none it shows Algiers. A dashed line joins the rider
/// and the stops of a delivery when [route] is true.
///
/// With [follow], the map keeps the rider and the stops in view as the
/// rider moves, until the rider moves the map by hand; a "re-centre"
/// button then brings the automatic framing back.
class RiderMap extends ConsumerStatefulWidget {
  const RiderMap({
    super.key,
    required this.pins,
    this.me,
    this.route = false,
    this.follow = false,
    this.padding = const EdgeInsets.all(48),
    this.interactive = true,
    this.meIcon,
  });
  final List<RiderPin> pins;
  final GeoPoint? me;

  /// Draws [me] as an orange round icon (the rider seen by the customer)
  /// instead of the blue dot.
  final IconData? meIcon;
  final bool route;
  final bool follow;

  /// Space kept free around the points (cards drawn over the map).
  final EdgeInsets padding;
  final bool interactive;

  @override
  ConsumerState<RiderMap> createState() => _RiderMapState();
}

class _RiderMapState extends ConsumerState<RiderMap> {
  final _map = MapController();
  bool _ready = false;
  late bool _following = widget.follow;

  List<LatLng> _points(RiderMap w) => [
    for (final p in w.pins) LatLng(p.lat, p.lng),
    if (w.me != null) LatLng(w.me!.lat, w.me!.lng),
  ];

  CameraFit _fit(List<LatLng> points) => CameraFit.coordinates(
    coordinates: points,
    padding: widget.padding,
    maxZoom: 16,
  );

  void _frame() {
    final points = _points(widget);
    if (!_ready || points.isEmpty) return;
    _map.fitCamera(_fit(points));
  }

  @override
  void didUpdateWidget(RiderMap old) {
    super.didUpdateWidget(old);
    final pinsChanged =
        old.pins.length != widget.pins.length ||
        [
          for (var i = 0; i < widget.pins.length; i++)
            old.pins[i].lat != widget.pins[i].lat ||
                old.pins[i].lng != widget.pins[i].lng,
        ].any((x) => x);
    final meMoved =
        old.me?.lat != widget.me?.lat || old.me?.lng != widget.me?.lng;
    // New jobs or stops: frame again. A rider who moves: only in follow
    // mode, and not while the rider is looking around by hand.
    if ((pinsChanged && (!widget.follow || _following)) ||
        (meMoved && _following)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _frame();
      });
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final me = w.me;
    final points = _points(w);
    // Rider first, then the stops in order.
    final routePoints = [
      if (me != null) LatLng(me.lat, me.lng),
      for (final p in w.pins)
        if (p.onRoute) LatLng(p.lat, p.lng),
    ];
    final flags = w.interactive
        ? InteractiveFlag.all & ~InteractiveFlag.rotate
        : InteractiveFlag.none;
    final options = MapOptions(
      initialCameraFit: points.isEmpty ? null : _fit(points),
      initialCenter: algiersCenter,
      initialZoom: 12,
      interactionOptions: InteractionOptions(flags: flags),
      onMapReady: () => _ready = true,
      onPositionChanged: (_, hasGesture) {
        if (hasGesture && _following) setState(() => _following = false);
      },
    );
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: options,
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dz.foodapp.food_app',
              tileProvider: ref.watch(mapTileProvider),
            ),
            if (w.route && routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4,
                    color: AppColors.primary.withValues(alpha: .8),
                    pattern: StrokePattern.dashed(segments: const [10, 8]),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final p in w.pins)
                  Marker(
                    point: LatLng(p.lat, p.lng),
                    width: 90,
                    height: 70,
                    alignment: Alignment.topCenter,
                    child: _PinWidget(pin: p),
                  ),
                if (me != null && w.meIcon != null)
                  Marker(
                    point: LatLng(me.lat, me.lng),
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: riderSmallShadow,
                      ),
                      child: Icon(w.meIcon, color: Colors.white, size: 22),
                    ),
                  )
                else if (me != null)
                  Marker(
                    point: LatLng(me.lat, me.lng),
                    width: 26,
                    height: 26,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F80ED),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: riderSmallShadow,
                      ),
                    ),
                  ),
              ],
            ),
            const SimpleAttributionWidget(source: Text('OpenStreetMap')),
          ],
        ),
        if (w.follow && !_following)
          PositionedDirectional(
            end: 16,
            top: w.padding.top - 4,
            child: Material(
              color: AppColors.surface,
              shape: const CircleBorder(),
              elevation: 3,
              shadowColor: Colors.black26,
              child: IconButton(
                key: const Key('recenter'),
                tooltip: l.recenterMap,
                icon: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() => _following = true);
                  _frame();
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _PinWidget extends StatelessWidget {
  const _PinWidget({required this.pin});
  final RiderPin pin;

  @override
  Widget build(BuildContext context) {
    final shop = pin.kind == RiderPinKind.restaurant;
    final circle = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: shop ? AppColors.primary : AppColors.night,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: riderSmallShadow,
      ),
      child: Icon(
        shop ? Icons.storefront_rounded : Icons.home_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
    return GestureDetector(
      onTap: pin.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (pin.label != null)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: riderSmallShadow,
              ),
              child: Text(
                pin.label!,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          circle,
        ],
      ),
    );
  }
}

/// Big orange tick with a few confetti around ("Well done!").
class DoneBadge extends StatelessWidget {
  const DoneBadge({super.key, this.size = 180});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.5,
    height: size,
    child: CustomPaint(
      painter: _ConfettiPainter(),
      child: Center(
        child: Container(
          width: size * .5,
          height: size * .5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, AppColors.primary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: size * .3,
          ),
        ),
      ),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(7); // the same confetti every time
    const colors = [
      AppColors.primary,
      AppColors.accent,
      Color(0xFF5B8DEF),
      Color(0xFF1B2A4A),
      AppColors.success,
    ];
    final c = size.center(Offset.zero);
    for (var i = 0; i < 22; i++) {
      final angle = r.nextDouble() * math.pi * 2;
      final dist = size.height * (.32 + r.nextDouble() * .2);
      final p =
          c + Offset(math.cos(angle) * dist * 1.4, math.sin(angle) * dist);
      final paint = Paint()..color = colors[i % colors.length];
      switch (i % 4) {
        case 0:
          canvas.drawCircle(p, 3 + r.nextDouble() * 2, paint);
        case 1:
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(angle);
          canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), paint);
          canvas.restore();
        case 2:
          final path = Path()
            ..moveTo(p.dx, p.dy - 5)
            ..lineTo(p.dx + 5, p.dy + 4)
            ..lineTo(p.dx - 5, p.dy + 4)
            ..close();
          canvas.drawPath(path, paint);
        default:
          final path = Path()..moveTo(p.dx - 9, p.dy);
          for (var k = 0; k < 3; k++) {
            path.relativeQuadraticBezierTo(3, k.isEven ? -5 : 5, 6, 0);
          }
          canvas.drawPath(
            path,
            paint
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

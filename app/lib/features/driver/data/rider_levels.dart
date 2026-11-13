import '../../../l10n/app_localizations.dart';
import 'driver_repository.dart';

/// Rider levels: earned with deliveries, kept with a good rating.
enum RiderLevel {
  rookie(0, null),
  pro(20, 4.0),
  expert(100, 4.5),
  legend(500, 4.7);

  const RiderLevel(this.deliveries, this.minRating);

  /// Deliveries needed.
  final int deliveries;

  /// Average needed (none for rookies).
  final double? minRating;

  String label(AppLocalizations l) => switch (this) {
    rookie => l.levelRookie,
    pro => l.levelPro,
    expert => l.levelExpert,
    legend => l.levelLegend,
  };

  RiderLevel? get next => index + 1 < RiderLevel.values.length
      ? RiderLevel.values[index + 1]
      : null;

  bool reachedBy(DriverStats s) =>
      s.deliveries >= deliveries &&
      (minRating == null || (s.average ?? 0) >= minRating!);

  /// The highest level [s] has reached.
  static RiderLevel of(DriverStats s) =>
      RiderLevel.values.lastWhere((v) => v.reachedBy(s));

  /// 0..1 towards [next] (by deliveries).
  double progress(DriverStats s) {
    final n = next;
    if (n == null) return 1;
    return ((s.deliveries - deliveries) / (n.deliveries - deliveries)).clamp(
      0,
      1,
    );
  }
}

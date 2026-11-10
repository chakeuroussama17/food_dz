import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_help.dart';
import '../../core/location/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../l10n/app_localizations.dart';

/// Location Access: illustration, ACCESS LOCATION button with a pin icon,
/// explanation in small caps. Shown once after login; skippable.
class LocationAccessPage extends ConsumerStatefulWidget {
  const LocationAccessPage({super.key});

  @override
  ConsumerState<LocationAccessPage> createState() => _LocationAccessPageState();
}

class _LocationAccessPageState extends ConsumerState<LocationAccessPage> {
  bool _busy = false;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _access() async {
    setState(() => _busy = true);
    final r = await ref.read(locationProvider.notifier).locate();
    if (!mounted) return;
    setState(() => _busy = false);
    if (r != LocationResult.granted) {
      showLocationProblem(context, r);
    }
    _close();
  }

  Future<void> _skip() async {
    await ref.read(locationProvider.notifier).markAsked();
    if (mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // Placeholder for the map illustration (not in the file).
                  Container(
                    width: 206,
                    height: 250,
                    decoration: BoxDecoration(
                      color: AppColors.field,
                      borderRadius: BorderRadius.circular(90),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 96,
                    ),
                  ),
                  const Spacer(flex: 2),
                  AppButton(
                    label: l.accessLocation,
                    loading: _busy,
                    onPressed: _access,
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 37),
                  Text(
                    l.locationExplain,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.body,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy ? null : _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.body,
                    ),
                    child: Text(l.notNow, style: const TextStyle(fontSize: 16)),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/snack.dart';
import '../../l10n/app_localizations.dart';
import 'qr_repository.dart';

/// The camera view, replaced in tests (no camera there).
typedef QrCameraBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onCode);

final qrCameraProvider = Provider<QrCameraBuilder>(
  (ref) =>
      (context, onCode) => _Camera(onCode: onCode),
);

/// /scan: scan a restaurant's QR code and open its page. Codes that aren't
/// ours are refused with a message.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  bool _done = false;
  String? _lastBad;

  void _onCode(String raw) {
    if (_done) return;
    final path = appPathFromScan(raw);
    if (path == null) {
      if (raw != _lastBad) {
        _lastBad = raw;
        showAppSnack(
          context,
          AppLocalizations.of(context).scanNotOurs,
          error: true,
        );
      }
      return;
    }
    _done = true;
    context.pushReplacement('$path?src=app');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final camera = ref.watch(qrCameraProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          camera(context, _onCode),
          // Frame to aim at.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.primary, width: 4),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton.filled(
                        tooltip: l.back,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/home'),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/brand/mark.png', width: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.scanTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              l.scanHint,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Camera extends StatefulWidget {
  const _Camera({required this.onCode});
  final ValueChanged<String> onCode;

  @override
  State<_Camera> createState() => _CameraState();
}

class _CameraState extends State<_Camera> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        for (final b in capture.barcodes) {
          final v = b.rawValue;
          if (v != null && v.isNotEmpty) {
            widget.onCode(v);
            return;
          }
        }
      },
      errorBuilder: (context, error) => ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  color: Colors.white70,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? l.scanCameraDenied
                      : l.scanCameraError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

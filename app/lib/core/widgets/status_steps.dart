import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Vertical order progress: done steps orange with a check, current step
/// orange ring, future steps grey. Used on the customer tracking page.
class StatusSteps extends StatelessWidget {
  const StatusSteps({
    super.key,
    required this.steps,
    required this.currentIndex,
    this.failedLabel,
  });

  final List<StatusStep> steps;

  /// Index of the step currently in progress. steps.length = all done.
  final int currentIndex;

  /// If set (rejected / cancelled) a red final row is shown instead.
  final String? failedLabel;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final done =
          i < currentIndex || (i == currentIndex && i == steps.length - 1);
      final current = i == currentIndex && !done && failedLabel == null;
      rows.add(
        _row(
          context,
          label: steps[i].label,
          time: steps[i].time,
          state: done
              ? _S.done
              : current
              ? _S.current
              : _S.todo,
          isLast: i == steps.length - 1 && failedLabel == null,
        ),
      );
    }
    if (failedLabel != null) {
      rows.add(
        _row(
          context,
          label: failedLabel!,
          time: null,
          state: _S.failed,
          isLast: true,
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required String? time,
    required _S state,
    required bool isLast,
  }) {
    final color = switch (state) {
      _S.done || _S.current => AppColors.primary,
      _S.failed => AppColors.danger,
      _S.todo => AppColors.border,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state == _S.current ? Colors.white : color,
                    border: Border.all(color: color, width: 3),
                  ),
                  child: switch (state) {
                    _S.done => const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    _S.failed => const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    _ => null,
                  },
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: state == _S.done
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: state == _S.current
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: state == _S.todo
                            ? AppColors.muted
                            : state == _S.failed
                            ? AppColors.danger
                            : AppColors.ink,
                      ),
                    ),
                  ),
                  if (time != null)
                    Text(time, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _S { done, current, todo, failed }

class StatusStep {
  const StatusStep(this.label, {this.time});
  final String label;
  final String? time;
}

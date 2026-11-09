import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Labels and colours for `public.order_status`, shared by the customer,
/// restaurant, driver and admin screens.
String orderStatusLabel(AppLocalizations l, String status) => switch (status) {
  'placed' => l.statusPlaced,
  'accepted' => l.statusAccepted,
  'rejected' => l.statusRejected,
  'ready' => l.statusReady,
  'picked_up' => l.statusPickedUp,
  'delivered' => l.statusDelivered,
  'cancelled' => l.statusCancelled,
  _ => status,
};

Color orderStatusColor(String status) => switch (status) {
  'delivered' => AppColors.success,
  'rejected' || 'cancelled' => AppColors.danger,
  _ => AppColors.primary,
};

const activeOrderStatuses = {'placed', 'accepted', 'ready', 'picked_up'};

/// Reject / cancel reason for display: system codes are translated, text
/// typed by the restaurant is shown as is.
String rejectReasonText(AppLocalizations l, String reason) => switch (reason) {
  'no_answer' => l.reasonNoAnswer,
  _ => reason,
};

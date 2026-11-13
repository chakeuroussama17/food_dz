import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../catalog/data/catalog_models.dart';

/// An option group as the restaurant manages it: the group, its choices
/// and the dishes using it.
class OwnerOptionGroup {
  const OwnerOptionGroup({required this.group, this.itemIds = const []});
  final OptionGroup group;
  final List<String> itemIds;

  factory OwnerOptionGroup.fromJson(Map<String, dynamic> j) => OwnerOptionGroup(
    group: OptionGroup.fromJson(j),
    itemIds: [
      for (final l in (j['menu_item_groups'] as List? ?? const []))
        (l as Map)['menu_item_id'] as String,
    ],
  );
}

/// One opening slot of a weekday (0 = Saturday). "HH:mm"; closes before
/// opens means after midnight.
class HourSlot {
  const HourSlot(this.weekday, this.opens, this.closes);
  final int weekday;
  final String opens;
  final String closes;

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'opens': opens,
    'closes': closes,
  };

  @override
  bool operator ==(Object other) =>
      other is HourSlot &&
      other.weekday == weekday &&
      other.opens == opens &&
      other.closes == closes;

  @override
  int get hashCode => Object.hash(weekday, opens, closes);
}

/// A holiday (closed) or a date with special hours.
class SpecialDay {
  const SpecialDay({
    required this.day,
    required this.closed,
    this.opens,
    this.closes,
    this.note = '',
  });

  final DateTime day;
  final bool closed;
  final String? opens;
  final String? closes;
  final String note;

  factory SpecialDay.fromJson(Map<String, dynamic> j) => SpecialDay(
    day: DateTime.parse(j['day'] as String),
    closed: (j['closed'] as bool?) ?? true,
    opens: j['opens'] as String?,
    closes: j['closes'] as String?,
    note: (j['note'] as String?) ?? '',
  );
}

class OutletHours {
  const OutletHours({
    this.weekly = const [],
    this.special = const [],
    this.switchOn = false,
    this.openNow = false,
    this.nextOpenAt,
  });

  final List<HourSlot> weekly;
  final List<SpecialDay> special;

  /// The restaurant's own open / closed switch.
  final bool switchOn;

  /// Switch on and within the hours.
  final bool openNow;
  final DateTime? nextOpenAt;

  factory OutletHours.fromJson(Map<String, dynamic> j) => OutletHours(
    weekly: [
      for (final h in (j['hours'] as List? ?? const []))
        HourSlot(
          ((h as Map)['weekday'] as num).toInt(),
          h['opens'] as String,
          h['closes'] as String,
        ),
    ],
    special: [
      for (final s in (j['special'] as List? ?? const []))
        SpecialDay.fromJson(Map<String, dynamic>.from(s as Map)),
    ],
    switchOn: (j['switch_on'] as bool?) ?? false,
    openNow: (j['open_now'] as bool?) ?? false,
    nextOpenAt: j['next_open_at'] == null
        ? null
        : DateTime.parse(j['next_open_at'] as String).toLocal(),
  );
}

/// Bulk actions on dishes.
enum BulkAction { show, hide, category, pricePercent, priceAdd, delete }

/// Menu options, bulk edits and opening hours of an outlet (managers).
abstract interface class OutletAdminRepository {
  Future<List<OwnerOptionGroup>> optionGroups(String restaurantId);

  /// Creates (no [id]) or updates a group. Returns its id.
  Future<String> saveOptionGroup(
    String restaurantId, {
    String? id,
    required String name,
    required int min,
    required int max,
    required List<OptionChoice> choices,
    required List<String> itemIds,
  });
  Future<void> deleteOptionGroup(String groupId);
  Future<void> setItemGroups(String itemId, List<String> groupIds);
  Future<void> setChoiceAvailable(String choiceId, bool available);

  /// Returns how many dishes changed.
  Future<int> bulkItems(
    String restaurantId,
    List<String> itemIds,
    BulkAction action, {
    num? number,
    String? categoryId,
  });

  Future<OutletHours> hours(String restaurantId);
  Future<void> setHours(String restaurantId, List<HourSlot> slots);
  Future<void> setSpecialDay(String restaurantId, SpecialDay day);
  Future<void> deleteSpecialDay(String restaurantId, DateTime day);
}

String _date(DateTime d) =>
    '${d.year}-${'${d.month}'.padLeft(2, '0')}-${'${d.day}'.padLeft(2, '0')}';

class SupabaseOutletAdminRepository implements OutletAdminRepository {
  SupabaseOutletAdminRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<List<OwnerOptionGroup>> optionGroups(String restaurantId) async {
    final rows = await _db
        .from('option_groups')
        .select(
          'id, name, min_select, max_select, sort_order, '
          'option_choices(id, name, price, is_available, sort_order), '
          'menu_item_groups(menu_item_id)',
        )
        .eq('restaurant_id', restaurantId)
        .order('sort_order');
    return rows.map(OwnerOptionGroup.fromJson).toList();
  }

  @override
  Future<String> saveOptionGroup(
    String restaurantId, {
    String? id,
    required String name,
    required int min,
    required int max,
    required List<OptionChoice> choices,
    required List<String> itemIds,
  }) async {
    final r = await _db.rpc(
      'owner_save_option_group',
      params: {
        'p_restaurant_id': restaurantId,
        'p_group': {
          'id': ?id,
          'name': name.trim(),
          'min': min,
          'max': max,
          'choices': [
            for (final c in choices)
              {
                if (c.id.isNotEmpty) 'id': c.id,
                'name': c.name.trim(),
                'price': c.price,
                'available': c.isAvailable,
              },
          ],
          'item_ids': itemIds,
        },
      },
    );
    return r as String;
  }

  @override
  Future<void> deleteOptionGroup(String groupId) =>
      _db.rpc('owner_delete_option_group', params: {'p_group_id': groupId});

  @override
  Future<void> setItemGroups(String itemId, List<String> groupIds) => _db.rpc(
    'owner_set_item_groups',
    params: {'p_item_id': itemId, 'p_group_ids': groupIds},
  );

  @override
  Future<void> setChoiceAvailable(String choiceId, bool available) => _db.rpc(
    'owner_set_choice_available',
    params: {'p_choice_id': choiceId, 'p_available': available},
  );

  @override
  Future<int> bulkItems(
    String restaurantId,
    List<String> itemIds,
    BulkAction action, {
    num? number,
    String? categoryId,
  }) async {
    final r = await _db.rpc(
      'owner_bulk_items',
      params: {
        'p_restaurant_id': restaurantId,
        'p_ids': itemIds,
        'p_action': switch (action) {
          BulkAction.show => 'show',
          BulkAction.hide => 'hide',
          BulkAction.category => 'category',
          BulkAction.pricePercent => 'price_percent',
          BulkAction.priceAdd => 'price_add',
          BulkAction.delete => 'delete',
        },
        'p_number': number,
        'p_category': categoryId,
      },
    );
    return (r as num).toInt();
  }

  @override
  Future<OutletHours> hours(String restaurantId) async => OutletHours.fromJson(
    Map<String, dynamic>.from(
      await _db.rpc('owner_hours', params: {'p_restaurant_id': restaurantId})
          as Map,
    ),
  );

  @override
  Future<void> setHours(String restaurantId, List<HourSlot> slots) => _db.rpc(
    'owner_set_hours',
    params: {
      'p_restaurant_id': restaurantId,
      'p_hours': [for (final s in slots) s.toJson()],
    },
  );

  @override
  Future<void> setSpecialDay(String restaurantId, SpecialDay day) => _db.rpc(
    'owner_set_special_day',
    params: {
      'p_restaurant_id': restaurantId,
      'p_day': _date(day.day),
      'p_closed': day.closed,
      'p_opens': day.closed ? null : day.opens,
      'p_closes': day.closed ? null : day.closes,
      'p_note': day.note,
    },
  );

  @override
  Future<void> deleteSpecialDay(String restaurantId, DateTime day) => _db.rpc(
    'owner_delete_special_day',
    params: {'p_restaurant_id': restaurantId, 'p_day': _date(day)},
  );
}

final outletAdminRepositoryProvider = Provider<OutletAdminRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseOutletAdminRepository(Supabase.instance.client);
});

final optionGroupsProvider =
    FutureProvider.family<List<OwnerOptionGroup>, String>(
      (ref, restaurantId) =>
          ref.watch(outletAdminRepositoryProvider).optionGroups(restaurantId),
    );

final outletHoursProvider = FutureProvider.family<OutletHours, String>(
  (ref, restaurantId) =>
      ref.watch(outletAdminRepositoryProvider).hours(restaurantId),
);

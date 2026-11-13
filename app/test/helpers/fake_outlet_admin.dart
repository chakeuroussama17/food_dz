import 'package:food_app/features/catalog/data/catalog_models.dart';
import 'package:food_app/features/restaurant_owner/data/outlet_admin_repository.dart';

/// In-memory option groups, bulk edits and opening hours.
class FakeOutletAdminRepository implements OutletAdminRepository {
  final groups = <String, List<OwnerOptionGroup>>{};
  final hoursOf = <String, OutletHours>{};
  final calls = <String>[];
  var _n = 0;

  @override
  Future<List<OwnerOptionGroup>> optionGroups(String restaurantId) async => [
    ...?groups[restaurantId],
  ];

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
    final gid = id ?? 'g${++_n}';
    final g = OwnerOptionGroup(
      group: OptionGroup(
        id: gid,
        name: name.trim(),
        min: min,
        max: max,
        choices: [
          for (final c in choices)
            OptionChoice(
              id: c.id.isEmpty ? 'c${++_n}' : c.id,
              name: c.name,
              price: c.price,
              isAvailable: c.isAvailable,
            ),
        ],
      ),
      itemIds: itemIds,
    );
    final list = groups.putIfAbsent(restaurantId, () => []);
    final i = list.indexWhere((x) => x.group.id == gid);
    i >= 0 ? list[i] = g : list.add(g);
    calls.add('save:$name');
    return gid;
  }

  @override
  Future<void> deleteOptionGroup(String groupId) async {
    for (final l in groups.values) {
      l.removeWhere((g) => g.group.id == groupId);
    }
    calls.add('deleteGroup:$groupId');
  }

  @override
  Future<void> setItemGroups(String itemId, List<String> groupIds) async {
    for (final l in groups.values) {
      for (var i = 0; i < l.length; i++) {
        final g = l[i];
        final ids = {...g.itemIds}..remove(itemId);
        if (groupIds.contains(g.group.id)) ids.add(itemId);
        l[i] = OwnerOptionGroup(group: g.group, itemIds: ids.toList());
      }
    }
    calls.add('itemGroups:$itemId:${groupIds.join(',')}');
  }

  @override
  Future<void> setChoiceAvailable(String choiceId, bool available) async =>
      calls.add('choice:$choiceId:$available');

  @override
  Future<int> bulkItems(
    String restaurantId,
    List<String> itemIds,
    BulkAction action, {
    num? number,
    String? categoryId,
  }) async {
    calls.add('bulk:${action.name}:${itemIds.length}:${number ?? ''}');
    return itemIds.length;
  }

  @override
  Future<OutletHours> hours(String restaurantId) async =>
      hoursOf[restaurantId] ?? const OutletHours(switchOn: true, openNow: true);

  @override
  Future<void> setHours(String restaurantId, List<HourSlot> slots) async {
    final h = await hours(restaurantId);
    hoursOf[restaurantId] = OutletHours(
      weekly: slots,
      special: h.special,
      switchOn: h.switchOn,
      openNow: h.openNow,
    );
    calls.add('hours:${slots.length}');
  }

  @override
  Future<void> setSpecialDay(String restaurantId, SpecialDay day) async {
    final h = await hours(restaurantId);
    hoursOf[restaurantId] = OutletHours(
      weekly: h.weekly,
      special: [...h.special, day],
      switchOn: h.switchOn,
      openNow: h.openNow,
    );
    calls.add('special:${day.closed}:${day.note}');
  }

  @override
  Future<void> deleteSpecialDay(String restaurantId, DateTime day) async {
    final h = await hours(restaurantId);
    hoursOf[restaurantId] = OutletHours(
      weekly: h.weekly,
      special: h.special.where((d) => d.day != day).toList(),
      switchOn: h.switchOn,
      openNow: h.openNow,
    );
    calls.add('deleteSpecial');
  }
}

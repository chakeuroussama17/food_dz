import 'package:food_app/features/admin/data/promo_repository.dart';

/// In-memory promo codes with the same checks as admin_save_promo_code.
class FakePromoRepository implements PromoRepository {
  final codes = <PromoCode>[];
  final calls = <String>[];
  var _n = 0;

  @override
  Future<List<PromoCode>> list() async => [...codes];

  @override
  Future<void> save(PromoInput i) async {
    if (!RegExp(r'^[A-Z0-9]{3,20}$').hasMatch(i.code)) {
      throw const PromoError(PromoFailure.invalidCode);
    }
    if (codes.any((c) => c.code == i.code && c.id != i.id)) {
      throw const PromoError(PromoFailure.codeTaken);
    }
    if (i.value <= 0 || (i.kind == 'percent' && i.value > 90)) {
      throw const PromoError(PromoFailure.invalidValue);
    }
    calls.add('save:${i.code}:${i.kind}:${i.value}:${i.fundedBy}');
    final c = PromoCode(
      id: i.id ?? 'p${++_n}',
      code: i.code,
      kind: i.kind,
      value: i.value,
      maxDiscount: i.maxDiscount,
      minOrder: i.minOrder,
      maxUses: i.maxUses,
      perCustomer: i.perCustomer,
      endsAt: i.endsAt,
      restaurantId: i.restaurantId,
      fundedBy: i.fundedBy,
      note: i.note,
    );
    final at = codes.indexWhere((x) => x.id == c.id);
    at < 0 ? codes.insert(0, c) : codes[at] = c;
  }

  @override
  Future<void> setActive(String id, bool active) async {
    calls.add('active:$id:$active');
    final at = codes.indexWhere((x) => x.id == id);
    final c = codes[at];
    codes[at] = PromoCode(
      id: c.id,
      code: c.code,
      kind: c.kind,
      value: c.value,
      maxDiscount: c.maxDiscount,
      minOrder: c.minOrder,
      maxUses: c.maxUses,
      perCustomer: c.perCustomer,
      endsAt: c.endsAt,
      restaurantId: c.restaurantId,
      restaurantName: c.restaurantName,
      fundedBy: c.fundedBy,
      isActive: active,
      note: c.note,
      uses: c.uses,
      discountGiven: c.discountGiven,
    );
  }
}

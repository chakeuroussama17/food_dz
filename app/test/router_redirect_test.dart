import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/app/router.dart';

void main() {
  String? r(
    String path, {
    bool signedIn = false,
    bool recovering = false,
    String? role = 'customer',
    bool registering = false,
    String? from,
  }) => authRedirect(
    path: path,
    signedIn: signedIn,
    recoveringPassword: recovering,
    role: signedIn ? role : null,
    registeringRestaurant: registering,
    from: from,
    fullLocation: path,
  );

  test('signed-out users can only reach auth pages', () {
    for (final p in [
      '/welcome',
      '/login',
      '/signup',
      '/verify',
      '/forgot-password',
      '/restaurant/register',
    ]) {
      expect(r(p), isNull, reason: p);
    }
    expect(r('/home'), '/login');
    expect(r('/restaurant'), '/login?from=%2Frestaurant');
    expect(r('/reset-password'), '/login');
    expect(r('/loading'), '/login');
  });

  test('customers are sent home from auth pages', () {
    expect(r('/login', signedIn: true), '/home');
    expect(r('/verify', signedIn: true), '/home');
    expect(r('/home', signedIn: true), isNull);
  });

  test('while the role loads, wait on /loading and keep the target', () {
    expect(r('/login', signedIn: true, role: null), '/loading');
    expect(
      r('/login', signedIn: true, role: null, from: '/r/pizzeria'),
      '/loading?from=%2Fr%2Fpizzeria',
    );
    expect(
      r('/r/pizzeria', signedIn: true, role: null),
      '/loading?from=%2Fr%2Fpizzeria',
    );
    expect(r('/loading', signedIn: true, role: null), isNull);
    expect(r('/loading', signedIn: true, from: '/r/pizzeria'), '/r/pizzeria');
  });

  test('restaurant owners land on and stay in their area', () {
    expect(r('/login', signedIn: true, role: 'restaurant'), '/restaurant');
    expect(r('/loading', signedIn: true, role: 'restaurant'), '/restaurant');
    expect(r('/home', signedIn: true, role: 'restaurant'), '/restaurant');
    expect(r('/r/pizzeria', signedIn: true, role: 'restaurant'), '/restaurant');
    expect(r('/restaurant/menu', signedIn: true, role: 'restaurant'), isNull);
    expect(
      r('/restaurant/register', signedIn: true, role: 'restaurant'),
      '/restaurant',
    );
    // A customer link in "from" is ignored for owners.
    expect(
      r('/loading', signedIn: true, role: 'restaurant', from: '/r/x'),
      '/restaurant',
    );
  });

  test('customers cannot open the restaurant dashboard', () {
    expect(r('/restaurant', signedIn: true), '/home');
    expect(r('/restaurant/menu', signedIn: true), '/home');
    expect(r('/restaurant/register', signedIn: true), isNull);
  });

  test('the admin lands on and stays in /admin; nobody else gets in', () {
    expect(r('/login', signedIn: true, role: 'admin'), '/admin');
    expect(r('/home', signedIn: true, role: 'admin'), '/admin');
    expect(r('/restaurant', signedIn: true, role: 'admin'), '/admin');
    expect(r('/admin/receipts/x', signedIn: true, role: 'admin'), isNull);
    expect(r('/admin', signedIn: true), '/home');
    expect(
      r('/admin/receipts', signedIn: true, role: 'restaurant'),
      '/restaurant',
    );
    expect(r('/admin'), '/login?from=%2Fadmin');
  });

  test('drivers land on and stay in /driver; nobody else gets in', () {
    expect(r('/login', signedIn: true, role: 'driver'), '/driver');
    expect(r('/loading', signedIn: true, role: 'driver'), '/driver');
    expect(r('/home', signedIn: true, role: 'driver'), '/driver');
    expect(r('/r/pizzeria', signedIn: true, role: 'driver'), '/driver');
    expect(r('/restaurant', signedIn: true, role: 'driver'), '/driver');
    expect(r('/admin', signedIn: true, role: 'driver'), '/driver');
    expect(r('/driver/orders/x', signedIn: true, role: 'driver'), isNull);
    expect(r('/driver/register', signedIn: true, role: 'driver'), '/driver');
    // Customers, owners and the admin can't open the driver area.
    expect(r('/driver', signedIn: true), '/home');
    expect(r('/driver', signedIn: true, role: 'restaurant'), '/restaurant');
    expect(r('/driver', signedIn: true, role: 'admin'), '/admin');
    // The sign-up form is open to visitors and customers.
    expect(r('/driver/register'), isNull);
    expect(r('/driver/register', signedIn: true), isNull);
    expect(r('/driver'), '/login?from=%2Fdriver');
  });

  test('registration in progress is not interrupted', () {
    expect(
      r('/restaurant/register', signedIn: true, role: null, registering: true),
      isNull,
    );
  });

  test('password recovery keeps the user on reset-password', () {
    expect(r('/verify', signedIn: true, recovering: true), '/reset-password');
    expect(r('/home', signedIn: true, recovering: true), '/reset-password');
    expect(r('/reset-password', signedIn: true, recovering: true), isNull);
  });

  test('splash is always reachable', () {
    expect(r('/'), isNull);
    expect(r('/', signedIn: true), isNull);
  });
}

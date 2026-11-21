import 'package:flutter_test/flutter_test.dart';
import 'package:udayana_app/core/native/cart_math.dart';

void main() {
  test('calculates the cart total from cent prices and quantities', () {
    expect(CartMath.total([12500, 7800], [2, 1]), 32800);
  });

  test('rejects mismatched price and quantity lists', () {
    expect(() => CartMath.total([1000], []), throwsA(isA<ArgumentError>()));
  });

  test('rejects a total that cannot fit in a signed 64-bit integer', () {
    expect(
      () => CartMath.total([0x7fffffffffffffff], [2]),
      throwsA(isA<StateError>()),
    );
  });
}

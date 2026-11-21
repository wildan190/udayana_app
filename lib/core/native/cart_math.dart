import 'dart:ffi';
import 'dart:io';

typedef _CartTotalNative = Int64 Function(
  Pointer<Int64>,
  Pointer<Int32>,
  Int32,
);
typedef _CartTotalDart = int Function(Pointer<Int64>, Pointer<Int32>, int);
typedef _CartCountNative = Int32 Function(Pointer<Int32>, Int32);
typedef _CartCountDart = int Function(Pointer<Int32>, int);
typedef _MallocNative = Pointer<Void> Function(IntPtr);
typedef _MallocDart = Pointer<Void> Function(int);
typedef _FreeNative = Void Function(Pointer<Void>);
typedef _FreeDart = void Function(Pointer<Void>);

class CartMath {
  const CartMath._();

  static int total(List<int> pricesCents, List<int> quantities) {
    if (pricesCents.length != quantities.length) {
      throw ArgumentError('Jumlah harga dan kuantitas harus sama.');
    }
    if (!Platform.isAndroid || pricesCents.isEmpty) {
      return _dartTotal(pricesCents, quantities);
    }

    try {
      final library = DynamicLibrary.open('libudayana_core.so');
      final nativeTotal = library
          .lookupFunction<_CartTotalNative, _CartTotalDart>('cart_total');
      final malloc = DynamicLibrary.process()
          .lookupFunction<_MallocNative, _MallocDart>('malloc');
      final free = DynamicLibrary.process()
          .lookupFunction<_FreeNative, _FreeDart>('free');
      final priceBytes = pricesCents.length * sizeOf<Int64>();
      final quantityBytes = quantities.length * sizeOf<Int32>();
      final priceMemory = malloc(priceBytes).cast<Int64>();
      final quantityMemory = malloc(quantityBytes).cast<Int32>();
      if (priceMemory.address == 0 || quantityMemory.address == 0) {
        if (priceMemory.address != 0) free(priceMemory.cast<Void>());
        if (quantityMemory.address != 0) free(quantityMemory.cast<Void>());
        return _dartTotal(pricesCents, quantities);
      }

      try {
        for (var index = 0; index < pricesCents.length; index++) {
          priceMemory[index] = pricesCents[index];
          quantityMemory[index] = quantities[index];
        }
        final total = nativeTotal(
          priceMemory,
          quantityMemory,
          pricesCents.length,
        );
        if (total < 0) {
          return _dartTotal(pricesCents, quantities);
        }
        return total;
      } finally {
        free(priceMemory.cast<Void>());
        free(quantityMemory.cast<Void>());
      }
    } catch (_) {
      return _dartTotal(pricesCents, quantities);
    }
  }

  static int itemCount(List<int> quantities) {
    if (!Platform.isAndroid || quantities.isEmpty) {
      return quantities.fold(0, (sum, q) => sum + (q > 0 ? q : 0));
    }
    try {
      final library = DynamicLibrary.open('libudayana_core.so');
      final nativeCount = library
          .lookupFunction<_CartCountNative, _CartCountDart>('cart_item_count');
      final malloc = DynamicLibrary.process()
          .lookupFunction<_MallocNative, _MallocDart>('malloc');
      final free = DynamicLibrary.process()
          .lookupFunction<_FreeNative, _FreeDart>('free');
      final quantityBytes = quantities.length * sizeOf<Int32>();
      final quantityMemory = malloc(quantityBytes).cast<Int32>();
      if (quantityMemory.address == 0) {
        return quantities.fold(0, (sum, q) => sum + (q > 0 ? q : 0));
      }

      try {
        for (var index = 0; index < quantities.length; index++) {
          quantityMemory[index] = quantities[index];
        }
        return nativeCount(quantityMemory, quantities.length);
      } finally {
        free(quantityMemory.cast<Void>());
      }
    } catch (_) {
      return quantities.fold(0, (sum, q) => sum + (q > 0 ? q : 0));
    }
  }

  static int _dartTotal(List<int> pricesCents, List<int> quantities) {
    var total = 0;
    const maxInt64 = 0x7fffffffffffffff;
    for (var index = 0; index < pricesCents.length; index++) {
      if (pricesCents[index] < 0 || quantities[index] < 0) {
        throw ArgumentError('Harga dan kuantitas tidak boleh negatif.');
      }
      if (quantities[index] != 0 &&
          pricesCents[index] > (maxInt64 - total) ~/ quantities[index]) {
        throw StateError('Total keranjang terlalu besar.');
      }
      total += pricesCents[index] * quantities[index];
    }
    return total;
  }
}

#include <cstdint>
#include <limits>

extern "C" __attribute__((visibility("default"))) std::int64_t cart_total(
    const std::int64_t* prices,
    const std::int32_t* quantities,
    std::int32_t count) {
  if (count < 0 || (count > 0 && (prices == nullptr || quantities == nullptr))) {
    return -1;
  }

  std::int64_t total = 0;
  for (std::int32_t index = 0; index < count; ++index) {
    if (prices[index] < 0 || quantities[index] < 0) {
      return -1;
    }
    if (quantities[index] != 0 &&
        prices[index] > (std::numeric_limits<std::int64_t>::max() - total) /
                             quantities[index]) {
      return -1;
    }
    total += prices[index] * quantities[index];
  }
  return total;
}

extern "C" __attribute__((visibility("default"))) std::int32_t cart_item_count(
    const std::int32_t* quantities,
    std::int32_t count) {
  if (count < 0 || (count > 0 && quantities == nullptr)) {
    return -1;
  }

  std::int32_t total_items = 0;
  for (std::int32_t index = 0; index < count; ++index) {
    if (quantities[index] < 0) {
      return -1;
    }
    total_items += quantities[index];
  }
  return total_items;
}

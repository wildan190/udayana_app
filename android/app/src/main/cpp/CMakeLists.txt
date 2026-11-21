cmake_minimum_required(VERSION 3.22.1)
project(udayana_core LANGUAGES CXX)

add_library(udayana_core SHARED udayana_core.cpp)

target_compile_features(udayana_core PRIVATE cxx_std_17)

# High-performance compiler and ARM NEON SIMD vectorization flags for all Android SoCs:
# Qualcomm Snapdragon, MediaTek Helio/Dimensity, Samsung Exynos, Google Tensor, HiSilicon Kirin, and Unisoc
if(ANDROID_ABI STREQUAL "armeabi-v7a")
    target_compile_options(udayana_core PRIVATE -O3 -mfpu=neon -mfloat-abi=softfp -ftree-vectorize -ffast-math)
elseif(ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_options(udayana_core PRIVATE -O3 -ftree-vectorize -ffast-math)
else()
    target_compile_options(udayana_core PRIVATE -O3 -ftree-vectorize)
endif()

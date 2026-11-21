import 'package:flutter/material.dart';

/// Token warna aplikasi.
///
/// Bahasa desain mengikuti Ant Design: biru #1677ff sebagai warna utama,
/// grid 8px, sudut sedang (tidak terlalu bulat), dan border tipis.
class AppColors {
  const AppColors._();

  // Primer (Ant Design blue)
  static const Color primary = Color(0xFF1677FF);
  static const Color primaryHover = Color(0xFF4096FF);
  static const Color primaryActive = Color(0xFF0958D9);
  static const Color primaryBg = Color(0xFFE6F4FF);
  static const Color primaryBorder = Color(0xFF91CAFF);

  static const Color gold = Color(0xFFFAAD14);

  // Status
  static const Color success = Color(0xFF52C41A);
  static const Color successBg = Color(0xFFF6FFED);
  static const Color successBorder = Color(0xFFB7EB8F);
  static const Color warning = Color(0xFFFAAD14);
  static const Color warningBg = Color(0xFFFFFBE6);
  static const Color warningBorder = Color(0xFFFFE58F);
  static const Color error = Color(0xFFFF4D4F);
  static const Color errorBg = Color(0xFFFFF2F0);
  static const Color errorBorder = Color(0xFFFFCCC7);

  // Netral
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF595959);
  static const Color textTertiary = Color(0xFF8C8C8C);
  static const Color border = Color(0xFFD9D9D9);
  static const Color split = Color(0xFFF0F0F0);
  static const Color layoutBg = Color(0xFFF5F5F5);
  static const Color container = Color(0xFFFFFFFF);
  static const Color fill = Color(0xFFFAFAFA);
}

/// Skala sudut (radius). Dijaga "sedang" agar tidak terlalu bulat.
class AppRadius {
  const AppRadius._();

  static const double tag = 6;
  static const double control = 8;
  static const double card = 12;
  static const double overlay = 16;

  static const BorderRadius tagAll = BorderRadius.all(Radius.circular(tag));
  static const BorderRadius controlAll =
      BorderRadius.all(Radius.circular(control));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius overlayAll =
      BorderRadius.all(Radius.circular(overlay));
}

/// Skala jarak pada grid 8px.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Padding standar untuk konten halaman.
  static const EdgeInsets page = EdgeInsets.fromLTRB(16, 16, 16, 16);
}

/// Bayangan tipis untuk elemen yang "melayang" (mis. navbar bawah).
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
}

class AppTheme {
  const AppTheme._();

  // Alias lama dipertahankan agar tidak memutus referensi yang masih ada.
  static const Color primaryNavy = AppColors.primary;
  static const Color globeBlue = AppColors.primaryHover;
  static const Color goldAccent = AppColors.gold;

  static const BorderSide _controlBorder =
      BorderSide(color: AppColors.border, width: 1);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryBg,
      onPrimaryContainer: AppColors.primaryActive,
      surface: AppColors.container,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.split,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.fill,
      surfaceContainer: AppColors.split,
      surfaceContainerHigh: AppColors.split,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorBg,
      onErrorContainer: Color(0xFFCF1322),
    );

    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.container,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.container,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        titleSpacing: 16,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        shape: Border(bottom: BorderSide(color: AppColors.split, width: 1)),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.container,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: AppColors.split, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.split,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.container,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        helperStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
        ),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
        iconColor: AppColors.textTertiary,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: _controlBorder,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: _controlBorder,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: AppColors.error, width: 1.4),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: AppColors.split, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: _filledStyle()),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _filledStyle()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
          backgroundColor: const WidgetStatePropertyAll(AppColors.container),
          side: const WidgetStatePropertyAll(_controlBorder),
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
          minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.fill,
        selectedColor: AppColors.primaryBg,
        secondarySelectedColor: AppColors.primaryBg,
        side: _controlBorder,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.tagAll),
        showCheckmark: false,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primaryActive,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.container,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.overlayAll),
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14.5,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.container,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.container,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        dragHandleSize: Size(40, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.overlay),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 12.5,
          color: AppColors.textSecondary,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 10,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.container,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
        textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        elevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
        insetPadding: const EdgeInsets.all(16),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.textSecondary,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.container,
          ),
          side: const WidgetStatePropertyAll(_controlBorder),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textTertiary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearMinHeight: 4,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.container,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.overlayAll),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: AppRadius.tagAll,
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  static ButtonStyle _filledStyle() => ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.border
              : AppColors.primary,
        ),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
        elevation: const WidgetStatePropertyAll(0),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );

  /// Tipografi tenang: heading cukup w700 (tidak terlalu tebal/gemuk).
  static TextTheme _textTheme(TextTheme base) => base.copyWith(
        headlineSmall: base.headlineSmall?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: AppColors.textPrimary,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: AppColors.textPrimary,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: base.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          fontSize: 15,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
        bodySmall: base.bodySmall?.copyWith(
          fontSize: 12.5,
          height: 1.4,
          color: AppColors.textTertiary,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Color palette ─────────────────────────────────────────────────────────────

class AppColors {
  // Light
  static const lightBg            = Color(0xFFF9FAFB);
  static const lightSurface       = Color(0xFFFFFFFF);
  static const lightBorder        = Color(0xFFE5E7EB);
  static const lightPrimary       = Color(0xFF22C55E);
  static const lightPrimaryDark   = Color(0xFF16A34A);
  static const lightGreenTint     = Color(0xFFF0FDF4);
  static const lightGreenBorder   = Color(0xFFBBF7D0);
  static const lightTextPrimary   = Color(0xFF111827);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightTextHint      = Color(0xFF9CA3AF);
  static const lightError         = Color(0xFFEF4444);
  static const lightErrorBg       = Color(0xFFFFF5F5);
  static const lightErrorBorder   = Color(0xFFFCA5A5);

  // Dark
  static const darkBg             = Color(0xFF0F172A);
  static const darkSurface        = Color(0xFF1E293B);
  static const darkBorder         = Color(0xFF334155);
  static const darkPrimary        = Color(0xFF22C55E);
  static const darkPrimaryLight   = Color(0xFF4ADE80);
  static const darkGreenTint      = Color(0xFF14532D);
  static const darkGreenBorder    = Color(0xFF166634);
  static const darkTextPrimary    = Color(0xFFF1F5F9);
  static const darkTextSecondary  = Color(0xFF64748B);
  static const darkTextHint       = Color(0xFF475569);
  static const darkError          = Color(0xFFF87171);
  static const darkErrorBg        = Color(0xFF1C0A0A);
  static const darkErrorBorder    = Color(0xFF7F1D1D);
}

// ── Context extension ─────────────────────────────────────────────────────────

extension AppThemeContext on BuildContext {
  ThemeData   get theme  => Theme.of(this);
  ColorScheme get cs     => Theme.of(this).colorScheme;
  TextTheme   get tt     => Theme.of(this).textTheme;
  bool        get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get primary        => cs.primary;
  Color get surface        => cs.surface;
  Color get scaffoldBg     => theme.scaffoldBackgroundColor;
  Color get textPrimary    => cs.onSurface;
  Color get textSecondary  => isDark ? AppColors.darkTextSecondary  : AppColors.lightTextSecondary;
  Color get textHint       => isDark ? AppColors.darkTextHint       : AppColors.lightTextHint;
  Color get borderColor    => isDark ? AppColors.darkBorder         : AppColors.lightBorder;
  Color get greenTint      => isDark ? AppColors.darkGreenTint      : AppColors.lightGreenTint;
  Color get primaryDark    => isDark ? AppColors.darkPrimaryLight   : AppColors.lightPrimaryDark;
  Color get errorColor     => cs.error;
  Color get errorBg        => isDark ? AppColors.darkErrorBg        : AppColors.lightErrorBg;
  Color get errorBorder    => isDark ? AppColors.darkErrorBorder    : AppColors.lightErrorBorder;
  Color get greenBorder    => isDark ? AppColors.darkGreenBorder    : AppColors.lightGreenBorder;
}

// ── Theme ─────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg           = isDark ? AppColors.darkBg            : AppColors.lightBg;
    final surface      = isDark ? AppColors.darkSurface       : AppColors.lightSurface;
    final border       = isDark ? AppColors.darkBorder        : AppColors.lightBorder;
    final primary      = isDark ? AppColors.darkPrimary       : AppColors.lightPrimary;
    final primaryDark  = isDark ? AppColors.darkPrimaryLight  : AppColors.lightPrimaryDark;
    final greenTint    = isDark ? AppColors.darkGreenTint     : AppColors.lightGreenTint;
    final greenBorder  = isDark ? AppColors.darkGreenBorder   : AppColors.lightGreenBorder;
    final textPrimary  = isDark ? AppColors.darkTextPrimary   : AppColors.lightTextPrimary;
    final textSec      = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint     = isDark ? AppColors.darkTextHint      : AppColors.lightTextHint;
    final error        = isDark ? AppColors.darkError         : AppColors.lightError;
    final errorBg      = isDark ? AppColors.darkErrorBg       : AppColors.lightErrorBg;

    final colorScheme = ColorScheme(
      brightness:   brightness,
      primary:      primary,
      onPrimary:    Colors.white,
      secondary:    primary,
      onSecondary:  Colors.white,
      error:        error,
      onError:      Colors.white,
      surface:      surface,
      onSurface:    textPrimary,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: border, width: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness:   brightness,
      colorScheme:  colorScheme,
      scaffoldBackgroundColor: bg,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:     bg,
        foregroundColor:     textPrimary,
        elevation:           0,
        scrolledUnderElevation: 0,
        centerTitle:         false,
        titleTextStyle: TextStyle(
          color:      textPrimary,
          fontSize:   18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme:        IconThemeData(color: textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: textPrimary, size: 22),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // ── Cards ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:     surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 0.5),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),

      // ── Input fields ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: bg,
        border:          inputBorder,
        enabledBorder:   inputBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: error, width: 1),
        ),
        hintStyle:      TextStyle(color: textHint, fontSize: 13),
        labelStyle:     TextStyle(color: textSec,  fontSize: 13),
        prefixIconColor: primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),

      // ── Buttons ───────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation:       0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // ── Navigation Bar ────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:  surface,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        indicatorColor:   greenTint,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize:   10,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color:      selected ? primary : textSec,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : textSec, size: 22);
        }),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(color: border, thickness: 0.5, space: 0),

      // ── Chips ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: greenTint,
        selectedColor:   greenTint,
        side: BorderSide(color: greenBorder, width: 0.5),
        labelStyle: TextStyle(
          color:      primaryDark,
          fontSize:   11,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation:       0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      // ── Dialogs ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation:       0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 0.5),
        ),
        titleTextStyle: TextStyle(
          color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(color: textSec, fontSize: 14, height: 1.5),
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation:       0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightTextPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Progress ─────────────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),

      // ── Switch ───────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : textHint),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? greenTint : border),
      ),

      // ── Icons ────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: textSec, size: 20),

      // ── Text ─────────────────────────────────────────────────────────────
      textTheme: TextTheme(
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium:    TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge:      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textPrimary),
        bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textSec),
        labelMedium:    TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSec),
        labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSec),
      ),
    );
  }
}

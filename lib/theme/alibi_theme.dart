import 'package:flutter/material.dart';

enum AlibiThemeChoice { red, green, yellow, orange, purple, pink, dark }

extension AlibiThemeChoiceX on AlibiThemeChoice {
  String get label => switch (this) {
    AlibiThemeChoice.red => 'Red',
    AlibiThemeChoice.green => 'Green',
    AlibiThemeChoice.yellow => 'Yellow',
    AlibiThemeChoice.orange => 'Orange',
    AlibiThemeChoice.purple => 'Purple',
    AlibiThemeChoice.pink => 'Pink',
    AlibiThemeChoice.dark => 'Dark',
  };
}

class AlibiPalette {
  const AlibiPalette({
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.isDark,
  });

  final Color background;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color accent;
  final bool isDark;
}

class AlibiTheme {
  static AlibiPalette palette(AlibiThemeChoice choice) => switch (choice) {
    AlibiThemeChoice.red => const AlibiPalette(
      background: Color(0xFFF0B8B1),
      surface: Color(0xFFFFF8F4),
      ink: Color(0xFF171313),
      muted: Color(0xFF684D4A),
      accent: Color(0xFF7C2424),
      isDark: false,
    ),
    AlibiThemeChoice.green => const AlibiPalette(
      background: Color(0xFFBFD8C2),
      surface: Color(0xFFF7FBF7),
      ink: Color(0xFF121713),
      muted: Color(0xFF49604E),
      accent: Color(0xFF245C37),
      isDark: false,
    ),
    AlibiThemeChoice.yellow => const AlibiPalette(
      background: Color(0xFFF2D98B),
      surface: Color(0xFFFFFBEE),
      ink: Color(0xFF18150D),
      muted: Color(0xFF6B5D2D),
      accent: Color(0xFF705300),
      isDark: false,
    ),
    AlibiThemeChoice.orange => const AlibiPalette(
      background: Color(0xFFF0BE8F),
      surface: Color(0xFFFFF8F0),
      ink: Color(0xFF19120D),
      muted: Color(0xFF704E34),
      accent: Color(0xFF8A3E14),
      isDark: false,
    ),
    AlibiThemeChoice.purple => const AlibiPalette(
      background: Color(0xFFCDBCE0),
      surface: Color(0xFFFBF8FF),
      ink: Color(0xFF17131A),
      muted: Color(0xFF5E506B),
      accent: Color(0xFF563078),
      isDark: false,
    ),
    AlibiThemeChoice.pink => const AlibiPalette(
      background: Color(0xFFEDBED0),
      surface: Color(0xFFFFF7FA),
      ink: Color(0xFF191216),
      muted: Color(0xFF6F4A5A),
      accent: Color(0xFF833450),
      isDark: false,
    ),
    AlibiThemeChoice.dark => const AlibiPalette(
      background: Color(0xFF171313),
      surface: Color(0xFF242020),
      ink: Color(0xFFFFF8F4),
      muted: Color(0xFFC9BDB8),
      accent: Color(0xFFF0B8B1),
      isDark: true,
    ),
  };

  static ThemeData build(AlibiThemeChoice choice) {
    final p = palette(choice);
    final brightness = p.isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoPageTransitionsBuilder(),
          TargetPlatform.iOS: NoPageTransitionsBuilder(),
          TargetPlatform.windows: NoPageTransitionsBuilder(),
          TargetPlatform.macOS: NoPageTransitionsBuilder(),
          TargetPlatform.linux: NoPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: brightness,
        surface: p.surface,
        onSurface: p.ink,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.background,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: p.ink, fontWeight: FontWeight.w700),
        ),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: p.background),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: p.ink,
          fontSize: 58,
          height: .92,
          fontWeight: FontWeight.w900,
          letterSpacing: -3.2,
        ),
        headlineMedium: TextStyle(
          color: p.ink,
          fontSize: 30,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        bodyLarge: TextStyle(color: p.ink, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: p.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface.withValues(alpha: p.isDark ? .65 : .35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

extension AlibiThemeContext on BuildContext {
  AlibiPalette get alibiPalette => AlibiTheme.palette(
    Theme.of(this).brightness == Brightness.dark
        ? AlibiThemeChoice.dark
        : _choiceFromBackground(Theme.of(this).scaffoldBackgroundColor),
  );

  static AlibiThemeChoice _choiceFromBackground(Color color) {
    for (final choice in AlibiThemeChoice.values) {
      if (AlibiTheme.palette(choice).background == color) return choice;
    }
    return AlibiThemeChoice.red;
  }
}

class NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

import 'package:flutter/material.dart';

/// 织物质感主题配置
class FabricTheme {
  // 温暖中性色调
  static const Color linen = Color(0xFFF5F1E8);
  static const Color canvas = Color(0xFFE8E3D6);
  static const Color denim = Color(0xFF6B7C93);
  static const Color cotton = Color(0xFFFFFDF7);
  static const Color thread = Color(0xFF8B7E74);
  static const Color stitch = Color(0xFFD4C5B9);

  // 点缀色
  static const Color warmTerracotta = Color(0xFFD4816B);
  static const Color softSage = Color(0xFF9CAF88);
  static const Color dustyRose = Color(0xFFCFA5A0);
  static const Color mutedGold = Color(0xFFD4AF6A);

  /// 创建浅色织物主题
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // 主色调 - 温暖的牛仔蓝
      colorScheme: ColorScheme.light(
        primary: denim,
        secondary: warmTerracotta,
        surface: cotton,
        surfaceContainerHighest: canvas,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: thread,
        outline: stitch,
      ),

      // 脚手架背景 - 亚麻色
      scaffoldBackgroundColor: linen,

      // AppBar 主题
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: cotton,
        foregroundColor: thread,
        shadowColor: stitch.withValues(alpha: 0.3),
      ),

      // 卡片主题 - 柔和阴影
      cardTheme: CardThemeData(
        elevation: 0,
        color: cotton,
        shadowColor: stitch.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: stitch.withValues(alpha: 0.3), width: 1),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cotton,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: stitch.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: stitch.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: denim, width: 1.5),
        ),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: denim,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: stitch.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: denim.withValues(alpha: 0.2), width: 1),
          ),
        ),
      ),

      // 文本主题 - 高对比度
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: thread, fontWeight: FontWeight.w600),
        displayMedium: TextStyle(color: thread, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(color: thread, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(color: thread, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: thread, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: thread, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: thread, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(color: thread, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: thread, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: thread),
        bodyMedium: TextStyle(color: thread),
        bodySmall: TextStyle(color: thread),
      ),
    );
  }

  /// 创建深色织物主题
  static ThemeData darkTheme() {
    const darkLinen = Color(0xFF2C2A26);
    const darkCanvas = Color(0xFF3A3731);
    const darkCotton = Color(0xFF242220);
    const lightThread = Color(0xFFE8E3D6);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: Color(0xFF8B9DB3),
        secondary: warmTerracotta,
        surface: darkCotton,
        surfaceContainerHighest: darkCanvas,
        onPrimary: darkCotton,
        onSecondary: Colors.white,
        onSurface: lightThread,
        outline: Color(0xFF5A5550),
      ),

      scaffoldBackgroundColor: darkLinen,

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkCotton,
        foregroundColor: lightThread,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCotton,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Color(0xFF5A5550).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

/// 织物纹理背景画笔
class FabricTexturePainter extends CustomPainter {
  final Color baseColor;
  final double opacity;
  final FabricPattern pattern;

  FabricTexturePainter({
    required this.baseColor,
    this.opacity = 0.15,
    this.pattern = FabricPattern.linen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (pattern) {
      case FabricPattern.linen:
        _paintLinenTexture(canvas, size);
        break;
      case FabricPattern.canvas:
        _paintCanvasTexture(canvas, size);
        break;
      case FabricPattern.denim:
        _paintDenimTexture(canvas, size);
        break;
    }
  }

  /// 亚麻纹理 - 交叉线条
  void _paintLinenTexture(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 横向线条
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 纵向线条
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 添加细微噪点
    _addNoise(canvas, size, paint);
  }

  /// 帆布纹理 - 斜向交织
  void _paintCanvasTexture(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // 斜向线条 /
    for (double i = -size.height; i < size.width; i += 6) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // 斜向线条 \
    paint.color = baseColor.withValues(alpha: opacity * 0.7);
    for (double i = 0; i < size.width + size.height; i += 6) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }

  /// 牛仔纹理 - 密集斜纹
  void _paintDenimTexture(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 密集斜纹
    for (double i = -size.height; i < size.width; i += 3) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint
          ..color = baseColor.withValues(
            alpha: opacity * (0.8 + math.Random(i.toInt()).nextDouble() * 0.4),
          ),
      );
    }
  }

  /// 添加噪点效果
  void _addNoise(Canvas canvas, Size size, Paint paint) {
    final random = math.Random(42);
    paint.strokeWidth = 0.5;

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(
        Offset(x, y),
        0.3,
        paint..color = baseColor.withValues(alpha: opacity * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum FabricPattern {
  linen, // 亚麻
  canvas, // 帆布
  denim, // 牛仔
}

/// 织物纹理背景容器
class FabricTextureContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final FabricPattern pattern;
  final double textureOpacity;

  const FabricTextureContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.pattern = FabricPattern.linen,
    this.textureOpacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      children: [
        // 基础背景色
        Container(color: bgColor),

        // 织物纹理层
        CustomPaint(
          painter: FabricTexturePainter(
            baseColor: Colors.black,
            opacity: textureOpacity,
            pattern: pattern,
          ),
          child: Container(),
        ),

        // 内容层
        child,
      ],
    );
  }
}

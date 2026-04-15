import 'package:flutter/material.dart';

/// 织物风格卡片 - 带缝线边框和柔和阴影
class FabricCard extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool showStitches;
  final double elevation;

  const FabricCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.onTap,
    this.showStitches = true,
    this.elevation = 2,
  });

  @override
  State<FabricCard> createState() => _FabricCardState();
}

class _FabricCardState extends State<FabricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation + 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        widget.backgroundColor ??
        theme.cardTheme.color ??
        theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin ?? const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: widget.showStitches
                  ? Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  blurRadius: _elevationAnimation.value * 4,
                  offset: Offset(0, _elevationAnimation.value),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: widget.onTap != null ? _handleTapDown : null,
                onTapUp: widget.onTap != null ? _handleTapUp : null,
                onTapCancel: widget.onTap != null ? _handleTapCancel : null,
                borderRadius: BorderRadius.circular(16),
                splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                highlightColor: theme.colorScheme.primary.withValues(
                  alpha: 0.05,
                ),
                child: widget.showStitches
                    ? CustomPaint(
                        painter: StitchBorderPainter(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        child: Padding(
                          padding: widget.padding ?? const EdgeInsets.all(16),
                          child: widget.child,
                        ),
                      )
                    : Padding(
                        padding: widget.padding ?? const EdgeInsets.all(16),
                        child: widget.child,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 缝线边框画笔
class StitchBorderPainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  StitchBorderPainter({
    required this.color,
    this.dashWidth = 4,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
          const Radius.circular(14),
        ),
      );

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 织物风格按钮
class FabricButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final bool isPrimary;

  const FabricButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.isPrimary = true,
  });

  @override
  State<FabricButton> createState() => _FabricButtonState();
}

class _FabricButtonState extends State<FabricButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        widget.backgroundColor ??
        (widget.isPrimary
            ? theme.colorScheme.primary
            : theme.colorScheme.surface);
    final fgColor =
        widget.foregroundColor ??
        (widget.isPrimary
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: bgColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                onTapDown: widget.onPressed != null
                    ? (_) => _controller.forward()
                    : null,
                onTapUp: widget.onPressed != null
                    ? (_) => _controller.reverse()
                    : null,
                onTapCancel: widget.onPressed != null
                    ? () => _controller.reverse()
                    : null,
                borderRadius: BorderRadius.circular(12),
                splashColor: fgColor.withValues(alpha: 0.1),
                highlightColor: fgColor.withValues(alpha: 0.05),
                child: Padding(
                  padding:
                      widget.padding ??
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: fgColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

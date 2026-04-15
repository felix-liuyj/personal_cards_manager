import 'package:flutter/material.dart';

class BaseCardUI extends StatelessWidget {
  final double aspectRatio;
  final Widget child;
  final Color backgroundColor;
  final Color textColor;
  final String? bgImageUrl;

  const BaseCardUI({
    super.key,
    required this.aspectRatio,
    required this.child,
    this.backgroundColor = const Color(0xFF2B2D3A),
    this.textColor = Colors.white,
    this.bgImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    // 采用 Material3 渲染特性的极高品质平滑边框卡片
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
          image: bgImageUrl != null 
            ? DecorationImage(image: NetworkImage(bgImageUrl!), fit: BoxFit.cover, opacity: 0.2) 
            : null,
        ),
        padding: const EdgeInsets.all(20.0),
        child: DefaultTextStyle(
          style: TextStyle(color: textColor),
          child: child,
        ),
      ),
    );
  }
}

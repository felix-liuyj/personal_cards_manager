import 'dart:async';
import 'package:flutter/material.dart';

class SecureText extends StatefulWidget {
  final String text;
  final bool isSensitive;
  final String mask;

  const SecureText({
    super.key, 
    required this.text, 
    this.isSensitive = true,
    this.mask = '•••• •••• •••• ••••'
  });

  @override
  State<SecureText> createState() => _SecureTextState();
}

class _SecureTextState extends State<SecureText> {
  bool _obfuscated = true;
  Timer? _timer;

  void _toggleObfuscation() {
    if (!widget.isSensitive) return;
    
    // 每次查看敏感字段时自动启动 15 秒销毁复原沙漏（符合高安全业务流规范）
    setState(() {
      _obfuscated = !_obfuscated;
    });

    if (!_obfuscated) {
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 15), () {
        if (mounted) setState(() => _obfuscated = true);
      });
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSensitive) return Text(widget.text);

    return InkWell(
      onTap: _toggleObfuscation,
      splashColor: Colors.transparent,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          _obfuscated ? widget.mask : widget.text,
          key: ValueKey<bool>(_obfuscated),
          style: TextStyle(
            letterSpacing: _obfuscated ? 2.0 : 1.2,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

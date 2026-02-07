import 'dart:ui';
import 'package:flutter/material.dart';

class FrostedGlass extends StatelessWidget {
  final Widget child;

  final double blur;
  final double radius;
  final EdgeInsets padding;

  final double borderWidth;
  final Color borderColor;

  // ✅ New: lighter/darker control
  final Color fillColor;

  // ✅ New: gradient strength control
  final double gradientOpacity;

  final double? width;
  final double? height;

  const FrostedGlass({
    super.key,
    required this.child,
    this.blur = 40,
    this.radius = 59,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.borderWidth = 2,
    this.borderColor = const Color.fromARGB(255, 255, 255, 255),
    this.fillColor = const Color.fromRGBO(255, 255, 255, 0.16),
    this.gradientOpacity = 0.9,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);

    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: r,
            border: Border.all(color: borderColor, width: borderWidth),
            color: fillColor,
            gradient: RadialGradient(
              center: const Alignment(-0.7, -0.6),
              radius: 1.35,
              colors: [
                Color.fromRGBO(255, 255, 255, 0.22 * gradientOpacity),
                Color.fromRGBO(255, 255, 255, 0.10 * gradientOpacity),
                Color.fromRGBO(255, 255, 255, 0.00),
              ],
              stops: const [0.0, 0.77, 1.0],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

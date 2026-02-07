import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogos {
  static const main = 'assets/logos/main_logo.svg';
  static const icon = 'assets/logos/icon_logo.svg';
}

/// Small icon to place next to "Snap Map" title (keeps everything else as Material icons)
class SnapMapTitleIcon extends StatelessWidget {
  final double size;
  final Color? tint; // optional: if you ever want to force monochrome tint

  const SnapMapTitleIcon({
    super.key,
    this.size = 18,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppLogos.icon,
      width: size,
      height: size,
      // If tint is null, SVG keeps its original colors.
      colorFilter: tint == null ? null : ColorFilter.mode(tint!, BlendMode.srcIn),
    );
  }
}

/// Large logo for places with lots of space (onboarding, empty states, etc.)
class SnapMapMainLogo extends StatelessWidget {
  final double size;

  const SnapMapMainLogo({
    super.key,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppLogos.main,
      width: size,
      height: size,
    );
  }
}

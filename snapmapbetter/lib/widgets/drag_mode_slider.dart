import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/frosted_glass.dart';

class DragModeSlider extends StatefulWidget {
  /// 0 = Camera, 1 = Map
  final int index;
  final ValueChanged<int> onChanged;

  const DragModeSlider({
    super.key,
    required this.index,
    required this.onChanged,
  });

  @override
  State<DragModeSlider> createState() => _DragModeSliderState();
}

class _DragModeSliderState extends State<DragModeSlider>
    with SingleTickerProviderStateMixin {
  // 0.0 -> left, 1.0 -> right
  late double _t;
  bool _dragging = false;

  late final AnimationController _snapCtrl;
  Animation<double>? _snapAnim;

  // Midpoint-cross haptic
  bool _wasRightHalf = false;

  @override
  void initState() {
    super.initState();
    _t = widget.index.toDouble();
    _wasRightHalf = _t >= 0.5;

    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        if (_snapAnim != null) {
          setState(() => _t = _snapAnim!.value);
        }
      });
  }

  @override
  void didUpdateWidget(covariant DragModeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.index != widget.index) {
      _animateTo(widget.index.toDouble(), microBounce: true);
    }
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _animateTo(double targetT, {required bool microBounce}) {
    _snapCtrl.stop();
    _snapCtrl.reset();

    if (microBounce) {
      final overshoot = (targetT == 1.0) ? 1.03 : -0.03;

      _snapAnim = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: _t, end: targetT + overshoot).chain(
            CurveTween(curve: Curves.easeOutCubic),
          ),
          weight: 60,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: targetT + overshoot, end: targetT).chain(
            CurveTween(curve: Curves.easeOutBack),
          ),
          weight: 40,
        ),
      ]).animate(_snapCtrl);
    } else {
      _snapAnim = Tween<double>(begin: _t, end: targetT).animate(
        CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOutCubic),
      );
    }

    _snapCtrl.forward();
  }

  int _decideIndex({
    required double t,
    required double velocityPxPerSec,
  }) {
    const flickThreshold = 650.0; // px/sec
    if (velocityPxPerSec.abs() >= flickThreshold) {
      return velocityPxPerSec > 0 ? 1 : 0;
    }
    return t >= 0.5 ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    // requested slate
  const slate = Colors.white;

    // Dynamic “feel” variables
    final dragBoost = _dragging ? 1.0 : 0.0; // 0..1

    // Track: slightly lighter than before
    final trackFill = Color.fromRGBO(
      255,
      255,
      255,
      0.16 + 0.06 * dragBoost, // gets a touch brighter while dragging
    );

    return FrostedGlass(
      radius: 59,
      padding: const EdgeInsets.all(6),
      borderWidth: 1.6,
      borderColor: Colors.white,
      blur: 30,
      fillColor: trackFill,
      gradientOpacity: 0.95,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackW = constraints.maxWidth;
          const trackH = 56.0;
          final knobW = trackW / 2;

          final knobLeft = _t.clamp(0.0, 1.0) * (trackW - knobW);

          // Parallax highlight offset (small)
          final parallaxX = (_t - 0.5) * 12.0;

          // Slight “press” scale while dragging
          final knobScale = _dragging ? 1.03 : 1.0;

          // Knob brightness: brighter overall + even brighter while dragging
          final knobFill = Color.fromRGBO(
            255,
            255,
            255,
            0.30 + 0.10 * dragBoost, // ✅ brighter knob
          );

          return SizedBox(
            width: trackW,
            height: trackH,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) {
                _dragging = true;
                _snapCtrl.stop();
                _wasRightHalf = _t >= 0.5;
                setState(() {});
                HapticFeedback.selectionClick();
              },
              onPanUpdate: (d) {
                final dt = d.delta.dx / (trackW - knobW);
                final nextT = (_t + dt).clamp(0.0, 1.0);

                final isRightHalf = nextT >= 0.5;
                if (isRightHalf != _wasRightHalf) {
                  HapticFeedback.selectionClick();
                  _wasRightHalf = isRightHalf;
                }

                setState(() => _t = nextT);
              },
              onPanEnd: (d) {
                _dragging = false;

                final vx = d.velocity.pixelsPerSecond.dx;
                final newIndex = _decideIndex(t: _t, velocityPxPerSec: vx);

                _animateTo(newIndex.toDouble(), microBounce: true);

                if (newIndex != widget.index) {
                  HapticFeedback.lightImpact();
                  widget.onChanged(newIndex);
                } else {
                  HapticFeedback.selectionClick();
                }

                setState(() {});
              },
              child: Stack(
                children: [
                  // Sliding frosted knob
                  Positioned(
                    left: knobLeft,
                    top: 0,
                    bottom: 0,
                    width: knobW,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      scale: knobScale,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: FrostedGlass(
                          radius: 59,
                          blur: 34,
                          borderWidth: 1.6,
                          borderColor: Colors.white,
                          fillColor: knobFill,
                          gradientOpacity: 1.0,
                          padding: EdgeInsets.zero,
                          child: Stack(
                            children: [
                              // Parallax highlight layer
                              Positioned.fill(
                                child: Transform.translate(
                                  offset: Offset(parallaxX, 0),
                                  child: Opacity(
                                    opacity: 0.26 + 0.08 * dragBoost,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(59),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color.fromRGBO(255, 255, 255, 0.65),
                                            Color.fromRGBO(255, 255, 255, 0.00),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Soft inner glow for “Instagram stories” vibe
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(59),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(
                                              0.10 + 0.06 * dragBoost),
                                          blurRadius: 18,
                                          spreadRadius: -6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Labels
                  Row(
                    children: [
                      Expanded(
                        child: _Label(
                          icon: Icons.camera_alt,
                          text: 'Camera',
                          activeAmount: 1.0 - _t,
                          color: slate,
                        ),
                      ),
                      Expanded(
                        child: _Label(
                          icon: Icons.map,
                          text: 'Map',
                          activeAmount: _t,
                          color: slate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final IconData icon;
  final String text;
  final double activeAmount; // 0..1
  final Color color;

  const _Label({
    required this.icon,
    required this.text,
    required this.activeAmount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final a = activeAmount.clamp(0.0, 1.0);

    final opacity = 0.55 + 0.45 * a;
    final scale = 0.98 + 0.04 * a;

    return Center(
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        scale: scale,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: opacity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

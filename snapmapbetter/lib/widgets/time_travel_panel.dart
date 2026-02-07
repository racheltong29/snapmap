import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/frosted_glass.dart';

enum TimeUnit { hours, days, months, years }

class TimeTravelPanel extends StatelessWidget {
  final DateTime cursorUtc;
  final TimeUnit unit;
  final ValueChanged<TimeUnit> onUnitChanged;
  final ValueChanged<DateTime> onCursorChanged;

  const TimeTravelPanel({
    super.key,
    required this.cursorUtc,
    required this.unit,
    required this.onUnitChanged,
    required this.onCursorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedGlass(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitPicker(
            unit: unit,
            onChanged: onUnitChanged,
          ),
          const SizedBox(height: 12),
          _TimeScrubber(
            cursorUtc: cursorUtc,
            unit: unit,
            onChanged: onCursorChanged,
          ),
        ],
      ),
    );
  }
}

class _UnitPicker extends StatefulWidget {
  final TimeUnit unit;
  final ValueChanged<TimeUnit> onChanged;

  const _UnitPicker({required this.unit, required this.onChanged});

  @override
  State<_UnitPicker> createState() => _UnitPickerState();
}

/// "Flickable selection menu where items cycle through and disappear"
/// Implemented as a PageView with viewportFraction + scale/fade.
class _UnitPickerState extends State<_UnitPicker> {
  final _ctrl = PageController(viewportFraction: 0.34);

  final _units = const [
    TimeUnit.hours,
    TimeUnit.days,
    TimeUnit.months,
    TimeUnit.years,
  ];

  int get _index => _units.indexOf(widget.unit);

  @override
  void didUpdateWidget(covariant _UnitPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unit != widget.unit) {
      _ctrl.animateToPage(
        _index,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: PageView.builder(
        controller: _ctrl,
        onPageChanged: (i) {
          HapticFeedback.selectionClick();
          widget.onChanged(_units[i]);
        },
        itemCount: _units.length,
        itemBuilder: (context, i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              double t = 0;
              if (_ctrl.position.haveDimensions) {
                t = (_ctrl.page! - i).abs().clamp(0.0, 1.0);
              }
              final scale = 1.0 - 0.12 * t;
              final opacity = 1.0 - 0.55 * t;

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Center(
                    child: Text(
                      _label(_units[i]),
                      style: TextStyle(
                        color: Colors.white.withOpacity(i == _index ? 1 : 0.85),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _label(TimeUnit u) {
    switch (u) {
      case TimeUnit.hours:
        return "HOURS";
      case TimeUnit.days:
        return "DAYS";
      case TimeUnit.months:
        return "MONTHS";
      case TimeUnit.years:
        return "YEARS";
    }
  }
}

/// The "tilt-style" horizontal scrubber:
/// - horizontal drag updates time
/// - snaps to increments of the chosen unit
class _TimeScrubber extends StatefulWidget {
  final DateTime cursorUtc;
  final TimeUnit unit;
  final ValueChanged<DateTime> onChanged;

  const _TimeScrubber({
    required this.cursorUtc,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<_TimeScrubber> createState() => _TimeScrubberState();
}

class _TimeScrubberState extends State<_TimeScrubber> {
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    // Visual: ticks in a capsule track
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 56,
        color: Colors.black.withOpacity(0.18),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => _dx = 0,
          onPanUpdate: (d) {
            _dx += d.delta.dx;

            // Convert drag to "steps"
            final stepPx = 18.0; // how sensitive the scrub is
            final rawSteps = (_dx / stepPx);

            final snappedSteps = rawSteps.round();
            final next = _applySteps(widget.cursorUtc, widget.unit, -snappedSteps);

            if (next != widget.cursorUtc) {
              HapticFeedback.selectionClick();
              widget.onChanged(next);
            }
          },
          child: CustomPaint(
            painter: _TickPainter(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _pretty(widget.cursorUtc, widget.unit),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Icon(Icons.drag_indicator, color: Colors.white70),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DateTime _applySteps(DateTime baseUtc, TimeUnit unit, int steps) {
    final b = baseUtc.toUtc();
    switch (unit) {
      case TimeUnit.hours:
        return DateTime.utc(b.year, b.month, b.day, b.hour).add(Duration(hours: steps));
      case TimeUnit.days:
        return DateTime.utc(b.year, b.month, b.day).add(Duration(days: steps));
      case TimeUnit.months:
        return DateTime.utc(b.year, b.month + steps, 1);
      case TimeUnit.years:
        return DateTime.utc(b.year + steps, 1, 1);
    }
  }

  String _pretty(DateTime utc, TimeUnit unit) {
    final d = utc.toUtc();
    switch (unit) {
      case TimeUnit.hours:
        return "${d.year}-${_2(d.month)}-${_2(d.day)}  ${_2(d.hour)}:00 UTC";
      case TimeUnit.days:
        return "${d.year}-${_2(d.month)}-${_2(d.day)} UTC";
      case TimeUnit.months:
        return "${d.year}-${_2(d.month)} UTC";
      case TimeUnit.years:
        return "${d.year} UTC";
    }
  }

  String _2(int x) => x.toString().padLeft(2, '0');
}

class _TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1;

    // draw ticks across the bar
    final gap = 10.0;
    for (double x = 0; x < size.width; x += gap) {
      final big = ((x / gap).round() % 6 == 0);
      final h = big ? 18.0 : 10.0;
      canvas.drawLine(Offset(x, size.height), Offset(x, size.height - h), p);
    }

    // center marker
    final c = Paint()
      ..color = const Color(0xFF98F9FF)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width / 2, size.height),
      Offset(size.width / 2, size.height - 26),
      c,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

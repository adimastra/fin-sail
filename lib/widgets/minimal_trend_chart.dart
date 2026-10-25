import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/theme.dart';

class MinimalTrendChart extends StatefulWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;
  final List<double>? monthlyTotals;

  const MinimalTrendChart({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
    this.monthlyTotals,
  });

  static List<DateTime> getDisplayMonths() {
    final now = DateTime.now();
    return [
      DateTime(now.year, now.month - 4),
      DateTime(now.year, now.month - 3),
      DateTime(now.year, now.month - 2),
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month),
    ];
  }

  static Path buildWavePath(double w, double h, {List<double>? monthlyTotals}) {
    final totals = (monthlyTotals != null && monthlyTotals.length == 5)
        ? monthlyTotals
        : [950000.0, 1155000.0, 1450000.0, 1350000.0, 1152000.0];

    double minVal = totals.reduce(min);
    double maxVal = totals.reduce(max);
    if (minVal == maxVal) {
      minVal = 0.0;
    }
    final span = max(maxVal - minVal, 1.0);

    // Leave comfortable margin at top for the ship (height ~26px)
    final topY = h * 0.28;
    final bottomY = h * 0.72;

    final yPoints = totals.map((val) {
      final norm = ((val - minVal) / span).clamp(0.0, 1.0);
      return bottomY - norm * (bottomY - topY);
    }).toList();

    final pts = <Offset>[];
    final yStart = (yPoints[0] + (yPoints[0] - yPoints[1]) * 0.35).clamp(
      h * 0.18,
      h * 0.82,
    );
    final yEnd = (yPoints[4] + (yPoints[4] - yPoints[3]) * 0.35).clamp(
      h * 0.18,
      h * 0.82,
    );

    pts.add(Offset(0.0, yStart));
    for (int i = 0; i < 5; i++) {
      pts.add(Offset((i + 0.5) / 5.0 * w, yPoints[i]));
    }
    pts.add(Offset(w, yEnd));

    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);

    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i < pts.length - 2 ? pts[i + 2] : pts[i + 1];

      // Catmull-Rom spline converted to Cubic Bezier
      final cp1 = p1 + (p2 - p0) * (1.0 / 6.0);
      final cp2 = p2 - (p3 - p1) * (1.0 / 6.0);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  @override
  State<MinimalTrendChart> createState() => _MinimalTrendChartState();
}

class _MinimalTrendChartState extends State<MinimalTrendChart>
    with TickerProviderStateMixin {
  late AnimationController _voyageController;
  late Animation<double> _voyageAnimation;
  late AnimationController _bobbingController;

  double _currentProgress = 0.9;
  bool _facingRight = true;

  List<DateTime> _getMonths() => MinimalTrendChart.getDisplayMonths();

  double _calculateProgress(DateTime month) {
    final months = _getMonths();
    int activeIndex = months.indexWhere(
      (m) => m.year == month.year && m.month == month.month,
    );
    if (activeIndex == -1) {
      activeIndex = 4;
    }
    return (activeIndex + 0.5) / months.length;
  }

  static Tangent? _findTangentAtX(PathMetric metric, double targetX) {
    double low = 0.0;
    double high = metric.length;
    Tangent? best;
    for (int i = 0; i < 16; i++) {
      final mid = (low + high) / 2;
      final tangent = metric.getTangentForOffset(mid);
      if (tangent == null) break;
      best = tangent;
      if (tangent.position.dx < targetX) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return best;
  }

  @override
  void initState() {
    super.initState();
    _currentProgress = _calculateProgress(widget.selectedMonth);

    _voyageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _voyageAnimation =
        Tween<double>(begin: _currentProgress, end: _currentProgress).animate(
          CurvedAnimation(
            parent: _voyageController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _bobbingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(MinimalTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMonth != oldWidget.selectedMonth) {
      final newProgress = _calculateProgress(widget.selectedMonth);
      _facingRight = newProgress >= _currentProgress;

      _voyageAnimation =
          Tween<double>(begin: _currentProgress, end: newProgress).animate(
            CurvedAnimation(
              parent: _voyageController,
              curve: Curves.easeInOutCubic,
            ),
          );

      _voyageController.forward(from: 0.0).then((_) {
        _currentProgress = newProgress;
      });
    }
  }

  @override
  void dispose() {
    _voyageController.dispose();
    _bobbingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strokeColor = isDark ? Colors.white : AppTheme.pureBlack;
    final months = _getMonths();

    return Column(
      children: [
        // Smooth Bezier Curve Canvas with Animated Voyage Ship
        SizedBox(
          height: 68,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              const h = 68.0;
              final path = MinimalTrendChart.buildWavePath(
                w,
                h,
                monthlyTotals: widget.monthlyTotals,
              );
              final pathMetrics = path.computeMetrics().toList();

              return AnimatedBuilder(
                animation: Listenable.merge([
                  _voyageAnimation,
                  _bobbingController,
                ]),
                builder: (context, _) {
                  final t = _voyageAnimation.value;
                  Offset shipPos = Offset(w * t, h * 0.5);
                  double slopeAngle = 0.0;

                  if (pathMetrics.isNotEmpty) {
                    final metric = pathMetrics.first;
                    final tangent = _findTangentAtX(
                      metric,
                      (w * t).clamp(16.0, w - 16.0),
                    );
                    if (tangent != null) {
                      shipPos = tangent.position;
                      slopeAngle = tangent.angle;
                    }
                  }

                  // Oceanic bobbing motion while sailing or at rest
                  final bobbingY = sin(_bobbingController.value * 2 * pi) * 1.8;
                  final bobbingTilt =
                      cos(_bobbingController.value * 2 * pi) * 0.035;

                  // Tilt angle follows the wave slope:
                  // If the line goes up, ship tilts up; if line goes down, ship tilts down!
                  final effectiveTilt =
                      slopeAngle.clamp(-0.48, 0.48) + bobbingTilt;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, h),
                        painter: _WavePathPainter(
                          color: strokeColor,
                          path: path,
                        ),
                      ),
                      Positioned(
                        left: shipPos.dx - 16,
                        top: shipPos.dy - 22 + bobbingY,
                        child: Transform.rotate(
                          angle: effectiveTilt,
                          child: CuteShipWidget(
                            color: strokeColor,
                            facingRight: _facingRight,
                            size: const Size(32, 26),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Horizontal 5 Month Row precisely aligned with the wave control points
        Row(
          children: months.map((m) {
            final isSelected =
                m.year == widget.selectedMonth.year &&
                m.month == widget.selectedMonth.month;
            final monthNames = [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ];
            final name = monthNames[m.month - 1];

            return Expanded(
              child: InkWell(
                onTap: () => widget.onMonthSelected(m),
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w400,
                        color: isSelected
                            ? (isDark ? Colors.white : AppTheme.pureBlack)
                            : AppTheme.grayTextMuted,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Custom vector ship matching the user reference image
class CuteShipWidget extends StatelessWidget {
  final Color color;
  final bool facingRight;
  final Size size;

  const CuteShipWidget({
    super.key,
    required this.color,
    this.facingRight = true,
    this.size = const Size(32, 26),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _CuteShipPainter(color: color, facingRight: facingRight),
    );
  }
}

class _CuteShipPainter extends CustomPainter {
  final Color color;
  final bool facingRight;

  _CuteShipPainter({required this.color, required this.facingRight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();

    // The reference silhouette is drawn naturally with bow on the left.
    // If facingRight is true, we mirror horizontally so the bow leads forward!
    if (facingRight) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Flagpole & Flag
    final mastPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    // Vertical mast in center
    canvas.drawLine(
      Offset(w * 0.56, h * 0.06),
      Offset(w * 0.56, h * 0.36),
      mastPaint,
    );

    // Wavy Flag waving to the right
    final flagPath = Path();
    flagPath.moveTo(w * 0.56, h * 0.08);
    flagPath.cubicTo(
      w * 0.64,
      h * 0.06,
      w * 0.72,
      h * 0.14,
      w * 0.84,
      h * 0.10,
    );
    flagPath.lineTo(w * 0.84, h * 0.28);
    flagPath.cubicTo(
      w * 0.72,
      h * 0.32,
      w * 0.64,
      h * 0.24,
      w * 0.56,
      h * 0.26,
    );
    flagPath.close();
    canvas.drawPath(flagPath, fillPaint);

    // 2. Cabin / Superstructure
    // Trapezoidal cabin with rounded roof corners
    final cabinPath = Path();
    cabinPath.moveTo(w * 0.32, h * 0.55);
    cabinPath.lineTo(w * 0.40, h * 0.36);
    cabinPath.arcToPoint(
      Offset(w * 0.46, h * 0.33),
      radius: Radius.circular(w * 0.06),
    );
    cabinPath.lineTo(w * 0.66, h * 0.33);
    cabinPath.arcToPoint(
      Offset(w * 0.71, h * 0.37),
      radius: Radius.circular(w * 0.05),
    );
    cabinPath.lineTo(w * 0.74, h * 0.55);
    cabinPath.close();
    canvas.drawPath(cabinPath, fillPaint);

    // 3. Hull (with curved sheerline, rounded bow & porthole)
    final hullPath = Path();
    hullPath.moveTo(w * 0.12, h * 0.51);
    hullPath.lineTo(w * 0.38, h * 0.53);
    hullPath.cubicTo(
      w * 0.46,
      h * 0.54,
      w * 0.52,
      h * 0.64,
      w * 0.62,
      h * 0.64,
    );
    hullPath.lineTo(w * 0.86, h * 0.64);
    // Rounded stern top-right
    hullPath.arcToPoint(
      Offset(w * 0.90, h * 0.68),
      radius: Radius.circular(w * 0.04),
    );
    // Stern curve down to keel
    hullPath.cubicTo(
      w * 0.89,
      h * 0.82,
      w * 0.78,
      h * 0.95,
      w * 0.62,
      h * 0.95,
    );
    // Flat keel bottom
    hullPath.lineTo(w * 0.32, h * 0.95);
    // Smooth upward curve to pointed bow
    hullPath.cubicTo(
      w * 0.18,
      h * 0.94,
      w * 0.09,
      h * 0.78,
      w * 0.08,
      h * 0.56,
    );
    hullPath.arcToPoint(
      Offset(w * 0.12, h * 0.51),
      radius: Radius.circular(w * 0.04),
    );
    hullPath.close();

    // Porthole circular cutout on the bow
    final porthole = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.25, h * 0.70), radius: w * 0.075),
      );

    final finalHull = Path.combine(
      PathOperation.difference,
      hullPath,
      porthole,
    );
    canvas.drawPath(finalHull, fillPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CuteShipPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.facingRight != facingRight;
  }
}

class _WavePathPainter extends CustomPainter {
  final Color color;
  final Path path;

  _WavePathPainter({required this.color, required this.path});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WavePathPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.path != path;
  }
}

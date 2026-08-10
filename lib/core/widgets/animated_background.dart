import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/sensor_constants.dart';

// ── AQI level passed in from dashboard ───────────────────────────────
// Default is good (clean sky) until real data loads.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final AirQualityLevel aqiLevel;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.aqiLevel = AirQualityLevel.good,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late final List<AnimationController> _cloudControllers;
  late final List<Animation<double>> _cloudAnimations;

  late final AnimationController _gradientController;
  late Animation<double> _gradientAnimation;

  AirQualityLevel _previousLevel = AirQualityLevel.good;

  // ── Cloud layers ──────────────────────────────────────────────────
  static const _clouds = [
    _CloudConfig(
      top: 0.04,
      width: 0.72,
      height: 0.09,
      opacity: 0.32,
      speed: 30,
    ),
    _CloudConfig(
      top: 0.11,
      width: 0.56,
      height: 0.07,
      opacity: 0.26,
      speed: 38,
    ),
    _CloudConfig(
      top: 0.19,
      width: 0.50,
      height: 0.06,
      opacity: 0.22,
      speed: 24,
    ),
    _CloudConfig(
      top: 0.07,
      width: 0.42,
      height: 0.055,
      opacity: 0.18,
      speed: 28,
    ),
    _CloudConfig(
      top: 0.23,
      width: 0.46,
      height: 0.06,
      opacity: 0.20,
      speed: 42,
    ),
    _CloudConfig(
      top: 0.29,
      width: 0.36,
      height: 0.045,
      opacity: 0.15,
      speed: 20,
    ),
    _CloudConfig(
      top: 0.02,
      width: 0.32,
      height: 0.04,
      opacity: 0.12,
      speed: 22,
    ),
    _CloudConfig(
      top: 0.33,
      width: 0.40,
      height: 0.05,
      opacity: 0.14,
      speed: 26,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _previousLevel = widget.aqiLevel;

    // ── Cloud animations ────────────────────────────────────────────
    _cloudControllers = List.generate(_clouds.length, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: _clouds[i].speed),
      )..repeat();
    });

    _cloudAnimations = List.generate(_clouds.length, (i) {
      return Tween<double>(begin: -0.5, end: 1.5).animate(
        CurvedAnimation(parent: _cloudControllers[i], curve: Curves.linear),
      );
    });

    // Stagger cloud start positions.
    for (int i = 0; i < _cloudControllers.length; i++) {
      _cloudControllers[i].value = (i * 0.13) % 1.0;
    }

    // ── Gradient transition controller ─────────────────────────────
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.aqiLevel != widget.aqiLevel) {
      _previousLevel = oldWidget.aqiLevel;

      _gradientController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    for (final controller in _cloudControllers) {
      controller.dispose();
    }

    _gradientController.dispose();

    super.dispose();
  }

  // ==================================================================
  // BUILD
  // ==================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Base color fill ─────────────────────────────────────────
        Positioned.fill(
          child: Container(
            color: isDark ? const Color(0xFF0A1628) : const Color(0xFF5BA3D9),
          ),
        ),

        // ── Sky gradient ────────────────────────────────────────────
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, _) {
              final t = _gradientAnimation.value;

              final fromColors = _skyColors(_previousLevel, isDark);

              final toColors = _skyColors(widget.aqiLevel, isDark);

              final fromStops = _skyStops(_previousLevel);

              final toStops = _skyStops(widget.aqiLevel);

              final colorCount = max(fromColors.length, toColors.length);

              final lerpedColors = List<Color>.generate(colorCount, (i) {
                final from = i < fromColors.length
                    ? fromColors[i]
                    : fromColors.last;

                final to = i < toColors.length ? toColors[i] : toColors.last;

                return Color.lerp(from, to, t) ?? to;
              });

              final stopCount = max(fromStops.length, toStops.length);

              final lerpedStops = List<double>.generate(stopCount, (i) {
                final from = i < fromStops.length
                    ? fromStops[i]
                    : fromStops.last;

                final to = i < toStops.length ? toStops[i] : toStops.last;

                return from + (to - from) * t;
              });

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: lerpedColors,
                    stops: lerpedStops,
                  ),
                ),
              );
            },
          ),
        ),

        // ── Haze overlay ────────────────────────────────────────────
        if (widget.aqiLevel == AirQualityLevel.warning ||
            widget.aqiLevel == AirQualityLevel.critical)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gradientAnimation,
              builder: (_, __) {
                final isCritical = widget.aqiLevel == AirQualityLevel.critical;

                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.4,
                      colors: [
                        (isCritical
                                ? const Color(0xFFB22222)
                                : const Color(0xFFD2691E))
                            .withValues(alpha: isCritical ? 0.18 : 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // ── Clouds ──────────────────────────────────────────────────
        ...List.generate(_clouds.length, (i) {
          final cloud = _clouds[i];

          return AnimatedBuilder(
            animation: _cloudAnimations[i],
            builder: (context, _) {
              final xPos =
                  (_cloudAnimations[i].value * size.width * 1.5) %
                      (size.width * 2) -
                  size.width * 0.5;

              final fromCloudColor = _cloudColor(
                _previousLevel,
                isDark,
                0,
                Colors.white,
              );

              final cloudColor = _cloudColor(
                widget.aqiLevel,
                isDark,
                _gradientAnimation.value,
                fromCloudColor,
              );

              final cloudOpacity =
                  (isDark ? cloud.opacity * 0.4 : cloud.opacity) *
                  _cloudOpacityMult(widget.aqiLevel);

              return Positioned(
                top: size.height * cloud.top,
                left: xPos,
                child: _CloudShape(
                  width: size.width * cloud.width,
                  height: size.height * cloud.height,
                  opacity: cloudOpacity,
                  color: cloudColor,
                ),
              );
            },
          );
        }),

        // ── Bottom depth gradient ───────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  (isDark
                          ? const Color(0xFF0D1B2E)
                          : _bottomFadeColor(widget.aqiLevel))
                      .withValues(alpha: 0.35),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
        ),

        // ── Content ─────────────────────────────────────────────────
        widget.child,
      ],
    );
  }

  // ==================================================================
  // SKY COLORS
  // ==================================================================

  List<Color> _skyColors(AirQualityLevel level, bool isDark) {
    if (isDark) {
      switch (level) {
        case AirQualityLevel.good:
          return [
            const Color(0xFF0A1628),
            const Color(0xFF0D2040),
            const Color(0xFF0F2A35),
            const Color(0xFF0D1B2E),
          ];

        case AirQualityLevel.moderate:
          return [
            const Color(0xFF0F1A2A),
            const Color(0xFF1A2A35),
            const Color(0xFF1F2F30),
            const Color(0xFF0D1B2E),
          ];

        case AirQualityLevel.warning:
          return [
            const Color(0xFF1A1208),
            const Color(0xFF2A1E0A),
            const Color(0xFF1F1A10),
            const Color(0xFF0D1208),
          ];

        case AirQualityLevel.critical:
          return [
            const Color(0xFF1A0808),
            const Color(0xFF2A1010),
            const Color(0xFF1F1212),
            const Color(0xFF0D0808),
          ];

        case AirQualityLevel.offline:
          return [
            const Color(0xFF0A0A12),
            const Color(0xFF141420),
            const Color(0xFF101018),
            const Color(0xFF0A0A10),
          ];
      }
    }

    switch (level) {
      case AirQualityLevel.good:
        return [
          const Color(0xFF4A90D9),
          const Color(0xFF6BB5E8),
          const Color(0xFF99D4F0),
          const Color(0xFFCCECF8),
          const Color(0xFFE8F6EC),
        ];

      case AirQualityLevel.moderate:
        return [
          const Color(0xFF6A9BB5),
          const Color(0xFF8BBAC8),
          const Color(0xFFB5D4D8),
          const Color(0xFFD8E8D0),
          const Color(0xFFECF0DC),
        ];

      case AirQualityLevel.warning:
        return [
          const Color(0xFF8B7355),
          const Color(0xFFAA9070),
          const Color(0xFFC8AD88),
          const Color(0xFFDDC8A0),
          const Color(0xFFEEDDB8),
        ];

      case AirQualityLevel.critical:
        return [
          const Color(0xFF5A3A3A),
          const Color(0xFF7A4A40),
          const Color(0xFF9A6050),
          const Color(0xFFB87868),
          const Color(0xFFCC9080),
        ];

      case AirQualityLevel.offline:
        return [
          const Color(0xFF6A7A8A),
          const Color(0xFF8A9AA8),
          const Color(0xFFAAB8C4),
          const Color(0xFFCCD4DA),
          const Color(0xFFE0E6EA),
        ];
    }
  }

  // ==================================================================
  // SKY STOPS
  // ==================================================================

  List<double> _skyStops(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:
        return [0.0, 0.25, 0.55, 0.80, 1.0];

      case AirQualityLevel.moderate:
        return [0.0, 0.30, 0.60, 0.82, 1.0];

      case AirQualityLevel.warning:
        return [0.0, 0.28, 0.58, 0.80, 1.0];

      case AirQualityLevel.critical:
        return [0.0, 0.28, 0.58, 0.80, 1.0];

      case AirQualityLevel.offline:
        return [0.0, 0.28, 0.58, 0.80, 1.0];
    }
  }

  // ==================================================================
  // CLOUD COLOR
  // ==================================================================

  Color _cloudColor(AirQualityLevel level, bool isDark, double t, Color from) {
    final Color to;

    switch (level) {
      case AirQualityLevel.good:
        to = isDark ? const Color(0xFFB0D4F0) : Colors.white;
        break;

      case AirQualityLevel.moderate:
        to = isDark ? const Color(0xFFB0C8C8) : const Color(0xFFE8EED8);
        break;

      case AirQualityLevel.warning:
        to = isDark ? const Color(0xFFB8A880) : const Color(0xFFDDD0A8);
        break;

      case AirQualityLevel.critical:
        to = isDark ? const Color(0xFFB89080) : const Color(0xFFD4A898);
        break;

      case AirQualityLevel.offline:
        to = isDark ? const Color(0xFF909090) : const Color(0xFFCCCCCC);
        break;
    }

    return Color.lerp(from, to, t) ?? to;
  }

  // ==================================================================
  // CLOUD OPACITY
  // ==================================================================

  double _cloudOpacityMult(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:
        return 1.0;

      case AirQualityLevel.moderate:
        return 1.2;

      case AirQualityLevel.warning:
        return 1.5;

      case AirQualityLevel.critical:
        return 1.8;

      case AirQualityLevel.offline:
        return 0.7;
    }
  }

  // ==================================================================
  // BOTTOM FADE COLOR
  // ==================================================================

  Color _bottomFadeColor(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:
        return const Color(0xFFE0F4EC);

      case AirQualityLevel.moderate:
        return const Color(0xFFE0ECD8);

      case AirQualityLevel.warning:
        return const Color(0xFFE8D8B0);

      case AirQualityLevel.critical:
        return const Color(0xFFD4A090);

      case AirQualityLevel.offline:
        return const Color(0xFFD8E0E8);
    }
  }
}

// ======================================================================
// CLOUD SHAPE
// ======================================================================

class _CloudShape extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;
  final Color color;

  const _CloudShape({
    required this.width,
    required this.height,
    required this.opacity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: CustomPaint(
        size: Size(width, height),
        painter: _CloudPainter(color: color),
      ),
    );
  }
}

// ======================================================================
// CLOUD PAINTER
// ======================================================================

class _CloudPainter extends CustomPainter {
  final Color color;

  _CloudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Main cloud body ──────────────────────────────────────────────
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final path = Path();

    path.moveTo(w * 0.15, h * 0.85);

    path.quadraticBezierTo(w * 0.0, h * 0.85, w * 0.05, h * 0.55);

    path.quadraticBezierTo(w * 0.0, h * 0.20, w * 0.18, h * 0.30);

    path.quadraticBezierTo(w * 0.20, h * 0.0, w * 0.38, h * 0.10);

    path.quadraticBezierTo(w * 0.45, h * 0.0, w * 0.50, h * 0.08);

    path.quadraticBezierTo(w * 0.58, h * 0.0, w * 0.62, h * 0.18);

    path.quadraticBezierTo(w * 0.72, h * 0.0, w * 0.80, h * 0.15);

    path.quadraticBezierTo(w * 1.0, h * 0.10, w * 0.95, h * 0.45);

    path.quadraticBezierTo(w * 1.0, h * 0.85, w * 0.85, h * 0.85);

    path.close();

    canvas.drawPath(path, paint);

    // ── Highlight ───────────────────────────────────────────────────
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final highlightPath = Path();

    highlightPath.moveTo(w * 0.20, h * 0.45);

    highlightPath.quadraticBezierTo(w * 0.22, h * 0.05, w * 0.40, h * 0.15);

    highlightPath.quadraticBezierTo(w * 0.55, h * 0.02, w * 0.65, h * 0.20);

    highlightPath.quadraticBezierTo(w * 0.75, h * 0.05, w * 0.82, h * 0.22);

    highlightPath.quadraticBezierTo(w * 0.88, h * 0.40, w * 0.78, h * 0.50);

    highlightPath.quadraticBezierTo(w * 0.50, h * 0.35, w * 0.20, h * 0.45);

    highlightPath.close();

    canvas.drawPath(highlightPath, highlight);
  }

  @override
  bool shouldRepaint(_CloudPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ======================================================================
// CLOUD CONFIG
// ======================================================================

class _CloudConfig {
  final double top;
  final double width;
  final double height;
  final double opacity;
  final int speed;

  const _CloudConfig({
    required this.top,
    required this.width,
    required this.height,
    required this.opacity,
    required this.speed,
  });
}

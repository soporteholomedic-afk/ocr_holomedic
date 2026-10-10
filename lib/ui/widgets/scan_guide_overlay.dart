/// Reusable camera scan-guide overlay ("cuadro de guía").
///
/// Renders a dark scrim over the whole surface with a transparent rounded
/// window framed by corner brackets in the theme primary color, plus a
/// hint line below the window. The overlay is wrapped in [IgnorePointer]
/// so camera controls (Cancel/Skip buttons) layered under or over it keep
/// receiving taps.
///
/// Colors and radii are theme-driven only (ColorScheme + [AppRadius]); the
/// widget has no hardcoded palette values.
library;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Fraction of the available width the guide window spans.
const double _kWidthFactor = 0.9;

/// Default guide shape: a wide horizontal strip (both capture targets are
/// wide: a PDF417 barcode and a 3-line TD1 MRZ block).
const double _kDefaultAspectRatio = 3.5;

const String _kDefaultHint = 'Align the document inside the frame';

/// Corner bracket edge length and stroke, in logical pixels.
const double _kBracketLength = 28;
const double _kBracketStroke = 4;

/// Gap between the window bottom edge and the hint text.
const double _kHintSpacing = 16;

/// A framed viewfinder overlay for camera capture screens.
class ScanGuideOverlay extends StatelessWidget {
  const ScanGuideOverlay({
    super.key,
    this.aspectRatio = _kDefaultAspectRatio,
    this.hint = _kDefaultHint,
    this.alignment = Alignment.center,
    this.widthFactor = _kWidthFactor,
  });

  /// Window aspect ratio (width / height).
  final double aspectRatio;

  /// Hint text rendered below the window; rendered only when non-empty.
  final String hint;

  /// How the window is placed inside the available surface (e.g.
  /// [Alignment.center] or a lower-third offset for MRZ-style targets).
  final Alignment alignment;

  /// Fraction of the available width the window spans (0 < factor <= 1).
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Rect window = _windowRect(constraints.biggest);
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScrimPainter(
                    window: window,
                    radius: AppRadius.xl,
                    color: scheme.scrim.withValues(alpha: 0.6),
                  ),
                ),
              ),
              // Invisible keyed box marking the transparent window; the
              // brackets below are its visible frame.
              Positioned.fromRect(
                rect: window,
                child: const SizedBox.expand(
                  key: Key('scan-guide-frame'),
                ),
              ),
              ..._brackets(window, scheme.primary),
              if (hint.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  top: window.bottom + _kHintSpacing,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      hint,
                      key: const Key('scan-guide-hint'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onPrimary),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Resolves the transparent window rect for the given surface: width is
  /// a fraction of the surface, height follows the aspect ratio, clamped
  /// to the surface, and the rect is inscribed per [alignment].
  Rect _windowRect(Size surface) {
    var width = surface.width * widthFactor;
    var height = width / aspectRatio;
    if (height > surface.height) {
      height = surface.height;
      width = height * aspectRatio;
      if (width > surface.width) {
        width = surface.width;
        height = width / aspectRatio;
      }
    }
    return alignment.inscribe(Size(width, height), Offset.zero & surface);
  }

  /// Positions one bracket widget at each corner of the window.
  List<Positioned> _brackets(Rect window, Color color) {
    return [
      _bracket(
        key: 'scan-guide-bracket-top-left',
        rect: Rect.fromLTWH(
            window.left, window.top, _kBracketLength, _kBracketLength),
        corner: _BracketCorner.topLeft,
        color: color,
      ),
      _bracket(
        key: 'scan-guide-bracket-top-right',
        rect: Rect.fromLTWH(window.right - _kBracketLength, window.top,
            _kBracketLength, _kBracketLength),
        corner: _BracketCorner.topRight,
        color: color,
      ),
      _bracket(
        key: 'scan-guide-bracket-bottom-left',
        rect: Rect.fromLTWH(window.left, window.bottom - _kBracketLength,
            _kBracketLength, _kBracketLength),
        corner: _BracketCorner.bottomLeft,
        color: color,
      ),
      _bracket(
        key: 'scan-guide-bracket-bottom-right',
        rect: Rect.fromLTWH(window.right - _kBracketLength,
            window.bottom - _kBracketLength, _kBracketLength, _kBracketLength),
        corner: _BracketCorner.bottomRight,
        color: color,
      ),
    ];
  }

  Positioned _bracket({
    required String key,
    required Rect rect,
    required _BracketCorner corner,
    required Color color,
  }) {
    return Positioned.fromRect(
      rect: rect,
      child: CustomPaint(
        key: Key(key),
        painter: _BracketPainter(corner: corner, color: color),
      ),
    );
  }
}

enum _BracketCorner { topLeft, topRight, bottomLeft, bottomRight }

/// Paints an L-shaped corner bracket with rounded joins.
class _BracketPainter extends CustomPainter {
  const _BracketPainter({required this.corner, required this.color});

  final _BracketCorner corner;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kBracketStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final length = size.width;
    final path = Path();
    switch (corner) {
      case _BracketCorner.topLeft:
        path
          ..moveTo(0, length)
          ..lineTo(0, 0)
          ..lineTo(length, 0);
      case _BracketCorner.topRight:
        path
          ..moveTo(0, 0)
          ..lineTo(length, 0)
          ..lineTo(length, length);
      case _BracketCorner.bottomLeft:
        path
          ..moveTo(0, 0)
          ..lineTo(0, length)
          ..lineTo(length, length);
      case _BracketCorner.bottomRight:
        path
          ..moveTo(length, 0)
          ..lineTo(length, length)
          ..lineTo(0, length);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BracketPainter oldDelegate) =>
      corner != oldDelegate.corner || color != oldDelegate.color;
}

/// Paints the dark scrim as the full surface minus the rounded window.
class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({
    required this.window,
    required this.radius,
    required this.color,
  });

  final Rect window;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final surface = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(window, Radius.circular(radius)));
    final scrim = Path.combine(PathOperation.difference, surface, hole);
    canvas.drawPath(scrim, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ScrimPainter oldDelegate) =>
      window != oldDelegate.window ||
      radius != oldDelegate.radius ||
      color != oldDelegate.color;
}

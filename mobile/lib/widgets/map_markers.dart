/// be:Safe v2 — Map Markers (Serenity Guard design)
///
/// Custom Canvas-drawn markers matching the design specs in
/// `design/ik/stitch_be_safe_calm_safety_app/refined_*`.
///
/// Marker types:
/// - alertPin(category, {variant, count})   teardrop pin with category glyph
/// - inactivePin()                          desaturated alert pin
/// - clusterPin(count)                      4 buckets (s/m/l/xl) with mint/coral glow
/// - userPin()                              navy dot inside aqua halo
/// - familyPin()                            mint→navy gradient orb with mint glow
/// - childPin(name)                         white circle with navy child_care glyph
/// - groupPin(count, {extra})               navy circle with count and +N badge
/// - sosPin()                               coral disk with 3 concentric rings
///
/// Implementation detail: glyphs are rendered via `TextPainter` using the
/// `MaterialIcons` font shipped with Flutter, so no extra asset is required.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/alert.dart';
import '../theme/design_tokens.dart';

/// Visual variant for an alert teardrop pin.
enum AlertPinVariant { defaultV, selected, confirmed, inactive, multi }

class MapMarkers {
  MapMarkers._();

  // Cache: hot path on map redraws. Keyed by a string descriptor.
  static final Map<String, BitmapDescriptor> _cache = {};

  // Render at 3x to get crisp pins on high-DPI screens.
  static const double _scale = 3.0;

  // -------- Public API --------------------------------------------------

  /// Default alert pin (teardrop, coral fill).
  static Future<BitmapDescriptor> alertPin(
    AlertCategory category, {
    AlertPinVariant variant = AlertPinVariant.defaultV,
    int count = 1,
  }) {
    final key =
        'alert_${category.apiValue}_${variant.name}_${variant == AlertPinVariant.multi ? count : 0}';
    return _memo(key, () => _drawAlertPin(category, variant, count));
  }

  /// Inactive (stale) alert — alias for `alertPin(..., variant: inactive)`.
  static Future<BitmapDescriptor> inactivePin(AlertCategory category) =>
      alertPin(category, variant: AlertPinVariant.inactive);

  /// Cluster pin — 4 visual buckets with continuous size growth inside each.
  static Future<BitmapDescriptor> clusterPin(int count) {
    final bucket = _clusterBucket(count);
    // Quantise to keep the cache bounded while preserving the visual ramp.
    final quantised = count < 10
        ? count
        : count < 50 ? (count ~/ 2) * 2
        : count < 100 ? (count ~/ 5) * 5
        : count < 200 ? (count ~/ 10) * 10
        : (count ~/ 25) * 25;
    final key = 'cluster_${bucket.name}_$quantised';
    return _memo(key, () => _drawClusterPin(count, bucket));
  }

  /// User position — small navy dot inside aqua radial halo.
  static Future<BitmapDescriptor> userPin() =>
      _memo('user_pos', _drawUserPin);

  /// Family member (adult) — gradient orb.
  static Future<BitmapDescriptor> familyPin() =>
      _memo('family', _drawFamilyPin);

  /// F11: AED defibrillator pin — mint circle with white heart glyph.
  static Future<BitmapDescriptor> aedPin() =>
      _memo('aed', _drawAedPin);

  /// Child pin — white circle with navy child_care glyph.
  ///
  /// `name` is currently unused (kept for API compatibility / future personalisation).
  static Future<BitmapDescriptor> childPin(String name) =>
      _memo('child', _drawChildPin);

  /// Group of users at the same point (e.g. parents + kids).
  static Future<BitmapDescriptor> groupPin(int count, {int extra = 1}) {
    final key = 'group_${count}_$extra';
    return _memo(key, () => _drawGroupPin(count, extra));
  }

  /// SOS button on the map — coral disk + concentric rings.
  static Future<BitmapDescriptor> sosPin() => _memo('sos', _drawSosPin);

  /// Clear cache (e.g. after theme change).
  static void clearCache() => _cache.clear();

  // -------- Drawing primitives -----------------------------------------

  static Future<BitmapDescriptor> _memo(
    String key,
    Future<BitmapDescriptor> Function() build,
  ) async {
    final cached = _cache[key];
    if (cached != null) return cached;
    final desc = await build();
    _cache[key] = desc;
    return desc;
  }

  /// Wraps the Canvas recording boilerplate and renders to a [BitmapDescriptor]
  /// at the given logical size (rendered at `_scale` for crispness).
  static Future<BitmapDescriptor> _record(
    double width,
    double height,
    void Function(Canvas canvas) draw,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width * _scale, height * _scale),
    );
    canvas.scale(_scale, _scale);
    draw(canvas);
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (width * _scale).toInt(),
      (height * _scale).toInt(),
    );
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: width,
      height: height,
    );
  }

  /// Paints a Material icon glyph centered at `(cx, cy)`.
  static void _paintGlyph(
    Canvas canvas,
    IconData icon, {
    required double cx,
    required double cy,
    required double size,
    required Color color,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  // -------- Alert teardrop --------------------------------------------

  static Path _teardropPath(double w, double h) {
    // Reference: design SVG `M28 80 C28 80, 56 46.12, 56 28
    //           C56 12.536, 43.464 0, 28 0
    //           C12.536 0, 0 12.536, 0 28
    //           C0 46.12, 28 80, 28 80 Z` scaled to (w, h).
    final sx = w / 56.0;
    final sy = h / 80.0;
    final p = Path()..moveTo(28 * sx, 80 * sy);
    p.cubicTo(28 * sx, 80 * sy, 56 * sx, 46.12 * sy, 56 * sx, 28 * sy);
    p.cubicTo(56 * sx, 12.536 * sy, 43.464 * sx, 0, 28 * sx, 0);
    p.cubicTo(12.536 * sx, 0, 0, 12.536 * sy, 0, 28 * sy);
    p.cubicTo(0, 46.12 * sy, 28 * sx, 80 * sy, 28 * sx, 80 * sy);
    p.close();
    return p;
  }

  static Future<BitmapDescriptor> _drawAlertPin(
    AlertCategory category,
    AlertPinVariant variant,
    int count,
  ) {
    const double w = 64;
    const double h = 84; // 80 + small bottom padding for shadow tail
    const double pinW = 56;
    const double pinH = 80;
    const double pinDx = (w - pinW) / 2; // = 4
    const double pinDy = 2;

    // Variant-specific colors
    final isInactive = variant == AlertPinVariant.inactive;
    final fillColor = isInactive
        ? const Color(0xFFB8B8B8)
        : SerenityColors.glowAlertCoral;
    final haloAlpha = switch (variant) {
      AlertPinVariant.defaultV => 0.25,
      AlertPinVariant.selected => 0.40,
      AlertPinVariant.confirmed => 0.25,
      AlertPinVariant.inactive => 0.15,
      AlertPinVariant.multi => 0.25,
    };
    final glyphAlpha = isInactive ? 0.7 : 1.0;
    final scale = variant == AlertPinVariant.selected ? 1.10 : 1.0;

    return _record(w, h, (canvas) {
      // Scale the entire pin around its tip (bottom-center) for "selected".
      if (scale != 1.0) {
        const tipX = w / 2;
        const tipY = pinDy + pinH;
        canvas.translate(tipX, tipY);
        canvas.scale(scale, scale);
        canvas.translate(-tipX, -tipY);
      }

      // Halo (radial gradient circle behind the pin head)
      final haloCenter = Offset(w / 2, pinDy + 28);
      const haloR = 40.0;
      final haloPaint = Paint()
        ..shader = ui.Gradient.radial(
          haloCenter,
          haloR,
          [fillColor.withValues(alpha: haloAlpha), fillColor.withValues(alpha: 0.0)],
          const [0.0, 0.7],
        );
      canvas.drawCircle(haloCenter, haloR, haloPaint);

      // Soft drop shadow under the teardrop
      canvas.save();
      canvas.translate(pinDx, pinDy + 4);
      final shadowPath = _teardropPath(pinW, pinH);
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = SerenityColors.primaryContainer.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.restore();

      // Teardrop body
      canvas.save();
      canvas.translate(pinDx, pinDy);
      final path = _teardropPath(pinW, pinH);
      canvas.drawPath(path, Paint()..color = fillColor);
      // White stroke (2.5px design value)
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      // Inner navy ring for "selected" (30% opacity, slightly inset)
      if (variant == AlertPinVariant.selected) {
        canvas.drawCircle(
          const Offset(28, 28),
          22,
          Paint()
            ..color = SerenityColors.primaryContainer.withValues(alpha: 0.30)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      canvas.restore();

      // Glyph (white Material symbol), centered on pin head at logical (32, 30)
      _paintGlyph(
        canvas,
        category.iconData,
        cx: w / 2,
        cy: pinDy + 28,
        size: 28,
        color: Colors.white.withValues(alpha: glyphAlpha),
      );

      // Confirmed: mint badge bottom-right of head with navy check
      if (variant == AlertPinVariant.confirmed) {
        final c = Offset(pinDx + 44, pinDy + 44);
        canvas.drawCircle(c, 11,
            Paint()..color = SerenityColors.secondaryContainer);
        canvas.drawCircle(c, 11,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        _paintGlyph(canvas, Icons.check,
            cx: c.dx,
            cy: c.dy,
            size: 14,
            color: SerenityColors.primaryContainer);
      }

      // Multi: navy badge bottom-right with count
      if (variant == AlertPinVariant.multi) {
        final c = Offset(pinDx + 44, pinDy + 44);
        canvas.drawCircle(c, 11,
            Paint()..color = SerenityColors.primaryContainer);
        canvas.drawCircle(c, 11,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        final label = count >= 100 ? '99+' : '$count';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              height: 1.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
      }
    });
  }

  // -------- Cluster pin -----------------------------------------------

  static _ClusterBucket _clusterBucket(int count) {
    if (count < 10) return _ClusterBucket.small;
    if (count < 50) return _ClusterBucket.medium;
    if (count < 100) return _ClusterBucket.large;
    return _ClusterBucket.mega;
  }

  static String _clusterLabel(int count) {
    if (count >= 200) return '200+';
    if (count >= 100) {
      final step = (count ~/ 50) * 50;
      return '$step+';
    }
    if (count >= 50) return '$count+';
    return '$count';
  }

  /// Per-bucket radius/font ranges. The cluster grows continuously inside its
  /// bucket on a log curve, so an 80-alert cluster is visibly bigger than a
  /// 12-alert cluster even though both fall into the same visual class.
  static _ClusterSpec _clusterSpec(int count, _ClusterBucket bucket) {
    final ranges = switch (bucket) {
      _ClusterBucket.small => const _Range(2, 9, 22, 32, 14, 16, 80, null, null),
      _ClusterBucket.medium => _Range(10, 49, 32, 48, 16, 20, 112, _Glow.mint(18), null),
      _ClusterBucket.large => _Range(
          50,
          99,
          48,
          60,
          20,
          22,
          144,
          _Glow.mint(20),
          _Border(SerenityColors.secondaryContainer, 1.5, 0.6)),
      _ClusterBucket.mega => _Range(100, 1000, 60, 78, 22, 28, 184, _Glow.coral(24), null),
    };
    // Logarithmic interpolation within the bucket.
    final cMinLog = math.log(ranges.cMin.toDouble());
    final span = math.log((ranges.cMax + 1).toDouble()) - cMinLog;
    final t = span <= 0
        ? 0.0
        : (math.log((count + 1).toDouble()) - cMinLog) / span;
    final tt = t.clamp(0.0, 1.0);
    return _ClusterSpec(
      box: ranges.box,
      radius: ranges.rMin + (ranges.rMax - ranges.rMin) * tt,
      font: ranges.fMin + (ranges.fMax - ranges.fMin) * tt,
      glow: ranges.glow,
      border: ranges.border,
    );
  }

  static Future<BitmapDescriptor> _drawClusterPin(
    int count,
    _ClusterBucket bucket,
  ) {
    final spec = _clusterSpec(count, bucket);
    final label = _clusterLabel(count);

    return _record(spec.box, spec.box, (canvas) {
      final center = Offset(spec.box / 2, spec.box / 2);

      // Glow halo — radius scales with the disk so the halo always extends
      // past the rim regardless of how big the cluster grew within its bucket.
      final glow = spec.glow;
      if (glow != null) {
        canvas.drawCircle(
          center,
          spec.radius * 1.25,
          Paint()
            ..color = glow.color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow.blur),
        );
      }

      // Navy fill
      canvas.drawCircle(
          center, spec.radius, Paint()..color = SerenityColors.primaryContainer);

      // Optional mint border
      final border = spec.border;
      if (border != null) {
        canvas.drawCircle(
          center,
          spec.radius,
          Paint()
            ..color = border.color.withValues(alpha: border.alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = border.width,
        );
      }

      // Count label
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: spec.font,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    });
  }

  // -------- Special pins -----------------------------------------------

  static Future<BitmapDescriptor> _drawUserPin() {
    const double w = 56;
    return _record(w, w, (canvas) {
      final c = Offset(w / 2, w / 2);
      // Aqua radial halo
      canvas.drawCircle(
        c,
        w / 2,
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            w / 2,
            [
              SerenityColors.glowCalmAqua.withValues(alpha: 0.50),
              SerenityColors.glowCalmAqua.withValues(alpha: 0.0),
            ],
            const [0.0, 0.7],
          ),
      );
      // Navy dot (16dp) with white border
      canvas.drawCircle(c, 9, Paint()..color = Colors.white);
      canvas.drawCircle(c, 7,
          Paint()..color = SerenityColors.primaryContainer);
    });
  }

  static Future<BitmapDescriptor> _drawFamilyPin() {
    const double w = 64;
    return _record(w, w, (canvas) {
      final c = Offset(w / 2, w / 2);
      // Mint glow
      canvas.drawCircle(
        c,
        26,
        Paint()
          ..color = SerenityColors.glowSafeMint.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      // 48px orb with mint→navy gradient
      final rect = Rect.fromCircle(center: c, radius: 24);
      canvas.drawCircle(
        c,
        24,
        Paint()
          ..shader = ui.Gradient.linear(
            rect.topLeft,
            rect.bottomRight,
            [SerenityColors.glowSafeMint, SerenityColors.primaryContainer],
          ),
      );
      // Mint border 4px @ 60%
      canvas.drawCircle(
        c,
        24,
        Paint()
          ..color = SerenityColors.secondaryContainer.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    });
  }

  static Future<BitmapDescriptor> _drawAedPin() {
    const double w = 56;
    return _record(w, w, (canvas) {
      final c = Offset(w / 2, w / 2);
      // Mint glow halo
      canvas.drawCircle(
        c, 22,
        Paint()
          ..color = SerenityColors.glowSafeMint.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      // Mint solid circle 20r
      canvas.drawCircle(c, 20, Paint()..color = SerenityColors.glowSafeMint);
      // White border 2px
      canvas.drawCircle(
        c, 20,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      // Navy heart glyph centered
      _paintGlyph(canvas, Icons.favorite,
          cx: c.dx, cy: c.dy, size: 22, color: SerenityColors.onSecondaryContainer);
    });
  }

  static Future<BitmapDescriptor> _drawChildPin() {
    const double w = 64;
    return _record(w, w, (canvas) {
      final c = Offset(w / 2, w / 2);
      // Soft navy drop shadow — gives separation from light monochrome map.
      canvas.drawCircle(
        c.translate(0, 2),
        24,
        Paint()
          ..color = SerenityColors.primaryContainer.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Mint outer glow
      canvas.drawCircle(
        c,
        27,
        Paint()
          ..color = SerenityColors.glowSafeMint.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      // White circle 48px
      canvas.drawCircle(c, 24, Paint()..color = Colors.white);
      // Mint border 4px @ full
      canvas.drawCircle(
        c,
        24,
        Paint()
          ..color = SerenityColors.secondaryContainer
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      // Thin navy outline 1px for crisp edge on light backgrounds
      canvas.drawCircle(
        c,
        22,
        Paint()
          ..color = SerenityColors.primaryContainer.withValues(alpha: 0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      // Navy face glyph (friendly child icon)
      _paintGlyph(
        canvas,
        Icons.face,
        cx: c.dx,
        cy: c.dy,
        size: 26,
        color: SerenityColors.primaryContainer,
      );
    });
  }

  static Future<BitmapDescriptor> _drawGroupPin(int count, int extra) {
    const double w = 64;
    return _record(w, w, (canvas) {
      final c = Offset(w / 2, w / 2);
      // Navy circle 48px
      canvas.drawCircle(c, 24,
          Paint()..color = SerenityColors.primaryContainer);
      // Count text
      final tp = TextPainter(
        text: TextSpan(
          text: '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
      // Mint +N badge bottom-right
      if (extra > 0) {
        final bc = Offset(c.dx + 18, c.dy + 18);
        canvas.drawCircle(
          bc,
          9,
          Paint()..color = SerenityColors.secondaryContainer,
        );
        canvas.drawCircle(
          bc,
          9,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        final btp = TextPainter(
          text: TextSpan(
            text: '+$extra',
            style: TextStyle(
              color: SerenityColors.primaryContainer,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              height: 1.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        btp.paint(canvas, Offset(bc.dx - btp.width / 2, bc.dy - btp.height / 2));
      }
    });
  }

  static Future<BitmapDescriptor> _drawSosPin() {
    const double w = 80;
    return _record(w, w, (canvas) {
      final c = Offset(w / 2, w / 2);
      final coral = SerenityColors.glowAlertCoral;
      // 3 concentric rings (outer-to-inner alphas 0.30, 0.60, 0.90)
      canvas.drawCircle(
        c,
        32,
        Paint()
          ..color = coral.withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        c,
        28,
        Paint()
          ..color = coral.withValues(alpha: 0.60)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        c,
        24,
        Paint()
          ..color = coral.withValues(alpha: 0.90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      // Solid coral disk (24 radius)
      canvas.drawCircle(c, 22, Paint()..color = coral);
      // "SOS" label
      final tp = TextPainter(
        text: const TextSpan(
          text: 'SOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            letterSpacing: 0.6,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
    });
  }
}

// -------- Internal helpers ---------------------------------------------

enum _ClusterBucket { small, medium, large, mega }

class _ClusterSpec {
  final double box;
  final double radius;
  final double font;
  final _Glow? glow;
  final _Border? border;
  const _ClusterSpec({
    required this.box,
    required this.radius,
    required this.font,
    this.glow,
    this.border,
  });
}

class _Glow {
  final Color color;
  final double blur;
  const _Glow(this.color, this.blur);
  factory _Glow.mint(double blur) => _Glow(
        SerenityColors.glowSafeMint.withValues(alpha: 0.30),
        blur,
      );
  factory _Glow.coral(double blur) => _Glow(
        SerenityColors.glowAlertCoral.withValues(alpha: 0.40),
        blur,
      );
}

class _Border {
  final Color color;
  final double width;
  final double alpha;
  const _Border(this.color, this.width, this.alpha);
}

/// Continuous (count → size) range for a cluster bucket.
class _Range {
  final int cMin;
  final int cMax;
  final double rMin;
  final double rMax;
  final double fMin;
  final double fMax;
  final double box;
  final _Glow? glow;
  final _Border? border;
  const _Range(
    this.cMin,
    this.cMax,
    this.rMin,
    this.rMax,
    this.fMin,
    this.fMax,
    this.box,
    this.glow,
    this.border,
  );
}

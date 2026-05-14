/// be:Safe v2 — Map Markers (simple, using default Google Maps pins)
///
/// Uses BitmapDescriptor.defaultMarkerWithHue for alert pins (proven shape)
/// and simple Canvas circles for clusters. No custom teardrop drawing.
library;

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/alert.dart';
import '../theme/design_tokens.dart';

class MapMarkers {
  MapMarkers._();

  static final Map<String, BitmapDescriptor> _cache = {};

  /// Alert pin — default Google Maps pin shape in coral hue (0 = red, 330 = rose).
  /// Each category gets a slightly different hue for variety.
  static Future<BitmapDescriptor> alertPin(AlertCategory category) async {
    final key = 'alert_${category.apiValue}';
    if (_cache.containsKey(key)) return _cache[key]!;

    // Map categories to hues (0-360): coral-ish range
    final hue = switch (category) {
      AlertCategory.aggression => BitmapDescriptor.hueRed,
      AlertCategory.theft => BitmapDescriptor.hueOrange,
      AlertCategory.accident => BitmapDescriptor.hueYellow,
      AlertCategory.fire => BitmapDescriptor.hueRed,
      AlertCategory.flood => BitmapDescriptor.hueAzure,
      AlertCategory.ice => BitmapDescriptor.hueCyan,
      AlertCategory.construction => BitmapDescriptor.hueOrange,
      AlertCategory.animal => BitmapDescriptor.hueGreen,
      AlertCategory.darkArea => BitmapDescriptor.hueViolet,
      AlertCategory.drugs => BitmapDescriptor.hueMagenta,
      AlertCategory.police => BitmapDescriptor.hueBlue,
      AlertCategory.weather => BitmapDescriptor.hueCyan,
      AlertCategory.other => BitmapDescriptor.hueRose,
      AlertCategory.strangerDanger => BitmapDescriptor.hueRed,
      AlertCategory.trafficDanger => BitmapDescriptor.hueOrange,
      AlertCategory.playgroundHazard => BitmapDescriptor.hueYellow,
      AlertCategory.waterHazard => BitmapDescriptor.hueAzure,
      AlertCategory.schoolZone => BitmapDescriptor.hueViolet,
    };

    _cache[key] = BitmapDescriptor.defaultMarkerWithHue(hue);
    return _cache[key]!;
  }

  /// Inactive alert — default marker in low-saturation.
  static Future<BitmapDescriptor> inactivePin() async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
  }

  /// Cluster pin — navy circle with white count text.
  static Future<BitmapDescriptor> clusterPin(int count) async {
    final bucket = count < 10 ? 's' : count < 50 ? 'm' : count < 100 ? 'l' : 'xl';
    final key = 'cluster_$bucket';
    if (_cache.containsKey(key)) return _cache[key]!;

    // Canvas size (logical) — will render @2x
    final double dp = bucket == 's' ? 44 : bucket == 'm' ? 52 : bucket == 'l' ? 60 : 68;
    final double fontSize = bucket == 's' ? 16 : bucket == 'm' ? 18 : bucket == 'l' ? 20 : 22;
    final px = (dp * 2).toInt(); // @2x render

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, dp, dp));
    final center = Offset(dp / 2, dp / 2);
    final r = dp / 2 - 2;

    // White border
    canvas.drawCircle(center, r, Paint()..color = Colors.white);
    // Navy fill
    canvas.drawCircle(center, r - 2.5, Paint()..color = SerenityColors.primaryContainer);

    // White text
    final label = count >= 100 ? '99+' : '$count';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(px, px);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    _cache[key] = BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: dp, height: dp);
    return _cache[key]!;
  }

  /// Child/family pin — green default marker.
  static Future<BitmapDescriptor> childPin(String name) async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  /// User position — not needed (Google Maps myLocationEnabled handles it).
  static Future<BitmapDescriptor> userPin() async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }

  /// SOS pin — red default marker.
  static Future<BitmapDescriptor> sosPin() async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  /// Clear cache.
  static void clearCache() => _cache.clear();
}

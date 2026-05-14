/// be:Safe v2 — Custom Map Markers (programmatic, resolution-independent)
///
/// Generates Google Maps BitmapDescriptor markers matching the Serenity Guard
/// pin design from Stitch: coral teardrop pins with white category icons,
/// navy cluster circles, mint family rings, aqua user dot.
///
/// Usage:
///   final pin = await MapMarkers.alertPin(AlertCategory.fire);
///   final cluster = await MapMarkers.clusterPin(23);
///   final user = await MapMarkers.userPin();
///   final child = await MapMarkers.childPin('Jan');
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/alert.dart';
import '../theme/design_tokens.dart';

class MapMarkers {
  MapMarkers._();

  static final Map<String, BitmapDescriptor> _cache = {};

  /// Alert pin — coral teardrop with white icon inside circular head.
  static Future<BitmapDescriptor> alertPin(AlertCategory category) async {
    final key = 'alert_${category.apiValue}';
    if (_cache.containsKey(key)) return _cache[key]!;

    // Tight canvas: just the pin, no glow
    const w = 48.0;
    const h = 64.0;
    const headR = 20.0;
    const headCy = 22.0; // center of head circle
    const cx = w / 2;
    const bottomY = h - 2.0; // tail tip

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    // Teardrop path
    final path = Path()
      ..moveTo(cx, bottomY)
      ..quadraticBezierTo(cx - headR * 0.7, headCy + headR * 0.9, cx - headR, headCy)
      ..arcTo(
        Rect.fromCircle(center: const Offset(cx, headCy), radius: headR),
        math.pi,
        -2 * math.pi,
        false,
      )
      ..quadraticBezierTo(cx + headR * 0.7, headCy + headR * 0.9, cx, bottomY)
      ..close();

    // White outline (draw first, thicker, acts as border)
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    // Slightly smaller coral fill
    final innerPath = Path()
      ..moveTo(cx, bottomY - 1.5)
      ..quadraticBezierTo(cx - (headR - 2) * 0.7, headCy + (headR - 2) * 0.9, cx - headR + 2, headCy)
      ..arcTo(
        Rect.fromCircle(center: const Offset(cx, headCy), radius: headR - 2),
        math.pi,
        -2 * math.pi,
        false,
      )
      ..quadraticBezierTo(cx + (headR - 2) * 0.7, headCy + (headR - 2) * 0.9, cx, bottomY - 1.5)
      ..close();
    canvas.drawPath(innerPath, Paint()..color = const Color(0xFFFF7A7A));

    // Icon centered in head
    final iconData = category.iconData;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 20,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, headCy - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage((w * 3).toInt(), (h * 3).toInt()); // @3x
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: w,
      height: h,
    );
    _cache[key] = descriptor;
    return descriptor;
  }

  /// Inactive/expired alert pin — gray teardrop.
  static Future<BitmapDescriptor> inactivePin() async {
    const key = 'alert_inactive';
    if (_cache.containsKey(key)) return _cache[key]!;

    const w = 48.0;
    const h = 64.0;
    const headR = 20.0;
    const headCy = 22.0;
    const cx = w / 2;
    const bottomY = h - 2.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    final path = Path()
      ..moveTo(cx, bottomY)
      ..quadraticBezierTo(cx - headR * 0.7, headCy + headR * 0.9, cx - headR, headCy)
      ..arcTo(Rect.fromCircle(center: const Offset(cx, headCy), radius: headR), math.pi, -2 * math.pi, false)
      ..quadraticBezierTo(cx + headR * 0.7, headCy + headR * 0.9, cx, bottomY)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);
    final inner = Path()
      ..moveTo(cx, bottomY - 1.5)
      ..quadraticBezierTo(cx - (headR - 2) * 0.7, headCy + (headR - 2) * 0.9, cx - headR + 2, headCy)
      ..arcTo(Rect.fromCircle(center: const Offset(cx, headCy), radius: headR - 2), math.pi, -2 * math.pi, false)
      ..quadraticBezierTo(cx + (headR - 2) * 0.7, headCy + (headR - 2) * 0.9, cx, bottomY - 1.5)
      ..close();
    canvas.drawPath(inner, Paint()..color = const Color(0xFFB8B8B8));

    final picture = recorder.endRecording();
    final img = await picture.toImage((w * 3).toInt(), (h * 3).toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    _cache[key] = BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: w, height: h);
    return _cache[key]!;
  }

  /// Cluster pin — navy circle with white count, size scales with density.
  static Future<BitmapDescriptor> clusterPin(int count) async {
    // Bucket: 2-9, 10-49, 50-99, 100+
    final bucket = count < 10 ? 's' : count < 50 ? 'm' : count < 100 ? 'l' : 'xl';
    final key = 'cluster_$bucket';
    if (_cache.containsKey(key)) return _cache[key]!;

    final double sz = bucket == 's' ? 40 : bucket == 'm' ? 48 : bucket == 'l' ? 56 : 64;
    final double r = sz / 2 - 4;
    final double fontSize = bucket == 's' ? 13 : bucket == 'm' ? 14 : bucket == 'l' ? 16 : 18;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, sz, sz));
    final center = Offset(sz / 2, sz / 2);

    // Glow for larger clusters
    if (bucket == 'l' || bucket == 'xl') {
      final glowColor = bucket == 'xl'
          ? const Color(0xFFFF7A7A) // coral for 100+
          : SerenityColors.glowSafeMint;
      canvas.drawCircle(
        center,
        r + 8,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            r + 8,
            [glowColor.withValues(alpha: 0.35), glowColor.withValues(alpha: 0)],
          ),
      );
    }

    // Navy circle
    canvas.drawCircle(center, r, Paint()..color = SerenityColors.primaryContainer);

    // Mint ring for 50-99
    if (bucket == 'l') {
      canvas.drawCircle(
        center,
        r - 2,
        Paint()
          ..color = SerenityColors.glowSafeMint.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // White text
    final label = count >= 100 ? '${count}+' : '$count';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage((sz * 3).toInt(), (sz * 3).toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    _cache[key] = BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: sz, height: sz);
    return _cache[key]!;
  }

  /// User position — small navy dot with aqua glow.
  static Future<BitmapDescriptor> userPin() async {
    const key = 'user';
    if (_cache.containsKey(key)) return _cache[key]!;

    const size = 36.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    final center = Offset(size / 2, size / 2);

    // Aqua glow
    canvas.drawCircle(
      center,
      24,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          24,
          [SerenityColors.glowCalmAqua.withValues(alpha: 0.5), SerenityColors.glowCalmAqua.withValues(alpha: 0)],
        ),
    );
    // White ring
    canvas.drawCircle(center, 7, Paint()..color = Colors.white);
    // Navy dot
    canvas.drawCircle(center, 5, Paint()..color = SerenityColors.primaryContainer);

    final picture = recorder.endRecording();
    final img = await picture.toImage((size * 3).toInt(), (size * 3).toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    _cache[key] = BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: size, height: size);
    return _cache[key]!;
  }

  /// Child/family pin — mint ring with initial letter.
  static Future<BitmapDescriptor> childPin(String name) async {
    final key = 'child_${name.hashCode}';
    if (_cache.containsKey(key)) return _cache[key]!;

    const size = 44.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    final center = Offset(size / 2, size / 2);

    // Mint glow
    canvas.drawCircle(
      center,
      32,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          32,
          [SerenityColors.glowSafeMint.withValues(alpha: 0.4), SerenityColors.glowSafeMint.withValues(alpha: 0)],
        ),
    );
    // White fill
    canvas.drawCircle(center, 15, Paint()..color = Colors.white);
    // Mint ring
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..color = SerenityColors.glowSafeMint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Initial
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final tp = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          color: SerenityColors.primaryContainer,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage((size * 3).toInt(), (size * 3).toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    _cache[key] = BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: size, height: size);
    return _cache[key]!;
  }

  /// SOS pin — coral circle with pulsing rings (static for map).
  static Future<BitmapDescriptor> sosPin() async {
    const key = 'sos';
    if (_cache.containsKey(key)) return _cache[key]!;

    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    final center = Offset(size / 2, size / 2);

    // 3 concentric coral rings
    for (var i = 3; i >= 1; i--) {
      canvas.drawCircle(
        center,
        20.0 + i * 8,
        Paint()
          ..color = const Color(0xFFFF7A7A).withValues(alpha: 0.3 / i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    // Core
    canvas.drawCircle(center, 20, Paint()..color = const Color(0xFFFF7A7A));
    // SOS text
    final tp = TextPainter(
      text: const TextSpan(
        text: 'SOS',
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, fontFamily: 'Inter'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage((size * 3).toInt(), (size * 3).toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    _cache[key] = BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: size, height: size);
    return _cache[key]!;
  }

  /// Clear cache (e.g. on theme change).
  static void clearCache() => _cache.clear();
}

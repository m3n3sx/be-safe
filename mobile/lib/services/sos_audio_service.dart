// F02 Audio SOS Recording — opt-in z RODO consent flow
//
// Nagrywanie audio podczas alertu SOS (gdy użytkownik świadomie zgodził się).
// Plik zapisany lokalnie + opcjonalnie uploaded do backend.
//
// RODO compliance:
// - Wymaga explicit opt-in w Settings + zaakceptowanie consent flow
// - Lokalna informacja przed nagrywaniem (visual + haptic)
// - Plik zapisywany w prywatnym katalogu app
// - User może w dowolnym momencie usunąć nagranie

import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SosAudioService {
  static final SosAudioService _instance = SosAudioService._();
  factory SosAudioService() => _instance;
  SosAudioService._();

  static const String _prefKeyEnabled = 'sos_audio_enabled';
  static const String _prefKeyConsentAt = 'sos_audio_consent_at';
  static const Duration _defaultDuration = Duration(seconds: 30);

  final AudioRecorder _recorder = AudioRecorder();
  bool _enabled = false;
  bool _recording = false;
  String? _currentPath;
  DateTime? _consentAt;

  bool get enabled => _enabled;
  bool get recording => _recording;
  bool get hasConsent => _consentAt != null;
  String? get currentPath => _currentPath;

  /// Wczytaj preferencje (call w main.dart init).
  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      _enabled = p.getBool(_prefKeyEnabled) ?? false;
      final consentMs = p.getInt(_prefKeyConsentAt);
      if (consentMs != null) {
        _consentAt = DateTime.fromMillisecondsSinceEpoch(consentMs);
      }
    } catch (_) {}
  }

  /// Zaakceptuj RODO consent. Bez tego nie da się włączyć nagrywania.
  Future<void> grantConsent() async {
    _consentAt = DateTime.now();
    final p = await SharedPreferences.getInstance();
    await p.setInt(_prefKeyConsentAt, _consentAt!.millisecondsSinceEpoch);
  }

  /// Cofnij zgodę RODO + wyłącz funkcję + usuń wszystkie nagrania.
  Future<void> revokeConsent() async {
    _consentAt = null;
    _enabled = false;
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefKeyConsentAt);
    await p.setBool(_prefKeyEnabled, false);
    await clearAllRecordings();
  }

  /// Włącz/wyłącz funkcję (po consent).
  Future<bool> setEnabled(bool v) async {
    if (v && !hasConsent) return false;
    if (v) {
      final granted = await _ensureMicPermission();
      if (!granted) return false;
    }
    _enabled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefKeyEnabled, v);
    return true;
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Rozpocznij nagrywanie. Wywoływane TYLKO z SOS flow gdy `enabled=true && hasConsent`.
  Future<bool> startRecording({Duration duration = _defaultDuration}) async {
    if (!_enabled || !hasConsent || _recording) return false;
    final ok = await _ensureMicPermission();
    if (!ok) return false;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final sosDir = Directory('${dir.path}/sos_audio');
      if (!sosDir.existsSync()) sosDir.createSync(recursive: true);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '${sosDir.path}/sos_$ts.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 22050,
          numChannels: 1,
        ),
        path: path,
      );
      _recording = true;
      _currentPath = path;
      // Auto-stop after duration
      Timer(duration, () async {
        if (_recording) await stopRecording();
      });
      return true;
    } catch (_) {
      _recording = false;
      _currentPath = null;
      return false;
    }
  }

  Future<String?> stopRecording() async {
    if (!_recording) return _currentPath;
    try {
      final p = await _recorder.stop();
      _recording = false;
      _currentPath = p ?? _currentPath;
      return _currentPath;
    } catch (_) {
      _recording = false;
      return _currentPath;
    }
  }

  /// Lista zapisanych nagrań (od najnowszego).
  Future<List<File>> listRecordings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final sosDir = Directory('${dir.path}/sos_audio');
      if (!sosDir.existsSync()) return [];
      final files = sosDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.m4a'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteRecording(File f) async {
    try {
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }

  Future<void> clearAllRecordings() async {
    try {
      final files = await listRecordings();
      for (final f in files) {
        try {
          await f.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

const int appVersion = 127;

class UpdateService {
  static const _channel = MethodChannel('pl.u235.alertmap/update');

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl.replaceAll('/api/v1', '')}/version'));
      final data = jsonDecode(res.body);
      if ((data['version'] as int) <= appVersion) return;
      if (!context.mounted) return;
      final url = data['url'] as String;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Dostępna aktualizacja'),
          content: const Text(
              'Nowa wersja be:Safe jest dostępna. Pobierzemy ją i zainstalujemy '
              'za Ciebie — wystarczy potwierdzić instalację.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Później')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _downloadAndInstall(context, url);
              },
              child: const Text('Zainstaluj teraz'),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  /// Pobiera APK w aplikacji (pasek postępu) i odpala instalator systemowy.
  /// Android nie pozwala na w pełni cichą instalację apek spoza Google Play —
  /// user widzi JEDEN systemowy dialog potwierdzenia. Bez przeglądarki/szukania
  /// pliku. Fallback: otwarcie URL w przeglądarce gdy coś zawiedzie.
  static Future<void> _downloadAndInstall(
      BuildContext context, String url) async {
    final progress = ValueNotifier<double>(0);
    final client = http.Client();

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Pobieram aktualizację'),
          content: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, p, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: p > 0 ? p : null),
                const SizedBox(height: 12),
                Text(p > 0 ? '${(p * 100).toStringAsFixed(0)}%' : 'Łączę...'),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/besafe_update.apk');
      final req = http.Request('GET', Uri.parse(url));
      final resp = await client.send(req);
      final total = resp.contentLength ?? 0;
      final sink = file.openWrite();
      int received = 0;
      await for (final chunk in resp.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) progress.value = received / total;
      }
      await sink.flush();
      await sink.close();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      await _channel.invokeMethod('installApk', file.path);
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      // Fallback — otwórz stronę pobierania w przeglądarce.
      _channel.invokeMethod('openUrl', url).catchError((_) {});
    } finally {
      client.close();
      progress.dispose();
    }
  }
}

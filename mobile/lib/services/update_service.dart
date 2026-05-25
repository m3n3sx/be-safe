import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

const int appVersion = 85;

class UpdateService {
  static const _channel = MethodChannel('pl.u235.alertmap/update');

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl.replaceAll('/api/v1', '')}/version'));
      final data = jsonDecode(res.body);
      if ((data['version'] as int) <= appVersion) return;
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Dostępna aktualizacja'),
          content: const Text('Nowa wersja AlertMap jest dostępna.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Później')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _channel.invokeMethod('openUrl', data['url']).catchError((_) {});
              },
              child: const Text('Pobierz'),
            ),
          ],
        ),
      );
    } catch (_) {}
  }
}

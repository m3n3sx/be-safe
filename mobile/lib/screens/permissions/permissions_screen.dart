/// F34 — Capability matrix screen.
///
/// Pokazuje 6 kategorii uprawnień (lokalizacja, kamera/galeria, mikrofon,
/// notyfikacje, biometria, sensory). Każda karta zawiera:
///  - status systemowy (permission_handler),
///  - toggle preferencji użytkownika (backend `/api/v1/permissions`),
///  - przycisk "Otwórz ustawienia" gdy permanently denied.
library;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class _Capability {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Permission permission;
  const _Capability({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.permission,
  });
}

const _kCapabilities = <_Capability>[
  _Capability(
    key: 'location',
    title: 'Lokalizacja',
    description:
        'Potrzebne aby pokazywać alerty w pobliżu, dzielić pozycję z rodziną oraz uruchamiać geofencing.',
    icon: Icons.location_on_outlined,
    permission: Permission.locationWhenInUse,
  ),
  _Capability(
    key: 'camera',
    title: 'Kamera i galeria',
    description: 'Dodawanie zdjęć do alertów i zgłoszeń.',
    icon: Icons.photo_camera_outlined,
    permission: Permission.camera,
  ),
  _Capability(
    key: 'microphone',
    title: 'Mikrofon',
    description: 'Nagranie audio SOS (zapis lokalny podczas aktywnego alarmu).',
    icon: Icons.mic_none_outlined,
    permission: Permission.microphone,
  ),
  _Capability(
    key: 'notifications',
    title: 'Powiadomienia',
    description:
        'Push o alertach w okolicy, SOS rodziny, eskorcie i przypomnieniach.',
    icon: Icons.notifications_outlined,
    permission: Permission.notification,
  ),
  _Capability(
    key: 'biometrics',
    title: 'Biometria',
    description: 'Odblokowanie aplikacji odciskiem palca lub twarzą.',
    icon: Icons.fingerprint,
    permission: Permission.unknown, // brak dedykowanego runtime permission
  ),
  _Capability(
    key: 'sensors',
    title: 'Sensory ruchu',
    description: 'Wykrywanie upadku (crash detection) i shake-to-SOS.',
    icon: Icons.sensors_outlined,
    permission: Permission.sensors,
  ),
];

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, bool> _granted = {};
  Map<String, PermissionStatus> _systemStatus = {};
  final Set<String> _pending = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSystemStatus();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/permissions');
      final caps = (res['capabilities'] as Map?)?.cast<String, dynamic>() ?? {};
      _granted = {
        for (final c in _kCapabilities)
          c.key: caps[c.key] == true,
      };
      await _refreshSystemStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshSystemStatus() async {
    final result = <String, PermissionStatus>{};
    for (final c in _kCapabilities) {
      if (c.permission == Permission.unknown) {
        result[c.key] = PermissionStatus.granted; // n/d — nie wymaga runtime
        continue;
      }
      try {
        result[c.key] = await c.permission.status;
      } catch (_) {
        result[c.key] = PermissionStatus.denied;
      }
    }
    if (mounted) setState(() => _systemStatus = result);
  }

  Future<void> _toggle(_Capability cap, bool value) async {
    if (_pending.contains(cap.key)) return;
    setState(() {
      _pending.add(cap.key);
      _granted[cap.key] = value;
    });
    try {
      if (value && cap.permission != Permission.unknown) {
        final status = await cap.permission.request();
        _systemStatus[cap.key] = status;
        if (status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Uprawnienie zablokowane w systemie. Otwórz ustawienia.',
                ),
              ),
            );
          }
        }
      }
      await _api.put('/permissions', {
        'capability': cap.key,
        'granted': value,
      });
    } catch (e) {
      _granted[cap.key] = !value;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _pending.remove(cap.key));
      }
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.groupedBackground,
      appBar: AppBar(
        title: const Text('Uprawnienia'),
        backgroundColor: SerenityColors.groupedBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(SerenitySpacing.xl),
                    children: [
                      Text('Błąd: $_error', style: SerenityText.bodyMain),
                      const SizedBox(height: SerenitySpacing.md),
                      FilledButton(
                        onPressed: _refresh,
                        child: const Text('Spróbuj ponownie'),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'Zarządzaj uprawnieniami aplikacji. Wyłączenie tutaj nie usuwa zgody systemowej — musisz to zrobić w ustawieniach Androida.',
                          style: SerenityText.iosSubhead,
                        ),
                      ),
                      for (final cap in _kCapabilities)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: SerenitySpacing.sm,
                          ),
                          child: _CapabilityCard(
                            cap: cap,
                            userGranted: _granted[cap.key] ?? false,
                            systemStatus: _systemStatus[cap.key] ??
                                PermissionStatus.denied,
                            pending: _pending.contains(cap.key),
                            onChanged: (v) => _toggle(cap, v),
                            onOpenSettings: _openSettings,
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  final _Capability cap;
  final bool userGranted;
  final PermissionStatus systemStatus;
  final bool pending;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenSettings;

  const _CapabilityCard({
    required this.cap,
    required this.userGranted,
    required this.systemStatus,
    required this.pending,
    required this.onChanged,
    required this.onOpenSettings,
  });

  ({String label, Color color}) _systemBadge() {
    if (cap.permission == Permission.unknown) {
      return (label: 'systemowe niepotrzebne', color: SerenityColors.onSurfaceVariant);
    }
    if (systemStatus.isGranted) {
      return (label: 'system: zezwolono', color: SerenityColors.tertiary);
    }
    if (systemStatus.isPermanentlyDenied) {
      return (label: 'system: zablokowane', color: SerenityColors.error);
    }
    if (systemStatus.isDenied) {
      return (label: 'system: brak zgody', color: SerenityColors.tertiaryFixedDim);
    }
    return (label: 'system: ${systemStatus.name}', color: SerenityColors.onSurfaceVariant);
  }

  @override
  Widget build(BuildContext context) {
    final badge = _systemBadge();
    return Container(
      padding: const EdgeInsets.all(SerenitySpacing.md),
      decoration: BoxDecoration(
        color: SerenityColors.groupedSurface,
        borderRadius: BorderRadius.circular(SerenityShapes.iosInline),
        boxShadow: SerenityElevation.ios(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SerenityColors.primaryContainer.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(SerenityShapes.radiusLg),
                ),
                child: Icon(cap.icon, color: SerenityColors.primary, size: 24),
              ),
              const SizedBox(width: SerenitySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cap.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: SerenityColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: badge.color,
                      ),
                    ),
                  ],
                ),
              ),
              pending
                  ? const SizedBox(
                      width: 32,
                      height: 32,
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Switch.adaptive(
                      value: userGranted,
                      onChanged: onChanged,
                    ),
            ],
          ),
          const SizedBox(height: SerenitySpacing.sm),
          Text(cap.description, style: SerenityText.bodyMain),
          if (systemStatus.isPermanentlyDenied) ...[
            const SizedBox(height: SerenitySpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Otwórz ustawienia systemu'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

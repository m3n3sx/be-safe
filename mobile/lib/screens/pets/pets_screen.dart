import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class PetsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const PetsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  List<Map<String, dynamic>> _pets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await context.read<ApiService>().get('/pets/mine');
      final all = (res['pets'] as List?) ?? const [];
      final filtered = all
          .cast<Map<String, dynamic>>()
          .where((p) => p['group_id'] == widget.groupId)
          .toList();
      if (!mounted) return;
      setState(() {
        _pets = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Nie udało się załadować zwierzaków.';
        _loading = false;
      });
    }
  }

  Future<void> _addPet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddPetSheet(groupId: widget.groupId),
    );
    if (added == true) await _load();
  }

  Future<void> _markLost(Map<String, dynamic> pet) async {
    final descCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl)),
        title: const Text('Zaginął zwierzak?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Powiadomimy całą rodzinę oraz osoby w okolicy 3 km, że ${pet['name']} został(a) zaginął(a).',
              style: SerenityText.bodyMain,
            ),
            const SizedBox(height: SerenitySpacing.md),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              maxLength: 280,
              decoration: const InputDecoration(
                labelText: 'Opis (opcjonalnie)',
                hintText: 'np. Wybiegł z ogródka około 17:00',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SerenityColors.glowAlertCoral,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Wszczyj alarm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    HapticFeedback.heavyImpact();

    double? lat;
    double? lng;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 6));
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {
      lat = (pet['home_lat'] as num?)?.toDouble() ??
          (pet['last_seen_lat'] as num?)?.toDouble();
      lng = (pet['home_lng'] as num?)?.toDouble() ??
          (pet['last_seen_lng'] as num?)?.toDouble();
    }
    if (lat == null || lng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Brak lokalizacji. Włącz GPS i spróbuj ponownie.'),
      ));
      return;
    }

    try {
      await context.read<ApiService>().post('/pets/${pet['id']}/lost', {
        'lat': lat,
        'lng': lng,
        if (descCtrl.text.trim().isNotEmpty)
          'description': descCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: SerenityColors.glowAlertCoral,
        content: Text('🚨 Alarm wysłany — szukamy ${pet['name']}'),
      ));
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nie udało się wysłać alarmu. Spróbuj ponownie.'),
      ));
    }
  }

  Future<void> _markFound(Map<String, dynamic> pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl)),
        title: Text('${pet['name']} znaleziony(a)?'),
        content: const Text(
          'Powiadomimy rodzinę, że zwierzak jest bezpieczny i odwołamy alarm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Jeszcze nie'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SerenityColors.secondaryContainer,
              foregroundColor: SerenityColors.onSecondaryContainer,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tak, znaleziony'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    HapticFeedback.mediumImpact();
    try {
      await context.read<ApiService>().post('/pets/${pet['id']}/found', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: SerenityColors.secondaryContainer,
        content: Text(
          '✓ ${pet['name']} jest bezpieczny — alarm odwołany',
          style: const TextStyle(color: SerenityColors.onSecondaryContainer),
        ),
      ));
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nie udało się odwołać alarmu.'),
      ));
    }
  }

  Future<void> _deletePet(Map<String, dynamic> pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl)),
        title: Text('Usunąć ${pet['name']}?'),
        content: const Text('Tej operacji nie da się cofnąć.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              foregroundColor: SerenityColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await context.read<ApiService>().delete('/pets/${pet['id']}');
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nie udało się usunąć zwierzaka.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.iosBackground,
      appBar: AppBar(
        backgroundColor: context.iosBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Wróć',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.groupName,
                style: SerenityText.labelCaps.copyWith(
                  color: context.iosSecondaryLabel,
                  letterSpacing: 1.2,
                )),
            const Text('Zwierzaki',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPet,
        backgroundColor: SerenityColors.primaryContainer,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj zwierzaka'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(SerenitySpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: SerenityColors.error),
              const SizedBox(height: SerenitySpacing.md),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: SerenitySpacing.md),
              FilledButton(onPressed: _load, child: const Text('Spróbuj ponownie')),
            ],
          ),
        ),
      );
    }
    if (_pets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(SerenitySpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: SerenityColors.secondaryContainer.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets,
                    size: 48,
                    color: SerenityColors.onSecondaryContainer),
              ),
              const SizedBox(height: SerenitySpacing.lg),
              Text('Brak zwierzaków',
                  style: SerenityText.headlineHeroMobile
                      .copyWith(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: SerenitySpacing.xs),
              Text(
                'Dodaj psa, kota lub innego zwierzaka,\naby wszcząć alarm gdy zaginie.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.iosSecondaryLabel, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final myId = context.read<AuthProvider>().user?.id;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _pets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _petTile(_pets[i], myId),
      ),
    );
  }

  String _speciesEmoji(String? species) {
    switch (species) {
      case 'dog':
        return '🐕';
      case 'cat':
        return '🐱';
      case 'bird':
        return '🐦';
      case 'rabbit':
        return '🐰';
      default:
        return '🐾';
    }
  }

  Widget _petTile(Map<String, dynamic> pet, String? myId) {
    final isLost = pet['status'] == 'lost';
    final isOwner = pet['owner_id'] == myId;
    final breed = (pet['breed'] as String?)?.trim();
    final color = (pet['color'] as String?)?.trim();
    final age = pet['age_years'] as int?;
    final ownerName = pet['owner_username'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: context.iosCardSurface,
        borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        border: isLost
            ? Border.all(color: SerenityColors.glowAlertCoral, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(SerenitySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color:
                        SerenityColors.secondaryContainer.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(_speciesEmoji(pet['species']),
                      style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: SerenitySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet['name'] ?? '—',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      _statusChip(isLost),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: context.iosSecondaryLabel),
                    tooltip: 'Usuń',
                    onPressed: () => _deletePet(pet),
                  ),
              ],
            ),
            if (breed != null && breed.isNotEmpty ||
                color != null && color.isNotEmpty ||
                age != null) ...[
              const SizedBox(height: SerenitySpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (breed != null && breed.isNotEmpty)
                    _metaChip(Icons.pets, breed),
                  if (color != null && color.isNotEmpty)
                    _metaChip(Icons.palette_outlined, color),
                  if (age != null) _metaChip(Icons.cake_outlined, '$age lat'),
                  if (ownerName != null)
                    _metaChip(Icons.person_outline, ownerName),
                ],
              ),
            ],
            if (isLost && pet['lost_description'] != null) ...[
              const SizedBox(height: SerenitySpacing.sm),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SerenityColors.glowAlertCoral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(pet['lost_description'].toString(),
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
            const SizedBox(height: SerenitySpacing.md),
            SizedBox(
              width: double.infinity,
              child: isLost
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: SerenityColors.secondaryContainer,
                        foregroundColor: SerenityColors.onSecondaryContainer,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('ZNALEZIONO!'),
                      onPressed: () => _markFound(pet),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: SerenityColors.glowAlertCoral,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('ZAGUBIONY!'),
                      onPressed: () => _markLost(pet),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(bool isLost) {
    final bg = isLost
        ? SerenityColors.glowAlertCoral
        : SerenityColors.secondaryContainer;
    final fg = isLost ? Colors.white : SerenityColors.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isLost ? '🚨 ZAGUBIONY' : 'BEZPIECZNY',
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SerenityColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.iosSecondaryLabel),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AddPetSheet extends StatefulWidget {
  final String groupId;
  const _AddPetSheet({required this.groupId});

  @override
  State<_AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<_AddPetSheet> {
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _species = 'dog';
  double _age = 3;
  bool _setHome = false;
  double? _homeLat;
  double? _homeLng;
  bool _settingHome = false;
  bool _submitting = false;

  static const _speciesOptions = [
    ('dog', 'Pies', '🐕'),
    ('cat', 'Kot', '🐱'),
    ('bird', 'Ptak', '🐦'),
    ('rabbit', 'Królik', '🐰'),
    ('other', 'Inny', '🐾'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _colorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _settingHome = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 6));
      if (!mounted) return;
      setState(() {
        _homeLat = pos.latitude;
        _homeLng = pos.longitude;
        _setHome = true;
        _settingHome = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _settingHome = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nie udało się pobrać lokalizacji.'),
      ));
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Wpisz imię zwierzaka.'),
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<ApiService>().post('/pets', {
        'group_id': widget.groupId,
        'name': name,
        'species': _species,
        if (_breedCtrl.text.trim().isNotEmpty) 'breed': _breedCtrl.text.trim(),
        if (_colorCtrl.text.trim().isNotEmpty) 'color': _colorCtrl.text.trim(),
        'age_years': _age.round(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
        if (_setHome && _homeLat != null && _homeLng != null) ...{
          'home_lat': _homeLat,
          'home_lng': _homeLng,
        },
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nie udało się dodać zwierzaka.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: padding),
      decoration: BoxDecoration(
        color: context.iosCardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SerenitySpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.iosSeparator,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: SerenitySpacing.md),
              const Text('Nowy zwierzak',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: SerenitySpacing.lg),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Imię *',
                  hintText: 'np. Reksio, Mruczek',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: SerenitySpacing.md),
              Text('Gatunek',
                  style: SerenityText.labelCaps
                      .copyWith(color: context.iosSecondaryLabel)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _speciesOptions.map((opt) {
                  final selected = _species == opt.$1;
                  return ChoiceChip(
                    label: Text('${opt.$3}  ${opt.$2}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _species = opt.$1),
                    selectedColor: SerenityColors.secondaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: SerenitySpacing.md),
              TextField(
                controller: _breedCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rasa (opcjonalnie)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: SerenitySpacing.md),
              TextField(
                controller: _colorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kolor / cechy (opcjonalnie)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: SerenitySpacing.md),
              Text('Wiek: ${_age.round()} lat',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: _age,
                min: 0,
                max: 30,
                divisions: 30,
                label: '${_age.round()}',
                onChanged: (v) => setState(() => _age = v),
              ),
              const SizedBox(height: SerenitySpacing.sm),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Notatki (opcjonalnie)',
                  hintText: 'np. Łagodny, reaguje na imię',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: SerenitySpacing.sm),
              OutlinedButton.icon(
                onPressed: _settingHome ? null : _useMyLocation,
                icon: _settingHome
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_setHome ? Icons.check_circle : Icons.home_outlined),
                label: Text(_setHome
                    ? 'Lokalizacja domu ustawiona'
                    : 'Ustaw dom (moja lokalizacja)'),
              ),
              const SizedBox(height: SerenitySpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: SerenityColors.primaryContainer,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Zapisz zwierzaka',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

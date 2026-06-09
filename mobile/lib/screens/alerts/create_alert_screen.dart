/// be:Safe v2 — Create Alert Screen (Serenity Guard)
///
/// Form: location map + category chips + title + description + photo + duration.
/// Minimal chrome, soft input fills, navy primary pill CTA.
///
/// Design source: design/stitch_v2/screens/zg_o_zagro_enie_nowy_alert/
library;

import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/map_style.dart';
import '../../theme/ios_surfaces.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/alert.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class CreateAlertScreen extends StatefulWidget {
  final LatLng position;
  final AlertCategory? presetCategory;
  final String? presetTitle;
  const CreateAlertScreen({
    super.key,
    required this.position,
    this.presetCategory,
    this.presetTitle,
  });

  @override
  State<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends State<CreateAlertScreen> {
  AlertCategory? _category;
  final _title = TextEditingController();
  final _desc = TextEditingController();
  int _durationHours = 3;
  late LatLng _selectedPos;
  XFile? _photo;
  bool _submitting = false;
  bool _isAnonymous = false; // F17: Anonimowe zgłoszenia

  @override
  void initState() {
    super.initState();
    _selectedPos = widget.position;
    _category = widget.presetCategory;
    if (widget.presetTitle != null) _title.text = widget.presetTitle!;
    // Odświeżaj button gdy user wpisuje tytuł / opis (potrzebne do walidacji
    // _enabled w submit-button).
    _title.addListener(_onFormChanged);
    _desc.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _title.removeListener(_onFormChanged);
    _desc.removeListener(_onFormChanged);
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _submit() async {
    if (_category == null || _title.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz kategorię i wpisz tytuł')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<ApiService>().multipart('/alerts', {
        'category': _category!.apiValue,
        'title': _title.text,
        if (_desc.text.isNotEmpty) 'description': _desc.text,
        'lat': _selectedPos.latitude.toString(),
        'lng': _selectedPos.longitude.toString(),
        'duration_hours': _durationHours.toString(),
        if (_isAnonymous) 'is_anonymous': 'true',
      }, filePath: _photo?.path);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool get _hasUnsavedChanges =>
      _category != null ||
      _title.text.isNotEmpty ||
      _desc.text.isNotEmpty ||
      _photo != null;

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges || _submitting) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Porzucić zgłoszenie?'),
        content: const Text(
          'Wpisane dane (kategoria, tytuł, opis, zdjęcie) zostaną utracone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Wróć do edycji'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: SerenityColors.error),
            child: const Text('Porzuć'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges || _submitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted) Navigator.pop(context);
      },
      child: Scaffold(
      backgroundColor: context.iosBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: SerenitySpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel('LOKALIZACJA ZAGROŻENIA'),
                    const SizedBox(height: 8),
                    Text(
                      'Dotknij mapy by wskazać dokładne miejsce',
                      style: SerenityText.bodyMain.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: SerenitySpacing.md),
                    _buildMap(),
                    const SizedBox(height: 8),
                    Text(
                      '📍 ${_selectedPos.latitude.toStringAsFixed(5)}, ${_selectedPos.longitude.toStringAsFixed(5)}',
                      style: SerenityText.labelCaps.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: SerenitySpacing.xl),
                    _sectionLabel('KATEGORIA'),
                    const SizedBox(height: SerenitySpacing.sm),
                    _buildCategoryChips(),
                    const SizedBox(height: SerenitySpacing.xl),
                    _sectionLabel('OPIS'),
                    const SizedBox(height: SerenitySpacing.sm),
                    _buildTextField(_title, 'Tytuł zagrożenia'),
                    const SizedBox(height: 12),
                    _buildTextField(_desc, 'Opis (opcjonalnie)', maxLines: 3),
                    const SizedBox(height: SerenitySpacing.xl),
                    _sectionLabel('ZDJĘCIE (OPCJONALNE)'),
                    const SizedBox(height: SerenitySpacing.sm),
                    _buildPhotoSection(),
                    const SizedBox(height: SerenitySpacing.xl),
                    _sectionLabel('CZAS WAŻNOŚCI'),
                    const SizedBox(height: SerenitySpacing.sm),
                    _buildDurationChips(),
                    const SizedBox(height: SerenitySpacing.xl),
                    _buildAnonymousToggle(),
                    const SizedBox(height: SerenitySpacing.xxxl),
                    _buildSubmitButton(),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16,
                    ),
                   ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SerenitySpacing.md,
        vertical: SerenitySpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Zamknij',
            icon: const Icon(Icons.close, size: 28),
            color: context.iosLabel,
            onPressed: () async {
              final ok = await _confirmDiscard();
              if (ok && mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          Text(
            'Zgłoś zagrożenie',
            style: SerenityText.headlineHeroMobile,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: SerenityText.labelCaps,
    );
  }

  Widget _buildMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            GoogleMap(
              style: Theme.of(context).brightness == Brightness.dark ? kDarkMapStyle : null,
              initialCameraPosition: CameraPosition(
                target: _selectedPos,
                zoom: 16,
              ),
              onTap: (pos) => setState(() => _selectedPos = pos),
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selectedPos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: SerenityColors.primaryContainer,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () =>
                      setState(() => _selectedPos = widget.position),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.my_location,
                      size: 20,
                      color: SerenityColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    // Cat10: group 18 categories into 4 sections for easier scanning
    final groups = <String, List<AlertCategory>>{
      'Pilne': [
        AlertCategory.aggression,
        AlertCategory.theft,
        AlertCategory.fire,
        AlertCategory.accident,
        AlertCategory.police,
        AlertCategory.strangerDanger,
      ],
      'Drogowe': [
        AlertCategory.ice,
        AlertCategory.construction,
        AlertCategory.trafficDanger,
        AlertCategory.weather,
      ],
      'Dla dzieci': [
        AlertCategory.playgroundHazard,
        AlertCategory.waterHazard,
        AlertCategory.schoolZone,
      ],
      'Infrastruktura miejska': [
        AlertCategory.pothole,
        AlertCategory.darkPassage,
        AlertCategory.brokenLights,
      ],
      'Inne': [
        AlertCategory.flood,
        AlertCategory.animal,
        AlertCategory.darkArea,
        AlertCategory.drugs,
        AlertCategory.other,
      ],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Text(
                  entry.key.toUpperCase(),
                  style: SerenityText.labelCaps.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: context.iosSecondaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((c) => _categoryChip(c)).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _categoryChip(AlertCategory c) {
    final selected = _category == c;
    return Material(
      color: selected
          ? SerenityColors.primaryContainer
          : context.iosCardSurface,
      borderRadius: SerenityShapes.pill(),
      child: InkWell(
        borderRadius: SerenityShapes.pill(),
        onTap: () => setState(() => _category = c),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: SerenityShapes.pill(),
            boxShadow: selected ? null : SerenityElevation.card(),
          ),
          child: Text(
            '${c.emoji} ${c.label}',
            style: SerenityText.labelButton.copyWith(
              fontSize: 13,
              color: selected
                  ? SerenityColors.onPrimary
                  : context.iosLabel,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: SerenityText.bodyMain.copyWith(color: context.iosLabel),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: SerenityText.bodyMain.copyWith(
          color: context.iosSecondaryLabel,
        ),
        filled: true,
        fillColor: SerenityColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: SerenityShapes.input(),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SerenityShapes.input(),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SerenityShapes.input(),
          borderSide: BorderSide(
            color: context.iosLabel,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    if (_photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
            child: Image.file(
              File(_photo!.path),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: context.iosLabel.withValues(alpha: 0.6),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _photo = null),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    color: SerenityColors.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: _photoActionButton(
            icon: Icons.camera_alt_outlined,
            label: 'Aparat',
            onTap: () => _pickPhoto(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _photoActionButton(
            icon: Icons.photo_library_outlined,
            label: 'Galeria',
            onTap: () => _pickPhoto(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _photoActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: SerenityShapes.pill(),
      child: InkWell(
        borderRadius: SerenityShapes.pill(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: SerenityShapes.pill(),
            border: Border.all(
              color: context.iosLabel.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: context.iosLabel),
              const SizedBox(width: 8),
              Text(
                label,
                style: SerenityText.labelButton.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChips() {
    const options = [1, 3, 6, 12, 24];
    return Wrap(
      spacing: 8,
      children: options.map((h) {
        final selected = _durationHours == h;
        return ChoiceChip(
          label: Text('$h h'),
          selected: selected,
          onSelected: (_) => setState(() => _durationHours = h),
          labelStyle: SerenityText.labelButton.copyWith(
            fontSize: 13,
            color: selected
                ? SerenityColors.onPrimary
                : context.iosLabel,
          ),
          backgroundColor: context.iosCardSurface,
          selectedColor: SerenityColors.primaryContainer,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: SerenityShapes.pill(),
          ),
        );
      }).toList(),
    );
  }

  // F17: Anonimowe zgłoszenia - toggle
  Widget _buildAnonymousToggle() {
    return Container(
      decoration: BoxDecoration(
        color: context.iosCardSurface,
        borderRadius: BorderRadius.circular(SerenityShapes.radiusLg),
        border: Border.all(
          color: _isAnonymous
              ? SerenityColors.primaryContainer.withValues(alpha: 0.6)
              : context.iosSeparator,
          width: _isAnonymous ? 1.5 : 1.0,
        ),
      ),
      child: SwitchListTile(
        value: _isAnonymous,
        onChanged: _submitting ? null : (v) => setState(() => _isAnonymous = v),
        secondary: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _isAnonymous
                ? SerenityColors.primaryContainer.withValues(alpha: 0.1)
                : SerenityColors.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isAnonymous ? Icons.visibility_off : Icons.person_outline,
            color: _isAnonymous
                ? SerenityColors.primaryContainer
                : SerenityColors.onSurfaceVariant,
            size: 22,
          ),
        ),
        title: const Text(
          'Zgłoszenie anonimowe',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _isAnonymous
              ? 'Twoja nazwa NIE będzie widoczna dla innych'
              : 'Inni zobaczą Twój nick przy alercie',
          style: TextStyle(
            fontSize: 12,
            color: context.iosSecondaryLabel,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final enabled = !_submitting && _category != null && _title.text.isNotEmpty;
    final String? hint = enabled
        ? null
        : _category == null && _title.text.isEmpty
              ? 'Wybierz kategorię i wpisz tytuł aby zgłosić'
              : _category == null
              ? 'Wybierz kategorię zagrożenia'
              : _title.text.isEmpty
              ? 'Wpisz krótki tytuł zagrożenia'
              : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: enabled
              ? SerenityColors.primaryContainer
              : SerenityColors.surfaceContainerHigh,
          borderRadius: SerenityShapes.pill(),
          child: InkWell(
            borderRadius: SerenityShapes.pill(),
            onTap: enabled ? _submit : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            SerenityColors.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'Zgłoś zagrożenie',
                        style: SerenityText.labelButton.copyWith(
                          fontSize: 16,
                          color: enabled
                              ? SerenityColors.onPrimary
                              : SerenityColors.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              hint,
              style: SerenityText.bodyMain.copyWith(
                fontSize: 12,
                color: context.iosSecondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

/// be:Safe v2 — Create Alert Screen (Serenity Guard)
///
/// Form: location map + category chips + title + description + photo + duration.
/// Minimal chrome, soft input fills, navy primary pill CTA.
///
/// Design source: design/stitch_v2/screens/zg_o_zagro_enie_nowy_alert/
library;

import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedPos = widget.position;
    _category = widget.presetCategory;
    if (widget.presetTitle != null) _title.text = widget.presetTitle!;
  }

  @override
  void dispose() {
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
      }, filePath: _photo?.path);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
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
            icon: const Icon(Icons.close, size: 28),
            color: SerenityColors.primary,
            onPressed: () => Navigator.pop(context),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AlertCategory.values.map((c) {
        final selected = _category == c;
        return Material(
          color: selected
              ? SerenityColors.primaryContainer
              : SerenityColors.surfaceContainerLowest,
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
                      : SerenityColors.primary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
      style: SerenityText.bodyMain.copyWith(color: SerenityColors.primary),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: SerenityText.bodyMain.copyWith(
          color: SerenityColors.onSurfaceVariant,
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
            color: SerenityColors.primary,
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
              color: SerenityColors.primary.withValues(alpha: 0.6),
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
              color: SerenityColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: SerenityColors.primary),
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
                : SerenityColors.primary,
          ),
          backgroundColor: SerenityColors.surfaceContainerLowest,
          selectedColor: SerenityColors.primaryContainer,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: SerenityShapes.pill(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    final enabled = !_submitting && _category != null && _title.text.isNotEmpty;
    return Material(
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
    );
  }
}

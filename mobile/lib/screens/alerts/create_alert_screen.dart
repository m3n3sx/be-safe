import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/alert.dart';
import '../../services/api_service.dart';
import '../../services/i18n.dart';

class CreateAlertScreen extends StatefulWidget {
  final LatLng position;
  final AlertCategory? presetCategory;
  final String? presetTitle;
  const CreateAlertScreen({super.key, required this.position, this.presetCategory, this.presetTitle});
  @override State<CreateAlertScreen> createState() => _CreateAlertScreenState();
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

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 80);
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _pickGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _submit() async {
    if (_category == null || _title.text.isEmpty) return;
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
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(S.get('report_threat'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(S.get('location_of_threat'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(S.get('tap_map'), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(height: 200, child: Stack(children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _selectedPos, zoom: 16),
            onTap: (pos) => setState(() => _selectedPos = pos),
            markers: {Marker(markerId: const MarkerId('selected'), position: _selectedPos, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))},
            myLocationEnabled: true, myLocationButtonEnabled: false, zoomControlsEnabled: false, mapToolbarEnabled: false,
            liteModeEnabled: false,
          ),
          Positioned(right: 8, bottom: 8, child: Container(
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E2C) : Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)]),
            child: IconButton(icon: const Icon(Icons.my_location, size: 20), onPressed: () => setState(() => _selectedPos = widget.position)))),
        ]))),
        Padding(padding: const EdgeInsets.only(top: 4), child: Text(
          '📍 ${_selectedPos.latitude.toStringAsFixed(5)}, ${_selectedPos.longitude.toStringAsFixed(5)}'
          '${_selectedPos == widget.position ? '  (${S.get('my_location')})' : '  (${S.get('pointed_place')})'}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500))),
        const SizedBox(height: 20),
        Text(S.get('category'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: AlertCategory.values.map((c) =>
          ChoiceChip(label: Text('${c.emoji} ${c.label}'), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
        ).toList()),
        const SizedBox(height: 16),
        TextField(controller: _title, decoration: InputDecoration(labelText: S.get('title'), border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _desc, decoration: InputDecoration(labelText: S.get('description_optional'), border: const OutlineInputBorder()), maxLines: 3),
        const SizedBox(height: 16),
        Text(S.get('photo_optional'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_photo != null) Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_photo!.path), height: 160, width: double.infinity, fit: BoxFit.cover)),
          Positioned(top: 4, right: 4, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.black54), onPressed: () => setState(() => _photo = null))),
        ]),
        if (_photo == null) Row(children: [
          OutlinedButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.camera_alt), label: Text(S.get('camera'))),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: _pickGallery, icon: const Icon(Icons.photo_library), label: Text(S.get('gallery'))),
        ]),
        const SizedBox(height: 16),
        Text(S.get('duration'), style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<int>(value: _durationHours, isExpanded: true,
          items: [1, 3, 6, 12, 24].map((h) => DropdownMenuItem(value: h, child: Text('$h ${S.get('hours')}'))).toList(),
          onChanged: (v) => setState(() => _durationHours = v!)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.red.shade700),
          child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(S.get('submit'), style: const TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ]),
    );
  }
}

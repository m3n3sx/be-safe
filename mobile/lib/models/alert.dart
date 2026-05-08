import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum AlertCategory {
  aggression, theft, accident, fire, flood, ice, construction,
  animal, darkArea, drugs, police, weather, other,
  strangerDanger, trafficDanger, playgroundHazard, waterHazard, schoolZone;

  String get label => switch (this) {
    aggression => 'Agresywne osoby',
    theft => 'Kradzież / rozbój',
    accident => 'Wypadek',
    fire => 'Pożar',
    flood => 'Powódź',
    ice => 'Oblodzenie',
    construction => 'Niebezpieczna budowa',
    animal => 'Niebezpieczne zwierzę',
    darkArea => 'Nieoświetlony teren',
    drugs => 'Narkotyki',
    police => 'Akcja policyjna',
    weather => 'Zagrożenie pogodowe',
    other => 'Inne',
    strangerDanger => 'Podejrzana osoba',
    trafficDanger => 'Niebezpieczne przejście',
    playgroundHazard => 'Uszkodzony plac zabaw',
    waterHazard => 'Zbiornik wodny',
    schoolZone => 'Strefa szkolna',
  };

  IconData get iconData => switch (this) {
    aggression => Icons.person_off,
    theft => Icons.front_hand,
    accident => Icons.car_crash,
    fire => Icons.local_fire_department,
    flood => Icons.waves,
    ice => Icons.severe_cold,
    construction => Icons.construction,
    animal => Icons.pets,
    darkArea => Icons.dark_mode,
    drugs => Icons.vaccines,
    police => Icons.shield,
    weather => Icons.bolt,
    other => Icons.priority_high,
    strangerDanger => Icons.person_search,
    trafficDanger => Icons.do_not_step,
    playgroundHazard => Icons.child_care,
    waterHazard => Icons.water_drop,
    schoolZone => Icons.directions_run,
  };

  Color get color => switch (this) {
    aggression => const Color(0xFFFF1744),
    theft => const Color(0xFFFF1744),
    accident => const Color(0xFFFF6D00),
    fire => const Color(0xFFFF3D00),
    flood => const Color(0xFF2979FF),
    ice => const Color(0xFF00B0FF),
    construction => const Color(0xFFFFAB00),
    animal => const Color(0xFFFF6D00),
    darkArea => const Color(0xFF78909C),
    drugs => const Color(0xFFAA00FF),
    police => const Color(0xFF2979FF),
    weather => const Color(0xFF1565C0),
    other => const Color(0xFFFFAB00),
    strangerDanger => const Color(0xFFFF1744),
    trafficDanger => const Color(0xFFFF6D00),
    playgroundHazard => const Color(0xFFFFAB00),
    waterHazard => const Color(0xFF2979FF),
    schoolZone => const Color(0xFFFF6D00),
  };

  // Zachowuję emoji dla kompatybilności (chip labels w filtrach)
  String get emoji => switch (this) {
    aggression => '🤬', theft => '🔪', accident => '💥', fire => '🔥',
    flood => '🌊', ice => '❄️', construction => '⛏️', animal => '🐺',
    darkArea => '🌑', drugs => '💉', police => '🚨', weather => '⛈️',
    other => '⚠️', strangerDanger => '😈', trafficDanger => '☠️',
    playgroundHazard => '⛔', waterHazard => '🌀', schoolZone => '🚸',
  };

  String get apiValue => name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
}

class AlertModel {
  final String id;
  final String authorId;
  final AlertCategory category;
  final String title;
  final String? description;
  final String? photoUrl;
  final LatLng location;
  final int radiusM;
  final int confirms;
  final int denies;
  final double? distanceM;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String authorUsername;
  final int authorReputation;
  final bool authorVerified;
  final String? authorRole;
  final String? authorAvatarUrl;

  AlertModel({
    required this.id, this.authorId = '', required this.category, required this.title,
    this.description, this.photoUrl, required this.location, this.radiusM = 100,
    this.confirms = 0, this.denies = 0, this.distanceM,
    required this.expiresAt, required this.createdAt, required this.authorUsername,
    this.authorReputation = 100, this.authorVerified = false, this.authorRole, this.authorAvatarUrl,
  });

  factory AlertModel.fromJson(Map<String, dynamic> j) => AlertModel(
    id: j['id'],
    authorId: j['author_id'] ?? '',
    category: AlertCategory.values.firstWhere(
      (c) => c.apiValue == j['category'], orElse: () => AlertCategory.other,
    ),
    title: j['title'],
    description: j['description'],
    photoUrl: j['photo_url'],
    location: LatLng(
      double.parse(j['lat']?.toString() ?? '0'),
      double.parse(j['lng']?.toString() ?? '0'),
    ),
    radiusM: j['radius_m'] ?? 100,
    confirms: j['confirms'] ?? 0,
    denies: j['denies'] ?? 0,
    distanceM: (j['distance_m'] as num?)?.toDouble(),
    expiresAt: DateTime.parse(j['expires_at']),
    createdAt: DateTime.parse(j['created_at']),
    authorUsername: j['author']?['username'] ?? j['author_username'] ?? 'Anonim',
    authorReputation: (j['author']?['reputation_score'] as num?)?.toInt() ?? 100,
    authorVerified: j['author']?['is_verified'] == true,
    authorRole: j['author']?['verified_role'] as String?,
    authorAvatarUrl: j['author']?['avatar_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'author_id': authorId, 'category': category.apiValue,
    'title': title, 'description': description, 'photo_url': photoUrl,
    'lat': location.latitude, 'lng': location.longitude,
    'radius_m': radiusM, 'confirms': confirms, 'denies': denies,
    'expires_at': expiresAt.toIso8601String(), 'created_at': createdAt.toIso8601String(),
    'author': {'username': authorUsername},
  };
}

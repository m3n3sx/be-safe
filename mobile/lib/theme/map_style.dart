/// Wspólny styl ciemnej mapy Google (night mode) dla trybu ciemnego apki.
/// Użycie: GoogleMap(style: isDark ? kDarkMapStyle : null, ...)
/// Spójny z ekranami rodziny (add_geofence/family_group/location_history).
library;

const String kDarkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#232a32"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9ea1a8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a2027"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c343d"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ea1a8"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17202a"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283039"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1f2a24"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2c343d"}]}
]
''';

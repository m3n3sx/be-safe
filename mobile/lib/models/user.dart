class User {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final int alertRadiusM;
  final int reputationScore;
  final bool isChild;

  User({required this.id, required this.email, required this.username, this.avatarUrl, this.alertRadiusM = 500, this.reputationScore = 100, this.isChild = false});

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'], email: j['email'], username: j['username'],
    avatarUrl: j['avatar_url'], alertRadiusM: j['alert_radius_m'] ?? 500,
    reputationScore: j['reputation_score'] ?? 100, isChild: j['is_child'] ?? false,
  );
}

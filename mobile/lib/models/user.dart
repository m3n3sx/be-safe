enum AppMode { kids, senior, normal }

extension AppModeX on AppMode {
  String get apiValue => switch (this) {
        AppMode.kids => 'kids',
        AppMode.senior => 'senior',
        AppMode.normal => 'normal',
      };

  String get label => switch (this) {
        AppMode.kids => 'Dla dziecka',
        AppMode.senior => 'Dla seniora',
        AppMode.normal => 'Standardowy',
      };

  static AppMode fromString(String? s) => switch (s) {
        'kids' => AppMode.kids,
        'senior' => AppMode.senior,
        _ => AppMode.normal,
      };
}

class User {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final int alertRadiusM;
  final int reputationScore;
  final bool isChild;
  final String? phone;
  final AppMode appMode;
  final bool isKpp;
  final String? kppCertificate;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.alertRadiusM = 500,
    this.reputationScore = 100,
    this.isChild = false,
    this.phone,
    this.appMode = AppMode.normal,
    this.isKpp = false,
    this.kppCertificate,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'],
        email: j['email'],
        username: j['username'] ?? '',
        avatarUrl: j['avatar_url'],
        alertRadiusM: j['alert_radius_m'] ?? 500,
        reputationScore: j['reputation_score'] ?? 100,
        isChild: j['is_child'] ?? false,
        phone: j['phone'] as String?,
        appMode: AppModeX.fromString(j['app_mode'] as String?),
        isKpp: j['is_kpp'] ?? false,
        kppCertificate: j['kpp_certificate'] as String?,
      );

  User copyWith({
    AppMode? appMode,
    String? phone,
    String? username,
    String? avatarUrl,
    int? alertRadiusM,
    bool? isKpp,
    String? kppCertificate,
  }) =>
      User(
        id: id,
        email: email,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        alertRadiusM: alertRadiusM ?? this.alertRadiusM,
        reputationScore: reputationScore,
        isChild: isChild,
        phone: phone ?? this.phone,
        appMode: appMode ?? this.appMode,
        isKpp: isKpp ?? this.isKpp,
        kppCertificate: kppCertificate ?? this.kppCertificate,
      );
}

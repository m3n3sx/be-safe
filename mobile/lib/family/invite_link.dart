final _code = RegExp(r'^[A-F0-9]{8}$');

String? parseInvite(String? input) {
  if (input == null) return null;
  final raw = input.trim();
  if (raw.isEmpty) return null;
  final direct = raw.toUpperCase();
  if (!raw.contains('://') && !raw.contains('/') && _code.hasMatch(direct)) return direct;
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  String? code;
  if (uri.scheme == 'besafe' && uri.host == 'family') {
    if (uri.pathSegments.isEmpty || uri.pathSegments.first != 'join') return null;
    code = uri.pathSegments.length > 1 ? uri.pathSegments[1] : uri.queryParameters['code'];
  } else if (uri.scheme == 'https' && uri.host == 'besafe.org.pl') {
    if (uri.pathSegments.length < 2 || uri.pathSegments[0] != 'family' || uri.pathSegments[1] != 'join') {
      return null;
    }
    code = uri.pathSegments.length > 2 ? uri.pathSegments[2] : uri.queryParameters['code'];
  } else {
    return null;
  }
  if (code == null) return null;
  code = code.toUpperCase();
  return _code.hasMatch(code) ? code : null;
}

const joinRoles = ['child', 'senior', 'family_member', 'partner', 'friend', 'other'];

bool canSelfJoinAs(String? role) => role == null || joinRoles.contains(role);

/// Models for the sign-in flow: `POST /api/v1/auth/authenticate`,
/// `POST /api/v1/auth/validateOtp` and `POST /api/v1/user/logout`.
///
/// The API answers with a `responseCode` of `SUCCESS` or `FAIL` plus a
/// `responseMessage` meant for people, so screens can show it as it is.

/// The raw `responseCode` as text. An enum can reach us as "SUCCESS", "00", a
/// number, or an object such as {"name": "SUCCESS", "code": "00"}.
String _codeText(dynamic code) {
  if (code is Map) {
    for (final k in const ['name', 'code', 'value', 'status']) {
      final v = code[k];
      if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
    }
    return '';
  }
  return code == null ? '' : '$code'.trim();
}

const _successCodes = {'SUCCESS', 'SUCCESSFUL', 'OK', '00', '0', '000', '200'};
const _failureCodes = {'FAIL', 'FAILED', 'FAILURE', 'ERROR', 'DENIED', '01', '1', '99'};

bool _isSuccess(dynamic code) {
  final c = _codeText(code).toUpperCase();
  return _successCodes.contains(c) || c.startsWith('SUCCESS');
}

/// Message for a reply that is neither a recognised success nor a recognised
/// failure, so a new code value is visible on screen instead of silently stuck.
String _unknownCodeNote(dynamic code, String message) {
  final c = _codeText(code);
  if (_isSuccess(code) || _failureCodes.contains(c.toUpperCase())) return message;
  return 'Unexpected response code "${c.isEmpty ? 'missing' : c}". Server said: $message';
}

String _text(dynamic v, [String fallback = '']) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty || s == 'null') ? fallback : s;
}

/// Result of step 1 (username + password). On success a one-time code has been sent.
class AuthChallenge {
  const AuthChallenge({
    required this.success,
    required this.message,
    this.otpExpiryMinutes = 5,
  });

  final bool success;
  final String message;

  /// How long the code stays valid, in minutes (`otpExpiry` arrives as text).
  final int otpExpiryMinutes;

  factory AuthChallenge.fromJson(Map<String, dynamic> json) {
    final minutes = int.tryParse(_text(json['otpExpiry'])) ?? 5;
    final ok = _isSuccess(json['responseCode']);
    final message =
        _text(json['responseMessage'], ok ? 'Code sent.' : 'Sign-in failed.');
    return AuthChallenge(
      success: ok,
      message: _unknownCodeNote(json['responseCode'], message),
      otpExpiryMinutes: minutes > 0 ? minutes : 5,
    );
  }
}

/// The signed-in person (`UserInfoDTO`). Parsing is forgiving: whichever of
/// the usual name fields the API sends is used.
class AuthUser {
  const AuthUser({
    required this.name,
    required this.username,
    required this.role,
    this.permissions = const [],
  });

  final String name;
  final String username;
  final String role;

  /// Privilege names from the role (`usersPerm`).
  final List<String> permissions;

  /// Admin screens (dashboard, inventory, payment modes) are offered when the
  /// role name contains "admin" (ADMIN, ROLE_ADMIN, Administrator ...).
  /// This only picks which screens show; the API still enforces access.
  bool get isAdmin => role.toLowerCase().contains('admin');

  /// "IW" style initials for the avatar.
  String get initials {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory AuthUser.fromJson(Map<String, dynamic> json, {String fallbackName = ''}) {
    // The DTO may nest the entity under "user" or put the fields at the top.
    final nested = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    String pick(List<String> keys) {
      for (final map in [json, nested]) {
        for (final k in keys) {
          final v = _text(map[k]);
          if (v.isNotEmpty) return v;
        }
      }
      return '';
    }

    final username = pick(['username', 'userName']);
    final first = pick(['firstName', 'firstname']);
    final last = pick(['lastName', 'lastname', 'surname']);
    final full = pick(['fullName', 'name', 'displayName']);
    final joined = [first, last].where((s) => s.isNotEmpty).join(' ');
    final name = [full, joined, username, fallbackName]
        .firstWhere((s) => s.isNotEmpty, orElse: () => 'User');

    final role = json['role'] is Map
        ? _text((json['role'] as Map)['roleName'])
        : _text(json['role']);

    final perms = json['usersPerm'];
    return AuthUser(
      name: name,
      username: username.isNotEmpty ? username : fallbackName,
      role: role,
      permissions: perms is List ? perms.map((e) => '$e').toList() : const [],
    );
  }
}

/// Result of step 2 (the one-time code). On success it carries the JWT.
class OtpResult {
  const OtpResult({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  final bool success;
  final String message;
  final String? token;
  final AuthUser? user;

  factory OtpResult.fromJson(Map<String, dynamic> json, {String fallbackName = ''}) {
    final token = _text(json['token']);
    // A token only comes back when the code was right, so it counts as success too.
    final ok = _isSuccess(json['responseCode']) || token.isNotEmpty;
    final user = json['user'];
    final message =
        _text(json['responseMessage'], ok ? 'Signed in.' : 'Sign-in failed.');
    return OtpResult(
      success: ok,
      message: ok ? message : _unknownCodeNote(json['responseCode'], message),
      token: token.isEmpty ? null : token,
      user: user is Map<String, dynamic>
          ? AuthUser.fromJson(user, fallbackName: fallbackName)
          : null,
    );
  }
}

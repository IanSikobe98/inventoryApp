import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:stockroom_app/models/permissions.dart';

import 'helpers.dart';

/// What `POST /api/v1/auth/authenticate` returns.
Map<String, dynamic> authJson({bool ok = true, String? message, String otpExpiry = '5'}) => {
      'responseCode': ok ? 'SUCCESS' : 'FAIL',
      'responseMessage': message ?? (ok ? 'Authentication Successful' : 'Invalid Username or Password!'),
      'otpExpiry': ok ? otpExpiry : null,
    };

/// What `POST /api/v1/auth/validateOtp` returns.
Map<String, dynamic> otpJson({
  bool ok = true,
  String? message,
  String token = 'jwt-token-123',
  String role = 'ADMIN',
  Iterable<String>? perms,
}) =>
    ok
        ? {
            'responseCode': 'SUCCESS',
            'responseMessage': message ?? 'Ian signed in successfully',
            'token': token,
            'user': {
              'username': 'Ian',
              'firstName': 'Ian',
              'lastName': 'Walter',
              'role': role,
              'usersPerm': (perms ?? Perm.all).toList(),
            },
          }
        : {
            'responseCode': 'FAIL',
            'responseMessage': message ?? 'wrong OTP Provided',
            'token': null,
            'user': null,
          };

/// A recording stand-in for the auth endpoints.
class AuthServer {
  AuthServer({
    this.authResponse,
    this.otpResponse,
    this.authStatus = 200,
    this.otpStatus = 200,
  });

  Map<String, dynamic>? authResponse;
  Map<String, dynamic>? otpResponse;
  int authStatus;
  int otpStatus;

  final requests = <http.Request>[];
  int logouts = 0;
  int logoutStatus = 200;

  /// Every call made to [path] (decoded bodies).
  List<Map<String, dynamic>> bodiesFor(String path) => requests
      .where((r) => r.url.path == path && r.body.isNotEmpty)
      .map((r) => jsonDecode(r.body) as Map<String, dynamic>)
      .toList();

  Future<http.Response> handle(http.Request req) async {
    requests.add(req);
    switch (req.url.path) {
      case '/api/v1/auth/authenticate':
        return jsonResponse(authResponse ?? authJson(), authStatus);
      case '/api/v1/auth/validateOtp':
        return jsonResponse(otpResponse ?? otpJson(), otpStatus);
      case '/api/v1/user/logout':
        logouts++;
        return jsonResponse(
            {'responseCode': 'SUCCESS', 'responseMessage': 'User Logged Out'},
            logoutStatus);
    }
    return jsonResponse({'message': 'not mocked'}, 404);
  }
}

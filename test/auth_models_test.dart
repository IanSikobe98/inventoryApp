import 'package:flutter_test/flutter_test.dart';
import 'package:stockroom_app/models/auth.dart';
import 'package:stockroom_app/models/permissions.dart';

import 'auth_helpers.dart';

void main() {
  group('AuthChallenge', () {
    test('success reads the expiry from its text form', () {
      final c = AuthChallenge.fromJson(authJson(otpExpiry: '10'));
      expect(c.success, isTrue);
      expect(c.otpExpiryMinutes, 10);
      expect(c.message, 'Authentication Successful');
    });

    test('failure keeps the server message', () {
      final c = AuthChallenge.fromJson(authJson(ok: false));
      expect(c.success, isFalse);
      expect(c.message, 'Invalid Username or Password!');
    });

    test('success is recognised however the enum arrives', () {
      for (final code in ['SUCCESS', 'success', 'Success', '00', 0, '200', 'SUCCESSFUL',
        {'name': 'SUCCESS', 'code': '00'}, {'code': '00'}]) {
        expect(AuthChallenge.fromJson({'responseCode': code}).success, isTrue,
            reason: '$code');
      }
    });

    test('an unrecognised code is reported on screen with the raw value', () {
      final c = AuthChallenge.fromJson(
          {'responseCode': 'PENDING_REVIEW', 'responseMessage': 'Hmm'});
      expect(c.success, isFalse);
      expect(c.message, contains('PENDING_REVIEW'));
      expect(c.message, contains('Hmm'));
    });

    test('a known failure keeps the plain server message', () {
      for (final code in ['FAIL', 'fail', 'FAILED', 'ERROR', '01']) {
        final c = AuthChallenge.fromJson(
            {'responseCode': code, 'responseMessage': 'Invalid Credentials'});
        expect(c.success, isFalse);
        expect(c.message, 'Invalid Credentials', reason: code);
      }
    });

    test('a missing or odd expiry falls back to 5 minutes', () {
      expect(AuthChallenge.fromJson({'responseCode': 'SUCCESS'}).otpExpiryMinutes, 5);
      expect(
          AuthChallenge.fromJson({'responseCode': 'SUCCESS', 'otpExpiry': 'abc'})
              .otpExpiryMinutes,
          5);
      expect(
          AuthChallenge.fromJson({'responseCode': 'SUCCESS', 'otpExpiry': '0'})
              .otpExpiryMinutes,
          5);
    });
  });

  group('OtpResult', () {
    test('success carries token and user', () {
      final r = OtpResult.fromJson(otpJson());
      expect(r.success, isTrue);
      expect(r.token, 'jwt-token-123');
      expect(r.user!.name, 'Ian Walter');
      expect(r.user!.role, 'ADMIN');
      expect(r.user!.permissions, Perm.all.toList());
    });

    test('a returned token counts as success even with an odd code', () {
      final r = OtpResult.fromJson({'responseCode': '00', 'token': 't', 'user': {'role': 'ADMIN'}});
      expect(r.success, isTrue);
      final r2 = OtpResult.fromJson({'responseCode': 'WEIRD', 'token': 't'});
      expect(r2.success, isTrue);
    });

    test('failure has no token', () {
      final r = OtpResult.fromJson(otpJson(ok: false));
      expect(r.success, isFalse);
      expect(r.token, isNull);
      expect(r.user, isNull);
      expect(r.message, 'wrong OTP Provided');
    });
  });

  test('reads the real validateOtp reply from the server', () {
    final r = OtpResult.fromJson({
      'responseCode': '00',
      'responseMessage': 'isikobe signed in successfully',
      'token': 'eyJ0eXAi.payload.sig',
      'user': {
        'role': 'SYSTEM_ADMIN',
        'user': {
          'userId': 1,
          'username': 'isikobe',
          'phone': '0716561507',
          'role': {'roleId': 1, 'roleName': 'SYSTEM_ADMIN'},
          'status': {'statusId': 1, 'statusName': 'ACTIVE'},
        },
        'usersPerm': [
          'VIEW_INVENTORY',
          'CREATE_INVENTORY',
          'UPDATE_INVENTORY',
          'CREATE_SALES',
          'VIEW_SALES'
        ],
      },
    });
    expect(r.success, isTrue);
    expect(r.token, 'eyJ0eXAi.payload.sig');
    expect(r.user!.username, 'isikobe');
    expect(r.user!.name, 'isikobe');
    expect(r.user!.role, 'SYSTEM_ADMIN');
    expect(r.user!.permissions, hasLength(5));
    expect(r.user!.permissions, contains('CREATE_SALES'));
  });

  group('AuthUser', () {
    test('finds the fields when the DTO nests the user entity', () {
      final u = AuthUser.fromJson({
        'user': {'username': 'mary', 'firstName': 'Mary', 'lastName': 'Achieng'},
        'role': 'Employee',
      });
      expect(u.name, 'Mary Achieng');
      expect(u.username, 'mary');
      expect(u.role, 'Employee');
      expect(u.isAdmin, isFalse);
    });

    test('a role given as an object uses its roleName', () {
      final u = AuthUser.fromJson({
        'username': 'sam',
        'role': {'roleId': 1, 'roleName': 'ROLE_ADMIN'},
      });
      expect(u.role, 'ROLE_ADMIN');
      expect(u.isAdmin, isTrue);
    });

    test('falls back to the typed username, then to "User"', () {
      expect(AuthUser.fromJson({}, fallbackName: 'ian').name, 'ian');
      expect(AuthUser.fromJson({}).name, 'User');
    });

    test('admin detection ignores case', () {
      for (final role in ['ADMIN', 'admin', 'Administrator', 'ROLE_ADMIN']) {
        expect(AuthUser(name: 'a', username: 'a', role: role).isAdmin, isTrue,
            reason: role);
      }
      for (final role in ['', 'Employee', 'Cashier']) {
        expect(AuthUser(name: 'a', username: 'a', role: role).isAdmin, isFalse,
            reason: role);
      }
    });

    test('initials', () {
      AuthUser u(String n) => AuthUser(name: n, username: n, role: '');
      expect(u('Ian Walter').initials, 'IW');
      expect(u('ian').initials, 'I');
      expect(u('Mary Jane Achieng').initials, 'MA');
      expect(u('').initials, '?');
    });
  });
}

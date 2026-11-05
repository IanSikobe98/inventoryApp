import 'package:flutter_test/flutter_test.dart';
import 'package:stockroom_app/services/password_cipher.dart';

// Expected values were produced independently with OpenSSL:
//   printf 'SQEW13' | openssl enc -aes-128-cbc -K <hex key> -iv <hex iv> | base64
void main() {
  const key = '0123456789abcdef'; // 16 chars -> AES-128
  const iv = 'abcdef9876543210';

  test('plain cipher leaves the password alone', () {
    expect(const PlainPasswordCipher().protect('SQEW13'), 'SQEW13');
  });

  test('AES-CBC matches the OpenSSL result', () {
    final c = AesPasswordCipher(key: key, iv: iv);
    expect(c.protect('SQEW13'), 'fljp+ccYOpSrFh8hiypEYQ==');
  });

  test('AES-ECB matches the OpenSSL result and needs no IV', () {
    final c = AesPasswordCipher(key: key, mode: 'ecb');
    expect(c.protect('SQEW13'), 'VkrWEhCPYEei3xeBZPpIaA==');
  });

  test('a base64: key and IV are decoded first', () {
    // base64 of the same 16 key bytes / 16 IV bytes as above
    final c = AesPasswordCipher(
        key: 'base64:MDEyMzQ1Njc4OWFiY2RlZg==',
        iv: 'base64:YWJjZGVmOTg3NjU0MzIxMA==');
    expect(c.protect('SQEW13'), 'fljp+ccYOpSrFh8hiypEYQ==');
  });

  test('CBC without an IV is refused up front', () {
    expect(() => AesPasswordCipher(key: key), throwsArgumentError);
  });

  test('with no AES_KEY defined the app sends the password as typed', () {
    expect(PasswordCipher.fromEnvironment(), isA<PlainPasswordCipher>());
  });
}

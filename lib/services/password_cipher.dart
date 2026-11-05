import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

/// Your API decrypts the password with `commonTasks.AESdecrypt(...)`, so the app
/// must send it encrypted the same way. Which cipher is used is decided by
/// build-time settings (see [PasswordCipher.fromEnvironment]).
abstract class PasswordCipher {
  /// Returns the text to put in the request's `password` field.
  String protect(String plainPassword);

  /// Picks the cipher from `--dart-define` values:
  ///
  /// * no `AES_KEY`  -> [PlainPasswordCipher] (use when the API reads the password as it is)
  /// * `AES_KEY`     -> [AesPasswordCipher]; also `AES_IV` (CBC only) and
  ///   `AES_MODE` = `cbc` (default) or `ecb`.
  factory PasswordCipher.fromEnvironment() {
    const key = String.fromEnvironment('AES_KEY');
    if (key.isEmpty) return const PlainPasswordCipher();
    const iv = String.fromEnvironment('AES_IV');
    const mode = String.fromEnvironment('AES_MODE', defaultValue: 'cbc');
    return AesPasswordCipher(key: key, iv: iv, mode: mode);
  }
}

/// Sends the password unchanged. Only sensible over HTTPS.
class PlainPasswordCipher implements PasswordCipher {
  const PlainPasswordCipher();

  @override
  String protect(String plainPassword) => plainPassword;
}

/// AES with PKCS#7 padding, output as Base64.
///
/// [key] must be 16, 24 or 32 characters (AES-128/192/256). Prefix it with
/// `base64:` if you hold it as Base64. In CBC mode [iv] must be 16 characters
/// (same `base64:` option).
///
/// NOTE: a key inside an app can be extracted from it. This hides the password
/// from casual viewing; HTTPS is what actually protects it in transit.
class AesPasswordCipher implements PasswordCipher {
  AesPasswordCipher({required String key, String iv = '', String mode = 'cbc'})
      : _key = enc.Key(_bytes(key)),
        _iv = iv.isEmpty ? null : enc.IV(_bytes(iv)),
        _mode = mode.toLowerCase().trim() == 'ecb'
            ? enc.AESMode.ecb
            : enc.AESMode.cbc {
    if (_mode == enc.AESMode.cbc && _iv == null) {
      throw ArgumentError('AES_IV is required for CBC mode (16 characters).');
    }
  }

  final enc.Key _key;
  final enc.IV? _iv;
  final enc.AESMode _mode;

  static Uint8List _bytes(String value) => value.startsWith('base64:')
      ? base64.decode(value.substring(7))
      : Uint8List.fromList(utf8.encode(value));

  @override
  String protect(String plainPassword) {
    final encrypter = enc.Encrypter(enc.AES(_key, mode: _mode, padding: 'PKCS7'));
    final result = _mode == enc.AESMode.ecb
        ? encrypter.encrypt(plainPassword, iv: enc.IV.fromLength(16))
        : encrypter.encrypt(plainPassword, iv: _iv);
    return result.base64;
  }
}

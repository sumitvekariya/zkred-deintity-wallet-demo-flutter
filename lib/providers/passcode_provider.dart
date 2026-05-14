import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PasscodeProvider extends ChangeNotifier {
  static const _keyPasscode = 'cleo_passcode';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _hasPasscode = false;
  bool get hasPasscode => _hasPasscode;

  /// Read storage and refresh [hasPasscode].
  Future<void> checkPasscode() async {
    final saved = await _storage.read(key: _keyPasscode);
    _hasPasscode = saved != null && saved.isNotEmpty;
    notifyListeners();
  }

  /// Returns true when [code] matches the stored passcode.
  Future<bool> verify(String code) async {
    final saved = await _storage.read(key: _keyPasscode);
    return saved == code;
  }

  /// Persist [code] as the wallet passcode.
  Future<void> save(String code) async {
    await _storage.write(key: _keyPasscode, value: code);
    _hasPasscode = true;
    notifyListeners();
  }

  /// Remove the stored passcode entirely.
  Future<void> clear() async {
    await _storage.delete(key: _keyPasscode);
    _hasPasscode = false;
    notifyListeners();
  }
}

import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servizio per la gestione dell'autenticazione biometrica
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastAuthTimeKey = 'last_auth_time';
  static const int _authTimeoutMinutes = 5; // Timeout autenticazione in minuti

  /// Verifica se l'autenticazione biometrica è disponibile
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene i tipi di autenticazione biometrica disponibili
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Verifica se l'autenticazione biometrica è abilitata
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Abilita l'autenticazione biometrica
  Future<void> enableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, true);
  }

  /// Disabilita l'autenticazione biometrica
  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
  }

  /// Richiede l'autenticazione biometrica
  Future<bool> authenticate({
    String reason = 'Autenticati per accedere all\'app',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
        ),
      );

      if (didAuthenticate) {
        await _saveLastAuthTime();
      }

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se l'autenticazione è ancora valida (non scaduta)
  Future<bool> isAuthStillValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAuthTimeString = prefs.getString(_lastAuthTimeKey);

    if (lastAuthTimeString == null) {
      return false;
    }

    final lastAuthTime = DateTime.parse(lastAuthTimeString);
    final now = DateTime.now();
    final difference = now.difference(lastAuthTime);

    return difference.inMinutes < _authTimeoutMinutes;
  }

  /// Salva il tempo dell'ultima autenticazione
  Future<void> _saveLastAuthTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAuthTimeKey, DateTime.now().toIso8601String());
  }

  /// Invalida l'autenticazione (logout)
  Future<void> invalidateAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastAuthTimeKey);
  }
}


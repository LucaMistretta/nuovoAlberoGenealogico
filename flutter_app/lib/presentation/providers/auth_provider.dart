import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider per la gestione dell'autenticazione
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userEmail;
  static const String _userEmailKey = 'user_email';

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;

  AuthProvider() {
    _loadAuthState();
  }

  /// Carica lo stato dell'autenticazione salvato
  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_userEmailKey);
    if (email != null) {
      _userEmail = email;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  /// Esegue il login
  Future<bool> login(String email, String password) async {
    // Per ora, in modalità offline, accetta qualsiasi credenziale
    // In futuro, qui si può aggiungere la verifica con il server
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userEmailKey, email);

      _userEmail = email;
      _isAuthenticated = true;
      notifyListeners();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Esegue il logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);

    _userEmail = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}


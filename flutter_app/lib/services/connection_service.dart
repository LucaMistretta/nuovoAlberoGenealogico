import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// Servizio per verificare la connessione al server
class ConnectionService {
  static const Duration _timeout = Duration(seconds: 3);
  static const String _baseUrl = 'http://casapionepc.hopto.org';
  static const String _statusEndpoint = '/api/sync/status';

  /// Verifica la connessione con un ping diretto al server
  Future<bool> pingServer() async {
    try {
      final url = Uri.parse('$_baseUrl$_statusEndpoint');
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      // 200 = OK, 401 = richiede autenticazione ma server raggiungibile
      return response.statusCode == 200 || response.statusCode == 401;
    } on SocketException {
      // Nessuna connessione di rete
      return false;
    } on HttpException {
      // Errore HTTP
      return false;
    } catch (e) {
      // Qualsiasi altro errore
      return false;
    }
  }

  /// Verifica se il server è raggiungibile
  Future<bool> checkConnection() async {
    return await pingServer();
  }
}


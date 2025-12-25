import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Client API per comunicare con il server Laravel
class ApiClient {
  // Usa l'IP locale del computer invece del nome host locale
  // Per trovare il tuo IP: hostname -I (Linux) o ipconfig (Windows)
  // Assicurati che il telefono sia sulla stessa rete WiFi
  static const String _baseUrl = 'http://192.168.1.6:8000/api';
  static const String _tokenKey = 'api_token';

  /// Ottiene il token di autenticazione salvato
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Salva il token di autenticazione
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Esegue una richiesta GET
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_baseUrl$endpoint');
      
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: il server non risponde. Verifica la connessione di rete.');
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Errore GET $endpoint: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      throw Exception('Errore di connessione: impossibile raggiungere il server $_baseUrl. Verifica che il server sia avviato e che il telefono sia sulla stessa rete WiFi.');
    } on HttpException catch (e) {
      throw Exception('Errore HTTP: $e');
    } catch (e) {
      throw Exception('Errore GET $endpoint: $e');
    }
  }

  /// Esegue una richiesta POST
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_baseUrl$endpoint');
      
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: il server non risponde. Verifica la connessione di rete.');
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw Exception('Errore POST $endpoint: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      throw Exception('Errore di connessione: impossibile raggiungere il server $_baseUrl. Verifica che il server sia avviato e che il telefono sia sulla stessa rete WiFi.');
    } on HttpException catch (e) {
      throw Exception('Errore HTTP: $e');
    } catch (e) {
      throw Exception('Errore POST $endpoint: $e');
    }
  }

  /// Esegue una richiesta POST con file multipart
  Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, dynamic> data,
    Map<String, File> files,
  ) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_baseUrl$endpoint');
      
      final request = http.MultipartRequest('POST', url);
      
      final headers = {
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      request.headers.addAll(headers);

      // Aggiungi i dati JSON come campo 'app_data'
      request.fields['app_data'] = json.encode(data['app_data']);
      if (data.containsKey('last_sync_timestamp') && data['last_sync_timestamp'] != null) {
        request.fields['last_sync_timestamp'] = data['last_sync_timestamp'].toString();
      }

      // Aggiungi i file
      for (final entry in files.entries) {
        final file = entry.value;
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'media_files[$entry.key]',
              file.path,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // Timeout più lungo per upload file
        onTimeout: () {
          throw Exception('Timeout: il server non risponde. Verifica la connessione di rete.');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw Exception('Errore POST $endpoint: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      throw Exception('Errore di connessione: impossibile raggiungere il server $_baseUrl. Verifica che il server sia avviato e che il telefono sia sulla stessa rete WiFi.');
    } on HttpException catch (e) {
      throw Exception('Errore HTTP: $e');
    } catch (e) {
      throw Exception('Errore POST multipart $endpoint: $e');
    }
  }

  /// Esegue il login e salva il token
  Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/login');
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          await _saveToken(data['token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Esegue il logout
  Future<void> logout() async {
    try {
      final token = await _getToken();
      if (token != null) {
        final url = Uri.parse('$_baseUrl/auth/logout');
        await http.post(
          url,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      // Ignora errori durante logout
    }
  }
}


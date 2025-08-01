import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String _baseUrl = 'https://patitas-care.onrender.com';
  static const String _tokenKey = 'jwt_token';
  static const String _userDataKey = 'user_data';

  // REGISTRO
  static Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String tipoUsuario,
  }) async {
    final url = Uri.parse('$_baseUrl/cliente/registro');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'correo': correo,
          'password': password,
          'tipoDeUsuario': tipoUsuario, // Campo corregido
        }),
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final body = jsonDecode(response.body);

      // Si el registro es exitoso, hacer login automático
      if (response.statusCode == 201) {
        // Después del registro exitoso, hacer login
        final loginResult = await _loginAfterRegistration(correo, password);
        if (loginResult['success']) {
          body['token'] = loginResult['token'];
        }
      }

      return {'status': response.statusCode, 'body': body};
    } catch (e) {
      print('Error en registro: $e');
      rethrow;
    }
  }

  // LOGIN AUTOMÁTICO DESPUÉS DEL REGISTRO
  static Future<Map<String, dynamic>> _loginAfterRegistration(String correo, String password) async {
    try {
      final loginResult = await login(correo: correo, password: password);
      return loginResult;
    } catch (e) {
      print('Error en login automático: $e');
      return {'success': false};
    }
  }

  // LOGIN NORMAL
  static Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo,
          'password': password,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['token'] != null) {
        await _saveToken(body['token']);
        
        // NUEVO: Obtener y guardar datos del usuario después del login
        try {
          final perfilResponse = await http.get(
            Uri.parse('$_baseUrl/cliente/perfil'),
            headers: {
              'Authorization': 'Bearer ${body['token']}',
              'Content-Type': 'application/json',
            },
          );
          
          if (perfilResponse.statusCode == 200) {
            final userData = json.decode(perfilResponse.body);
            await _saveUserData(userData);
          }
        } catch (e) {
          print('Error obteniendo perfil después del login: $e');
        }
        
        return {'success': true, 'token': body['token'], 'body': body};
      }

      return {'success': false, 'body': body};
    } catch (e) {
      print('Error en login: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // GESTIÓN DE TOKEN
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('TOKEN GUARDADO: $token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // HEADERS AUTENTICADOS
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> authenticatedPost(
    String url, {
    required Map<String, dynamic> body,
  }) async {
    final headers = await getAuthHeaders();
    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> authenticatedGet(String url) async {
    final headers = await getAuthHeaders();
    return await http.get(
      Uri.parse(url),
      headers: headers,
    );
  }

  // LOGOUT
  static Future<void> logout() async {
    try {
      await removeToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      print('Sesión cerrada y datos limpiados');
    } catch (e) {
      print('Error en logout: $e');
    }
  }

  static Future<bool> verificarToken() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // Usar el endpoint de perfil para verificar el token
      final response = await http.get(
        Uri.parse('$_baseUrl/cliente/perfil'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error verificando token: $e');
      return false;
    }
  }

  // NUEVO: Método para verificar sesión completa con datos del usuario
  static Future<Map<String, dynamic>> verificarSesionCompleta() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return {'isValid': false, 'user': null};
      }

      // Verificar token y obtener datos del usuario
      final response = await http.get(
        Uri.parse('$_baseUrl/cliente/perfil'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        // Guardar datos del usuario actualizados
        await _saveUserData(userData);
        return {'isValid': true, 'user': userData};
      } else {
        return {'isValid': false, 'user': null};
      }
    } catch (e) {
      print('Error verificando sesión completa: $e');
      return {'isValid': false, 'user': null};
    }
  }

  // NUEVO: Guardar datos del usuario
  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, json.encode(userData));
    } catch (e) {
      print('Error guardando datos del usuario: $e');
    }
  }

  // NUEVO: Obtener datos del usuario guardados
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        return json.decode(userDataString);
      }
      return null;
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
      return null;
    }
  }

}
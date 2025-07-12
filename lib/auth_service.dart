import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final String _baseUrl = 'https://patitas-care.onrender.com';

  Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String tipoUsuario,
  }) async {
    final url = Uri.parse('$_baseUrl/usuarios/registro');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'tipo_usuario': tipoUsuario,
      }),
    );

    final body = jsonDecode(response.body);

    // ✅ Guarda el token si existe en la respuesta
    if (response.statusCode == 201 && body['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', body['token']);
      print('TOKEN GUARDADO: ${body['token']}'); // Para confirmar en consola
    } else {
      print('No se recibió token en el registro');
    }

    return {'status': response.statusCode, 'body': body};
  }

  // También puedes agregar esto por si lo necesitas más adelante
  Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}

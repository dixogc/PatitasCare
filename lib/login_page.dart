import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'registro_page.dart';
import 'main.dart';
import 'veterinarias_mapa_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> iniciarSesion() async {
    if (!_validarCampos()) return;

    setState(() {
      _isLoading = true;
    });

    const baseUrl = 'https://patitas-care.onrender.com';
    const endpoint = '$baseUrl/auth/login';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correoController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];
        
        // Guardar el token
        await _guardarToken(token);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Inicio de sesión exitoso!')),
          );
          
          // Navegar a la pantalla principal de la app
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainAppScreen()),
            //Cuando tengas lista la pantalla principal, cambia la línea de arriba
            //porque te dirige a la pantalla principal provicional(el código de esa pantalla está en
            //está en la línea 266)
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['error'] ?? 'Error en el inicio de sesión'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validarCampos() {
    if (correoController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos.')),
      );
      return false;
    }
    return true;
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  '¡Hola! Bienvenido',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Inicia Sesión',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'ACCEDE A TU CUENTA',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              
              const SizedBox(height: 40),
              _buildTextField('Correo', correoController),
              
              const SizedBox(height: 15),
              _buildTextField(
                'Contraseña',
                passwordController,
                isPassword: true,
              ),
              
              const SizedBox(height: 35),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0XFFB6A9F8)),
                      )
                    : ElevatedButton(
                        onPressed: iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFFB6A9F8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 55,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegistroPage()),
                    );
                  },
                  child: const Text(
                    '¿No tienes una cuenta? Regístrate',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Clase auxiliar para manejar HTTP con JWT
class AuthService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

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
}

// Pantalla temporal para después del login (reemplaza con tu pantalla principal)
class MainAppScreen extends StatelessWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patitas Care'),
        backgroundColor: const Color(0XFFB6A9F8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.removeToken();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 80, color: Color(0XFFB6A9F8)),
            const SizedBox(height: 20),
            const Text(
              '¡Bienvenido a Patitas Care!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aquí puedes acceder a todas las funciones de la app',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VeterinariasMapaPage(),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Ver veterinarias cercanas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0XFFB6A9F8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
    );
  }
}
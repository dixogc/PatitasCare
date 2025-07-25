import 'package:flutter/material.dart';
import 'package:patitas_care/login_page.dart';
import 'mascotas/registro_mascota.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  _RegistroPageState createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? rolSeleccionado;
  final List<String> roles = ['CLIENTE', 'VETERINARIO'];
  bool esVeterinario = false;
  bool _isLoading = false;

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

Future<void> registrarUsuario(
  String nombre,
  String email,
  String password,
  String tipoUsuario,
) async {
  setState(() {
    _isLoading = true;
  });

  try {
    final result = await AuthService.registrarUsuario(
      nombre: nombre,
      correo: email,
      password: password,
      tipoUsuario: tipoUsuario,
    );

    final status = result['status'];
    final body = result['body'];

    if (status == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Registro exitoso! Bienvenido'))
      );
      
      // Si hay token, va directo a home
      if (body['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', body['token']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RegistroMascotaPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${body['mensaje'] ?? body.toString()}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error de conexión: $e'))
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  bool _validarCampos() {
    if (nombreController.text.isEmpty ||
        correoController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos.')),
      );
      return false;
    }
    
    // Asegurar que rolSeleccionado tenga un valor basado en esVeterinario
    rolSeleccionado = esVeterinario ? 'VETERINARIO' : 'CLIENTE';
    
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

  Widget _buildRolSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: const Text('Soy veterinario'),
        subtitle: Text(esVeterinario ? 'Registrándote como veterinario' : 'Registrándote como usuario común'),
        value: esVeterinario,
        onChanged: (bool? value) {
          setState(() {
            esVeterinario = value ?? false;
            // Actualizar rolSeleccionado para el backend
            rolSeleccionado = esVeterinario ? 'VETERINARIO' : 'CLIENTE';
          });
        },
        activeColor: const Color(0xFFB6A9F8),
        controlAffinity: ListTileControlAffinity.leading,
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

              const SizedBox(height: 1),
              const Center(
                child: Text(
                  '¡Hola! Bienvenido',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 1),
              const Center(
                child: Text(
                  'Regístrate',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'CREA UNA CUENTA',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('Nombre', nombreController),
              const SizedBox(height: 15),
              _buildTextField('Correo', correoController),
              const SizedBox(height: 15),
              _buildTextField(
                'Contraseña',
                passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 15),
              _buildRolSelector(),
              const SizedBox(height: 35),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB6A9F8)),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          if (_validarCampos()) {
                            await registrarUsuario(
                              nombreController.text,
                              correoController.text,
                              passwordController.text,
                              rolSeleccionado!,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0XFFB6A9F8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 55,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'COMENZAR',
                          style: TextStyle(color: Colors.white),
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
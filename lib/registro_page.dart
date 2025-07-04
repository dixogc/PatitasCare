import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    final baseUrl = 'https://patitas-care.onrender.com';

    String endpoint;
    if (tipoUsuario.toLowerCase() == 'cliente') {
      endpoint = '$baseUrl/cliente/registro';
    } else if (tipoUsuario.toLowerCase() == 'veterinario') {
      endpoint = '$baseUrl/veterinario/registro';
    } else {
      throw Exception("Tipo de usuario no valido");
    }

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombreController.text,
          'correo': correoController.text,
          'password': passwordController.text,
          'tipoDeUsuario': rolSeleccionado,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('¡Registro exitoso!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    }
  }

  bool _validarCampos() {
    if (nombreController.text.isEmpty ||
        correoController.text.isEmpty ||
        passwordController.text.isEmpty ||
        rolSeleccionado == null) {
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

  Widget _buildDropdownRol() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonFormField<String>(
        value: rolSeleccionado,
        isExpanded: true,
        hint: const Text('Tipo de Usuario'),
        items: roles.map((rol) {
          return DropdownMenuItem(value: rol, child: Text(rol));
        }).toList(),
        onChanged: (value) {
          setState(() {
            rolSeleccionado = value;
          });
        },
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
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
              _buildDropdownRol(),
              const SizedBox(height: 35),
              Center(
                child: ElevatedButton(
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

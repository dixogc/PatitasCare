import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:patitas_care/auth_service.dart';
import 'package:patitas_care/mascotas/lista_de_mascotas.dart';
import 'package:patitas_care/login_page.dart';

class RegistroMascotaPage extends StatefulWidget {
  const RegistroMascotaPage({super.key});

  @override
  _RegistroMascotaState createState() => _RegistroMascotaState();
}

class _RegistroMascotaState extends State<RegistroMascotaPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController edadController = TextEditingController();
  final TextEditingController razaController = TextEditingController();
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController colorController = TextEditingController();

  String? especieSeleccionado;
  final List<String> especie = ['Perro', 'Gato', 'Conejo', 'Tortuga', 'Otro'];
  
  bool _isLoading = false;

  @override
  void dispose() {
    nombreController.dispose();
    edadController.dispose();
    razaController.dispose();
    pesoController.dispose();
    sizeController.dispose();
    colorController.dispose();
    super.dispose();
  }

Future<void> registrarMascota() async {
  
  if (!_validarCampos()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  final token = await AuthService.getToken();

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token no encontrado. Vuelve a iniciar sesión.'),
      ),
    );
    // Redirigir al login si no hay token
    Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
    return;
  }

  try {
    final baseUrl = 'https://patitas-care.onrender.com';
    final url = Uri.parse('$baseUrl/mascotas/mis-mascotas');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nombre': nombreController.text,
        'especie': especieSeleccionado,
        'raza': razaController.text,
        'edad': int.tryParse(edadController.text) ?? 0,
        'peso': double.tryParse(pesoController.text) ?? 0.0,
        'size': int.tryParse(sizeController.text) ?? 0,
        'color': colorController.text,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Mascota registrada exitosamente!')),
      );
      
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyPetPage()),
        ); 
      
    } else {
      final error = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error al registrar'),
          content: Text(error['mensaje'] ?? 'Ocurrió un error inesperado.'),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error de conexión: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  bool _validarCampos() {
    if (nombreController.text.isEmpty ||
        edadController.text.isEmpty ||
        razaController.text.isEmpty ||
        pesoController.text.isEmpty ||
        sizeController.text.isEmpty ||
        colorController.text.isEmpty ||
        especieSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos.')),
      );
      return false;
    }

    if (double.tryParse(pesoController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El peso debe ser un número válido.')),
      );
      return false;
    }

    if (int.tryParse(sizeController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El tamaño debe ser un número válido.')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 250,
              width: double.infinity,
              color: const Color(0xFFB6A9F8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
            child: ListView(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Registra a tu mascota',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unos datos y estamos listos para comenzar.',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildTextField('Nombre de tu mascota', nombreController),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Edad', edadController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Raza', razaController)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Peso', pesoController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Tamaño', sizeController)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDropdown(especie, 'Especie')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Color', colorController)),
                  ],
                ),
                const SizedBox(height: 40),
                // Botón con animación de carga
                ElevatedButton(
                  onPressed: () {
                    if (_validarCampos()) {
                      registrarMascota();
                    }
                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFDD4A),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                  child: const Text(
                    'AGREGAR MASCOTA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFF4F5F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> options, String label) {
    return DropdownButtonFormField<String>(
      value: especieSeleccionado,
      hint: Text(label),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF4F5F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option.toUpperCase(),
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          especieSeleccionado = value;
        });
      },
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 60);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 120);
    var secondEndPoint = Offset(size.width, size.height - 60);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:patitas_care/auth_service.dart';
import 'package:patitas_care/mascotas/lista_de_mascotas.dart';
import 'package:patitas_care/login_page.dart';
import 'package:patitas_care/success_feedback_widget.dart';
import 'package:patitas_care/notification_helper.dart';

class RegistroMascotaPage extends StatefulWidget {
  const RegistroMascotaPage({super.key});

  @override
  _RegistroMascotaState createState() => _RegistroMascotaState();
}

class _RegistroMascotaState extends State<RegistroMascotaPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController especieController = TextEditingController();
  final TextEditingController edadController = TextEditingController();
  final TextEditingController razaController = TextEditingController();
  final TextEditingController colorController = TextEditingController();

  String? sexoSeleccionado;
  DateTime? fechaNacimientoSeleccionada;
  bool? esterilizado;
  
  final List<String> sexoOpciones = ['Hembra', 'Macho', 'Desconocido'];
  
  bool _isLoading = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    nombreController.dispose();
    especieController.dispose();
    edadController.dispose();
    razaController.dispose();
    colorController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)), // 1 año atrás por defecto
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    
    if (fechaSeleccionada != null) {
      setState(() {
        fechaNacimientoSeleccionada = fechaSeleccionada;
      });
    }
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
      setState(() {
        _isLoading = false;
      });
      
      context.showErrorNotification(
        'Sesión expirada. Por favor, inicia sesión nuevamente.',
        actionLabel: 'Iniciar Sesión',
        onAction: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
      );
      return;
    }

    try {
      final baseUrl = 'https://patitas-care.onrender.com';
      final url = Uri.parse('$baseUrl/mascotas/mis-mascotas');

      // Preparar el cuerpo de la petición
      Map<String, dynamic> requestBody = {
        'nombre': nombreController.text,
        'especie': especieController.text,
      };

      // Agregar campos opcionales solo si tienen valor
      if (razaController.text.isNotEmpty) {
        requestBody['raza'] = razaController.text;
      }
      
      if (sexoSeleccionado != null) {
        requestBody['sexo'] = sexoSeleccionado!.toUpperCase();
      }
      
      if (esterilizado != null) {
        requestBody['esterilizado'] = esterilizado;
      }
      
      if (fechaNacimientoSeleccionada != null) {
        requestBody['fechaNacimiento'] = fechaNacimientoSeleccionada!.toIso8601String().split('T')[0];
      }
      
      if (edadController.text.isNotEmpty) {
        final edad = int.tryParse(edadController.text);
        if (edad != null) {
          requestBody['edad'] = edad;
        }
      }
      
      if (colorController.text.isNotEmpty) {
        requestBody['color'] = colorController.text;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mostrar animación de éxito
        setState(() {
          _showSuccess = true;
        });
        
      } else {
        final error = jsonDecode(response.body);
        context.showErrorNotification(
          error['mensaje'] ?? 'No se pudo registrar la mascota. Intenta nuevamente.',
          actionLabel: 'Reintentar',
          onAction: () => registrarMascota(),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      context.showErrorNotification(
        'Error de conexión. Verifica tu internet e intenta nuevamente.',
        actionLabel: 'Reintentar',
        onAction: () => registrarMascota(),
      );
    }
  }

  void _onSuccessComplete() {
    setState(() {
      _showSuccess = false;
    });
    
    // Navegar a la siguiente pantalla
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyPetPage()),
    );
  }

  bool _validarCampos() {
    if (nombreController.text.isEmpty) {
      context.showWarningNotification('El nombre de la mascota es obligatorio.');
      return false;
    }

    if (especieController.text.isEmpty) {
      context.showWarningNotification('La especie es obligatoria.');
      return false;
    }

    // Validar edad si se proporcionó
    if (edadController.text.isNotEmpty && int.tryParse(edadController.text) == null) {
      context.showWarningNotification('La edad debe ser un número válido.');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SuccessFeedbackWidget(
      showSuccess: _showSuccess,
      successMessage: '¡Mascota registrada!',
      onComplete: _onSuccessComplete,
      child: Scaffold(
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
                    'Es importante guardar los datos básicos de tu mascota.',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _buildTextField('Nombre de tu mascota *', nombreController),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Especie *', especieController)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Raza', razaController)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildDropdown(sexoOpciones, 'Sexo')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Color', colorController)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Edad', edadController)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDateField()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildCheckboxField(),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () {
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
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
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
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: label.contains('Edad') ? TextInputType.number : TextInputType.text,
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
      value: sexoSeleccionado,
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
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          sexoSeleccionado = value;
        });
      },
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _seleccionarFecha,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  fechaNacimientoSeleccionada != null
                      ? '${fechaNacimientoSeleccionada!.day}/${fechaNacimientoSeleccionada!.month}/${fechaNacimientoSeleccionada!.year}'
                      : 'Fecha de nacimiento',
                  style: TextStyle(
                    color: fechaNacimientoSeleccionada != null
                        ? Colors.black
                        : Colors.grey[600],
                  ),
                ),
              ),
              Icon(Icons.calendar_today, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CheckboxListTile(
        title: const Text('¿Está esterilizado/a?'),
        value: esterilizado ?? false,
        onChanged: (value) {
          setState(() {
            esterilizado = value;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFFB6A9F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
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
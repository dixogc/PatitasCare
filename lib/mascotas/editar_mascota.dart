import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:patitas_care/auth_service.dart';


class EditPetPage extends StatefulWidget {
  final String mascotaId;
  final Map<String, dynamic> mascotaData;
  
  const EditPetPage({
    super.key,
    required this.mascotaId,
    required this.mascotaData,
  });

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nombreController;
  late TextEditingController especieController;
  late TextEditingController razaController;
  late TextEditingController edadController;
  late TextEditingController colorController;
  
  String? sexoSeleccionado;
  DateTime? fechaNacimientoSeleccionada;
  bool? esterilizado;
  bool isLoading = false;

  final List<String> sexoOpciones = ['Hembra', 'Macho', 'Desconocido'];
  final Color purple = const Color(0xFF8F88F2);
  final Color yellow = const Color(0xFFF9DC5C);

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
  }

  void _inicializarControladores() {
    nombreController = TextEditingController(
      text: widget.mascotaData['nombre'] ?? ''
    );
    especieController = TextEditingController(
      text: widget.mascotaData['especie'] ?? ''
    );
    razaController = TextEditingController(
      text: widget.mascotaData['raza'] ?? ''
    );
    edadController = TextEditingController(
      text: widget.mascotaData['edad']?.toString() ?? ''
    );
    colorController = TextEditingController(
      text: widget.mascotaData['color'] ?? ''
    );

    // Inicializar sexo
    String? sexoBackend = widget.mascotaData['sexo'];
    if (sexoBackend != null) {
      switch (sexoBackend.toUpperCase()) {
        case 'HEMBRA':
          sexoSeleccionado = 'Hembra';
          break;
        case 'MACHO':
          sexoSeleccionado = 'Masculino';
          break;
        case 'DESCONOCIDO':
          sexoSeleccionado = 'Desconocido';
          break;
        default:
          sexoSeleccionado = 'Desconocido';
      }
    } else {
      sexoSeleccionado = 'Desconocido';
    }

    // Inicializar esterilizado
    esterilizado = widget.mascotaData['esterilizado'];

    // Inicializar fecha de nacimiento
    String? fechaString = widget.mascotaData['fechaNacimiento'];
    if (fechaString != null && fechaString.isNotEmpty) {
      try {
        fechaNacimientoSeleccionada = DateTime.parse(fechaString);
      } catch (e) {
        fechaNacimientoSeleccionada = null;
      }
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    especieController.dispose();
    razaController.dispose();
    edadController.dispose();
    colorController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: fechaNacimientoSeleccionada ?? DateTime.now().subtract(const Duration(days: 365)),
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

  Future<void> actualizarMascota() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final token = await AuthService.getToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token no encontrado')),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final baseUrl = 'https://patitas-care.onrender.com';
      final url = Uri.parse('$baseUrl/mascotas/mis-mascotas/${widget.mascotaId}');

      // Preparar el cuerpo de la petición
      Map<String, dynamic> requestBody = {
        'nombre': nombreController.text,
        'especie': especieController.text
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

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mascota actualizada exitosamente')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Error al actualizar mascota');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo decorativo
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: yellow.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: yellow.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(75),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Editar Mascota',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                // Formulario
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField('Nombre *:', nombreController),
                          const SizedBox(height: 20),
                          _buildTextField('Especie *:', especieController),
                          const SizedBox(height: 20),
                          _buildTextField('Raza:', razaController),
                          const SizedBox(height: 20),
                          _buildDropdownField(),
                          const SizedBox(height: 20),
                          _buildTextField('Color:', colorController),
                          const SizedBox(height: 20),
                          _buildTextField('Edad:', edadController, TextInputType.number),
                          const SizedBox(height: 20),
                          _buildDateField(),
                          const SizedBox(height: 20),
                          _buildCheckboxField(),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : actualizarMascota,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Actualizar Mascota'),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTextField(String label, TextEditingController controller, [TextInputType? keyboardType, bool isRequired = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: isRequired ? (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            return null;
          } : (value) {
            // Validar edad si se proporcionó
            if (label.contains('Edad') && value != null && value.isNotEmpty && int.tryParse(value) == null) {
              return 'La edad debe ser un número válido';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFE8E8E8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sexo:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: sexoSeleccionado,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFE8E8E8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          items: sexoOpciones.map((sexo) => DropdownMenuItem(
                value: sexo,
                child: Text(sexo),
              )).toList(),
          onChanged: (value) {
            setState(() {
              sexoSeleccionado = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha de nacimiento:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _seleccionarFecha,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fechaNacimientoSeleccionada != null
                        ? '${fechaNacimientoSeleccionada!.day.toString().padLeft(2, '0')}/${fechaNacimientoSeleccionada!.month.toString().padLeft(2, '0')}/${fechaNacimientoSeleccionada!.year}'
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      fontSize: 16,
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
      ],
    );
  }

  Widget _buildCheckboxField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Está esterilizado/a?:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(25),
          ),
          child: CheckboxListTile(
            title: const Text('Sí, está esterilizado/a'),
            value: esterilizado ?? false,
            onChanged: (value) {
              setState(() {
                esterilizado = value;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ],
    );
  }
}
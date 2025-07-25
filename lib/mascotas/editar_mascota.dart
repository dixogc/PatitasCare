import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


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
  late TextEditingController razaController;
  late TextEditingController edadController;
  late TextEditingController pesoController;
  late TextEditingController sizeController;
  late TextEditingController colorController;
  String? especieSeleccionada;
  bool isLoading = false;

  final Color purple = const Color(0xFF8F88F2);
  final Color yellow = const Color(0xFFF9DC5C);

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.mascotaData['nombre']);
    razaController = TextEditingController(text: widget.mascotaData['raza']);
    edadController = TextEditingController(text: widget.mascotaData['edad'].toString());
    pesoController = TextEditingController(text: widget.mascotaData['peso'].toString());
    sizeController = TextEditingController(text: widget.mascotaData['size'].toString());
    colorController = TextEditingController(text: widget.mascotaData['color']);
    especieSeleccionada = widget.mascotaData['especie'];
  }

  @override
  void dispose() {
    nombreController.dispose();
    razaController.dispose();
    edadController.dispose();
    pesoController.dispose();
    sizeController.dispose();
    colorController.dispose();
    super.dispose();
  }

  Future<void> actualizarMascota() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

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

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': nombreController.text,
          'especie': especieSeleccionada,
          'raza': razaController.text,
          'edad': int.tryParse(edadController.text) ?? 0,
          'peso': double.tryParse(pesoController.text) ?? 0.0,
          'size': sizeController.text,
          'color': colorController.text,
        }),
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
                          _buildTextField('Nombre:', nombreController),
                          const SizedBox(height: 20),
                          _buildDropdownField(),
                          const SizedBox(height: 20),
                          _buildTextField('Raza:', razaController),
                          const SizedBox(height: 20),
                          _buildTextField('Edad:', edadController, TextInputType.number),
                          const SizedBox(height: 20),
                          _buildTextField('Peso (kg):', pesoController, TextInputType.number),
                          const SizedBox(height: 20),
                          _buildTextField('Tamaño (cm):', sizeController),
                          const SizedBox(height: 20),
                          _buildTextField('Color:', colorController),
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

  Widget _buildTextField(String label, TextEditingController controller, [TextInputType? keyboardType]) {
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
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
          'Especie:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: especieSeleccionada,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Selecciona una especie';
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
          items: ['PERRO', 'GATO', 'CONEJO', 'TORTUGA', 'OTRO']
              .map((especie) => DropdownMenuItem(
                    value: especie,
                    child: Text(especie),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              especieSeleccionada = value;
            });
          },
        ),
      ],
    );
  }
}
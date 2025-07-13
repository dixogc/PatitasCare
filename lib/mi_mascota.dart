import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'editar_mascota.dart';


class PetDetailPage extends StatefulWidget {
  final String mascotaId;
  
  const PetDetailPage({super.key, required this.mascotaId});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  Map<String, dynamic>? mascota;
  bool isLoading = true;
  final Color purple = const Color(0xFF8F88F2);
  final Color yellow = const Color(0xFFF9DC5C);

  @override
  void initState() {
    super.initState();
    cargarDetalleMascota();
  }

  Future<void> cargarDetalleMascota() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token no encontrado')),
      );
      return;
    }

    try {
      final baseUrl = 'https://patitas-care.onrender.com';
      final url = Uri.parse('$baseUrl/mascotas/mis-mascotas/${widget.mascotaId}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          mascota = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Error al cargar mascota');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> eliminarMascota() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${mascota?['nombre']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    try {
      final baseUrl = 'https://patitas-care.onrender.com';
      final url = Uri.parse('$baseUrl/mascotas/mis-mascotas/${widget.mascotaId}');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mascota eliminada exitosamente')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Error al eliminar mascota');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : mascota == null
                    ? const Center(child: Text('Error al cargar mascota'))
                    : Column(
                        children: [
                          // Header fijo
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
                                  'Mi Mascota',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Contenido scrollable
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoField('Nombre:', mascota!['nombre']),
                                  const SizedBox(height: 16),
                                  _buildInfoField('Especie:', mascota!['especie']),
                                  const SizedBox(height: 16),
                                  _buildInfoField('Edad:', '${mascota!['edad']} años'),
                                  const SizedBox(height: 16),
                                  _buildInfoField('Raza:', mascota!['raza']),
                                  const SizedBox(height: 16),
                                  _buildInfoField('Peso:', '${mascota!['peso']} kg'),
                                  const SizedBox(height: 16),
                                  _buildInfoField('Tamaño:', '${mascota!['size']} cm'),
                                  const SizedBox(height: 16),
                                  _buildInfoField('Color:', mascota!['color']),
                                  const SizedBox(height: 32),
                                  // Botones de acción
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EditPetPage(
                                                  mascotaId: widget.mascotaId,
                                                  mascotaData: mascota!,
                                                ),
                                              ),
                                            ).then((_) => cargarDetalleMascota());
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: purple,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                          ),
                                          child: const Text('Editar'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: eliminarMascota,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                          ),
                                          child: const Text('Eliminar'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20), // Espacio adicional al final
                                ],
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

  Widget _buildInfoField(String label, String value) {
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
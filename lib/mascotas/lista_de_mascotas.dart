import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:patitas_care/inicio_page.dart';
import 'package:patitas_care/mascotas/registro_mascota.dart';
import 'mi_mascota.dart';
import 'package:patitas_care/auth_service.dart';
import 'package:patitas_care/notification_helper.dart';

class MyPetPage extends StatefulWidget {
  const MyPetPage({super.key});

  @override
  State<MyPetPage> createState() => _MyPetPageState();
}

class _MyPetPageState extends State<MyPetPage> {
  List<Map<String, dynamic>> mascotas = [];
  bool isLoading = true;
  final Color purple = const Color(0xFF8F88F2);
  final Color yellow = const Color(0xFFF9DC5C);

  @override
  void initState() {
    super.initState();
    cargarMascotas();
  }

  Future<void> cargarMascotas() async {
    setState(() {
      isLoading = true;
    });

    final token = await AuthService.getToken();

    if (token == null) {
      context.showErrorNotification(
        'Sesión expirada. Por favor, inicia sesión nuevamente.',
        actionLabel: 'Iniciar Sesión',
        onAction: () {
          Navigator.pushReplacementNamed(context, '/auth/login');
        },
      );
      return;
    }

    try {
      final baseUrl = 'https://patitas-care.onrender.com';

      final response = await AuthService.authenticatedGet('$baseUrl/mascotas/mis-mascotas');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          mascotas = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        throw Exception('Error al cargar mascotas');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      context.showErrorNotification(
        'Error al cargar tus mascotas. Verifica tu conexión.',
        actionLabel: 'Reintentar',
        onAction: () => cargarMascotas(),
      );
    }
  }

  String _formatearSexo(String? sexo) {
    if (sexo == null || sexo.isEmpty) return 'Sin especificar';
    
    switch (sexo.toUpperCase()) {
      case 'FEMENINO':
        return 'Femenino';
      case 'MASCULINO':
        return 'Masculino';
      case 'DESCONOCIDO':
        return 'Desconocido';
      default:
        return sexo;
    }
  }

  String _formatearEdad(int? edad) {
    if (edad == null) return 'Sin especificar';
    return edad == 1 ? '$edad año' : '$edad años';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo decorativo con formas amarillas
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
                // Header con botón de retroceso
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => InicioPage()),
                        ),
                        icon: const Icon(Icons.arrow_back, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Mis Mascotas',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenido principal
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : mascotas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes mascotas registradas',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegistroMascotaPage(),
                                    ),
                                  ).then((_) => cargarMascotas());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text('Registrar Primera Mascota'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: mascotas.length,
                          itemBuilder: (context, index) {
                            final mascota = mascotas[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: purple.withOpacity(0.2),
                                  radius: 30,
                                  child: Icon(
                                    Icons.pets,
                                    size: 30,
                                    color: purple,
                                  ),
                                ),
                                title: Text(
                                  mascota['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${mascota['especie'] ?? 'Sin especie'} • ${mascota['raza'] ?? 'Sin raza'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_formatearEdad(mascota['edad'])} • ${_formatearSexo(mascota['sexo'])}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PetDetailPage(
                                        mascotaId: mascota['id'],
                                      ),
                                    ),
                                  ).then((_) => cargarMascotas());
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistroMascotaPage(),
            ),
          ).then((_) => cargarMascotas());
        },
        backgroundColor: purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
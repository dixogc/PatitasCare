import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:patitas_care/auth_service.dart';
import 'package:patitas_care/historialMedico/historial_medico_list_page.dart';
import 'package:patitas_care/inicio_page.dart';
import 'package:patitas_care/login_page.dart';
import 'package:patitas_care/mascotas/registro_mascota.dart';
import 'package:patitas_care/notification_helper.dart';

class HistorialMascotaSelectionPage extends StatefulWidget {
  const HistorialMascotaSelectionPage({super.key});

  @override
  State<HistorialMascotaSelectionPage> createState() => _HistorialMascotaSelectionPageState();
}

class _HistorialMascotaSelectionPageState extends State<HistorialMascotaSelectionPage> {
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
        'Sesión expirada. Por favor inicia sesión nuevamente.',
        actionLabel: 'Ir a login',
        onAction: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),),
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
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      final errorMessage = _getReadableErrorMessage(e.toString());
      context.showErrorNotification(
        errorMessage,
        actionLabel: 'Reintentar',
        onAction: () => cargarMascotas(),
      );
    }
  }

  String _getReadableErrorMessage(String originalMessage) {
    // Convierte mensajes técnicos en mensajes amigables
    if (originalMessage.contains('401') || originalMessage.contains('Unauthorized')) {
      return 'Tu sesión ha expirado. Por favor inicia sesión nuevamente.';
    } else if (originalMessage.contains('403') || originalMessage.contains('Forbidden')) {
      return 'No tienes permisos para ver las mascotas.';
    } else if (originalMessage.contains('404') || originalMessage.contains('Not Found')) {
      return 'No se encontraron mascotas registradas.';
    } else if (originalMessage.contains('500') || originalMessage.contains('Internal Server Error')) {
      return 'Error en el servidor. Por favor intenta más tarde.';
    } else if (originalMessage.toLowerCase().contains('network') || 
               originalMessage.toLowerCase().contains('connection') ||
               originalMessage.toLowerCase().contains('timeout')) {
      return 'Problema de conexión. Verifica tu internet e intenta de nuevo.';
    } else if (originalMessage.contains('SocketException') || 
               originalMessage.contains('HttpException')) {
      return 'No pudimos conectar con el servidor. Revisa tu conexión a internet.';
    }
    return 'Ocurrió un error inesperado. Por favor intenta de nuevo.';
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
                        'Historial Médico',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                // Subtítulo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Selecciona la mascota para ver su historial médico',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                // Contenido principal
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8F88F2)),
                          ),
                        )
                      : mascotas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes mascotas registradas',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Registra una mascota primero para\npoder llevar su historial médico',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegistroMascotaPage(),
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
                                icon: const Icon(Icons.add),
                                label: const Text('Registrar mascota'),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: cargarMascotas,
                                style: TextButton.styleFrom(
                                  foregroundColor: purple,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.refresh, size: 20),
                                    SizedBox(width: 8),
                                    Text('Actualizar lista'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: cargarMascotas,
                          color: purple,
                          child: ListView.builder(
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
                                      Icons.medical_services,
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
                                        '${mascota['edad'] ?? 0} años • ${mascota['sexo'] ?? 'Desconocido'}',
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
                                        builder: (context) => HistorialMedicoListPage(
                                          mascotaId: mascota['id'],
                                          mascotaNombre: mascota['nombre'],
                                        ),
                                      ),
                                    ).then((_) {
                                      // Opcional: recargar la lista si es necesario
                                      // cargarMascotas();
                                    });
                                  },
                                ),
                              );
                            },
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
}
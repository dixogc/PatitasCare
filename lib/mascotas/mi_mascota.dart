import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:patitas_care/auth_service.dart';
import 'package:patitas_care/login_page.dart';
import 'editar_mascota.dart';
import 'package:patitas_care/notification_helper.dart';
import 'package:patitas_care/success_feedback_widget.dart';


class PetDetailPage extends StatefulWidget {
  final String mascotaId;
  
  const PetDetailPage({super.key, required this.mascotaId});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  Map<String, dynamic>? mascota;
  bool isLoading = true;
  bool _showSuccess = false;
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

    final token = await AuthService.getToken();

    if (token == null) {
      context.showErrorNotification(
        'Sesión expirada. Por favor inicia sesión nuevamente.',
        actionLabel: 'Ir a login',
        onAction: () => Navigator.pushReplacement(context, 
        MaterialPageRoute(builder: (context) => const LoginPage()),),
      );
      return;
    }

    try {
      final baseUrl = 'https://patitas-care.onrender.com';
      final response = await AuthService.authenticatedGet('$baseUrl/mascotas/mis-mascotas/${widget.mascotaId}');

      if (response.statusCode == 200) {
        setState(() {
          mascota = jsonDecode(response.body);
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
        onAction: () => cargarDetalleMascota(),
      );
    }
  }

  Future<void> eliminarMascota() async {
    final confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    setState(() {
      isLoading = true;
    });

    final token = await AuthService.getToken();

    if (token == null) {
      context.showErrorNotification(
        'Sesión expirada. Por favor inicia sesión nuevamente.',
        actionLabel: 'Ir a login',
        onAction: () => Navigator.pushReplacement(context, 
        MaterialPageRoute(builder: (context) => const LoginPage()),),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

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
        setState(() {
          _showSuccess = true;
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
        onAction: () => eliminarMascota(),
      );
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Confirmar eliminación',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${mascota?['nombre'] ?? 'esta mascota'}?\n\nEsta acción no se puede deshacer.',
          style: const TextStyle(
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _getReadableErrorMessage(String originalMessage) {
    // Convierte mensajes técnicos en mensajes amigables
    if (originalMessage.contains('401') || originalMessage.contains('Unauthorized')) {
      return 'Tu sesión ha expirado. Por favor inicia sesión nuevamente.';
    } else if (originalMessage.contains('403') || originalMessage.contains('Forbidden')) {
      return 'No tienes permisos para realizar esta acción.';
    } else if (originalMessage.contains('404') || originalMessage.contains('Not Found')) {
      return 'La mascota que buscas ya no existe o fue eliminada.';
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

  void _onSuccessComplete() {
    setState(() {
      _showSuccess = false;
    });
    
    // Navegar después de la animación
    Navigator.pop(context, true); // Retorna true para indicar que se eliminó
  }

  String _formatearSexo(String? sexo) {
    if (sexo == null || sexo.isEmpty) return 'No especificado';
    
    switch (sexo.toUpperCase()) {
      case 'HEMBRA':
        return 'Hembra';
      case 'MACHO':
        return 'Macho';
      case 'DESCONOCIDO':
        return 'Desconocido';
      default:
        return sexo;
    }
  }

  String _formatearEsterilizado(bool? esterilizado) {
    if (esterilizado == null) return 'No especificado';
    return esterilizado ? 'Sí' : 'No';
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'No especificada';
    
    try {
      final DateTime parsedDate = DateTime.parse(fecha);
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  String _formatearEdad(int? edad) {
    if (edad == null) return 'No especificada';
    return edad == 1 ? '$edad año' : '$edad años';
  }

  String _formatearTexto(String? texto) {
    return (texto == null || texto.isEmpty) ? 'No especificado' : texto;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SuccessFeedbackWidget(
        showSuccess: _showSuccess,
        successMessage: '¡Mascota eliminada!\nExitosamente',
        onComplete: _onSuccessComplete,
        child: Stack(
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8F88F2)),
                      ),
                    )
                  : mascota == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se pudo cargar la mascota',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Verifica tu conexión e intenta de nuevo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: cargarDetalleMascota,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
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
                                    _buildInfoField('Nombre:', mascota!['nombre'] ?? 'Sin nombre'),
                                    const SizedBox(height: 16),
                                    _buildInfoField('Especie:', _formatearTexto(mascota!['especie'])),
                                    const SizedBox(height: 16),
                                    _buildInfoField('Raza:', _formatearTexto(mascota!['raza'])),
                                    const SizedBox(height: 16),
                                    _buildInfoField('Sexo:', _formatearSexo(mascota!['sexo'])),
                                    const SizedBox(height: 16),
                                    _buildInfoField('Edad:', _formatearEdad(mascota!['edad'])),
                                    const SizedBox(height: 16),
                                    _buildInfoField('Fecha de nacimiento:', _formatearFecha(mascota!['fechaNacimiento'])),
                                    const SizedBox(height: 16),
                                    _buildInfoField('Color:', _formatearTexto(mascota!['color'])),
                                    const SizedBox(height: 16),
                                    _buildInfoField('¿Está esterilizado/a?:', _formatearEsterilizado(mascota!['esterilizado'])),
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
                                              ).then((result) {
                                                if (result == true) {
                                                  // Si se editó exitosamente, recargar datos
                                                  cargarDetalleMascota();
                                                  context.showSuccessNotification(
                                                    'Mascota actualizada exitosamente',
                                                  );
                                                }
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: purple,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 15),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(25),
                                              ),
                                            ),
                                            child: const Text(
                                              'Editar',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
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
                                            child: const Text(
                                              'Eliminar',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
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
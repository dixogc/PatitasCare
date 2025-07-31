import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:patitas_care/auth_service.dart';
import 'package:patitas_care/historialMedico/historial_medico.dart';
import 'package:patitas_care/historialMedico/historial_medico_detail_page.dart';
import 'package:patitas_care/notification_helper.dart';
import 'package:patitas_care/success_feedback_widget.dart';


class HistorialMedicoListPage extends StatefulWidget {
  final String mascotaId;
  final String mascotaNombre;

  const HistorialMedicoListPage({
    super.key,
    required this.mascotaId,
    required this.mascotaNombre,
  });

  @override
  State<HistorialMedicoListPage> createState() => _HistorialMedicoListPageState();
}

class _HistorialMedicoListPageState extends State<HistorialMedicoListPage> {
  List<HistorialMedico> historialList = [];
  bool isLoading = true;
  bool showSuccessAnimation = false;
  final Color purple = const Color(0xFF8F88F2);
  final Color yellow = const Color(0xFFF9DC5C);

  @override
  void initState() {
    super.initState();
    cargarHistorialMedico();
  }

  Future<void> cargarHistorialMedico() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final baseUrl = 'https://patitas-care.onrender.com';
      final response = await AuthService.authenticatedGet(
        '$baseUrl/historial-medico/mis-mascotas/${widget.mascotaId}'
      );
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          historialList = data.map((json) => HistorialMedico.fromJson(json)).toList();
          isLoading = false;
        });
        
        // Mostrar notificación de éxito solo si hay datos
        if (historialList.isNotEmpty) {
          context.showSuccessNotification(
            'Historial médico cargado correctamente (${historialList.length} registros)'
          );
        }
        
      } else if (response.statusCode == 200) {
        setState(() {
          historialList = [];
          isLoading = false;
        });
        
        context.showInfoNotification(
          'No hay registros en el historial médico de ${widget.mascotaNombre}',
          actionLabel: 'Agregar',
          onAction: () => _navegarACrearHistorial(),
        );
        
      } else if (response.statusCode == 404) {
        setState(() {
          historialList = [];
          isLoading = false;
        });
        
        context.showInfoNotification(
          'No se encontró historial médico para ${widget.mascotaNombre}',
          actionLabel: 'Crear primero',
          onAction: () => _navegarACrearHistorial(),
        );
        
      } else if (response.statusCode == 403) {
        setState(() {
          isLoading = false;
        });
        
        context.showErrorNotification(
          'No tienes permisos para ver este historial médico',
          actionLabel: 'Volver',
          onAction: () => Navigator.pop(context),
        );
        
      } else if (response.statusCode == 401) {
        setState(() {
          isLoading = false;
        });
        
        context.showErrorNotification(
          'Tu sesión ha expirado. Inicia sesión nuevamente',
          actionLabel: 'Iniciar sesión',
          onAction: () => Navigator.pushReplacementNamed(context, '/login'),
        );
        
      } else if (response.statusCode >= 500) {
        setState(() {
          isLoading = false;
        });
        
        context.showErrorNotification(
          'Error del servidor. Intenta nuevamente en unos minutos',
          actionLabel: 'Reintentar',
          onAction: () => cargarHistorialMedico(),
        );
        
      } else {
        throw Exception('Error al cargar historial médico: ${response.statusCode}');
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        // Determinar el tipo de error específico
        if (e.toString().contains('SocketException') || 
            e.toString().contains('TimeoutException')) {
          context.showErrorNotification(
            'Sin conexión a internet. Verifica tu conexión',
            actionLabel: 'Reintentar',
            onAction: () => cargarHistorialMedico(),
          );
        } else if (e.toString().contains('FormatException')) {
          context.showErrorNotification(
            'Error en el formato de datos recibidos del servidor',
            actionLabel: 'Reintentar',
            onAction: () => cargarHistorialMedico(),
          );
        } else {
          context.showErrorNotification(
            'Error inesperado al cargar el historial médico',
            actionLabel: 'Reintentar',
            onAction: () => cargarHistorialMedico(),
          );
        }
      }
    }
  }

  void _navegarACrearHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistorialMedicoDetailPage(
          mascotaId: widget.mascotaId,
          mascotaNombre: widget.mascotaNombre,
          historialId: null,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Se creó un nuevo registro exitosamente
        setState(() {
          showSuccessAnimation = true;
        });
        cargarHistorialMedico();
      } else {
        // Solo recargar sin animación
        cargarHistorialMedico();
      }
    });
  }

  void _navegarADetalleHistorial(String historialId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistorialMedicoDetailPage(
          mascotaId: widget.mascotaId,
          mascotaNombre: widget.mascotaNombre,
          historialId: historialId,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Se actualizó o eliminó un registro
        context.showSuccessNotification(
          'Historial médico actualizado'
        );
      }
      cargarHistorialMedico();
    });
  }

  void _onSuccessAnimationComplete() {
    setState(() {
      showSuccessAnimation = false;
    });
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  IconData getTipoEventoIcon(String tipoEvento) {
    String tipo = tipoEvento.toLowerCase();
    if (tipo.contains('vacun')) return Icons.vaccines;
    if (tipo.contains('consulta') || tipo.contains('revision')) return Icons.medical_services;
    if (tipo.contains('cirug') || tipo.contains('operac')) return Icons.healing;
    if (tipo.contains('emergen')) return Icons.emergency;
    if (tipo.contains('control') || tipo.contains('peso')) return Icons.monitor_weight;
    return Icons.health_and_safety;
  }

  Color getTipoEventoColor(String tipoEvento) {
    String tipo = tipoEvento.toLowerCase();
    if (tipo.contains('vacun')) return Colors.green;
    if (tipo.contains('consulta') || tipo.contains('revision')) return Colors.blue;
    if (tipo.contains('cirug') || tipo.contains('operac')) return Colors.red;
    if (tipo.contains('emergen')) return Colors.orange;
    if (tipo.contains('control') || tipo.contains('peso')) return purple;
    return Colors.grey;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Sin historial médico',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Comienza a registrar las visitas al veterinario, vacunas y tratamientos de ${widget.mascotaNombre}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navegarACrearHistorial,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Agregar primer registro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuccessFeedbackWidget(
      showSuccess: showSuccessAnimation,
      successMessage: '¡Registro agregado!',
      onComplete: _onSuccessAnimationComplete,
      child: Scaffold(
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
                  // Header mejorado
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 24),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.mascotaNombre,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.medical_services,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Historial Médico',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (!isLoading && historialList.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: purple.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${historialList.length} registros',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: purple,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Botón de refresh
                        if (!isLoading)
                          IconButton(
                            onPressed: cargarHistorialMedico,
                            icon: const Icon(Icons.refresh),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Contenido principal
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Cargando historial médico...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : historialList.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: cargarHistorialMedico,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: historialList.length,
                              itemBuilder: (context, index) {
                                final entrada = historialList[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 4,
                                  shadowColor: Colors.black.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _navegarADetalleHistorial(entrada.id),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Icono del tipo de evento
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: getTipoEventoColor(entrada.tipoEvento).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              getTipoEventoIcon(entrada.tipoEvento),
                                              size: 24,
                                              color: getTipoEventoColor(entrada.tipoEvento),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Información del evento
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  entrada.tipoEvento,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      formatDate(entrada.fechaEvento),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (entrada.veterinario != null) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person,
                                                        size: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          entrada.veterinario!,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          // Flecha
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey[400],
                                          ),
                                        ],
                                      ),
                                    ),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navegarACrearHistorial,
          backgroundColor: purple,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Agregar registro'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
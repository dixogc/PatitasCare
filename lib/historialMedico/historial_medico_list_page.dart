import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:patitas_care/auth_service.dart';
import 'package:patitas_care/historialMedico/historial_medico.dart';
import 'package:patitas_care/historialMedico/historial_medico_detail_page.dart';


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
  final Color purple = const Color(0xFF8F88F2);
  final Color yellow = const Color(0xFFF9DC5C);

  @override
  void initState() {
    super.initState();
    cargarHistorialMedico();
  }

  Future<void> cargarHistorialMedico() async {
    if (!mounted) return; // Verificar antes de empezar
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final baseUrl = 'https://patitas-care.onrender.com';
      final response = await AuthService.authenticatedGet(
        '$baseUrl/historial-medico/mis-mascotas/${widget.mascotaId}'
      );
      
      if (!mounted) return; // Verificar después de la operación async
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          historialList = data.map((json) => HistorialMedico.fromJson(json)).toList();
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          historialList = []; 
          isLoading = false;
        });
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos para ver este historial')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Error al cargar historial médico');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error inesperado al cargar el historial')),
        );
      }
    }
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
                            Text(
                              'Historial Médico',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenido principal
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : historialList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sin historial médico',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agrega el primer registro del\nhistorial médico de ${widget.mascotaNombre}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: cargarHistorialMedico,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: historialList.length,
                            itemBuilder: (context, index) {
                              final entrada = historialList[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: getTipoEventoColor(entrada.tipoEvento).withOpacity(0.2),
                                    radius: 25,
                                    child: Icon(
                                      getTipoEventoIcon(entrada.tipoEvento),
                                      size: 24,
                                      color: getTipoEventoColor(entrada.tipoEvento),
                                    ),
                                  ),
                                  title: Text(
                                    entrada.tipoEvento,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
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
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (entrada.veterinario != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              entrada.veterinario!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
                                        builder: (context) => HistorialMedicoDetailPage(
                                          mascotaId: widget.mascotaId,
                                          mascotaNombre: widget.mascotaNombre,
                                          historialId: entrada.id,
                                        ),
                                      ),
                                    ).then((_) => cargarHistorialMedico());
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistorialMedicoDetailPage(
                mascotaId: widget.mascotaId,
                mascotaNombre: widget.mascotaNombre,
                historialId: null, // null indica nueva entrada
              ),
            ),
          ).then((_) => cargarHistorialMedico());
        },
        backgroundColor: purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
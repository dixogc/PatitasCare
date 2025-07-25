import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:patitas_care/auth_service.dart';
import 'package:patitas_care/historialMedico/historial_medico.dart';


class HistorialMedicoDetailPage extends StatefulWidget {
  final String mascotaId;
  final String mascotaNombre;
  final String? historialId;

  const HistorialMedicoDetailPage({
    super.key,
    required this.mascotaId,
    required this.mascotaNombre,
    this.historialId,
  });

  @override
  State<HistorialMedicoDetailPage> createState() => _HistorialMedicoDetailPageState();
}

class _HistorialMedicoDetailPageState extends State<HistorialMedicoDetailPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _tipoEventoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _diagnosticoController = TextEditingController();
  final TextEditingController _tratamientoController = TextEditingController();
  final TextEditingController _veterinarioController = TextEditingController();

  DateTime _fechaEvento = DateTime.now();
  DateTime? _fechaProximaRevision;
  
  bool isLoading = false;
  bool isEditing = false;
  HistorialMedico? historialActual;

  final Color purple = const Color(0xFF8F88F2);
  final Color yellow = const Color(0xFFFFDD4A);

  bool get isNewEntry => widget.historialId == null;

  @override
  void initState() {
    super.initState();
    if (!isNewEntry) {
      cargarHistorialMedico();
    } else {
      isEditing = true;
    }
  }

  Future<void> cargarHistorialMedico() async {
    setState(() {
      isLoading = true;
    });

    try {
      final baseUrl = 'https://patitas-care.onrender.com';
      final response = await AuthService.authenticatedGet(
        '$baseUrl/historial-medico/mis-mascotas/${widget.mascotaId}/${widget.historialId}'
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        historialActual = HistorialMedico.fromJson(data);
        _llenarFormulario();
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos para ver esta entrada')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Entrada no encontrada');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      Navigator.pop(context);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _llenarFormulario() {
    if (historialActual != null) {
      _tipoEventoController.text = historialActual!.tipoEvento;
      _descripcionController.text = historialActual!.descripcion ?? '';
      _pesoController.text = historialActual!.peso?.toString() ?? '';
      _diagnosticoController.text = historialActual!.diagnostico ?? '';
      _tratamientoController.text = historialActual!.tratamiento ?? '';
      _veterinarioController.text = historialActual!.veterinario ?? '';
      _fechaEvento = historialActual!.fechaEvento;
      _fechaProximaRevision = historialActual!.fechaProximaRevision;
    }
  }

  Future<void> _guardarHistorial() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final request = HistorialMedicoRequest(
        fechaEvento: _fechaEvento,
        tipoEvento: _tipoEventoController.text,
        descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
        peso: _pesoController.text.isEmpty ? null : double.tryParse(_pesoController.text),
        diagnostico: _diagnosticoController.text.isEmpty ? null : _diagnosticoController.text,
        tratamiento: _tratamientoController.text.isEmpty ? null : _tratamientoController.text,
        fechaProximaRevision: _fechaProximaRevision,
        veterinario: _veterinarioController.text.isEmpty ? null : _veterinarioController.text,
      );

      // Validar usando el modelo
      final errors = request.validateAll();
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errors.first)),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final baseUrl = 'https://patitas-care.onrender.com';
      http.Response response;

      if (isNewEntry) {
        // Crear nueva entrada
        response = await AuthService.authenticatedPost(
          '$baseUrl/historial-medico/mis-mascotas/${widget.mascotaId}',
          body: request.toJson(),
        );
      } else {
        // Actualizar entrada existente
        final url = Uri.parse('$baseUrl/historial-medico/mis-mascotas/${widget.mascotaId}/${widget.historialId}');
        final headers = await AuthService.getAuthHeaders();
        response = await http.put(
          url,
          headers: headers,
          body: jsonEncode(request.toJson()),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNewEntry 
              ? 'Historial creado exitosamente'
              : 'Historial actualizado exitosamente'),
          ),
        );
        Navigator.pop(context);
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos para esta acción')),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['mensaje'] ?? 'Error al guardar');
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

  Future<void> _eliminarHistorial() async {
    if (isNewEntry) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta entrada del historial médico?'),
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

    setState(() {
      isLoading = true;
    });

    try {
      final baseUrl = 'https://patitas-care.onrender.com';
      final url = Uri.parse('$baseUrl/historial-medico/mis-mascotas/${widget.mascotaId}/${widget.historialId}');
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrada eliminada exitosamente')),
        );
        Navigator.pop(context);
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos para eliminar esta entrada')),
        );
      } else {
        throw Exception('Error al eliminar');
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

  Future<void> _selectDate(BuildContext context, {required bool isProximaRevision}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isProximaRevision 
        ? (_fechaProximaRevision ?? DateTime.now().add(const Duration(days: 30)))
        : _fechaEvento,
      firstDate: isProximaRevision ? DateTime.now() : DateTime(2000),
      lastDate: isProximaRevision ? DateTime(2030) : DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isProximaRevision) {
          _fechaProximaRevision = picked;
        } else {
          _fechaEvento = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _tipoEventoController.dispose();
    _descripcionController.dispose();
    _pesoController.dispose();
    _diagnosticoController.dispose();
    _tratamientoController.dispose();
    _veterinarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo decorativo con wave
          Container(
            color: const Color(0xFFB6A9F8), // El mismo morado del wave original
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
                              isNewEntry 
                                ? 'Nueva Actualización'
                                : (isEditing ? 'Editar Entrada' : 'Ver Entrada'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              widget.mascotaNombre,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isNewEntry && !isEditing)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.edit, size: 24),
                        ),
                      if (!isNewEntry)
                        IconButton(
                          onPressed: _eliminarHistorial,
                          icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                        ),
                    ],
                  ),
                ),
                // Contenido
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Fecha del evento
                                const Text(
                                  'Fecha de consulta *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: isEditing ? () => _selectDate(context, isProximaRevision: false) : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isEditing ? const Color(0xFFF4F5F8) : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: isEditing ? Colors.grey[700] : Colors.grey[500],
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(_fechaEvento),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isEditing ? Colors.black : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Tipo de evento
                                _buildTextField(
                                  'Motivo de consulta *',
                                  _tipoEventoController,
                                  enabled: isEditing,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'El tipo de evento es obligatorio';
                                    }
                                    if (value.length > 100) {
                                      return 'El tipo de evento no puede exceder 100 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Peso
                                _buildTextField(
                                  'Peso (kg)',
                                  _pesoController,
                                  enabled: isEditing,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final peso = double.tryParse(value);
                                      if (peso == null) {
                                        return 'Ingresa un peso válido';
                                      }
                                      if (peso < 0.1) {
                                        return 'El peso debe ser mayor a 0.1 kg';
                                      }
                                      if (peso > 200.0) {
                                        return 'El peso no puede exceder 200 kg';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Veterinario
                                _buildTextField(
                                  'Veterinario o establecimiento',
                                  _veterinarioController,
                                  enabled: isEditing,
                                  validator: (value) {
                                    if (value != null && value.length > 100) {
                                      return 'El nombre del veterinario no puede exceder 100 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Descripción
                                _buildTextField(
                                  'Descripción (síntomas, padecimientos)',
                                  _descripcionController,
                                  enabled: isEditing,
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value != null && value.length > 1000) {
                                      return 'La descripción no puede exceder 1000 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Diagnóstico
                                _buildTextField(
                                  'Diagnóstico',
                                  _diagnosticoController,
                                  enabled: isEditing,
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value != null && value.length > 1000) {
                                      return 'El diagnóstico no puede exceder 1000 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Tratamiento
                                _buildTextField(
                                  'Tratamiento',
                                  _tratamientoController,
                                  enabled: isEditing,
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value != null && value.length > 1000) {
                                      return 'El tratamiento no puede exceder 1000 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Fecha próxima revisión
                                const Text(
                                  'Fecha próxima de revisión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: isEditing ? () => _selectDate(context, isProximaRevision: true) : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isEditing ? const Color(0xFFF4F5F8) : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: isEditing ? Colors.grey[700] : Colors.grey[500],
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _fechaProximaRevision != null
                                              ? DateFormat('dd/MM/yyyy').format(_fechaProximaRevision!)
                                              : 'Sin fecha programada',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: _fechaProximaRevision != null
                                                ? (isEditing ? Colors.black : Colors.grey[600])
                                                : Colors.grey[500],
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isEditing && _fechaProximaRevision != null)
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _fechaProximaRevision = null;
                                              });
                                            },
                                            icon: const Icon(Icons.clear, size: 20),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // Botones de acción
                                if (isEditing) ...[
                                  Row(
                                    children: [
                                      if (!isNewEntry)
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                isEditing = false;
                                                _llenarFormulario(); // Restaurar valores originales
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey[300],
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                            ),
                                            child: const Text('CANCELAR'),
                                          ),
                                        ),
                                      if (!isNewEntry) const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _guardarHistorial,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: yellow,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: Text(
                                            isNewEntry ? 'CREAR HISTORIAL' : 'GUARDAR CAMBIOS',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? const Color(0xFFF4F5F8) : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: TextStyle(
            color: enabled ? Colors.black : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Reutilizar el WaveClipper de la pantalla de registro
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
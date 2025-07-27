import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:patitas_care/auth_service.dart';
import 'package:patitas_care/historialMedico/historial_medico.dart';
import 'package:patitas_care/success_feedback_widget.dart';
import 'package:patitas_care/notification_helper.dart';


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
  bool _showSuccess = false;
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
        setState(() {
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
      
      if (e.toString().contains('403')) {
        context.showErrorNotification(
          'No tienes permisos para ver este historial',
          actionLabel: 'Volver',
          onAction: () => Navigator.pop(context),
        );
      } else {
        context.showErrorNotification(
          errorMessage,
          actionLabel: 'Reintentar',
          onAction: () => cargarHistorialMedico(),
        );
      }
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
      context.showWarningNotification(
        'Por favor corrige los errores en el formulario'
      );
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
        context.showErrorNotification(
          errors.first,
          actionLabel: 'Entendido',
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
        onAction: () => _guardarHistorial(),
      );
    }
  }

  Future<void> _eliminarHistorial() async {
    if (isNewEntry) return;

    final confirmed = await _showConfirmationDialog();
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
      
      if (e.toString().contains('403')) {
        context.showErrorNotification(
          'No tienes permisos para eliminar este historial médico'
        );
      } else {
        context.showErrorNotification(
          errorMessage,
          actionLabel: 'Reintentar',
          onAction: () => _eliminarHistorial(),
        );
      }
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
        content: const Text(
          '¿Estás seguro de que quieres eliminar este registro del historial médico?\n\nEsta acción no se puede deshacer.',
          style: TextStyle(
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
      return 'El historial médico que buscas ya no existe.';
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
    
    // Mensaje específico según la acción y navegación
    // ignore: unused_local_variable
    final message = isNewEntry 
        ? 'Historial médico creado exitosamente'
        : (!isEditing && widget.historialId != null) 
            ? 'Historial médico eliminado exitosamente'
            : 'Historial médico actualizado exitosamente';
    
    Navigator.pop(context, true);
  }

  Future<void> _selectDate(BuildContext context, {required bool isProximaRevision}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isProximaRevision 
        ? (_fechaProximaRevision ?? DateTime.now().add(const Duration(days: 30)))
        : _fechaEvento,
      firstDate: isProximaRevision ? DateTime.now() : DateTime(2000),
      lastDate: isProximaRevision ? DateTime(2030) : DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: purple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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
      body: SuccessFeedbackWidget(
        showSuccess: _showSuccess,
        successMessage: isNewEntry 
            ? '¡Historial creado!\nExitosamente'
            : (!isEditing && widget.historialId != null)
                ? '¡Historial eliminado!\nExitosamente'
                : '¡Historial actualizado!\nExitosamente',
        onComplete: _onSuccessComplete,
        child: Stack(
          children: [
            // Fondo decorativo con wave
            Container(
              color: const Color(0xFFB6A9F8),
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
                                  : (isEditing ? 'Editar Historial' : 'Ver Historial'),
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
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8F88F2)),
                            ),
                          )
                        : historialActual == null && !isNewEntry
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
                                      'No se pudo cargar el historial',
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
                                      onPressed: cargarHistorialMedico,
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
                                            border: Border.all(
                                              color: Colors.grey.withOpacity(0.3),
                                            ),
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
                                            border: Border.all(
                                              color: Colors.grey.withOpacity(0.3),
                                            ),
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
                                                  child: const Text(
                                                    'CANCELAR',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (!isNewEntry) const SizedBox(width: 16),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: isLoading ? null : _guardarHistorial,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: yellow,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                ),
                                                child: isLoading
                                                    ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                        ),
                                                      )
                                                    : Text(
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: purple,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
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
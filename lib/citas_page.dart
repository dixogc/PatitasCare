import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:patitas_care/auth_service.dart';
import 'package:patitas_care/inicio_page.dart';
import 'package:patitas_care/notification_helper.dart';
import 'package:patitas_care/success_feedback_widget.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'notification_service.dart';


class CitasPage extends StatefulWidget {
  const CitasPage({super.key});

  @override
  State<CitasPage> createState() => _CitasPageState();
}

class _CitasPageState extends State<CitasPage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _motivoController = TextEditingController();
  String? _selectedMascotaId;
  List<Map<String, dynamic>> _mascotas = [];
  List<Map<String, dynamic>> _citas = [];
  bool _isLoading = false;
  bool _isLoadingCitas = false;
  int _selectedTabIndex = 0;
  
  // Variables para el feedback de éxito
  bool _showSuccessFeedback = false;
  String _successMessage = '';

  // Variables para filtros
  String _filtroEstado = 'TODAS';
  final List<String> _estadosDisponibles = ['TODAS', 'PENDIENTE', 'COMPLETADA', 'CANCELADA'];

  // Variables para edición
  bool _isEditMode = false;
  String? _editingCitaId;
  Map<String, dynamic>? _citaEditando;

  @override
  void initState() {
    super.initState();
    _inicializar(); 
  }

  void _inicializar() async {
    await NotificationService.initialize();
    await NotificationService.verificarYSolicitarPermisos(context);
    await _cargarMascotas();
    await _cargarCitas();
  }

  Future<void> _cargarMascotas() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        context.showErrorNotification('Sesión expirada. Inicia sesión nuevamente');
        return;
      }

      final response = await http.get(
        Uri.parse('https://patitas-care.onrender.com/mascotas/mis-mascotas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> mascotasData = json.decode(response.body);
        setState(() {
          _mascotas = mascotasData.map((mascota) => {
            'id': mascota['id'].toString(),
            'nombre': mascota['nombre'].toString(),
          }).toList();
        });

        if (_mascotas.isEmpty) {
          context.showInfoNotification(
            'No tienes mascotas registradas',
            actionLabel: 'Registrar',
            onAction: () {
              // Navegar a registro de mascotas
            },
          );
        }
      } else {
        context.showErrorNotification('Error al cargar tus mascotas');
      }
    } catch (e) {
      print('Error al cargar mascotas: $e');
      context.showErrorNotification(
        'Error de conexión al cargar mascotas',
        actionLabel: 'Reintentar',
        onAction: () => _cargarMascotas(),
      );
    }
  }

  Future<void> _cargarCitas() async {
    setState(() {
      _isLoadingCitas = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        context.showErrorNotification('Sesión expirada. Inicia sesión nuevamente');
        return;
      }

      // Usar el endpoint que incluye citas canceladas para tener todos los datos
      final response = await http.get(
        Uri.parse('https://patitas-care.onrender.com/citas/mis-citas/todas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> citasData = json.decode(response.body);
        setState(() {
          _citas = citasData.map((cita) => {
            'id': cita['id'].toString(),
            'mascotaNombre': cita['mascotaNombre'].toString(),
            'motivo': cita['motivo'].toString(),
            'fechaHora': cita['fechaHora'].toString(),
            'estado': cita['estado'].toString(),
            'veterinarioNombre': cita['veterinarioNombre']?.toString() ?? 'No asignado',
          }).toList();
        });
      } else {
        context.showWarningNotification('No se pudieron cargar las citas');
      }
    } catch (e) {
      print('Error al cargar citas: $e');
      context.showErrorNotification(
        'Error al cargar las citas',
        actionLabel: 'Reintentar',
        onAction: () => _cargarCitas(),
      );
    } finally {
      setState(() {
        _isLoadingCitas = false;
      });
    }
  }

  Future<void> _agendarCita() async {
    final String motivo = _motivoController.text.trim();

    if (motivo.isEmpty || _selectedMascotaId == null) {
      context.showWarningNotification('Por favor completa todos los campos requeridos');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? token = await AuthService.getToken();

      if (token == null) {
        context.showErrorNotification('Error de autenticación. Inicia sesión nuevamente');
        return;
      }

      final DateTime fechaCita = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (fechaCita.isBefore(DateTime.now())) {
        context.showWarningNotification('La fecha y hora debe ser futura');
        return;
      }

      final String fechaFormateada = DateFormat("yyyy-MM-dd'T'HH:mm").format(fechaCita);

      final Map<String, dynamic> citaData = {
        'mascotaId': _selectedMascotaId,
        'fechaHora': fechaFormateada,
        'motivo': motivo,
      };

      final response = await http.post(
        Uri.parse('https://patitas-care.onrender.com/citas/agendar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(citaData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final Map<String, dynamic> citaResponse = json.decode(response.body);
        final mascotaNombre = _mascotas.firstWhere((m) => m['id'] == _selectedMascotaId)['nombre'];
        
        // Mostrar feedback de éxito animado
        setState(() {
          _showSuccessFeedback = true;
          _successMessage = '¡Cita agendada!';
        });
        
        // Programar notificaciones
        final bool notificacionProgramada = await NotificationService.programarNotificacionCita(
          citaId: citaResponse['id'],
          titulo: 'Recordatorio: Cita de $mascotaNombre',
          cuerpo: 'Motivo: ${citaResponse['motivo']}',
          fechaCita: fechaCita,
          mascotaId: _selectedMascotaId,
        );

        if (notificacionProgramada) {
          context.showSuccessNotification('Recordatorios programados correctamente');
        } else {
          context.showWarningNotification('Cita agendada, pero no se pudieron programar los recordatorios');
        }
        
        _limpiarCampos();
        await _cargarCitas(); // Recargar la lista de citas
        
        // Cambiar a la pestaña de citas después del feedback
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _selectedTabIndex = 1;
            });
          }
        });
        
      } else {
        try {
          final errorData = json.decode(response.body);
          context.showErrorNotification(
            errorData['message'] ?? 'Error al agendar la cita',
            actionLabel: 'Reintentar',
            onAction: () => _agendarCita(),
          );
        } catch (e) {
          context.showErrorNotification('Error inesperado del servidor');
        }
      }
    } on TimeoutException {
      context.showErrorNotification(
        'Tiempo de espera agotado',
        actionLabel: 'Reintentar',
        onAction: () => _agendarCita(),
      );
    } catch (e) {
      context.showErrorNotification(
        'Error de conexión. Verifica tu internet',
        actionLabel: 'Reintentar',
        onAction: () => _agendarCita(),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarCita() async {
    if (_editingCitaId == null || _citaEditando == null) return;

    final String motivo = _motivoController.text.trim();

    if (motivo.isEmpty || _selectedMascotaId == null) {
      context.showWarningNotification('Por favor completa todos los campos requeridos');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? token = await AuthService.getToken();

      if (token == null) {
        context.showErrorNotification('Error de autenticación. Inicia sesión nuevamente');
        return;
      }

      final DateTime fechaCita = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (fechaCita.isBefore(DateTime.now())) {
        context.showWarningNotification('La fecha y hora debe ser futura');
        return;
      }

      final String fechaFormateada = DateFormat("yyyy-MM-dd'T'HH:mm").format(fechaCita);

      final Map<String, dynamic> citaData = {
        'mascotaId': _selectedMascotaId,
        'fechaHora': fechaFormateada,
        'motivo': motivo,
      };

      final response = await http.put(
        Uri.parse('https://patitas-care.onrender.com/citas/$_editingCitaId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(citaData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> citaResponse = json.decode(response.body);
        final mascotaNombre = _mascotas.firstWhere((m) => m['id'] == _selectedMascotaId)['nombre'];
        
        // Mostrar feedback de éxito
        setState(() {
          _showSuccessFeedback = true;
          _successMessage = '¡Cita actualizada!';
        });
        
        // Actualizar notificaciones
        final bool notificacionActualizada = await NotificationService.actualizarNotificacionesCita(
          citaId: _editingCitaId!,
          titulo: 'Recordatorio: Cita de $mascotaNombre',
          cuerpo: 'Motivo: ${citaResponse['motivo']}',
          fechaCita: fechaCita,
          mascotaId: _selectedMascotaId,
        );

        if (notificacionActualizada) {
          context.showSuccessNotification('Cita y recordatorios actualizados');
        } else {
          context.showWarningNotification('Cita actualizada, pero no se pudieron actualizar los recordatorios');
        }
        
        _cancelarEdicion();
        await _cargarCitas(); // Recargar la lista de citas
        
        // Cambiar a la pestaña de citas
        setState(() {
          _selectedTabIndex = 1;
        });
        
      } else {
        try {
          final errorData = json.decode(response.body);
          context.showErrorNotification(
            errorData['message'] ?? 'Error al actualizar la cita',
            actionLabel: 'Reintentar',
            onAction: () => _actualizarCita(),
          );
        } catch (e) {
          context.showErrorNotification('Error inesperado del servidor');
        }
      }
    } on TimeoutException {
      context.showErrorNotification(
        'Tiempo de espera agotado',
        actionLabel: 'Reintentar',
        onAction: () => _actualizarCita(),
      );
    } catch (e) {
      context.showErrorNotification(
        'Error de conexión. Verifica tu internet',
        actionLabel: 'Reintentar',
        onAction: () => _actualizarCita(),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelarCita(String citaId) async {
    // Mostrar confirmación
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cancelar Cita'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final String? token = await AuthService.getToken();
      if (token == null) {
        context.showErrorNotification('Sesión expirada');
        return;
      }

      final response = await http.delete(
        Uri.parse('https://patitas-care.onrender.com/citas/$citaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Cancelar notificaciones
        await NotificationService.cancelarNotificacionesCita(citaId);
        
        context.showSuccessNotification('Cita cancelada correctamente');
        await _cargarCitas();
      } else {
        final errorData = json.decode(response.body);
        context.showErrorNotification(
          errorData['message'] ?? 'Error al cancelar la cita',
        );
      }
    } catch (e) {
      context.showErrorNotification('Error de conexión');
    }
  }

  Future<void> _marcarComoCompletada(String citaId) async {
    try {
      final String? token = await AuthService.getToken();
      if (token == null) {
        context.showErrorNotification('Sesión expirada');
        return;
      }

      final response = await http.patch(
        Uri.parse('https://patitas-care.onrender.com/citas/$citaId/completar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        context.showSuccessNotification('Cita marcada como completada');
        await _cargarCitas();
      } else {
        final errorData = json.decode(response.body);
        context.showErrorNotification(
          errorData['message'] ?? 'Error al completar la cita',
        );
      }
    } catch (e) {
      context.showErrorNotification('Error de conexión');
    }
  }

  void _iniciarEdicion(Map<String, dynamic> cita) {
  try {
    setState(() {
      _isEditMode = true;
      _editingCitaId = cita['id'];
      _citaEditando = cita;
      _selectedTabIndex = 0;
      
      _motivoController.text = cita['motivo'] ?? '';
      
      final mascotaNombre = cita['mascotaNombre'];
      Map<String, dynamic>? mascotaEncontrada;
      
      try {
        mascotaEncontrada = _mascotas.firstWhere(
          (m) => m['nombre'] == mascotaNombre,
        );
        _selectedMascotaId = mascotaEncontrada['id'];
      } catch (e) {
        print('No se encontró la mascota: $mascotaNombre');
        print('Mascotas disponibles: ${_mascotas.map((m) => m['nombre']).join(', ')}');
        
        // Fallback: usar la primera mascota disponible
        if (_mascotas.isNotEmpty) {
          _selectedMascotaId = _mascotas.first['id'];
          context.showWarningNotification(
            'No se encontró la mascota "$mascotaNombre". Se seleccionó "${_mascotas.first['nombre']}".'
          );
        } else {
          _selectedMascotaId = null;
          context.showErrorNotification('No hay mascotas disponibles');
        }
      }
      
      try {
        final DateTime fechaCita = DateTime.parse(cita['fechaHora']);
        _selectedDate = fechaCita;
        _selectedTime = TimeOfDay.fromDateTime(fechaCita);
      } catch (e) {
        print('Error al parsear fecha: ${cita['fechaHora']}');
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
        context.showWarningNotification('Error al cargar la fecha. Se usará la fecha actual.');
      }
    });
  } catch (e) {
    print('Error en _iniciarEdicion: $e');
    context.showErrorNotification('Error al cargar los datos de la cita');
  }
}

  void _cancelarEdicion() {
    setState(() {
      _isEditMode = false;
      _editingCitaId = null;
      _citaEditando = null;
    });
    _limpiarCampos();
  }

  void _onSuccessComplete() {
    setState(() {
      _showSuccessFeedback = false;
    });
  }

  Future<void> _seleccionarHora(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('en', 'US'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: false,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                useMaterial3: false,
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF8B5CF6), 
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                  background: Colors.white,
                ),
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: Colors.white,
                  elevation: 8, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), 
                  ),
                  
                  dialBackgroundColor: Colors.white,
                  dialHandColor: const Color(0xFF8B5CF6), 
                  dialTextColor: Colors.black87,
                  dialTextStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  
                  hourMinuteColor: MaterialStateColor.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return const Color(0xFF8B5CF6); 
                    }
                    return const Color(0xFFF5F5F5); 
                  }),
                  hourMinuteTextColor: MaterialStateColor.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white; 
                    }
                    return Colors.black87; 
                  }),
                  hourMinuteTextStyle: const TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.w300, 
                  ),
                  hourMinuteShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), 
                  ),
                  
                  dayPeriodColor: MaterialStateColor.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return const Color(0xFF00E5FF); 
                    }
                    return Colors.transparent; 
                  }),
                  dayPeriodTextColor: MaterialStateColor.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white; 
                    }
                    return Colors.black54; 
                  }),
                  dayPeriodTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  dayPeriodShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  dayPeriodBorderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  
                  helpTextStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                  
                  cancelButtonStyle: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  confirmButtonStyle: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6), 
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B5CF6),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16, 
                    ),
                    constraints: const BoxConstraints(
                      minHeight: 56,
                    ),
                  ),
                  
                  entryModeIconColor: const Color(0xFF8B5CF6),
                ),
              ),
              child: child!,
            ),
          ),
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  void _limpiarCampos() {
    _motivoController.clear();
    setState(() {
      _selectedMascotaId = null;
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    });
  }

  String _formatearFecha(String fechaHora) {
    try {
      final DateTime fecha = DateTime.parse(fechaHora);
      return DateFormat('dd/MM/yyyy - HH:mm').format(fecha);
    } catch (e) {
      return fechaHora;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.blue;
      case 'COMPLETADA':
        return Colors.green;
      case 'CANCELADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getCitasFiltradas() {
    if (_filtroEstado == 'TODAS') {
      return _citas;
    }
    return _citas.where((cita) => cita['estado'] == _filtroEstado).toList();
  }

  Widget _buildMascotaDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _mascotas.isEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Icon(Icons.pets, color: Color(0xFF6B7280)),
                  SizedBox(width: 12),
                  Text(
                    'Cargando mascotas...',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : DropdownButtonFormField<String>(
              value: _selectedMascotaId,
              hint: const Row(
                children: [
                  Icon(Icons.pets, color: Color(0xFF6B7280)),
                  SizedBox(width: 12),
                  Text(
                    'Selecciona tu mascota',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B5CF6),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              dropdownColor: Colors.white,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF6B7280),
              ),
              isExpanded: true,
              items: _mascotas.map<DropdownMenuItem<String>>((mascota) {
                return DropdownMenuItem<String>(
                  value: mascota['id'],
                  child: Row(
                    children: [
                      const Icon(
                        Icons.pets,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        mascota['nombre'],
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMascotaId = newValue;
                });
              },
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
          labelStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF8B5CF6),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFiltroEstados() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _estadosDisponibles.length,
        itemBuilder: (context, index) {
          final estado = _estadosDisponibles[index];
          final isSelected = _filtroEstado == estado;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(estado),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filtroEstado = estado;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
              checkmarkColor: const Color(0xFF8B5CF6),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF6B7280),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCitaCard(Map<String, dynamic> cita) {
    final String estado = cita['estado'];
    final bool isCancelada = estado == 'CANCELADA';
    final bool isPendiente = estado == 'PENDIENTE';
    // ignore: unused_local_variable
    final bool isCompletada = estado == 'COMPLETADA';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCancelada 
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estado,
                    style: TextStyle(
                      color: _getEstadoColor(estado),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (isPendiente) ...[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                    onSelected: (value) {
                      switch (value) {
                        case 'editar':
                          _iniciarEdicion(cita);
                          break;
                        case 'completar':
                          _marcarComoCompletada(cita['id']);
                          break;
                        case 'cancelar':
                          _cancelarCita(cita['id']);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Color(0xFF8B5CF6)),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'completar',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Marcar completada'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'cancelar',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Cancelar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Icon(
                    Icons.pets,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              cita['mascotaNombre'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCancelada 
                    ? const Color(0xFF6B7280) 
                    : const Color(0xFF1F2937),
                decoration: isCancelada ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cita['motivo'],
              style: TextStyle(
                fontSize: 16,
                color: isCancelada 
                    ? const Color(0xFF9CA3AF) 
                    : const Color(0xFF6B7280),
                decoration: isCancelada ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.grey[500],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatearFecha(cita['fechaHora']),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (cita['veterinarioNombre'] != 'No asignado') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.local_hospital,
                    color: Colors.grey[500],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Dr. ${cita['veterinarioNombre']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAgendarTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Header para modo edición
          if (_isEditMode) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Editando cita',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _cancelarEdicion,
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Calendario
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar(
              focusedDay: _selectedDate,
              firstDay: DateTime.now(),
              lastDay: DateTime.utc(2100),
              selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                });
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(
                  color: Color(0xFF6B7280),
                ),
                defaultTextStyle: const TextStyle(
                  color: Color(0xFF1F2937),
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildMascotaDropdown(),
          const SizedBox(height: 16),

          _buildTextField(
            _motivoController,
            'Motivo de la cita',
            Icons.medical_services,
          ),
          const SizedBox(height: 16),

          // Selección de hora
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Hora:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _seleccionarHora(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Cambiar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Botón principal
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (_isEditMode ? _actualizarCita : _agendarCita),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isEditMode ? 'Actualizar Cita' : 'Agendar Cita',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCitasTab() {
    final citasFiltradas = _getCitasFiltradas();
    
    return Column(
      children: [
        // Filtros de estado
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _buildFiltroEstados(),
        ),
        const SizedBox(height: 8),
        
        // Lista de citas
        Expanded(
          child: _isLoadingCitas
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                  ),
                )
              : citasFiltradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filtroEstado == 'TODAS' 
                                ? 'No tienes citas programadas'
                                : 'No tienes citas con estado $_filtroEstado',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _filtroEstado == 'TODAS' 
                                ? 'Agenda tu primera cita usando la pestaña anterior'
                                : 'Cambia el filtro para ver otras citas',
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
                      onRefresh: _cargarCitas,
                      child: ListView.builder(
                        itemCount: citasFiltradas.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final cita = citasFiltradas[index];
                          return _buildCitaCard(cita);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SuccessFeedbackWidget(
        showSuccess: _showSuccessFeedback,
        successMessage: _successMessage,
        onComplete: _onSuccessComplete,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.transparent,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const InicioPage()),
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Citas Veterinarias',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = 0;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? const Color(0xFF8B5CF6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEditMode ? Icons.edit : Icons.add_circle_outline,
                                color: _selectedTabIndex == 0
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEditMode ? 'Editar' : 'Agendar',
                                style: TextStyle(
                                  color: _selectedTabIndex == 0
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_isEditMode) {
                            _cancelarEdicion();
                          }
                          setState(() {
                            _selectedTabIndex = 1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? const Color(0xFF8B5CF6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: _selectedTabIndex == 1
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mis Citas',
                                style: TextStyle(
                                  color: _selectedTabIndex == 1
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
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

              const SizedBox(height: 20),

              // Tab Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: _selectedTabIndex == 0
                      ? _buildAgendarTab()
                      : _buildCitasTab(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }
}

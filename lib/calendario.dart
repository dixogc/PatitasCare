import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:patitas_care/inicio_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'auth_service.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificacionCalendarPage extends StatefulWidget {
  const NotificacionCalendarPage({super.key});

  @override
  State<NotificacionCalendarPage> createState() =>
      _NotificacionCalendarPageState();
}

class _NotificacionCalendarPageState extends State<NotificacionCalendarPage> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _motivoController = TextEditingController();
  String? _selectedMascotaId;
  List<Map<String, dynamic>> _mascotas = [];
  List<Map<String, dynamic>> _citas = [];
  bool _isLoading = false;
  bool _isLoadingCitas = false;
  bool _permisosVerificados = false;
  int _selectedTabIndex = 0; // 0 para agendar, 1 para ver citas

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _inicializar();
  }

  void _inicializar() async {
    await inicializarNotificaciones();
    await _verificarPermisoAlarmasUnaVez();
    await _cargarMascotas();
    await _cargarCitas();
  }

  Future<void> inicializarNotificaciones() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _verificarPermisoAlarmasUnaVez() async {
    if (_permisosVerificados) return;
    
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 31) {
        // Solo mostrar si realmente no tiene permisos
        final prefs = await SharedPreferences.getInstance();
        final permisoVerificado = prefs.getBool('permiso_alarmas_verificado') ?? false;
        
        if (!permisoVerificado) {
          final shouldShowDialog = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Color(0xFF8B5CF6)),
                    SizedBox(width: 8),
                    Text('Permisos de Notificación'),
                  ],
                ),
                content: Text(
                  'Para recibir recordatorios de citas, necesitamos permisos de notificación. ¿Deseas configurarlos ahora?',
                  style: TextStyle(fontSize: 16),
                  softWrap: true,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text('Más tarde'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: Text('Configurar'),
                  ),
                ],
              );
            },
          );

          if (shouldShowDialog == true) {
            final intent = AndroidIntent(
              action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
              flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
            );
            await intent.launch();
          }
          
          await prefs.setBool('permiso_alarmas_verificado', true);
        }
      }
    }
    _permisosVerificados = true;
  }

  Future<void> _cargarMascotas() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

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
      }
    } catch (e) {
      print('Error al cargar mascotas: $e');
    }
  }

  Future<void> _cargarCitas() async {
    setState(() {
      _isLoadingCitas = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('https://patitas-care.onrender.com/citas/mis-citas'),
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
      }
    } catch (e) {
      print('Error al cargar citas: $e');
    } finally {
      setState(() {
        _isLoadingCitas = false;
      });
    }
  }

  Future<void> _agendarCita() async {
    final String motivo = _motivoController.text.trim();

    if (motivo.isEmpty || _selectedMascotaId == null) {
      _mostrarSnackBar('Por favor completa todos los campos', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? token = await AuthService.getToken();

      if (token == null) {
        _mostrarSnackBar('Error de autenticación. Inicia sesión nuevamente', Colors.red);
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
        _mostrarSnackBar('La fecha debe ser futura', Colors.red);
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
        await _programarNotificacion(
          'Cita: ${citaResponse['motivo']}',
          fechaCita,
        );
        _mostrarSnackBar('Cita agendada exitosamente', Colors.green);
        _limpiarCampos();
        await _cargarCitas(); // Recargar la lista de citas
        setState(() {
          _selectedTabIndex = 1; // Cambiar a la pestaña de citas
        });
      } else {
        try {
          final errorData = json.decode(response.body);
          _mostrarSnackBar(
            errorData['message'] ?? 'Error al agendar la cita',
            Colors.red,
          );
        } catch (e) {
          _mostrarSnackBar('Error inesperado del servidor', Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Error de conexión: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _programarNotificacion(String titulo, DateTime fechaCita) async {
    final tz.TZDateTime fechaProgramada = tz.TZDateTime.from(
      fechaCita,
      tz.local,
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'canal_citas',
          'Recordatorios de Citas',
          channelDescription: 'Canal para notificaciones de citas programadas',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titulo,
      '¡Es hora de tu cita veterinaria!',
      fechaProgramada,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _seleccionarHora(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF8B5CF6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _limpiarCampos() {
    _motivoController.clear();
    setState(() {
      _selectedMascotaId = null;
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
      case 'AGENDADA':
        return Colors.blue;
      case 'COMPLETADA':
        return Colors.green;
      case 'CANCELADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
              child: Row(
                children: [
                  const Icon(Icons.pets, color: Color(0xFF6B7280)),
                  const SizedBox(width: 12),
                  const Text(
                    'Cargando mascotas...',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF8B5CF6),
                      ),
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

  Widget _buildAgendarTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
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
              onPressed: _isLoading ? null : _agendarCita,
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
                  : const Text(
                      'Agendar Cita',
                      style: TextStyle(
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
    return _isLoadingCitas
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
            ),
          )
        : _citas.isEmpty
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
                      'No tienes citas programadas',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agenda tu primera cita usando la pestaña anterior',
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
                  itemCount: _citas.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final cita = _citas[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                                    color: _getEstadoColor(cita['estado']).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    cita['estado'],
                                    style: TextStyle(
                                      color: _getEstadoColor(cita['estado']),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.pets,
                                  color: const Color(0xFF8B5CF6),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              cita['mascotaNombre'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cita['motivo'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
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
                  },
                ),
              );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
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
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1F2937),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => InicioPage()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Recordatorios',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),

            // Tab selector
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
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? const Color(0xFF8B5CF6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Agendar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTabIndex == 0
                                ? Colors.white
                                : const Color(0xFF6B7280),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? const Color(0xFF8B5CF6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Mis Citas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTabIndex == 1
                                ? Colors.white
                                : const Color(0xFF6B7280),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _selectedTabIndex == 0
                    ? _buildAgendarTab()
                    : _buildCitasTab(),
              ),
            ),
          ],
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
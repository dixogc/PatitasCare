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
  String? _selectedMascotaId; // Para almacenar el ID de la mascota seleccionada
  List<Map<String, dynamic>> _mascotas = []; // Lista de mascotas del usuario
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    inicializarNotificaciones();
    _cargarMascotas(); // Cargar las mascotas del usuario
  }

  void inicializarNotificaciones() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _cargarMascotas() async {
  try {
    
    final token = await AuthService.getToken();

    
    if (token == null) {
      print('No se encontró token de autenticación');
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

    } else {
      print('Error HTTP: ${response.statusCode}');
      print('Error Body: ${response.body}');
      
      // Mostrar mensaje de error al usuario
      if (mounted) {
        _mostrarSnackBar(
          'Error al cargar mascotas: ${response.statusCode}', 
          Colors.red
        );
      }
    }
  } catch (e) {
    print('Error al cargar mascotas: $e');
    print('Stack trace: ${StackTrace.current}');
    
    // Mostrar mensaje de error al usuario
    if (mounted) {
      _mostrarSnackBar(
        'Error de conexión al cargar mascotas', 
        Colors.red
      );
    }
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
    } else {
      print("STATUS: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");

      try {
        final errorData = json.decode(response.body);
        _mostrarSnackBar(
          errorData['message'] ?? 'Error al agendar la cita',
          Colors.red,
        );
      } catch (e) {
        print('No se pudo decodificar el body del error: ${response.body}');
        _mostrarSnackBar('Error inesperado del servidor', Colors.red);
      }
    }
  } catch (e) {
    print('Error general en _agendarCita: $e');
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

  Widget _buildMascotaDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
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
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor selecciona una mascota';
                }
                return null;
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
        color: const Color(0xFFE5E7EB).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFFEF3C7), // Amarillo suave
              Color(0xFFF3E8FF), // Púrpura muy suave
              Color(0xFFE0E7FF), // Azul muy suave
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con botón de regreso
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
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
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Título principal
                  const Text(
                    'Agendar Cita',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Calendario
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
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
                  const SizedBox(height: 30),

                  // Campos de información
                  const Text(
                    'Información de la Cita:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildMascotaDropdown(),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _motivoController,
                    'Motivo de la cita (ej: Vacunación, Consulta)',
                    Icons.medical_services,
                  ),
                  const SizedBox(height: 20),

                  // Selección de hora
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
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
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Cambiar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

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
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                        shadowColor: const Color(0xFF8B5CF6).withOpacity(0.3),
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Agendar Cita',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
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
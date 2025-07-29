import 'dart:async';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:patitas_care/inicio_page.dart';
import 'package:patitas_care/notification_helper.dart';
import 'package:patitas_care/success_feedback_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'auth_service.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  int _selectedTabIndex = 0;
  
  // Variables para el feedback de éxito
  bool _showSuccessFeedback = false;
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);
    _inicializar(); 
  }

  void _inicializar() async {
    await inicializarNotificaciones();
    await _verificarYSolicitarPermisos();
    await _cargarMascotas();
    await _cargarCitas();
  }

  Future<void> inicializarNotificaciones() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    try {
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notificación tocada: ${response.payload}');
        },
      );

      // Crear canales de notificación para Android
      if (Platform.isAndroid) {
        await _crearCanalesNotificacion();
      }
    } catch (e) {
      print('Error al inicializar notificaciones: $e');
      context.showErrorNotification(
        'Error al configurar las notificaciones',
        actionLabel: 'Reintentar',
        onAction: () => inicializarNotificaciones(),
      );
    }
  }

  Future<void> _crearCanalesNotificacion() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Canal para notificaciones 1 hora antes
      const AndroidNotificationChannel canalAntes = AndroidNotificationChannel(
        'recordatorios_citas_antes',
        'Recordatorios de Citas (1 hora antes)',
        description: 'Notificaciones de recordatorio de citas veterinarias 1 hora antes',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // Canal para notificaciones a la hora exacta
      const AndroidNotificationChannel canalExacta = AndroidNotificationChannel(
        'recordatorios_citas_exacta',
        'Recordatorios de Citas (Hora exacta)',
        description: 'Notificaciones de recordatorio de citas veterinarias a la hora exacta',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImplementation.createNotificationChannel(canalAntes);
      await androidImplementation.createNotificationChannel(canalExacta);
    }
  }

  Future<void> _verificarYSolicitarPermisos() async {
    if (_permisosVerificados) return;

    if (Platform.isAndroid) {
      // 1. Primero verificar permisos básicos de notificación
      await _solicitarPermisoNotificacionesBasicas();
      
      // 2. Luego verificar y solicitar permiso de alarmas exactas
      await _manejarPermisoAlarmasExactas();
    }
    
    _permisosVerificados = true;
  }

  Future<void> _solicitarPermisoNotificacionesBasicas() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      
      if (granted != true) {
        context.showWarningNotification(
          'Permisos de notificación requeridos para recordatorios',
          actionLabel: 'Configurar',
          onAction: () => _solicitarPermisoNotificacionesBasicas(),
        );
      } else {
        context.showSuccessNotification('Permisos de notificación concedidos');
      }
    }
  }

  Future<void> _manejarPermisoAlarmasExactas() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final int sdkInt = androidInfo.version.sdkInt;

      // Android 12 (API 31) y superior necesitan este permiso
      if (sdkInt < 31) {
        return; // No se necesita en versiones anteriores
      }

      // Verificar si ya tenemos el permiso
      final status = await Permission.scheduleExactAlarm.status;
      
      if (status != PermissionStatus.granted) {
        // Mostrar diálogo explicativo
        final bool? shouldRequest = await _mostrarDialogoPermisoAlarmas();
        
        if (shouldRequest == true) {
          // Intentar solicitar el permiso
          final result = await Permission.scheduleExactAlarm.request();
          
          if (result != PermissionStatus.granted) {
            // Si no se concedió, abrir configuración manual
            await _abrirConfiguracionAlarmasManual();
          } else {
            context.showSuccessNotification('Permiso de alarmas concedido correctamente');
          }
        }
      }
    } catch (e) {
      print('Error al manejar permiso de alarmas: $e');
      context.showErrorNotification(
        'Error al gestionar permisos de alarmas',
        actionLabel: 'Configurar manualmente',
        onAction: () => _abrirConfiguracionAlarmasManual(),
      );
    }
  }

  Future<bool?> _mostrarDialogoPermisoAlarmas() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.alarm, color: Color(0xFF8B5CF6)),
              SizedBox(width: 8),
              Expanded(child: Text('Permiso Especial Requerido')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para enviar recordatorios precisos de citas, necesitamos el permiso especial "Alarmas y recordatorios".',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Esto permitirá:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('• Recordatorios 1 hora antes', style: TextStyle(fontSize: 14)),
                    Text('• Notificación a la hora exacta', style: TextStyle(fontSize: 14)),
                    Text('• Funcionamiento en segundo plano', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
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
              child: Text('Conceder Permiso'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _abrirConfiguracionAlarmasManual() async {
    try {
      // Mostrar diálogo con instrucciones
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Configuración Manual'),
          content: Text(
            'Sigue estos pasos:\n\n'
            '1. Se abrirá la configuración\n'
            '2. Busca "Patitas Care" en la lista\n'
            '3. Activa "Permitir alarmas y recordatorios"\n'
            '4. Regresa a la app',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _abrirConfiguracion();
              },
              child: Text('Abrir Configuración'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error: $e');
      context.showErrorNotification('No se pudo abrir la configuración');
    }
  }

  Future<void> _abrirConfiguracion() async {
    try {
      // Intentar abrir configuración específica de alarmas
      await Permission.scheduleExactAlarm.request();
      
      // Fallback: abrir configuración de la app
      final Uri uri = Uri.parse('app-settings:');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('Error al abrir configuración: $e');
      context.showErrorNotification('Error al abrir la configuración del sistema');
    }
  }

  Future<void> _programarNotificacion(String titulo, String cuerpo, DateTime fechaCita) async {
    try {
      // Verificar permisos antes de programar
      final status = await Permission.scheduleExactAlarm.status;
      if (status != PermissionStatus.granted && Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt >= 31) {
          context.showWarningNotification(
            'Se necesita permiso de alarmas exactas',
            actionLabel: 'Configurar',
            onAction: () => _manejarPermisoAlarmasExactas(),
          );
          return;
        }
      }

      // Generar IDs únicos
      final int baseId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final String payload = jsonEncode({
        'tipo': 'cita',
        'mascota_id': _selectedMascotaId,
        'fecha': fechaCita.toIso8601String(),
      });

      int notificacionesProgramadas = 0;

      // Notificación 1 hora antes
      final DateTime notificacionAntes = fechaCita.subtract(Duration(hours: 1));
      if (notificacionAntes.isAfter(DateTime.now())) {
        final tz.TZDateTime fechaNotificacionAntes = tz.TZDateTime.from(
          notificacionAntes,
          tz.local,
        );

        const AndroidNotificationDetails androidDetailsAntes = AndroidNotificationDetails(
          'recordatorios_citas_antes',
          'Recordatorios de Citas (1 hora antes)',
          channelDescription: 'Notificaciones de recordatorio de citas veterinarias 1 hora antes',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          fullScreenIntent: false,
          category: AndroidNotificationCategory.reminder,
        );

        const NotificationDetails notificationDetailsAntes = NotificationDetails(
          android: androidDetailsAntes,
        );

        await flutterLocalNotificationsPlugin.zonedSchedule(
          baseId,
          '⏰ Cita en 1 hora - $titulo',
          cuerpo,
          fechaNotificacionAntes,
          notificationDetailsAntes,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        notificacionesProgramadas++;
      }

      // Notificación a la hora exacta
      final tz.TZDateTime fechaProgramada = tz.TZDateTime.from(fechaCita, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'recordatorios_citas_exacta',
        'Recordatorios de Citas (Hora exacta)',
        channelDescription: 'Notificaciones de recordatorio de citas veterinarias a la hora exacta',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId + 1,
        '🐾 ¡Es hora de tu cita!',
        '$titulo - $cuerpo',
        fechaProgramada,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      notificacionesProgramadas++;

      // Mostrar mensaje de éxito personalizado
      final String mensajeExito = notificacionesProgramadas == 2 
          ? 'Recordatorios programados: 1 hora antes y a la hora exacta'
          : 'Recordatorio programado correctamente';
      
      context.showSuccessNotification(mensajeExito);
      
    } catch (e) {
      print('Error al programar notificación: $e');
      context.showErrorNotification(
        'Error al programar los recordatorios',
        actionLabel: 'Reintentar',
        onAction: () => _programarNotificacion(titulo, cuerpo, fechaCita),
      );
    }
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
        
        await _programarNotificacion(
          'Recordatorio: Cita de $mascotaNombre',
          'Motivo: ${citaResponse['motivo']}',
          fechaCita,
        );
        
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
                  
                  // Estilo adicional para que se vea más limpio
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
                            MaterialPageRoute(builder: (context) => InicioPage()),
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
                                Icons.add_circle_outline,
                                color: _selectedTabIndex == 0
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Agendar',
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
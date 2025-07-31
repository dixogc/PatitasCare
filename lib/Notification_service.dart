import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  static late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  static bool _isInitialized = false;
  static bool _permisosVerificados = false;

  // Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);
    
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notificación tocada: ${response.payload}');
        },
      );

      // Crear canales de notificación para Android
      if (Platform.isAndroid) {
        await _crearCanalesNotificacion();
      }
      
      _isInitialized = true;
    } catch (e) {
      print('Error al inicializar notificaciones: $e');
      throw Exception('Error al configurar las notificaciones');
    }
  }

  // Crear canales de notificación para Android
  static Future<void> _crearCanalesNotificacion() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
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

  // Verificar y solicitar permisos
  static Future<bool> verificarYSolicitarPermisos(BuildContext context) async {
    if (_permisosVerificados) return true;

    if (Platform.isAndroid) {
      // 1. Primero verificar permisos básicos de notificación
      bool permisosBasicos = await _solicitarPermisoNotificacionesBasicas(context);
      
      // 2. Luego verificar y solicitar permiso de alarmas exactas
      bool permisosAlarmas = await _manejarPermisoAlarmasExactas(context);
      
      _permisosVerificados = permisosBasicos && permisosAlarmas;
      return _permisosVerificados;
    }
    
    _permisosVerificados = true;
    return true;
  }

  static Future<bool> _solicitarPermisoNotificacionesBasicas(BuildContext context) async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      
      if (granted != true) {
        if (context.mounted) {
          _showPermissionDialog(
            context,
            'Permisos de notificación requeridos',
            'Se necesitan permisos de notificación para enviar recordatorios de citas.',
            () => _solicitarPermisoNotificacionesBasicas(context),
          );
        }
        return false;
      }
      return true;
    }
    return false;
  }

  static Future<bool> _manejarPermisoAlarmasExactas(BuildContext context) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final int sdkInt = androidInfo.version.sdkInt;

      // Android 12 (API 31) y superior necesitan este permiso
      if (sdkInt < 31) {
        return true; // No se necesita en versiones anteriores
      }

      // Verificar si ya tenemos el permiso
      final status = await Permission.scheduleExactAlarm.status;
      
      if (status != PermissionStatus.granted) {
        // Mostrar diálogo explicativo
        if (context.mounted) {
          final bool? shouldRequest = await _mostrarDialogoPermisoAlarmas(context);
          
          if (shouldRequest == true) {
            // Intentar solicitar el permiso
            final result = await Permission.scheduleExactAlarm.request();
            
            if (result != PermissionStatus.granted) {
              // Si no se concedió, abrir configuración manual
              await _abrirConfiguracionAlarmasManual(context);
              return false;
            }
            return true;
          }
        }
        return false;
      }
      return true;
    } catch (e) {
      print('Error al manejar permiso de alarmas: $e');
      if (context.mounted) {
        _showPermissionDialog(
          context,
          'Error al gestionar permisos',
          'Error al gestionar permisos de alarmas',
          () => _abrirConfiguracionAlarmasManual(context),
        );
      }
      return false;
    }
  }

  static void _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onRetry,
  ) {
    // Aquí puedes usar tu sistema de notificaciones personalizado
    // Por ahora uso un AlertDialog básico
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Más tarde'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  static Future<bool?> _mostrarDialogoPermisoAlarmas(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.alarm, color: Color(0xFF8B5CF6)),
              SizedBox(width: 8),
              Expanded(child: Text('Permiso Especial Requerido')),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para enviar recordatorios precisos de citas, necesitamos el permiso especial "Alarmas y recordatorios".',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              // Info box
              // ... resto del contenido del diálogo
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Más tarde'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Conceder Permiso'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _abrirConfiguracionAlarmasManual(BuildContext context) async {
    try {
      // Mostrar diálogo con instrucciones
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Configuración Manual'),
          content: const Text(
            'Sigue estos pasos:\n\n'
            '1. Se abrirá la configuración\n'
            '2. Busca "Patitas Care" en la lista\n'
            '3. Activa "Permitir alarmas y recordatorios"\n'
            '4. Regresa a la app',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _abrirConfiguracion();
              },
              child: const Text('Abrir Configuración'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error: $e');
    }
  }

  static Future<void> _abrirConfiguracion() async {
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
    }
  }

  // Programar notificación para una cita
  static Future<bool> programarNotificacionCita({
    required String citaId,
    required String titulo,
    required String cuerpo,
    required DateTime fechaCita,
    String? mascotaId,
  }) async {
    try {
      // Verificar permisos antes de programar
      if (Platform.isAndroid) {
        final status = await Permission.scheduleExactAlarm.status;
        if (status != PermissionStatus.granted) {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          if (androidInfo.version.sdkInt >= 31) {
            print('Se necesita permiso de alarmas exactas');
            return false;
          }
        }
      }

      // Generar IDs únicos basados en el ID de la cita
      final int baseId = citaId.hashCode;
      final String payload = jsonEncode({
        'tipo': 'cita',
        'cita_id': citaId,
        'mascota_id': mascotaId,
        'fecha': fechaCita.toIso8601String(),
      });

      int notificacionesProgramadas = 0;

      // Notificación 1 hora antes
      final DateTime notificacionAntes = fechaCita.subtract(const Duration(hours: 1));
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

        await _flutterLocalNotificationsPlugin.zonedSchedule(
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

      await _flutterLocalNotificationsPlugin.zonedSchedule(
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

      print('Notificaciones programadas: $notificacionesProgramadas');
      return true;
      
    } catch (e) {
      print('Error al programar notificación: $e');
      return false;
    }
  }

  // Cancelar notificaciones de una cita específica
  static Future<void> cancelarNotificacionesCita(String citaId) async {
    try {
      final int baseId = citaId.hashCode;
      
      // Cancelar notificación 1 hora antes
      await _flutterLocalNotificationsPlugin.cancel(baseId);
      
      // Cancelar notificación a la hora exacta
      await _flutterLocalNotificationsPlugin.cancel(baseId + 1);
      
      print('Notificaciones canceladas para cita: $citaId');
    } catch (e) {
      print('Error al cancelar notificaciones: $e');
    }
  }

  // Actualizar notificaciones de una cita (cancela las anteriores y programa nuevas)
  static Future<bool> actualizarNotificacionesCita({
    required String citaId,
    required String titulo,
    required String cuerpo,
    required DateTime fechaCita,
    String? mascotaId,
  }) async {
    // Primero cancelar las notificaciones existentes
    await cancelarNotificacionesCita(citaId);
    
    // Luego programar las nuevas
    return await programarNotificacionCita(
      citaId: citaId,
      titulo: titulo,
      cuerpo: cuerpo,
      fechaCita: fechaCita,
      mascotaId: mascotaId,
    );
  }

  // Obtener notificaciones pendientes (para debug)
  static Future<List<PendingNotificationRequest>> obtenerNotificacionesPendientes() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Cancelar todas las notificaciones
  static Future<void> cancelarTodasLasNotificaciones() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
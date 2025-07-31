import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:patitas_care/editar_perfil_page.dart';
import 'package:patitas_care/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:patitas_care/notification_helper.dart';
import 'package:patitas_care/success_feedback_widget.dart';

class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  bool _notificacionesActivadas = true;
  bool _isLoading = false;
  bool showSuccessAnimation = false;
  Map<String, dynamic>? _perfilUsuario;

  @override
  void initState() {
    super.initState();
    _cargarConfiguraciones();
    _cargarPerfilUsuario();
  }

  Future<void> _cargarConfiguraciones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificacionesActivadas = prefs.getBool('notificaciones_activadas') ?? true;
      });
    } catch (e) {
      context.showErrorNotification(
        'Error al cargar configuraciones',
        actionLabel: 'Reintentar',
        onAction: () => _cargarConfiguraciones(),
      );
    }
  }

  Future<void> _cargarPerfilUsuario() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        context.showErrorNotification(
          'Sesión expirada. Inicia sesión nuevamente',
          actionLabel: 'Iniciar sesión',
          onAction: () => Navigator.pushReplacementNamed(context, '/login'),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('https://patitas-care.onrender.com/cliente/perfil'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final perfilData = json.decode(response.body);
        setState(() {
          _perfilUsuario = perfilData;
        });
        
        context.showSuccessNotification(
          'Perfil cargado correctamente'
        );
        
      } else if (response.statusCode == 401) {
        context.showErrorNotification(
          'Tu sesión ha expirado. Inicia sesión nuevamente',
          actionLabel: 'Iniciar sesión',
          onAction: () => Navigator.pushReplacementNamed(context, '/login'),
        );
      } else if (response.statusCode == 404) {
        context.showWarningNotification(
          'No se encontró la información del perfil',
          actionLabel: 'Reintentar',
          onAction: () => _cargarPerfilUsuario(),
        );
      } else if (response.statusCode >= 500) {
        context.showErrorNotification(
          'Error del servidor. Intenta nuevamente en unos minutos',
          actionLabel: 'Reintentar',
          onAction: () => _cargarPerfilUsuario(),
        );
      } else {
        context.showErrorNotification(
          'Error inesperado al cargar el perfil',
          actionLabel: 'Reintentar',
          onAction: () => _cargarPerfilUsuario(),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException')) {
        context.showErrorNotification(
          'Sin conexión a internet. Verifica tu conexión',
          actionLabel: 'Reintentar',
          onAction: () => _cargarPerfilUsuario(),
        );
      } else {
        context.showErrorNotification(
          'Error inesperado al cargar el perfil',
          actionLabel: 'Reintentar',
          onAction: () => _cargarPerfilUsuario(),
        );
      }
    }
  }

  Future<void> _toggleNotificaciones(bool valor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificaciones_activadas', valor);
      setState(() {
        _notificacionesActivadas = valor;
      });

      if (valor) {
        context.showSuccessNotification(
          'Notificaciones activadas correctamente'
        );
      } else {
        context.showInfoNotification(
          'Notificaciones desactivadas. Puedes activarlas cuando quieras'
        );
      }
    } catch (e) {
      // Revertir el cambio si hubo error
      setState(() {
        _notificacionesActivadas = !valor;
      });
      
      context.showErrorNotification(
        'Error al guardar la configuración',
        actionLabel: 'Reintentar',
        onAction: () => _toggleNotificaciones(valor),
      );
    }
  }

  Future<void> _abrirEditarPerfil() async {
    if (_perfilUsuario == null) {
      context.showWarningNotification(
        'Espera a que se carguen los datos del perfil',
        actionLabel: 'Cargar',
        onAction: () => _cargarPerfilUsuario(),
      );
      return;
    }

    try {
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditarPerfilPage(
            perfilActual: _perfilUsuario!,
          ),
        ),
      );

      if (resultado != null) {
        setState(() {
          _perfilUsuario = resultado;
          showSuccessAnimation = true;
        });
        
        context.showSuccessNotification(
          'Perfil actualizado exitosamente'
        );
      }
    } catch (e) {
      context.showErrorNotification(
        'Error al abrir la página de edición del perfil',
        actionLabel: 'Reintentar',
        onAction: () => _abrirEditarPerfil(),
      );
    }
  }

  Future<void> _abrirFormularioFeedback() async {
    const String urlFormulario = 'https://forms.gle/p1Ubf8Zjumvm4Wbu7';
    
    try {
      final Uri url = Uri.parse(urlFormulario);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        
        context.showSuccessNotification(
          'Formulario abierto. ¡Gracias por tu feedback!'
        );
      } else {
        context.showErrorNotification(
          'No se puede abrir el formulario de feedback',
          actionLabel: 'Copiar enlace',
          onAction: () {
            Clipboard.setData(ClipboardData(text: urlFormulario));
            context.showInfoNotification('Enlace copiado al portapapeles');
          },
        );
      }
    } catch (e) {
      context.showErrorNotification(
        'Error al abrir el formulario de feedback',
        actionLabel: 'Copiar enlace',
        onAction: () {
          Clipboard.setData(ClipboardData(text: urlFormulario));
          context.showInfoNotification('Enlace copiado al portapapeles');
        },
      );
    }
  }

  Future<void> _mostrarDialogoCerrarSesion() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Color(0xFFEF4444),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión? Tendrás que iniciar sesión nuevamente para acceder a la aplicación.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _cerrarSesion();
              },
              child: Text(
                'Cerrar Sesión',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cerrarSesion() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cerrando sesión...'),
              ],
            ),
          ),
        ),
      );

      await AuthService.logout();
      
      // Cerrar el diálogo de carga
      Navigator.of(context).pop();
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()), 
        (Route<dynamic> route) => false,
      );
      
      context.showSuccessNotification(
        'Sesión cerrada exitosamente. ¡Hasta pronto!'
      );
      
    } catch (e) {
      // Cerrar el diálogo de carga si existe
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      context.showErrorNotification(
        'Error al cerrar sesión. Intenta nuevamente',
        actionLabel: 'Reintentar',
        onAction: () => _cerrarSesion(),
      );
    }
  }

  void _onSuccessAnimationComplete() {
    setState(() {
      showSuccessAnimation = false;
    });
  }

  Widget _buildSeccionHeader(String titulo, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24),
      child: Row(
        children: [
          Icon(
            icono,
            color: Color(0xFF8B5CF6),
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionSwitch({
    required String titulo,
    required String subtitulo,
    required bool valor,
    required Function(bool) onChanged,
    required IconData icono,
  }) {
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
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icono,
            color: Color(0xFF8B5CF6),
            size: 20,
          ),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        trailing: Switch(
          value: valor,
          onChanged: onChanged,
          activeColor: Color(0xFF8B5CF6),
          activeTrackColor: Color(0xFF8B5CF6).withOpacity(0.3),
          inactiveThumbColor: Color(0xFF9CA3AF),
          inactiveTrackColor: Color(0xFFE5E7EB),
        ),
      ),
    );
  }

  Widget _buildOpcionBoton({
    required String titulo,
    String? subtitulo,
    required Function() onTap,
    required IconData icono,
    Color? colorIcono,
    Color? colorTexto,
    Widget? trailing,
  }) {
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
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (colorIcono ?? Color(0xFF8B5CF6)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icono,
            color: colorIcono ?? Color(0xFF8B5CF6),
            size: 20,
          ),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorTexto ?? Color(0xFF1F2937),
          ),
        ),
        subtitle: subtitulo != null
            ? Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              )
            : null,
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9CA3AF),
              size: 16,
            ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoUsuario() {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(20),
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
            CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF8B5CF6).withOpacity(0.1),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_perfilUsuario == null) {
      return GestureDetector(
        onTap: _cargarPerfilUsuario,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFEF4444).withOpacity(0.3)),
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
              CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFEF4444).withOpacity(0.1),
                child: Icon(
                  Icons.error_outline,
                  color: Color(0xFFEF4444),
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error al cargar datos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    Text(
                      'Toca para reintentar cargar tu perfil',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.refresh,
                color: Color(0xFF8B5CF6),
                size: 24,
              ),
            ],
          ),
        ),
      );
    }

    // Obtener la primera letra del nombre para el avatar
    String iniciales = '';
    if (_perfilUsuario!['nombre'] != null && _perfilUsuario!['nombre'].isNotEmpty) {
      final nombres = _perfilUsuario!['nombre'].toString().split(' ');
      iniciales = nombres.map((nombre) => nombre.isNotEmpty ? nombre[0] : '').take(2).join('').toUpperCase();
    }

    return Container(
      padding: EdgeInsets.all(20),
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
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF8B5CF6),
            child: Text(
              iniciales.isNotEmpty ? iniciales : 'U',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _perfilUsuario!['nombre'] ?? 'Usuario',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _perfilUsuario!['correo'] ?? 'correo@ejemplo.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Indicador de perfil cargado
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
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
      successMessage: '¡Perfil actualizado!',
      onComplete: _onSuccessAnimationComplete,
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // Header mejorado
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
                          Navigator.pop(context);
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
                        'Ajustes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    // Botón de refresh para recargar perfil
                    if (_perfilUsuario != null)
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
                          onPressed: _cargarPerfilUsuario,
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección de Notificaciones
                      _buildSeccionHeader('Notificaciones', Icons.notifications),
                      _buildOpcionSwitch(
                        titulo: 'Recordatorios',
                        subtitulo: 'Recibe notificaciones de citas y cuidados',
                        valor: _notificacionesActivadas,
                        onChanged: _toggleNotificaciones,
                        icono: Icons.notifications_active,
                      ),

                      // Sección de Cuenta
                      _buildSeccionHeader('Cuenta', Icons.account_circle),
                      _buildInfoUsuario(),
                      SizedBox(height: 12),
                      _buildOpcionBoton(
                        titulo: 'Editar datos',
                        subtitulo: 'Modificar información personal',
                        onTap: _abrirEditarPerfil,
                        icono: Icons.edit,
                      ),
                      SizedBox(height: 12),
                      _buildOpcionBoton(
                        titulo: 'Cerrar sesión',
                        subtitulo: 'Salir de tu cuenta',
                        onTap: _mostrarDialogoCerrarSesion,
                        icono: Icons.logout,
                        colorIcono: Color(0xFFEF4444),
                        colorTexto: Color(0xFFEF4444),
                      ),

                      // Sección de Soporte
                      _buildSeccionHeader('Soporte', Icons.support_agent),
                      _buildOpcionBoton(
                        titulo: 'Enviar feedback',
                        subtitulo: 'Comparte tu opinión y sugerencias',
                        onTap: _abrirFormularioFeedback,
                        icono: Icons.feedback,
                        trailing: Icon(
                          Icons.open_in_new,
                          color: Color(0xFF9CA3AF),
                          size: 16,
                        ),
                      ),

                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
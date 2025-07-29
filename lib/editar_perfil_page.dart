import 'package:flutter/material.dart';
import 'package:patitas_care/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:patitas_care/notification_helper.dart';
import 'package:patitas_care/success_feedback_widget.dart';

class EditarPerfilPage extends StatefulWidget {
  final Map<String, dynamic> perfilActual;
  
  const EditarPerfilPage({
    super.key,
    required this.perfilActual,
  });

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirmarPassword = false;
  bool _cambiarPassword = false;
  bool _showSuccessAnimation = false;

  // Estados de validación en tiempo real
  String? _nombreError;
  String? _passwordError;
  String? _confirmarPasswordError;

  @override
  void initState() {
    super.initState();
    _cargarDatosActuales();
  }

  void _cargarDatosActuales() {
    _nombreController.text = widget.perfilActual['nombre']?.toString() ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  // Validaciones en tiempo real
  void _validarNombre() {
    final nombre = _nombreController.text.trim();
    setState(() {
      if (nombre.isEmpty) {
        _nombreError = 'El nombre es obligatorio';
      } else if (nombre.length < 2) {
        _nombreError = 'El nombre debe tener al menos 2 caracteres';
      } else if (nombre.length > 255) {
        _nombreError = 'El nombre es demasiado largo';
      } else {
        _nombreError = null;
      }
    });
  }

  void _validarPassword() {
    final password = _passwordController.text;
    setState(() {
      if (_cambiarPassword) {
        if (password.isEmpty) {
          _passwordError = 'La contraseña es obligatoria';
        } else if (password.length < 8) {
          _passwordError = 'La contraseña debe tener al menos 8 caracteres';
        } else {
          _passwordError = null;
        }
      } else {
        _passwordError = null;
      }
    });
  }

  void _validarConfirmarPassword() {
    final password = _passwordController.text;
    final confirmarPassword = _confirmarPasswordController.text;
    
    setState(() {
      if (_cambiarPassword) {
        if (confirmarPassword.isEmpty) {
          _confirmarPasswordError = 'Confirma tu contraseña';
        } else if (password != confirmarPassword) {
          _confirmarPasswordError = 'Las contraseñas no coinciden';
        } else {
          _confirmarPasswordError = null;
        }
      } else {
        _confirmarPasswordError = null;
      }
    });
  }

  bool _formularioValido() {
    return _nombreError == null &&
           _passwordError == null &&
           _confirmarPasswordError == null &&
           _nombreController.text.trim().isNotEmpty &&
           (!_cambiarPassword || _passwordController.text.isNotEmpty);
  }

  String _getReadableErrorMessage(String originalMessage) {
    if (originalMessage.toLowerCase().contains('password') || 
               originalMessage.toLowerCase().contains('contraseña')) {
      return 'Error en la contraseña. Verifica que tenga al menos 8 caracteres';
    } else if (originalMessage.toLowerCase().contains('network') || 
               originalMessage.toLowerCase().contains('connection')) {
      return 'Problema de conexión. Verifica tu internet e intenta de nuevo';
    } else if (originalMessage.toLowerCase().contains('not found')) {
      return 'Usuario no encontrado. Inicia sesión nuevamente';
    }
    return 'Ocurrió un error inesperado. Por favor intenta de nuevo';
  }

  Future<void> _actualizarPerfil() async {
    // Validar todos los campos
    _validarNombre();
    _validarPassword();
    _validarConfirmarPassword();

    if (!_formularioValido()) {
      context.showErrorNotification('Por favor contesta los campos obligatorios');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        context.showErrorNotification('Error de autenticación. Inicia sesión nuevamente');
        return;
      }

      // Obtener el ID del usuario desde el perfil actual
      final String userId = widget.perfilActual['id']?.toString() ?? '';
      if (userId.isEmpty) {
        context.showErrorNotification('Error: No se pudo obtener el ID del usuario');
        return;
      }

      // Preparar los datos para enviar (solo nombre, el correo se mantiene igual)
      final Map<String, dynamic> datosActualizacion = {
        'nombre': _nombreController.text.trim(),
        'correo': widget.perfilActual['correo']?.toString() ?? '', // Mantener el correo actual
      };

      // Solo incluir password si se quiere cambiar
      if (_cambiarPassword && _passwordController.text.isNotEmpty) {
        datosActualizacion['password'] = _passwordController.text;
      } else {
        // El backend requiere password, enviar uno temporal que será ignorado
        datosActualizacion['password'] = 'temporal123'; // Se ignorará si no se quiere cambiar
      }

      final response = await http.put(
        Uri.parse('https://patitas-care.onrender.com/cliente/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(datosActualizacion),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // ignore: unused_local_variable
        final Map<String, dynamic> usuarioActualizado = json.decode(response.body);
        
        // Mostrar animación de éxito
        setState(() {
          _showSuccessAnimation = true;
        });
        
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage = _getReadableErrorMessage(
            errorData['mensaje'] ?? errorData['message'] ?? errorData.toString()
          );
          context.showErrorNotification(errorMessage);
        } catch (e) {
          context.showErrorNotification('Error del servidor. Código: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error al actualizar perfil: $e');
      if (e.toString().contains('TimeoutException')) {
        context.showWarningNotification('La solicitud tomó demasiado tiempo. Intenta de nuevo');
      } else {
        context.showErrorNotification('Error de conexión. Verifica tu internet');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSuccessComplete() {
    // Cuando termine la animación de éxito, regresar a la pantalla anterior
    final Map<String, dynamic> usuarioActualizado = {
      ...widget.perfilActual,
      'nombre': _nombreController.text.trim(),
    };
    Navigator.of(context).pop(usuarioActualizado);
  }

  // Método removido - ahora usamos las notificaciones personalizadas
  // void _mostrarSnackBar(String mensaje, Color color) { ... }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Function() onChanged,
    String? errorText,
    bool isPassword = false,
    bool? showPassword,
    VoidCallback? togglePasswordVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8),
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
          child: TextField(
            controller: controller,
            obscureText: isPassword && !(showPassword ?? false),
            onChanged: (_) => onChanged(),
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                icon,
                color: errorText != null ? Colors.red : Color(0xFF6B7280),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        (showPassword ?? false) ? Icons.visibility_off : Icons.visibility,
                        color: Color(0xFF6B7280),
                      ),
                      onPressed: togglePasswordVisibility,
                    )
                  : null,
              filled: true,
              fillColor: errorText != null 
                  ? Color(0xFFFEF2F2)
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: errorText != null 
                    ? BorderSide(color: Colors.red, width: 1)
                    : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: errorText != null 
                    ? BorderSide(color: Colors.red, width: 1)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorText != null 
                      ? Colors.red 
                      : Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.red,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCorreoInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.email,
                color: Color(0xFF6B7280),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Correo Electrónico',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: Color(0xFF6B7280),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.perfilActual['correo']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.lock_outline,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'El correo electrónico no puede ser modificado',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCambiarPasswordSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Color(0xFF8B5CF6),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Seguridad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cambiar contraseña',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              Switch(
                value: _cambiarPassword,
                onChanged: (value) {
                  setState(() {
                    _cambiarPassword = value;
                    if (!value) {
                      _passwordController.clear();
                      _confirmarPasswordController.clear();
                      _passwordError = null;
                      _confirmarPasswordError = null;
                    }
                  });
                },
                activeColor: Color(0xFF8B5CF6),
                activeTrackColor: Color(0xFF8B5CF6).withOpacity(0.3),
              ),
            ],
          ),
          if (_cambiarPassword) ...[
            SizedBox(height: 20),
            _buildTextField(
              controller: _passwordController,
              label: 'Nueva Contraseña',
              hint: 'Ingresa tu nueva contraseña',
              icon: Icons.lock,
              onChanged: _validarPassword,
              errorText: _passwordError,
              isPassword: true,
              showPassword: _mostrarPassword,
              togglePasswordVisibility: () {
                setState(() {
                  _mostrarPassword = !_mostrarPassword;
                });
              },
            ),
            SizedBox(height: 20),
            _buildTextField(
              controller: _confirmarPasswordController,
              label: 'Confirmar Contraseña',
              hint: 'Confirma tu nueva contraseña',
              icon: Icons.lock_outline,
              onChanged: _validarConfirmarPassword,
              errorText: _confirmarPasswordError,
              isPassword: true,
              showPassword: _mostrarConfirmarPassword,
              togglePasswordVisibility: () {
                setState(() {
                  _mostrarConfirmarPassword = !_mostrarConfirmarPassword;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuccessFeedbackWidget(
      showSuccess: _showSuccessAnimation,
      successMessage: 'Perfil actualizado\nexitosamente',
      onComplete: _onSuccessComplete,
      child: Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
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
                      'Editar Perfil',
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

            // Formulario
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información Personal
                      Container(
                        width: double.infinity,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: Color(0xFF8B5CF6),
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Información Personal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            _buildTextField(
                              controller: _nombreController,
                              label: 'Nombre Completo',
                              hint: 'Ingresa tu nombre completo',
                              icon: Icons.person_outline,
                              onChanged: _validarNombre,
                              errorText: _nombreError,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // Sección de Correo (Solo lectura)
                      _buildCorreoInfoSection(),

                      SizedBox(height: 20),

                      // Sección de Contraseña
                      _buildCambiarPasswordSection(),

                      SizedBox(height: 30),

                      // Botón de Guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _actualizarPerfil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: Color(0xFF9CA3AF),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Guardando...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Guardar Cambios',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      )
    );
  }
}
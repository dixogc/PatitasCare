import 'package:flutter/material.dart';
import 'mascotas/registro_mascota.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_helper.dart';
import 'success_feedback_widget.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  _RegistroPageState createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? rolSeleccionado;
  final List<String> roles = ['CLIENTE', 'VETERINARIO'];
  bool esVeterinario = false;
  bool _isLoading = false;
  bool _showSuccess = false;
  
  // Estados de validación
  String? nombreError;
  String? correoError;
  String? passwordError;

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> registrarUsuario(
    String nombre,
    String email,
    String password,
    String tipoUsuario,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.registrarUsuario(
        nombre: nombre,
        correo: email,
        password: password,
        tipoUsuario: tipoUsuario,
      );

      final status = result['status'];
      final body = result['body'];

      if (status == 201) {
        // Mostrar feedback de éxito
        setState(() {
          _showSuccess = true;
        });
        
        // Si hay token, va directo a home
        if (body['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', body['token']);
        }
        
      } else {
        // Mostrar error con el nuevo sistema
        final errorMessage = _getReadableErrorMessage(body['mensaje'] ?? body.toString());
        context.showErrorNotification(
          errorMessage,
          actionLabel: 'Reintentar',
          onAction: () => _submitForm(),
        );
      }
    } catch (e) {
      // Error de conexión
      context.showErrorNotification(
        'No pudimos conectar con el servidor. Revisa tu conexión a internet.',
        actionLabel: 'Reintentar',
        onAction: () => _submitForm(),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getReadableErrorMessage(String originalMessage) {
    // Convierte mensajes técnicos en mensajes amigables
    if (originalMessage.toLowerCase().contains('email')) {
      return 'El correo electrónico ya está registrado o no es válido.';
    } else if (originalMessage.toLowerCase().contains('password')) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    } else if (originalMessage.toLowerCase().contains('network') || 
               originalMessage.toLowerCase().contains('connection')) {
      return 'Problema de conexión. Verifica tu internet e intenta de nuevo.';
    }
    return 'Ocurrió un error inesperado. Por favor intenta de nuevo.';
  }

  void _validateFields() {
    setState(() {
      nombreError = null;
      correoError = null;
      passwordError = null;
    });

    if (nombreController.text.isEmpty) {
      setState(() {
        nombreError = 'El nombre es obligatorio';
      });
    } else if (nombreController.text.length < 2) {
      setState(() {
        nombreError = 'El nombre debe tener al menos 2 caracteres';
      });
    }

    if (correoController.text.isEmpty) {
      setState(() {
        correoError = 'El correo es obligatorio';
      });
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(correoController.text)) {
      setState(() {
        correoError = 'Ingresa un correo válido';
      });
    }

    if (passwordController.text.isEmpty) {
      setState(() {
        passwordError = 'La contraseña es obligatoria';
      });
    } else if (passwordController.text.length < 8) {
      setState(() {
        passwordError = 'La contraseña debe tener al menos 8 caracteres';
      });
    }
  }

  bool _isFormValid() {
    return nombreError == null && 
           correoError == null && 
           passwordError == null &&
           nombreController.text.isNotEmpty &&
           correoController.text.isNotEmpty &&
           passwordController.text.isNotEmpty;
  }

  void _submitForm() async {
    _validateFields();
    
    if (_isFormValid()) {
      rolSeleccionado = esVeterinario ? 'VETERINARIO' : 'CLIENTE';
      await registrarUsuario(
        nombreController.text,
        correoController.text,
        passwordController.text,
        rolSeleccionado!,
      );
    }
  }

  void _onSuccessComplete() {
    setState(() {
      _showSuccess = false;
    });
    
    // Navegar después de la animación
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RegistroMascotaPage()),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword,
          onChanged: (_) => _validateFields(),
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: errorText != null 
                ? const Color(0xFFFFEBEE)
                : const Color(0xFFF5F6F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null 
                  ? const BorderSide(color: Colors.red, width: 1)
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null 
                  ? const BorderSide(color: Colors.red, width: 1)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null 
                    ? Colors.red 
                    : const Color(0xFFB6A9F8),
                width: 2,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRolSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: const Text('Soy veterinario'),
        subtitle: Text(esVeterinario ? 'Registrándote como veterinario' : 'Registrándote como usuario común'),
        value: esVeterinario,
        onChanged: (bool? value) {
          setState(() {
            esVeterinario = value ?? false;
            rolSeleccionado = esVeterinario ? 'VETERINARIO' : 'CLIENTE';
          });
        },
        activeColor: const Color(0xFFB6A9F8),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SuccessFeedbackWidget(
        showSuccess: _showSuccess,
        successMessage: '¡Registro exitoso!\nBienvenido',
        onComplete: _onSuccessComplete,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 1),
                const Center(
                  child: Text(
                    '¡Hola! Bienvenido',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 1),
                const Center(
                  child: Text(
                    'Regístrate',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'CREA UNA CUENTA',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildTextField('Nombre', nombreController, errorText: nombreError),
                const SizedBox(height: 15),
                
                _buildTextField('Correo', correoController, errorText: correoError),
                const SizedBox(height: 15),
                
                _buildTextField(
                  'Contraseña',
                  passwordController,
                  isPassword: true,
                  errorText: passwordError,
                ),
                const SizedBox(height: 15),
                
                _buildRolSelector(),
                const SizedBox(height: 35),
                
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB6A9F8)),
                        )
                      : ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0XFFB6A9F8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 55,
                              vertical: 15,
                            ),
                          ),
                          child: const Text(
                            'COMENZAR',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
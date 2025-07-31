import 'package:flutter/material.dart';
import 'package:patitas_care/inicio_page.dart';
import 'registro_page.dart';
import 'auth_service.dart';
import 'success_feedback_widget.dart';
import 'notification_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    if (!_validarCampos()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.login(
        correo: correoController.text.trim(),
        password: passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Mostrar animación de éxito
        setState(() {
          _showSuccess = true;
        });
      } else {
        if (mounted) {
          final errorMessage = result['body']?['error'] ?? 
                             result['body']?['mensaje'] ?? 
                             'Credenciales incorrectas. Verifica tu correo y contraseña.';
          
          context.showErrorNotification(
            errorMessage,
            actionLabel: 'Reintentar',
            onAction: () => iniciarSesion(),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        context.showErrorNotification(
          'Error de conexión. Verifica tu internet e intenta nuevamente.',
          actionLabel: 'Reintentar',
          onAction: () => iniciarSesion(),
        );
      }
    }
  }

  void _onSuccessComplete() {
    setState(() {
      _showSuccess = false;
    });
    
    // Navegar a la pantalla principal de la app
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const InicioPage()),
    );
  }

  bool _validarCampos() {
    if (correoController.text.isEmpty || passwordController.text.isEmpty) {
      context.showWarningNotification('Por favor, completa todos los campos.');
      return false;
    }

    // Validación básica de formato de email
    if (!correoController.text.contains('@') || !correoController.text.contains('.')) {
      context.showWarningNotification('Por favor, ingresa un correo válido.');
      return false;
    }

    return true;
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuccessFeedbackWidget(
      showSuccess: _showSuccess,
      successMessage: '¡Bienvenido de vuelta!',
      onComplete: _onSuccessComplete,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => {
                    if (Navigator.canPop(context)) {
                        Navigator.pop(context)
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          )
                        }
                    },
                ),

                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    '¡Hola! Bienvenido',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Inicia Sesión',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'ACCEDE A TU CUENTA',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                
                const SizedBox(height: 40),
                _buildTextField('Correo', correoController),
                
                const SizedBox(height: 15),
                _buildTextField(
                  'Contraseña',
                  passwordController,
                  isPassword: true,
                ),
                
                const SizedBox(height: 35),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0XFFB6A9F8)),
                        )
                      : ElevatedButton(
                          onPressed: iniciarSesion,
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
                            'INICIAR SESIÓN',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegistroPage()),
                      );
                    },
                    child: const Text(
                      '¿No tienes una cuenta? Regístrate',
                      style: TextStyle(color: Colors.grey),
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
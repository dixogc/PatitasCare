import 'package:flutter/material.dart';
import 'package:patitas_care/inicio_page.dart';
import 'package:patitas_care/main.dart';
import 'auth_service.dart';


class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Iniciar animación
    _animationController.forward();
    
    // Verificar sesión después de un delay
    _verificarSesion();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _verificarSesion() async {
    try {
      // Esperar un mínimo de 2 segundos para mostrar el splash
      await Future.delayed(Duration(milliseconds: 2000));
      
      // Verificar si existe un token guardado
      final token = await AuthService.getToken();
      
      if (token != null && token.isNotEmpty) {
        print('Token encontrado, verificando validez...');
        
        // Token existe, verificar si es válido
        final esValido = await AuthService.verificarToken();
        
        if (esValido) {
          print('Token válido, navegando al inicio...');
          // Token válido, ir directamente al inicio
          _navegarAInicio();
        } else {
          print('Token inválido, limpiando y navegando al welcome...');
          // Token inválido, limpiar y ir al welcome
          await AuthService.logout();
          _navegarAWelcome();
        }
      } else {
        print('No hay token, navegando al welcome...');
        // No hay token, ir al welcome
        _navegarAWelcome();
      }
    } catch (e) {
      print('Error en verificación de sesión: $e');
      // Error en la verificación, ir al welcome por seguridad
      _navegarAWelcome();
    }
  }

  void _navegarAInicio() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const InicioPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  void _navegarAWelcome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB6A9F8),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo animado
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.pets,
                        size: 70,
                        color: Color(0xFFB6A9F8),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Título
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Patitas ',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          Icons.pets,
                          size: 32,
                          color: Colors.white,
                        ),
                        Text(
                          ' Care',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Subtítulo
                    Text(
                      'Cuidando a tus mascotas',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    SizedBox(height: 50),
                    
                    // Indicador de carga
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    Text(
                      'Cargando...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
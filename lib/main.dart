import 'package:flutter/material.dart';
import 'registro_page.dart';

void main() {
  runApp(const PatitasCareApp());
}

class PatitasCareApp extends StatelessWidget {
  const PatitasCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Patitas Care',
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 250,
              width: double.infinity,
              color: Color(0xFFB6A9F8),
            ),
          ),

          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Patitas ',
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.pets, size: 35, color: Colors.black),
              Text(
                ' Care',
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 35),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Miles de personas que adoramos a nuestras mascotas!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),

          const SizedBox(height: 70),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegistroPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0XFFB6A9F8),
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Registrate',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            '¿Ya tienes una cuenta? Inicia sesión',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    path.lineTo(0, size.height - 60);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 60);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 120);
    var secondEndPonit = Offset(size.width, size.height - 60);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPonit.dx,
      secondEndPonit.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

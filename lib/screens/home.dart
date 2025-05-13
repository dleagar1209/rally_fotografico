import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.pushNamed(context, '/login');
  }

  void _navigateToSignUp(BuildContext context) {
    Navigator.pushNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bienvenido a RallyFotografico',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text(
                'RallyFotografico es una aplicación que te permite participar en concursos de fotografía, '
                'compartir tus imágenes y competir con otros usuarios. ¡Únete y muestra tu talento!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E90FF), // color azul
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToSignUp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF32CD32), // color verde
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(fontSize: 18, color: Colors.white),
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

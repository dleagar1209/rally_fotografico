// Pantalla de inicio/bienvenida de la app.
// Permite acceder al login y registro, y cambiar el modo oscuro.

import 'package:flutter/material.dart';
import 'login.dart';
import 'signUp.dart';
import '../main.dart'; // Asegúrate de importar el notifier

class Home extends StatelessWidget {
  const Home({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const Login()));
  }

  void _navigateToSignUp(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SignUp()));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = darkModeNotifier.value;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: darkModeNotifier,
            builder: (_, isDark, __) {
              return IconButton(
                icon: Icon(
                  isDark ? Icons.nights_stay : Icons.wb_sunny,
                  color: isDark ? Colors.yellowAccent : Colors.orange,
                ),
                onPressed: () {
                  darkModeNotifier.value = !isDark;
                },
              );
            },
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF2F2F2),
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
              Text(
                'Inicia sesión y empieza a subir imágenes, las imágenes serán puntuadas por otros usuarios. ¡Únete y empieza a subir imágenes!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E90FF),
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
                    backgroundColor: const Color(0xFF32CD32),
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

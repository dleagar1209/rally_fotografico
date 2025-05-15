import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rally_fotografico/screens/imagenes.dart';
import 'screens/home.dart';
import 'screens/rally.dart';
import 'screens/options.dart';
import 'screens/users.dart';

// Notificador global para el modo oscuro
ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Obtiene el usuario actual y, si existe, carga el atributo "oscuro" de Firestore
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    bool oscuro = false;
    if (doc.exists) {
      oscuro = doc.get('oscuro') ?? false;
    }
    darkModeNotifier.value = oscuro;
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDarkMode, _) {
        return MaterialApp(
          title: 'RallyFotografico',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                final user = snapshot.data;
                if (user == null) {
                  return const Home();
                } else {
                  return const Rally();
                }
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          routes: {
            '/home': (context) => const Home(),
            '/rally': (context) => const Rally(),
            '/options': (context) => const Options(),
            "/users": (context) => const Users(),
            "/imagenes": (context) => const Imagenes(),
          },
        );
      },
    );
  }
}

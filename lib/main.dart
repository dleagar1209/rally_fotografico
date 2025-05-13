import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- nuevo
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home.dart';
import 'screens/rally.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // <-- inicializas Firebase
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RallyFotografico',
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
      },
    );
  }
}

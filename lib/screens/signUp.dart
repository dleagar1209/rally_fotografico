// Pantalla de registro de usuario.
// Permite crear una cuenta nueva, validando nombre, email y contraseña, y guarda los datos en Firebase.
// Al registrarse, el usuario es asignado con el rol de "participante" por defecto.
// La contraseña debe tener al menos 7 caracteres, incluyendo una mayúscula, una minúscula y un carácter especial.
// Se utiliza Firebase Authentication para la creación de usuarios y Cloud Firestore para el almacenamiento de datos.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // Para acceder a darkModeNotifier

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _obscurePassword = true;

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Requerido';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Requerido';
    }
    final RegExp emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Requerido';
    }
    final RegExp passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W).{7,}$',
    );
    if (!passwordRegex.hasMatch(value)) {
      return 'La contraseña debe tener al menos 7 caracteres, una mayúscula, una minúscula y un carácter especial';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        final String name = _nameController.text.trim();
        final String email = _emailController.text.trim();
        final String password = _passwordController.text.trim();
        final String rol = 'participante'; // Siempre participante

        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);
        String userId = userCredential.user!.uid;

        await _firestore.collection('users').doc(userId).set({
          'id': userId,
          'nombre': name,
          'email': email,
          'rol': rol,
          'oscuro': darkModeNotifier.value,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'numeroVotos': 3,
        });

        // Incrementar NumeroUsuarios en el documento de la colección rally
        await _firestore.collection('rally').doc('info').set({
          'NumeroUsuarios': FieldValue.increment(1),
        }, SetOptions(merge: true));

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Usuario creado exitosamente'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/rally');
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } catch (error) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Error'),
                content: Text(error.toString()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text('Registro', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre y Apellido',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleSignUp,
                    child: const Text('Registrarse'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

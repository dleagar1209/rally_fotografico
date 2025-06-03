// Pantalla de opciones/configuración del usuario.
// Permite cambiar nombre, modo oscuro, cerrar sesión, eliminar cuenta y finalizar rally (si es admin global).

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // Asegúrate de importar main.dart para acceder a darkModeNotifier
import 'home.dart'; // Se utiliza para redirigir a Home en caso de cierre exitoso

class Options extends StatefulWidget {
  const Options({Key? key}) : super(key: key);

  @override
  _OptionsState createState() => _OptionsState();
}

class _OptionsState extends State<Options> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isDarkMode = darkModeNotifier.value;
  String _userName = "";
  bool _loading = true;
  bool _isAdminGlobal = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Carga la información del usuario desde Firestore, incluyendo el modo oscuro
  Future<void> _loadUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (doc.exists) {
        setState(() {
          _userName = doc.get('nombre') ?? "";
          _isDarkMode = doc.get('oscuro') ?? false;
          _isAdminGlobal = doc.get('rol') == 'administrador global';
          // Actualiza el ValueNotifier global con el valor obtenido
          darkModeNotifier.value = _isDarkMode;
          _loading = false;
        });
      }
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  // Actualiza el nombre del usuario en Firestore
  Future<void> _updateUserName(String newName) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'nombre': newName,
      });
      setState(() {
        _userName = newName;
      });
    }
  }

  // Actualiza el atributo "oscuro" en Firestore según el modo
  Future<void> _updateUserMode(bool darkMode) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'oscuro': darkMode,
      });
    }
  }

  // Diálogo para cambiar el nombre del usuario
  void _showChangeNameDialog() {
    final TextEditingController _nameController = TextEditingController(
      text: _userName,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cambiar Nombre'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nuevo Nombre'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String newName = _nameController.text.trim();
                if (newName.isNotEmpty) {
                  await _updateUserName(newName);
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Función para cerrar sesión
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // Al cerrar sesión con éxito, se redirige a Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
        (route) => false,
      );
    } catch (error) {
      // En caso de error, se muestra un diálogo
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error al cerrar sesión'),
            content: Text(error.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // Función para eliminar la cuenta
  Future<void> _deleteAccount() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Eliminar todas las imágenes asociadas al usuario
      QuerySnapshot imagesSnapshot =
          await _firestore
              .collection('imagenes')
              .where('usuario', isEqualTo: currentUser.uid)
              .get();
      int numImages = imagesSnapshot.docs.length;
      for (var doc in imagesSnapshot.docs) {
        await doc.reference.delete();
      }
      // Eliminar el documento del usuario en Firestore
      await _firestore.collection('users').doc(currentUser.uid).delete();

      // Decrementar NumeroUsuarios en la colección rally
      await _firestore.collection('rally').doc('info').set({
        'NumeroUsuarios': FieldValue.increment(-1),
      }, SetOptions(merge: true));
      // Decrementar numeroImagenes en la colección rally según imágenes eliminadas
      if (numImages > 0) {
        await _firestore.collection('rally').doc('info').set({
          'numeroImagenes': FieldValue.increment(-numImages),
        }, SetOptions(merge: true));
      }

      // Eliminar la cuenta del usuario en Firebase Authentication
      try {
        await currentUser.delete();
      } catch (error) {
        debugPrint("Error al eliminar la cuenta de Firebase Auth: $error");
        return;
      }
      // Redirige a Home después de eliminar la cuenta
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Opción para cambiar datos del usuario
            ListTile(
              title: const Text('Cambiar datos de usuario'),
              subtitle: Text('Nombre: $_userName'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _showChangeNameDialog,
              ),
            ),
            const Divider(),
            // Opción para activar/desactivar modo oscuro mediante switch
            ListTile(
              title: const Text('Modo Oscuro'),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  // Actualiza el ValueNotifier global y Firebase
                  darkModeNotifier.value = value;
                  _updateUserMode(value);
                },
              ),
            ),
            const Divider(),
            // Opción para cerrar sesión
            ListTile(
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.red),
                onPressed: _signOut,
              ),
            ),
            const Divider(),
            // Nueva opción para eliminar cuenta
            ListTile(
              title: const Text(
                'Eliminar cuenta',
                style: TextStyle(color: Colors.red),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () async {
                  // Opcional: Confirmar acción con un diálogo
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Confirmar eliminación'),
                        content: const Text(
                          '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción eliminará todas tus imágenes y datos.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm == true) {
                    await _deleteAccount();
                  }
                },
              ),
            ),
            // Opción para finalizar rally, visible solo para administrador global
            if (_isAdminGlobal)
              ListTile(
                title: const Text(
                  'Finalizar rally',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.emoji_events, color: Colors.blue),
                  onPressed: () {
                    Navigator.pushNamed(context, '/endRally');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

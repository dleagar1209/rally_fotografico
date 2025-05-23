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
  bool _isAdmin = false;
  String _userName = "";
  bool _loading = true;

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
          String rol = doc.get('rol') ?? "participante";
          _isAdmin = rol == 'administrador';
          _isDarkMode = doc.get('oscuro') ?? false;
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

  // Actualiza el atributo "rol" del usuario en Firestore
  Future<void> _updateUserRole(bool isAdmin) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String newRole = isAdmin ? 'administrador' : 'participante';
      await _firestore.collection('users').doc(currentUser.uid).update({
        'rol': newRole,
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
      for (var doc in imagesSnapshot.docs) {
        await doc.reference.delete();
      }
      // Eliminar el documento del usuario en Firestore
      await _firestore.collection('users').doc(currentUser.uid).delete();

      // Eliminar la cuenta del usuario en Firebase Authentication
      try {
        await currentUser.delete();
      } catch (error) {
        // Si se requiere reautenticación, se mostrará un error.
        debugPrint("Error al eliminar la cuenta de Firebase Auth: $error");
        // Se puede informar al usuario que es necesario reautenticarse antes de eliminar la cuenta.
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
      appBar: AppBar(title: const Text('Opciones')),
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
            // Opción para cambiar el rol a administrador o participante
            ListTile(
              title: const Text('Usuario Administrador'),
              trailing: Checkbox(
                value: _isAdmin,
                onChanged: (bool? newValue) async {
                  if (newValue != null) {
                    setState(() {
                      _isAdmin = newValue;
                    });
                    await _updateUserRole(_isAdmin);
                  }
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
          ],
        ),
      ),
    );
  }
}

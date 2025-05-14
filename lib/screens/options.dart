import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // Asegúrate de importar main.dart para acceder a darkModeNotifier

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

  // Carga la información del usuario desde Firestore
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
            // Opción para activar el modo oscuro
            ListTile(
              title: const Text('Modo Oscuro'),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  // Actualiza el ValueNotifier global para que toda la app cambie de tema
                  darkModeNotifier.value = value;
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
          ],
        ),
      ),
    );
  }
}

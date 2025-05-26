import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'imageDetail.dart'; // Importa la clase desde el otro fichero

class Rally extends StatelessWidget {
  const Rally({Key? key}) : super(key: key);

  void _navigateToUsers(BuildContext context) {
    Navigator.pushNamed(context, '/users');
  }

  void _navigateToImagenes(BuildContext context) {
    Navigator.pushNamed(context, '/imagenes');
  }

  Future<void> _showImageSourceActionSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de Galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      try {
        final imageUrl = await _uploadImageToFirebase(File(pickedFile.path));
        final user = FirebaseAuth.instance.currentUser;

        if (user != null && imageUrl != null) {
          await FirebaseFirestore.instance.collection('imagenes').add({
            'imagen': imageUrl,
            'usuario': user.uid,
            'fecha': Timestamp.now(),
            'estado': 'por aprobar', // Atributo añadido
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen subida exitosamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error: Usuario no autenticado o error al subir imagen',
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se seleccionó imagen')));
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      final fileName = path.basename(imageFile.path);
      final storageRef = FirebaseStorage.instance.ref().child(
        'imagenes/$fileName',
      );
      final uploadTask = await storageRef.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error al subir imagen a Firebase Storage: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("No se pudo cargar el usuario")),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final bool isAdmin = userData['rol'] == "administrador";

        // Stream según el rol
        final imagesStream =
            isAdmin
                ? FirebaseFirestore.instance
                    .collection('imagenes')
                    .where('estado', whereIn: ['aprobada', 'por aprobar'])
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('imagenes')
                    .where('estado', isEqualTo: 'aprobada')
                    .snapshots();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rally Fotográfico'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/options');
                },
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: imagesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text("No hay imágenes"));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 16 / 9,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final imageUrl = data['imagen'];
                  String estado = data['estado'] ?? '';
                  if (estado.isNotEmpty) {
                    estado = estado[0].toUpperCase() + estado.substring(1);
                  }
                  return GridTile(
                    footer:
                        (data['estado'] != 'aprobada')
                            ? GridTileBar(
                              backgroundColor: Colors.black54,
                              title: Text(
                                estado,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            )
                            : null,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ImageDetailScreen(
                                  documentId: docs[index].id,
                                ),
                          ),
                        );
                      },
                      onLongPress:
                          isAdmin && (data['estado'] == 'por aprobar')
                              ? () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.thumb_up,
                                            color: Colors.green,
                                            size: 40,
                                          ),
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('imagenes')
                                                .doc(docs[index].id)
                                                .update({'estado': 'aprobada'});
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Imagen aprobada',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.thumb_down,
                                            color: Colors.red,
                                            size: 40,
                                          ),
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('imagenes')
                                                .doc(docs[index].id)
                                                .update({'estado': 'denegada'});
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Imagen denegada',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                              : null,
                      child:
                          imageUrl != null
                              ? Image.network(imageUrl, fit: BoxFit.cover)
                              : const Icon(Icons.broken_image),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.camera),
            onPressed: () => _showImageSourceActionSheet(context),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.image),
                label: 'Imágenes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.photo_album_outlined),
                label: 'Tus Imágenes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_sharp),
                label: 'Usuarios',
              ),
            ],
            currentIndex: 0,
            onTap: (index) {
              if (index == 1) {
                _navigateToImagenes(context);
              } else if (index == 2) {
                _navigateToUsers(context);
              }
            },
          ),
        );
      },
    );
  }
}

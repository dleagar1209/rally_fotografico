// Pantalla de gestión de imágenes propias del usuario.
// Permite ver, eliminar y modificar imágenes subidas por el usuario actual.
// Requiere autenticación de Firebase y acceso a Firestore y Storage.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class Imagenes extends StatefulWidget {
  const Imagenes({Key? key}) : super(key: key);

  @override
  _ImagenesState createState() => _ImagenesState();
}

class _ImagenesState extends State<Imagenes> {
  @override
  Widget build(BuildContext context) {
    // Context garantizado vivo durante todo el ciclo de vida de este State
    final scaffoldContext = context;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text(''), automaticallyImplyLeading: false),
      body:
          user == null
              ? const Center(child: Text("Usuario no autenticado"))
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('imagenes')
                        .where('usuario', isEqualTo: user.uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("No has subido imágenes"));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 16 / 9,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final String? imageUrl = data['imagen'] as String?;
                      final fecha = (data['fecha'] as Timestamp?)?.toDate();
                      final docId = docs[index].id;

                      return GridTile(
                        footer: GridTileBar(
                          backgroundColor: Colors.black54,
                          title: Text(
                            fecha != null
                                ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'
                                : 'Sin fecha',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: scaffoldContext,
                              builder: (sheetContext) {
                                return Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      title: const Text(
                                        'Eliminar imagen',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onTap: () async {
                                        // 1) Cierra el sheet
                                        Navigator.pop(sheetContext);
                                        await Future.delayed(
                                          const Duration(milliseconds: 100),
                                        );
                                        // 2) Pide confirmación
                                        final bool?
                                        confirm = await showDialog<bool>(
                                          context: scaffoldContext,
                                          useRootNavigator: true,
                                          builder: (dialogCtx) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Confirmar eliminación',
                                              ),
                                              content: const Text(
                                                '¿Estás seguro de eliminar esta imagen?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        dialogCtx,
                                                        false,
                                                      ),
                                                  child: const Text('Cancelar'),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        dialogCtx,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    'Eliminar',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (confirm != true || imageUrl == null)
                                          return;

                                        // 3) Realiza la eliminación
                                        try {
                                          await FirebaseStorage.instance
                                              .refFromURL(imageUrl)
                                              .delete();
                                          await FirebaseFirestore.instance
                                              .collection('imagenes')
                                              .doc(docId)
                                              .delete();
                                          // Decrementar NumeroImagenes en la colección rally
                                          await FirebaseFirestore.instance
                                              .collection('rally')
                                              .doc('info')
                                              .set({
                                                'numeroImagenes':
                                                    FieldValue.increment(-1),
                                              }, SetOptions(merge: true));
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            scaffoldContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text("Imagen eliminada"),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            scaffoldContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $e"),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      title: const Text(
                                        'Modificar imagen',
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                      onTap: () async {
                                        Navigator.pop(sheetContext);
                                        await Future.delayed(
                                          const Duration(milliseconds: 100),
                                        );

                                        final picker = ImagePicker();
                                        final XFile? pickedFile = await picker
                                            .pickImage(
                                              source: ImageSource.camera,
                                            );
                                        if (pickedFile == null ||
                                            imageUrl == null)
                                          return;

                                        final newImageFile = File(
                                          pickedFile.path,
                                        );
                                        try {
                                          await FirebaseStorage.instance
                                              .refFromURL(imageUrl)
                                              .delete();
                                          final fileName = path.basename(
                                            newImageFile.path,
                                          );
                                          final storageRef = FirebaseStorage
                                              .instance
                                              .ref()
                                              .child('imagenes/$fileName');
                                          final uploadTask = await storageRef
                                              .putFile(newImageFile);
                                          final newImageUrl =
                                              await uploadTask.ref
                                                  .getDownloadURL();

                                          await FirebaseFirestore.instance
                                              .collection('imagenes')
                                              .doc(docId)
                                              .update({'imagen': newImageUrl});
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            scaffoldContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Imagen actualizada",
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            scaffoldContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $e"),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
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
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Imágenes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album_outlined),
            label: 'Tus Imágenes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
        ],
        currentIndex: 1,
        onTap: (idx) {
          if (idx == 0) Navigator.pushNamed(context, '/rally');
          if (idx == 2) Navigator.pushNamed(context, '/users');
        },
      ),
    );
  }
}

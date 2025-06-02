import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Users extends StatelessWidget {
  const Users({Key? key}) : super(key: key);

  String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  void _navigateToRally(BuildContext context) {
    Navigator.pushNamed(context, '/rally');
  }

  void _navigateToImagenes(BuildContext context) {
    Navigator.pushNamed(context, '/imagenes');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser?.uid)
              .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("No se pudo cargar el usuario actual")),
          );
        }

        final currentUserData =
            userSnapshot.data!.data() as Map<String, dynamic>;
        final String currentRol = currentUserData['rol'] ?? '';
        final bool isAdminGlobal = currentRol == 'administrador global';

        return Scaffold(
          appBar: AppBar(
            title: const Text(''),
            automaticallyImplyLeading: false,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('fechaCreacion', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Usuario")),
                    DataColumn(label: Text("Fecha")),
                    DataColumn(label: Text("Rol")),
                  ],
                  rows:
                      users.map((doc) {
                        final userData = doc.data() as Map<String, dynamic>;
                        final name = userData['nombre'] ?? 'Sin nombre';
                        final role = userData['rol'] ?? 'Desconocido';
                        final dateTimestamp =
                            userData['fechaCreacion'] as Timestamp?;
                        final createdDate =
                            dateTimestamp != null
                                ? formatDate(dateTimestamp)
                                : 'Sin fecha';
                        final userId = userData['id'];

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(name),
                              onTap:
                                  isAdminGlobal && currentUser?.uid != userId
                                      ? () {
                                        final parentContext = context;
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (ctx) {
                                            bool isUserAdmin =
                                                role == 'administrador';

                                            return StatefulBuilder(
                                              builder: (context, setState) {
                                                return Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CheckboxListTile(
                                                      title: const Text(
                                                        'Administrador',
                                                      ),
                                                      value: isUserAdmin,
                                                      onChanged: (value) async {
                                                        final newRole =
                                                            value == true
                                                                ? 'administrador'
                                                                : 'participante';

                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(userId)
                                                            .update({
                                                              'rol': newRole,
                                                            });

                                                        setState(() {});
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      title: const Text(
                                                        'Expulsar',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                      onTap: () async {
                                                        Navigator.pop(context);
                                                        final confirm = await showDialog<
                                                          bool
                                                        >(
                                                          context:
                                                              parentContext,
                                                          builder:
                                                              (
                                                                dctx,
                                                              ) => AlertDialog(
                                                                title: const Text(
                                                                  'Confirmar expulsión',
                                                                ),
                                                                content: const Text(
                                                                  '¿Seguro que quieres expulsar a este usuario? Se eliminarán todos sus datos e imágenes.',
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed:
                                                                        () => Navigator.pop(
                                                                          dctx,
                                                                          false,
                                                                        ),
                                                                    child: const Text(
                                                                      'Cancelar',
                                                                    ),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed:
                                                                        () => Navigator.pop(
                                                                          dctx,
                                                                          true,
                                                                        ),
                                                                    child: const Text(
                                                                      'Expulsar',
                                                                      style: TextStyle(
                                                                        color:
                                                                            Colors.red,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                        );

                                                        if (confirm == true) {
                                                          // Mostrar loading
                                                          showDialog(
                                                            context:
                                                                parentContext,
                                                            barrierDismissible:
                                                                false,
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => const Center(
                                                                  child:
                                                                      CircularProgressIndicator(),
                                                                ),
                                                          );

                                                          try {
                                                            // Eliminar imágenes del usuario
                                                            final imagesSnapshot =
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                      'imagenes',
                                                                    )
                                                                    .where(
                                                                      'usuario',
                                                                      isEqualTo:
                                                                          userId,
                                                                    )
                                                                    .get();

                                                            for (var imgDoc
                                                                in imagesSnapshot
                                                                    .docs) {
                                                              final imgData =
                                                                  imgDoc.data();
                                                              final imageUrl =
                                                                  imgData['imagen'];
                                                              if (imageUrl !=
                                                                  null) {
                                                                try {
                                                                  await FirebaseStorage
                                                                      .instance
                                                                      .refFromURL(
                                                                        imageUrl,
                                                                      )
                                                                      .delete();
                                                                } catch (_) {}
                                                              }
                                                              await imgDoc
                                                                  .reference
                                                                  .delete();
                                                            }

                                                            // Eliminar usuario
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                  'users',
                                                                )
                                                                .doc(userId)
                                                                .delete();

                                                            // Decrementar número de usuarios en el documento info de la colección rally
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                  'rally',
                                                                )
                                                                .doc('info')
                                                                .set(
                                                                  {
                                                                    'NumeroUsuarios':
                                                                        FieldValue.increment(
                                                                          -1,
                                                                        ),
                                                                  },
                                                                  SetOptions(
                                                                    merge: true,
                                                                  ),
                                                                );

                                                            // Mostrar confirmación
                                                            Navigator.pop(
                                                              parentContext,
                                                            ); // cerrar loading
                                                            ScaffoldMessenger.of(
                                                              parentContext,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Usuario expulsado de Firestore y sus imágenes eliminadas. Elimina la cuenta de Auth desde el backend si es necesario.',
                                                                ),
                                                              ),
                                                            );
                                                          } catch (e) {
                                                            Navigator.pop(
                                                              parentContext,
                                                            ); // cerrar loading
                                                            ScaffoldMessenger.of(
                                                              parentContext,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Error al expulsar: $e',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        );
                                      }
                                      : null,
                            ),
                            DataCell(Text(createdDate)),
                            DataCell(Text(role)),
                          ],
                        );
                      }).toList(),
                ),
              );
            },
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
                icon: Icon(Icons.people),
                label: 'Usuarios',
              ),
            ],
            currentIndex: 2,
            onTap: (index) {
              if (index == 0) {
                _navigateToRally(context);
              } else if (index == 1) {
                _navigateToImagenes(context);
              }
            },
          ),
        );
      },
    );
  }
}

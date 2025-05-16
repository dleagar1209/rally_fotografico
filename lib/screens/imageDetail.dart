import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageDetailScreen extends StatelessWidget {
  final String documentId;
  const ImageDetailScreen({Key? key, required this.documentId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('imagenes')
              .doc(documentId)
              .get(),
      builder: (context, snapshotImage) {
        if (snapshotImage.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshotImage.error}")),
          );
        }
        if (snapshotImage.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshotImage.hasData || !snapshotImage.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("No se encontró la imagen")),
          );
        }
        final data = snapshotImage.data!.data() as Map<String, dynamic>;
        final String imageUrl = data['imagen'] as String;
        final String usuarioId = data['usuario'] as String;
        final DateTime fecha = (data['fecha'] as Timestamp).toDate();
        final String estado = data['estado'] as String;
        final formattedFecha =
            "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";
        final displayEstado =
            estado.isNotEmpty
                ? estado[0].toUpperCase() + estado.substring(1)
                : '';

        // Obtiene el nombre del usuario a partir de su id
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(usuarioId)
                  .get(),
          builder: (context, snapshotUser) {
            String nombreUsuario = usuarioId;
            if (snapshotUser.hasData && snapshotUser.data!.exists) {
              final userData =
                  snapshotUser.data!.data() as Map<String, dynamic>;
              nombreUsuario = userData['nombre'] as String? ?? usuarioId;
            }
            return Scaffold(
              appBar: AppBar(
                title: const Text("Detalle de Imagen"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Información de la Imagen"),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  Text("Usuario: $nombreUsuario"),
                                  Text("Fecha: $formattedFecha"),
                                  Text("Estado: $displayEstado"),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text("Cerrar"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

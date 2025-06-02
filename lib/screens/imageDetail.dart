import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                title: const Text(""),
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
              body: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: InteractiveViewer(
                        child: Image.network(imageUrl, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  // Sistema de votación con estrellas
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 100.0,
                      top: 32.0, // Más alto aún respecto al borde inferior
                    ),
                    child: _StarRatingWidget(documentId: documentId),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Widget separado para el sistema de estrellas
class _StarRatingWidget extends StatefulWidget {
  final String documentId;
  const _StarRatingWidget({required this.documentId});

  @override
  State<_StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<_StarRatingWidget> {
  int selectedStars = 0;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < selectedStars ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () {
                setState(() {
                  selectedStars = index + 1;
                });
              },
            );
          }),
        ),
        if (selectedStars > 0)
          loading
              ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              )
              : ElevatedButton(
                onPressed: () async {
                  setState(() {
                    loading = true;
                  });
                  // Comprobar numeroVotos del usuario
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debes iniciar sesión para votar.'),
                      ),
                    );
                    setState(() {
                      loading = false;
                    });
                    return;
                  }
                  final userDoc =
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .get();
                  int numeroVotos =
                      (userDoc.data()?['numeroVotos'] ?? 0) as int;
                  if (numeroVotos <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No te quedan votos disponibles.'),
                      ),
                    );
                    setState(() {
                      loading = false;
                    });
                    return;
                  }
                  // Permitir votar y restar 1 a numeroVotos
                  final docRef = FirebaseFirestore.instance
                      .collection('imagenes')
                      .doc(widget.documentId);
                  final snapshot = await docRef.get();
                  if (snapshot.exists) {
                    final data = snapshot.data() as Map<String, dynamic>;
                    final List<dynamic> votos = List.from(data['votos'] ?? []);
                    votos.add(selectedStars);
                    final double notaMedia =
                        votos.fold<double>(
                          0,
                          (sum, voto) => sum + (voto as int),
                        ) /
                        votos.length;
                    await docRef.update({
                      'votos': votos,
                      'notaMedia': notaMedia,
                    });
                    // Restar 1 a numeroVotos del usuario
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .update({'numeroVotos': numeroVotos - 1});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voto registrado exitosamente'),
                      ),
                    );
                    setState(() {
                      selectedStars = 0;
                      loading = false;
                    });
                  } else {
                    setState(() {
                      loading = false;
                    });
                  }
                },
                child: const Text('Confirmar'),
              ),
      ],
    );
  }
}

// Pantalla de podium y finalización del rally fotográfico.
// Muestra el top 3 de imágenes con sus autores y notas medias.
// Permite al administrador finalizar el rally, eliminando todas las imágenes y reiniciando los votos de los usuarios.
// Navega a la pantalla principal de rally tras finalizar.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'rally.dart'; // Importa la pantalla de Rally

class EndRallyScreen extends StatelessWidget {
  const EndRallyScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _getTopImages() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('imagenes')
            .where('estado', isEqualTo: 'aprobada')
            .get();
    final images =
        snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            })
            .where((img) => img['notaMedia'] != null)
            .toList();
    images.sort(
      (a, b) => (b['notaMedia'] as num).compareTo(a['notaMedia'] as num),
    );
    return images.take(3).toList();
  }

  Future<String> _getUserName(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      return data?['nombre'] ?? userId;
    }
    return userId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''), // Sin título
        automaticallyImplyLeading: false, // Quita la flecha de atrás
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getTopImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay imágenes aprobadas.'));
          }
          final top = snapshot.data!;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (top.isNotEmpty)
                FutureBuilder<String>(
                  future: _getUserName(top[0]['usuario']),
                  builder: (context, userSnap) {
                    final nombre = userSnap.data ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        if (top[0]['imagen'] != null)
                          Container(
                            height: 220,
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: NetworkImage(top[0]['imagen']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          '1º $nombre',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nota media: ${top[0]['notaMedia']?.toStringAsFixed(2) ?? '-'}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              if (top.length > 1)
                FutureBuilder<String>(
                  future: _getUserName(top[1]['usuario']),
                  builder: (context, userSnap) {
                    final nombre = userSnap.data ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          '2º $nombre',
                          style: const TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Nota media: ${top[1]['notaMedia']?.toStringAsFixed(2) ?? '-'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              if (top.length > 2)
                FutureBuilder<String>(
                  future: _getUserName(top[2]['usuario']),
                  builder: (context, userSnap) {
                    final nombre = userSnap.data ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          '3º $nombre',
                          style: const TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Nota media: ${top[2]['notaMedia']?.toStringAsFixed(2) ?? '-'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 50.0, right: 50.0, bottom: 100.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 74, 74, 75),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () async {
            // Eliminar todas las imágenes de Firestore y Storage
            final firestore = FirebaseFirestore.instance;
            final storage = FirebaseStorage.instance;
            final imagesSnapshot = await firestore.collection('imagenes').get();
            for (final doc in imagesSnapshot.docs) {
              final data = doc.data();
              final imageUrl = data['imagen'] as String?;
              if (imageUrl != null && imageUrl.contains('/o/')) {
                try {
                  final path = Uri.decodeFull(
                    imageUrl.split('/o/')[1].split('?').first,
                  );
                  await storage.ref().child(path).delete();
                } catch (_) {}
              }
              await doc.reference.delete();
            }
            // Reiniciar numeroVotos a 3 para todos los usuarios
            final usersSnapshot = await firestore.collection('users').get();
            for (final userDoc in usersSnapshot.docs) {
              await userDoc.reference.update({'numeroVotos': 3});
            }
            // Opcional: mostrar confirmación
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Rally finalizado: imágenes eliminadas y votos reiniciados.',
                  ),
                ),
              );
              // Redirigir a Rally y eliminar el historial de navegación
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Rally()),
                (route) => false,
              );
            }
          },
          child: const Text('Finalizar'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      appBar: AppBar(title: const Text('Podio Rally Fotográfico')),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (top.isNotEmpty)
                FutureBuilder<String>(
                  future: _getUserName(top[0]['usuario']),
                  builder: (context, userSnap) {
                    final nombre = userSnap.data ?? '';
                    return Column(
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
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nota media: ${top[0]['notaMedia']?.toStringAsFixed(2) ?? '-'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
              const Spacer(),
              if (top.length > 1)
                FutureBuilder<String>(
                  future: _getUserName(top[1]['usuario']),
                  builder: (context, userSnap) {
                    final nombre = userSnap.data ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '2º $nombre',
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  },
                ),
              if (top.length > 2)
                FutureBuilder<String>(
                  future: _getUserName(top[2]['usuario']),
                  builder: (context, userSnap) {
                    final nombre = userSnap.data ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0, top: 4.0),
                      child: Text(
                        '3º $nombre',
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

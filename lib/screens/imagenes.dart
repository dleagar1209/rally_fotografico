import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Imagenes extends StatelessWidget {
  const Imagenes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Imágenes")),
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
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final imageUrl = data['imagen'];
                      final fecha = (data['fecha'] as Timestamp?)?.toDate();
                      return GridTile(
                        footer: GridTileBar(
                          backgroundColor: Colors.black54,
                          title: Text(
                            fecha != null
                                ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute}'
                                : 'Sin fecha',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        child:
                            imageUrl != null
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : const Icon(Icons.broken_image),
                      );
                    },
                  );
                },
              ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Imágenes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            label: 'Tus Imágenes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
        ],
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/rally');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/users');
          }
        },
      ),
    );
  }
}

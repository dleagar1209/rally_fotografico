import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Users extends StatelessWidget {
  const Users({Key? key}) : super(key: key);

  // Función para formatear la fecha a dd/mm/yyyy
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
    return Scaffold(
      appBar: AppBar(title: const Text("Lista de Usuarios")),
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
                    return DataRow(
                      cells: [
                        DataCell(Text(name)),
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
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Imágenes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album_outlined),
            label: 'Tus Imágenes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
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
  }
}

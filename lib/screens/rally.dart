import 'package:flutter/material.dart';

class Rally extends StatelessWidget {
  const Rally({Key? key}) : super(key: key);

  void _navigateToUsers(BuildContext context) {
    Navigator.pushNamed(context, '/users');
  }

  @override
  Widget build(BuildContext context) {
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
      body: const Center(child: Text('Bienvenido al Rally Fotográfico')),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'Imágenes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuarios',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            _navigateToUsers(context);
          }
        },
      ),
    );
  }
}

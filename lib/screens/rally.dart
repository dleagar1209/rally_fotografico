import 'package:flutter/material.dart';

class Rally extends StatelessWidget {
  const Rally({Key? key}) : super(key: key);

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
    );
  }
}

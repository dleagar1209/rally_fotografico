import 'package:flutter/material.dart';

class ImageDetailScreen extends StatelessWidget {
  final String imageUrl;
  const ImageDetailScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de Imagen")),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class Rally extends StatelessWidget {
  const Rally({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rally Fotográfico')),
      body: Center(child: Text('Bienvenido al Rally Fotográfico')),
    );
  }
}

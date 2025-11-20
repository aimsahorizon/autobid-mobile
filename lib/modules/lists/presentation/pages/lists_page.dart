import 'package:flutter/material.dart';

class ListsPage extends StatelessWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lists'),
      ),
      body: const Center(
        child: Text(
          'Lists Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

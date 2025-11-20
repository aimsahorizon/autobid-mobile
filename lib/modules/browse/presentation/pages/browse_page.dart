import 'package:flutter/material.dart';

class BrowsePage extends StatelessWidget {
  const BrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
      ),
      body: const Center(
        child: Text(
          'Browse Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

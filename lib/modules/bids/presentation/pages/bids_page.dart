import 'package:flutter/material.dart';

class BidsPage extends StatelessWidget {
  const BidsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bids'),
      ),
      body: const Center(
        child: Text(
          'Bids Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

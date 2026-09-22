import 'package:flutter/material.dart';

void main() => runApp(const CatalogApp());

class CatalogApp extends StatelessWidget {
  const CatalogApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Learning catalog',
              key: ValueKey('title'),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CourseTile(
              title: 'Introduction to astronomy',
              summary: 'Explore the night sky.',
              price: 'Free',
            ),
            SizedBox(height: 20),
            CourseTile(
              title: 'Practical photography',
              summary: 'Understand light and composition.',
              price: '€29',
            ),
          ],
        ),
      ),
    ),
  );
}

class CourseTile extends StatelessWidget {
  const CourseTile({
    super.key,
    required this.title,
    required this.summary,
    required this.price,
    this.labelSize = 22,
  });

  final String title;
  final String summary;
  final String price;
  final double labelSize;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(fontSize: labelSize, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(summary),
      const SizedBox(height: 8),
      Text(price),
    ],
  );
}

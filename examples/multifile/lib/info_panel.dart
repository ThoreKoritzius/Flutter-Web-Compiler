import 'package:flutter/material.dart';
import 'sample_stat.dart';

void main() => runApp(
  const MaterialApp(
    home: Scaffold(
      body: InfoPanel(
        'Delivery status',
        description: 'This week',
        child: SampleStat('Completed tasks', value: '24'),
      ),
    ),
  ),
);

class InfoPanel extends StatelessWidget {
  const InfoPanel(
    this.heading, {
    super.key,
    this.description,
    required this.child,
  });
  final String heading;
  final String? description;
  final Widget child;

  bool get hasDescription => description != null && description != '';

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(heading))]),
          if (hasDescription) Text(description!),
          const SizedBox(height: 20),
          child,
        ],
      ),
    ),
  );
}

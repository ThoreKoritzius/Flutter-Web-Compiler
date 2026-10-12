import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: ActivitySummary(items: [])));

class Activity {
  const Activity({required this.name, required this.minutes});
  final String name;
  final double minutes;
}

class ActivitySummary extends StatelessWidget {
  const ActivitySummary({required this.items, super.key});
  final List<Activity> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Activity summary', style: TextStyle(fontSize: 28)),
      const SizedBox(height: 20),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text(item.name)),
              Text('${item.minutes.toStringAsFixed(0)} min'),
            ],
          ),
        ),
    ],
  );
}

import 'package:flutter/material.dart';

void main() =>
    runApp(const MaterialApp(home: Scaffold(body: PeriodSelector())));

class PeriodSelector extends StatefulWidget {
  const PeriodSelector({super.key});

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  bool monthly = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity', style: TextStyle(fontSize: 28)),
        const SizedBox(height: 16),
        Text(monthly ? 'Last 30 days' : 'Last 7 days'),
        const SizedBox(height: 8),
        Text(
          monthly ? '124,800 steps' : '30,900 steps',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => setState(() => monthly = !monthly),
          child: Text(monthly ? 'Show week' : 'Show month'),
        ),
        const SizedBox(height: 8),
        const Text('Sample data'),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

void main() => runApp(const App());

class StaticApp extends StatelessWidget {
  const StaticApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A document, built from Flutter.',
              key: ValueKey('details'),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'This route is static HTML and CSS. It includes no JavaScript '
              'and does not download a Flutter runtime.',
            ),
          ],
        ),
      ),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'FLUTTER DOM / PROTOTYPE 01',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Flutter, meet the web.',
              key: ValueKey('title'),
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'This page started as ordinary Flutter code. The compiler '
              'emits its content as HTML before any Flutter engine loads.',
            ),
            SizedBox(height: 32),
            Details(),
            SizedBox(height: 32),
            CounterPanel(),
          ],
        ),
      ),
    ),
  );
}

class Details extends StatelessWidget {
  const Details({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'HTML first. Flutter when needed.',
        key: ValueKey('details'),
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 12),
      Text(
        'Select this text, inspect the headings, or disable JavaScript. '
        'The content remains a native web document.',
      ),
      SizedBox(height: 12),
      Text(
        'The counter below is a real StatefulWidget. Its Flutter bundle '
        'is downloaded only after you press the button.',
      ),
    ],
  );
}

class CounterPanel extends StatefulWidget {
  const CounterPanel({super.key});

  @override
  State<CounterPanel> createState() => _CounterPanelState();
}

class _CounterPanelState extends State<CounterPanel> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xfff4f6f9),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Running inside a real Flutter island'),
          const SizedBox(height: 16),
          Text('Count: $count', style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => count++),
            child: const Text('Increment'),
          ),
        ],
      ),
    ),
  );
}

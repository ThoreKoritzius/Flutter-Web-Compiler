import 'package:flutter/material.dart';

void main() => runApp(const ShowcaseApp());

class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: 'Flutter DOM Compiler — Flutter target',
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ONE SOURCE / TWO WEB BUILDS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Flutter source.\nA native web document.',
                key: ValueKey('hero'),
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Explore a document-first build of this Flutter page. '
                'Select text, search the feature list, then try the same source through Flutter Web.',
              ),
              SizedBox(height: 28),
              FeatureSearch(
                label: 'Explore the approach',
                hintText: 'Search features, e.g. HTML or Flutter',
                items: [
                  'Native HTML — content in the first document response',
                  'Static routes — no JavaScript required for plain content',
                  'Explicit DOM adapters — native search and local filtering',
                  'Flutter islands — keep complex interactions in Flutter',
                  'One source — compare two independent build targets',
                  'Clear limits — narrow compatibility, approximate layout',
                ],
              ),
              SizedBox(height: 28),
              Text(
                'Keep Flutter where it helps.',
                key: ValueKey('counter'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'This counter is real Flutter in both builds. The native target '
                'defers it until activation; Flutter Web starts it immediately.',
              ),
              SizedBox(height: 20),
              SizedBox(height: 220, child: CounterPanel()),
              SizedBox(height: 24),
              Text(
                'Research prototype. Search uses an explicit filter-list adapter; '
                'arbitrary StatefulWidget conversion and shared state are not implemented.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// The sidecar opts this widget into the documented filter-list DOM adapter.
// Its Dart implementation below is what the standard Flutter target runs.
class FeatureSearch extends StatefulWidget {
  const FeatureSearch({
    super.key,
    required this.items,
    required this.label,
    required this.hintText,
  });
  final List<String> items;
  final String label;
  final String hintText;
  @override
  State<FeatureSearch> createState() => _FeatureSearchState();
}

class _FeatureSearchState extends State<FeatureSearch> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final results = widget.items
        .where(
          (item) => item.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 10),
        Text(
          '${results.length} of ${widget.items.length} features',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 10),
        for (final item in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffdbe2ea)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item),
            ),
          ),
      ],
    );
  }
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
          const Text('Running in Flutter'),
          const SizedBox(height: 12),
          Text('Count: $count', style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => setState(() => count++),
            child: const Text('Increment'),
          ),
        ],
      ),
    ),
  );
}

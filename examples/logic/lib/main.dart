import 'dart:async';

import 'package:flutter/material.dart';

import 'transport.dart';
import 'repository.dart';

void main() => runApp(const MaterialApp(home: ActivityApp()));

class ActivityApp extends StatefulWidget {
  const ActivityApp({super.key});
  @override
  State<ActivityApp> createState() => _ActivityAppState();
}

class _ActivityAppState extends State<ActivityApp> {
  final _transport = BrowserTransport();
  late final _repository = SummaryRepository(_transport);
  Summary? _summary;
  bool _loading = true;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _repository.fetch();
      if (!mounted || generation != _generation) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = 'Request failed. Retry to recover.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity'),
        Text(_loading ? 'Loading…' : _error ?? 'Updated from local API'),
        if (_summary != null) ...[
          Text('${_summary!.totalMinutes.toStringAsFixed(0)} min total'),
          for (final activity in _summary!.activities)
            Text(
              '${activity.name} · ${activity.minutes.toStringAsFixed(0)} min',
            ),
        ],
        Row(
          children: [
            ElevatedButton(
              onPressed: _load,
              child: const Text('Refresh / retry'),
            ),
            ElevatedButton(
              onPressed: () {
                _transport.failNext = true;
                _load();
              },
              child: const Text('Test request failure'),
            ),
          ],
        ),
      ],
    ),
  );
}

import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('go_router imports route with redirects, shells and history', () async {
    final directory = Directory.systemTemp.createTempSync('native-router-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final auth = ValueNotifier<bool>(false);

final router = GoRouter(
  initialLocation: '/feed',
  refreshListenable: auth,
  redirect: (context, state) {
    final loggingIn = state.matchedLocation == '/login';
    if (!auth.value) return loggingIn ? null : '/login';
    return loggingIn ? '/feed' : null;
  },
  errorBuilder: (context, state) => Text('error ${state.uri.path}'),
  routes: [
    GoRoute(path: '/login', builder: (context, state) => ElevatedButton(onPressed: () => auth.value = true, child: const Text('Sign in'))),
    GoRoute(
      path: '/details/:id',
      name: 'details',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text('Details ${state.pathParameters['id']}')),
        body: Column(children: [
          Text('query ${state.uri.queryParameters['tab']} extra ${state.extra}'),
          ElevatedButton(onPressed: () => context.pop('picked ${state.pathParameters['id']}'), child: const Text('Pick')),
        ]),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: shell.goBranch,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Feed'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/feed', builder: (context, state) => const Feed())]),
        StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (context, state) => const Text('Settings page'))]),
      ],
    ),
  ],
);

void main() => runApp(MaterialApp.router(routerConfig: router));

class Feed extends StatefulWidget {
  const Feed({super.key});
  @override
  State<Feed> createState() => FeedState();
}

class FeedState extends State<Feed> {
  int likes = 0;
  String result = '-';
  @override
  Widget build(BuildContext context) => Column(children: [
    Text('likes $likes result $result at ${GoRouterState.of(context).uri}'),
    ElevatedButton(onPressed: () => setState(() => likes++), child: const Text('Like')),
    ElevatedButton(
      onPressed: () async {
        final value = await context.pushNamed<String>('details', pathParameters: {'id': '7'}, queryParameters: {'tab': 'info'}, extra: 'payload');
        setState(() => result = value ?? 'none');
      },
      child: const Text('Open'),
    ),
    ElevatedButton(
      onPressed: () => showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: const Text('Dialog'),
        actions: [TextButton(onPressed: () => context.pop(), child: const Text('Close'))],
      )),
      child: const Text('Ask'),
    ),
    ElevatedButton(onPressed: () => context.go('/missing'), child: const Text('Broken link')),
    ElevatedButton(onPressed: () => auth.value = false, child: const Text('Sign out')),
  ]);
}
""");
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    expect(app.builtInBridges, ['go_router']);
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      'tool/browser/native_go_router_test.cjs',
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Router passed'));
  });
}

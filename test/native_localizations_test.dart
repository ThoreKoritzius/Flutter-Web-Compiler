import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('gen_l10n-style localizations resolve browser locales', () async {
    final directory = Directory.systemTemp.createTempSync('native-l10n-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib/l10n').createSync(recursive: true);
    // Shaped like flutter gen_l10n output (independently written).
    File('${directory.path}/lib/l10n/app_localizations.dart').writeAsStringSync(
      r"""
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());
  final String localeName;
  static AppLocalizations? of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
  static const List<Locale> supportedLocales = <Locale>[Locale('de'), Locale('en')];
  String get greeting;
  String steps(int count);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }
  throw FlutterError('AppLocalizations.delegate failed to load unsupported locale "$locale".');
}

class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);
  @override
  String get greeting => 'Hallo';
  @override
  String steps(int count) => intl.Intl.pluralLogic(count, locale: localeName, one: '$count Schritt', other: '$count Schritte');
}

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);
  @override
  String get greeting => 'Hello';
  @override
  String steps(int count) => intl.Intl.pluralLogic(count, locale: localeName, one: '$count step', other: '$count steps');
}
""",
    );
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  Locale? forced;
  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: forced,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return Column(children: [
        Text('${l10n.greeting} · ${l10n.steps(1)} · ${l10n.steps(3)}'),
        Text('locale ${Localizations.localeOf(context)} ok ${MaterialLocalizations.of(context).okButtonLabel}'),
        ElevatedButton(onPressed: () => setState(() => forced = const Locale('en')), child: const Text('English')),
      ]);
    }),
  );
}
""");
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    expect(app.builtInBridges, ['flutter_localizations']);
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      '-e',
      r"""
const {install,find,label,until}=require('./tool/browser/dom_shim.cjs');
const {host}=install({languages:['de-AT','en-US']});
const text=p=>find(host,n=>n.tag==='p'&&n.textContent.startsWith(p));
(async()=>{require(process.argv[1]);
 if(!text('Hallo · 1 Schritt · 3 Schritte'))throw Error('German strings: '+label(host));
 if(!text('locale de ok OK'))throw Error('resolved locale');
 if(global.document.documentElement.lang!=='de')throw Error('html lang');
 find(host,n=>n.tag==='button').events.click();
 await until(()=>text('Hello · 1 step · 3 steps'),'switched locale');
 if(global.document.documentElement.lang!=='en')throw Error('html lang update');
 console.log('Localizations passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Localizations passed'));
  });
}

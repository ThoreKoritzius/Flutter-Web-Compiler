import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'shared_preferences and url_launcher use browser storage and windows',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-plugins-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  print('read ${prefs.getInt('count')} ${prefs.getStringList('tags')} ${prefs.getBool('missing')}');
  await prefs.setInt('count', (prefs.getInt('count') ?? 0) + 1);
  await prefs.setStringList('tags', ['a', 'b', 'c']);
  await prefs.remove('obsolete');
  final async = SharedPreferencesAsync();
  await async.setString('theme', 'dark');
  print('async ${await async.getString('theme')}');
  print('https ${await launchUrl(Uri.parse('https://example.com/help'))}');
  print('mail ${await launchUrl(Uri.parse('mailto:team@example.com'))}');
  print('script ${await launchUrl(Uri.parse('javascript:alert(1)'))}');
  runApp(const Text('done'));
}
""");
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      expect(app.builtInBridges, ['shared_preferences', 'url_launcher']);
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        '-e',
        r"""
const {install,until,label}=require('./tool/browser/dom_shim.cjs');
const {host}=install();
const store=new Map([['flutter.count','3'],['flutter.tags','["x","y"]'],['flutter.obsolete','true'],['other','1']]);
global.localStorage={get length(){return store.size;},key:i=>[...store.keys()][i]??null,getItem:k=>store.has(k)?store.get(k):null,setItem:(k,v)=>store.set(k,String(v)),removeItem:k=>store.delete(k)};
const opened=[];global.window.open=(url,target,features)=>{opened.push([url,target,features]);return {};};
const logs=[];const log=console.log;console.log=(...a)=>logs.push(a.join(' '));
(async()=>{require(process.argv[1]);
 await until(()=>label(host)==='done','app ran');
 console.log=log;
 const expect=(a,b)=>{if(JSON.stringify(a)!==JSON.stringify(b))throw Error(JSON.stringify(a)+' != '+JSON.stringify(b));};
 expect(logs,['read 3 [x, y] null','async dark','https true','mail true','script false']);
 expect(store.get('flutter.count'),'4');
 expect(store.get('flutter.tags'),'["a","b","c"]');
 expect(store.has('flutter.obsolete'),false);
 expect(store.get('theme'),'"dark"');
 expect(store.get('other'),'1');
 expect(opened,[['https://example.com/help','_blank','noopener,noreferrer'],['mailto:team@example.com','_top','']]);
 log('Plugins passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('Plugins passed'));
    },
  );
}

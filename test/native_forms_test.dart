import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('native inputs, forms and selection controls are controlled', () async {
    final directory = Directory.systemTemp.createTempSync('native-forms-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MaterialApp(home: const Scaffold(body: FormsPage())));

class FormsPage extends StatefulWidget {
  const FormsPage({super.key});
  @override
  State<FormsPage> createState() => FormsPageState();
}

class FormsPageState extends State<FormsPage> {
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController(text: '12');
  String saved = '-';
  bool agree = false, alerts = true, locked = false;
  String size = 'm';
  double level = 0.5;
  String fruit = 'apple';
  String submitted = '-';

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'Name', helperText: 'Required'),
          validator: (value) => value == null || value.isEmpty ? 'Enter a name' : null,
          onSaved: (value) => saved = value ?? '',
          onFieldSubmitted: (value) => setState(() => submitted = value),
          textInputAction: TextInputAction.done,
        ),
        TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 4,
          decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
          onChanged: (value) => print('amount:$value'),
        ),
        TextButton(onPressed: () => amount.text = '777', child: const Text('Set amount')),
        Checkbox(value: agree, onChanged: (v) => setState(() => agree = v!)),
        Checkbox(value: false, onChanged: (v) => print('ignored:$v')),
        Switch(value: alerts, onChanged: locked ? null : (v) => setState(() => alerts = v)),
        for (final option in ['s', 'm', 'l'])
          Radio<String>(value: option, groupValue: size, onChanged: (v) => setState(() => size = v!)),
        Slider(value: level, divisions: 4, onChanged: (v) => setState(() => level = v)),
        DropdownButton<String>(
          value: fruit,
          items: const [
            DropdownMenuItem(value: 'apple', child: Text('Apple')),
            DropdownMenuItem(value: 'pear', child: Text('Pear')),
          ],
          onChanged: (v) => setState(() => fruit = v!),
        ),
        Text('state agree=$agree alerts=$alerts size=$size level=$level fruit=$fruit saved=$saved submitted=$submitted'),
        ElevatedButton(
          onPressed: () {
            final valid = formKey.currentState!.validate();
            if (valid) formKey.currentState!.save();
            setState(() {});
            print('valid:$valid');
          },
          child: const Text('Submit'),
        ),
        ElevatedButton(onPressed: () => formKey.currentState!.reset(), child: const Text('Reset')),
        ElevatedButton(onPressed: () => setState(() => locked = true), child: const Text('Lock')),
      ],
    ),
  );
}
""");
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      'tool/browser/native_forms_test.cjs',
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Forms and controls passed'));
  });
}

import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'selection tiles, steppers, tables, panels and rails run natively',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-extra-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: Home()));

class Item {
  Item(this.name, this.qty);
  final String name;
  final int qty;
  bool selected = false;
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool wifi = false;
  bool? agree;
  String size = 's';
  RangeValues range = const RangeValues(0.2, 0.6);
  List<bool> styles = [true, false, false];
  int step = 0;
  int? sortColumn;
  bool ascending = true;
  final items = [Item('pear', 3), Item('apple', 7), Item('fig', 1)];
  final open = [false, false];
  int rail = 0;
  int drawer = 0;
  String log = '';

  void sort(int column, bool asc) => setState(() {
    sortColumn = column;
    ascending = asc;
    items.sort((a, b) {
      final order = column == 0 ? a.name.compareTo(b.name) : a.qty.compareTo(b.qty);
      return asc ? order : -order;
    });
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: NavigationDrawer(
      selectedIndex: drawer,
      onDestinationSelected: (i) => setState(() => drawer = i),
      children: const [
        Padding(padding: EdgeInsets.all(16), child: Text('Mail')),
        NavigationDrawerDestination(icon: Icon(Icons.inbox), label: Text('Inbox')),
        Divider(),
        NavigationDrawerDestination(icon: Icon(Icons.send), label: Text('Sent')),
      ],
    ),
    bottomNavigationBar: BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Row(children: [
        Builder(builder: (context) => IconButton(
          tooltip: 'open drawer',
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu),
        )),
      ]),
    ),
    body: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NavigationRail(
          selectedIndex: rail,
          labelType: NavigationRailLabelType.all,
          onDestinationSelected: (i) => setState(() => rail = i),
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
            NavigationRailDestination(icon: Icon(Icons.star), label: Text('Starred')),
          ],
        ),
        Expanded(child: SingleChildScrollView(child: Column(children: [
          SwitchListTile(
            title: const Text('Wi-Fi'),
            value: wifi,
            onChanged: (v) => setState(() => wifi = v),
          ),
          CheckboxListTile(
            title: const Text('Agree'),
            tristate: true,
            value: agree,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => agree = v),
          ),
          for (final s in ['s', 'l'])
            RadioListTile<String>(
              title: Text('size $s'),
              value: s,
              groupValue: size,
              onChanged: (v) => setState(() => size = v!),
            ),
          RangeSlider(
            values: range,
            divisions: 10,
            labels: RangeLabels('${range.start}', '${range.end}'),
            onChanged: (v) => setState(() => range = v),
            onChangeEnd: (v) => setState(() => log += 'end;'),
          ),
          ToggleButtons(
            isSelected: styles,
            onPressed: (i) => setState(() => styles[i] = !styles[i]),
            children: const [Icon(Icons.format_bold), Icon(Icons.format_italic), Icon(Icons.format_underline)],
          ),
          Stepper(
            currentStep: step,
            onStepContinue: () => setState(() => step = (step + 1).clamp(0, 2)),
            onStepCancel: () => setState(() => step = 0),
            onStepTapped: (i) => setState(() => step = i),
            steps: [
              Step(title: const Text('Account'), content: const Text('account body'), isActive: step >= 0, state: step > 0 ? StepState.complete : StepState.indexed),
              Step(title: const Text('Address'), content: const Text('address body'), isActive: step >= 1),
              const Step(title: Text('Done'), content: Text('done body')),
            ],
          ),
          DataTable(
            sortColumnIndex: sortColumn,
            sortAscending: ascending,
            headingRowColor: WidgetStateProperty.resolveWith((_) => Colors.black12),
            columns: [
              DataColumn(label: const Text('Name'), onSort: sort),
              DataColumn(label: const Text('Qty'), numeric: true, onSort: sort),
            ],
            rows: [
              for (final (i, item) in items.indexed)
                DataRow.byIndex(
                  index: i,
                  selected: item.selected,
                  onSelectChanged: (v) => setState(() => item.selected = v ?? false),
                  cells: [DataCell(Text(item.name)), DataCell(Text('${item.qty}'))],
                ),
            ],
          ),
          ExpansionPanelList(
            expansionCallback: (i, expanded) => setState(() => open[i] = expanded),
            children: [
              for (var i = 0; i < 2; i++)
                ExpansionPanel(
                  isExpanded: open[i],
                  headerBuilder: (context, expanded) => Text('panel $i'),
                  body: Text('panel body $i'),
                ),
            ],
          ),
          ExpansionPanelList.radio(
            initialOpenPanelValue: 'a',
            children: [
              for (final v in ['a', 'b'])
                ExpansionPanelRadio(
                  value: v,
                  canTapOnHeader: true,
                  headerBuilder: (context, expanded) => Text('radio $v'),
                  body: Text('radio body $v'),
                ),
            ],
          ),
          SizedBox(
            height: 120,
            child: GridTile(
              footer: const GridTileBar(backgroundColor: Colors.black45, title: Text('tile title')),
              child: Container(color: Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showMaterialBanner(
              MaterialBanner(
                content: const Text('banner text'),
                actions: [
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
            child: const Text('show banner'),
          ),
          Text('state $wifi $agree $size ${range.start}-${range.end} ${styles.join(',')} $step ${items.map((e) => e.name).join(',')} ${items.where((e) => e.selected).length} ${open.join(',')} $rail $drawer $log'),
        ]))),
      ],
    ),
  );
}
""");
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        '-e',
        r"""
const {install,until,label,find,findAll}=require('./tool/browser/dom_shim.cjs');
const {host}=install();
(async()=>{require(process.argv[1]);
 const state=()=>label(host).split('state ')[1];
 await until(()=>state()!==undefined,'app ran');
 const expect=(want,what)=>until(()=>state().startsWith(want),what+': '+state());
 const role=(r,t)=>find(host,n=>n.attributes.role===r&&label(n).includes(t));
 // Selection tiles toggle from the whole tile.
 const wifi=role('switch','Wi-Fi');
 if(wifi.attributes['aria-checked']!=='false'||wifi.attributes.tabindex!=='0')throw Error('switch tile');
 const inner=find(wifi,n=>n.tag==='input');
 if(inner.parent.attributes.inert===undefined)throw Error('inner control inert');
 wifi.events.click({});
 await expect('true null s','switch tile');
 if(role('switch','Wi-Fi').attributes['aria-checked']!=='true'||!find(role('switch','Wi-Fi'),n=>n.tag==='input').checked)throw Error('switch checked');
 const agree=role('checkbox','Agree');
 if(agree.attributes['aria-checked']!=='mixed')throw Error('tristate mixed');
 agree.events.click({});
 await expect('true false s','tristate step');
 role('checkbox','Agree').events.keydown({key:' ',preventDefault(){}});
 await expect('true true s','checkbox keyboard');
 role('radio','size l').events.click({});
 await expect('true true l','radio tile');
 if(role('radio','size s').attributes['aria-checked']!=='false')throw Error('radio unchecked');
 // Range slider: two native inputs, values clamp and report end.
 const ranges=findAll(host,n=>n.tag==='input'&&n.attributes.type==='range');
 if(ranges.length!==2||ranges[0].attributes.step!=='0.1'||ranges[1].attributes['aria-valuetext']!=='0.6')throw Error('range inputs '+JSON.stringify(ranges.map(r=>r.attributes)));
 ranges[1].value='0.9';ranges[1].events.input({});
 await expect('true true l 0.2-0.9','range end');
 ranges[0].value='0.95';ranges[0].events.input({});ranges[0].events.change({});
 await expect('true true l 0.9-0.9','range start clamps');
 await until(()=>state().includes(' end;'),'change end: '+state());
 // Toggle buttons.
 const toggles=()=>findAll(host,n=>n.tag==='button'&&n.parent.attributes.role==='group'&&n.attributes['aria-pressed']!==undefined);
 if(toggles().length!==3||toggles()[0].attributes['aria-pressed']!=='true')throw Error('toggle buttons');
 toggles()[2].events.click({});
 await until(()=>state().includes('true,false,true'),'toggle: '+state());
 // Stepper continue and tap.
 if(!label(host).includes('account body')||label(host).includes('address body'))throw Error('stepper content');
 find(host,n=>n.tag==='button'&&label(n)==='Continue').events.click({});
 await until(()=>state().includes('true,false,true 1 '),'continue: '+state());
 const current=find(host,n=>n.attributes['aria-current']==='step');
 if(!label(current).includes('Address')||!label(host).includes('address body'))throw Error('stepper current');
 find(host,n=>n.tag==='button'&&label(n).includes('Done')).events.click({});
 await until(()=>state().includes('true,false,true 2 '),'step tap: '+state());
 // DataTable: real table, sorting and selection.
 const table=find(host,n=>n.tag==='table');
 if(!table||findAll(table,n=>n.tag==='th').length!==3||findAll(table,n=>n.tag==='tr').length!==4)throw Error('table structure');
 const sortButton=t=>find(table,n=>n.tag==='button'&&label(n).includes(t));
 sortButton('Name').events.click({});
 await until(()=>state().includes(' apple,fig,pear '),'sort asc: '+state());
 if(find(host,n=>n.tag==='th'&&label(n).includes('Name')).attributes['aria-sort']!=='ascending')throw Error('aria-sort');
 sortButton('Name').events.click({});
 await until(()=>state().includes(' pear,fig,apple '),'sort desc: '+state());
 const rows=()=>findAll(find(host,n=>n.tag==='tbody'),n=>n.tag==='tr');
 rows()[1].events.click({});
 await until(()=>state().includes(' pear,fig,apple 1 '),'row select: '+state());
 if(rows()[1].attributes['aria-selected']!=='true')throw Error('row selected');
 find(host,n=>n.tag==='th').children[0].events.change({});
 await until(()=>state().includes(' pear,fig,apple 3 '),'select all: '+state());
 // Expansion panels.
 const expander=find(host,n=>n.tag==='button'&&n.attributes['aria-expanded']==='false');
 expander.events.click({});
 await until(()=>state().includes(' true,false '),'panel: '+state());
 if(!label(host).includes('panel body 0')||label(host).includes('panel body 1'))throw Error('panel body');
 if(!label(host).includes('radio body a'))throw Error('radio initial');
 role('button','radio b').events.click({});
 await until(()=>label(host).includes('radio body b')&&!label(host).includes('radio body a'),'radio panel');
 // Navigation rail.
 const railButtons=findAll(find(host,n=>n.tag==='nav'),n=>n.tag==='button');
 if(railButtons.length!==2||railButtons[0].attributes['aria-current']!=='page')throw Error('rail');
 railButtons[1].events.click({});
 await until(()=>state().includes(' 1 0 '),'rail: '+state());
 // Bottom app bar, grid tile and banner.
 if(!find(host,n=>n.attributes.role==='toolbar'))throw Error('bottom app bar');
 if(!label(host).includes('tile title'))throw Error('grid tile');
 find(host,n=>n.tag==='button'&&label(n)==='show banner').events.click({});
 await until(()=>role('status','banner text'),'banner shown');
 find(role('status','banner text'),n=>n.tag==='button').events.click({});
 await until(()=>!label(host).includes('banner text'),'banner hidden');
 // Navigation drawer inside Scaffold.drawer.
 find(host,n=>n.tag==='button'&&n.attributes['aria-label']==='open drawer').events.click({});
 await until(()=>find(host,n=>n.attributes.role==='dialog'),'drawer open');
 const dialog=find(host,n=>n.attributes.role==='dialog');
 const sent=find(dialog,n=>n.tag==='button'&&label(n).includes('Sent'));
 if(find(dialog,n=>n.attributes['aria-current']==='page'&&label(n).includes('Inbox'))===undefined)throw Error('drawer selected');
 sent.events.click({});
 await until(()=>state().includes(' 1 1 end;'),'drawer: '+state());
 console.log('Extra passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('Extra passed'));
    },
  );
}

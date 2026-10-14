import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test('ThemeData component themes reach native widgets', () async {
    final directory = Directory.systemTemp.createTempSync('native-theme-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Directory('${directory.path}/lib').createSync();
    File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final theme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xff336699),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  splashFactory: NoSplash.splashFactory,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xff112233),
    foregroundColor: Color(0xfffafafa),
    centerTitle: true,
    toolbarHeight: 60,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xff223344),
    elevation: 0,
    margin: const EdgeInsets.all(10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xff334455),
      foregroundColor: const Color(0xffeeeeee),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xff445566),
    border: OutlineInputBorder(),
  ),
  chipTheme: const ChipThemeData(backgroundColor: Color(0xff556677)),
  dividerTheme: const DividerThemeData(color: Color(0xff667788), thickness: 3),
  listTileTheme: const ListTileThemeData(
    tileColor: Color(0xff778899),
    iconColor: Color(0xff123123),
  ),
  switchTheme: SwitchThemeData(
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? const Color(0xff00aa00)
          : null,
    ),
  ),
  sliderTheme: const SliderThemeData(activeTrackColor: Color(0xffaa0000)),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xff0000aa),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Color(0xff101010),
    indicatorColor: Color(0xff202020),
  ),
  tabBarTheme: const TabBarTheme(labelColor: Color(0xff303030)),
  dialogTheme: const DialogThemeData(backgroundColor: Color(0xff404040)),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Color(0xff505050),
  ),
);

void main() => runApp(MaterialApp(theme: theme, home: const Home()));

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool on = true;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(title: const Text('Themed')),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      body: ListView(
        children: [
          const Card(child: Text('base card')),
          Builder(
            builder: (context) => Theme(
              data: Theme.of(context).copyWith(
                cardTheme: const CardTheme(color: Color(0xff8899aa)),
                dividerColor: const Color(0xff999999),
              ),
              child: const Card(child: Text('scoped card')),
            ),
          ),
          ElevatedButton(onPressed: () {}, child: const Text('themed button')),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff998877),
            ),
            child: const Text('own button'),
          ),
          TextButtonTheme(
            data: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff876543),
              ),
            ),
            child: TextButton(onPressed: () {}, child: const Text('scoped text')),
          ),
          const TextField(decoration: InputDecoration(labelText: 'Name')),
          const Chip(label: Text('chip')),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('tile'),
            onTap: () {},
          ),
          Switch(value: on, onChanged: (value) => setState(() => on = value)),
          Slider(value: 0.5, onChanged: (_) {}),
          const LinearProgressIndicator(value: 0.5),
          const TabBar(tabs: [Tab(text: 'One'), Tab(text: 'Two')]),
          Text('platform ${Theme.of(context).platform.name}'),
          Text('compiled ${compileOnly().length}'),
        ],
      ),
    ),
  );
}

/// Exercises theme constructors and copyWith with Flutter's signatures.
List<Object> compileOnly() {
  final base = ThemeData.light();
  final dark = ThemeData.dark(useMaterial3: true);
  final from = ThemeData.from(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
      surfaceTint: Colors.indigo,
    ),
    textTheme: Typography.material2021().white,
  );
  final legacy = ThemeData(
    useMaterial3: false,
    primarySwatch: Colors.green,
    fontFamily: 'Roboto',
    fontFamilyFallback: const ['Arial'],
    platform: TargetPlatform.iOS,
    buttonTheme: const ButtonThemeData(minWidth: 100),
    cupertinoOverrideTheme: null,
    canvasColor: Colors.white,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: Colors.black12,
    focusColor: Colors.black12,
    disabledColor: Colors.grey,
    hintColor: Colors.grey,
    secondaryHeaderColor: Colors.green.shade50,
    shadowColor: Colors.black,
    unselectedWidgetColor: Colors.black54,
    primaryColorLight: Colors.green.shade100,
    primaryColorDark: Colors.green.shade700,
    primaryTextTheme: const TextTheme(),
    primaryIconTheme: const IconThemeData(color: Colors.white),
    applyElevationOverlayColor: false,
    typography: Typography.material2018(platform: TargetPlatform.android),
    scrollbarTheme: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(4)),
  );
  final copied = base.copyWith(
    brightness: Brightness.light,
    primaryColor: Colors.red,
    colorScheme: base.colorScheme.copyWith(primary: Colors.red, surfaceVariant: Colors.grey),
    appBarTheme: base.appBarTheme.copyWith(elevation: 2, color: Colors.blue),
    cardTheme: const CardThemeData(elevation: 4),
    dialogTheme: const DialogTheme(elevation: 3),
    tabBarTheme: const TabBarThemeData(indicatorSize: TabBarIndicatorSize.label),
    inputDecorationTheme: const InputDecorationTheme(isDense: true).merge(
      const InputDecorationTheme(filled: true),
    ),
    textTheme: base.textTheme.apply(bodyColor: Colors.black, displayColor: Colors.black),
    iconTheme: base.iconTheme.copyWith(size: 20),
    extensions: const [],
  );
  final scheme = ColorScheme.fromSwatch(
    primarySwatch: Colors.teal,
    accentColor: Colors.amber,
    brightness: Brightness.dark,
  );
  return [
    base,
    dark,
    from,
    legacy,
    copied,
    scheme,
    ThemeData.lerp(base, dark, 0.7),
    ThemeData.estimateBrightnessForColor(Colors.yellow),
    VisualDensity.compact,
    VisualDensity.comfortable,
    VisualDensity.standard,
    InkSplash.splashFactory,
    InkRipple.splashFactory,
    InkSparkle.splashFactory,
    const FadeUpwardsPageTransitionsBuilder(),
    const OpenUpwardsPageTransitionsBuilder(),
    const PredictiveBackPageTransitionsBuilder(),
    const BadgeThemeData(backgroundColor: Colors.red),
    const MaterialBannerThemeData(),
    const BottomAppBarTheme(color: Colors.white, shape: CircularNotchedRectangle()),
    const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
    ),
    const BottomSheetThemeData(showDragHandle: true, modalBackgroundColor: Colors.white),
    CheckboxThemeData(
      fillColor: WidgetStateProperty.all(Colors.green),
      shape: const RoundedRectangleBorder(),
    ),
    ChipThemeData.fromDefaults(
      secondaryColor: Colors.blue,
      labelStyle: const TextStyle(fontSize: 12),
    ),
    const DataTableThemeData(headingRowHeight: 40),
    const DatePickerThemeData(headerBackgroundColor: Colors.blue),
    const DrawerThemeData(width: 280, scrimColor: Colors.black54),
    const DropdownMenuThemeData(menuStyle: MenuStyle(alignment: Alignment.center)),
    const ExpansionTileThemeData(iconColor: Colors.red),
    const FilledButtonThemeData(),
    const FloatingActionButtonThemeData(backgroundColor: Colors.orange, iconSize: 20),
    IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: Colors.red)),
    const MenuThemeData(),
    const NavigationDrawerThemeData(),
    const NavigationRailThemeData(labelType: NavigationRailLabelType.all),
    OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
        overlayColor: Colors.red,
        splashFactory: NoSplash.splashFactory,
        animationDuration: const Duration(milliseconds: 100),
        enableFeedback: false,
      ),
    ),
    const PopupMenuThemeData(position: PopupMenuPosition.under),
    const RadioThemeData(),
    const SearchBarThemeData(),
    const SegmentedButtonThemeData(),
    SliderThemeData(
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: SliderComponentShape.noOverlay,
      trackShape: const RoundedRectSliderTrackShape(),
      valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
      showValueIndicator: ShowValueIndicator.always,
    ).copyWith(trackHeight: 6),
    const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    const TimePickerThemeData(),
    const ToggleButtonsThemeData(),
    const TooltipThemeData(triggerMode: TooltipTriggerMode.tap),
    MaterialColor(0xff2196f3, const {500: Color(0xff2196f3)}),
    defaultTargetPlatform,
    TextButton.icon(
      onPressed: null,
      icon: const Icon(Icons.add),
      label: const Text('x'),
      iconAlignment: IconAlignment.end,
    ),
    const ListTileTheme(dense: true, child: SizedBox()),
    const ChipTheme(data: ChipThemeData(), child: SizedBox()),
    const DividerTheme(data: DividerThemeData(), child: SizedBox()),
    const ElevatedButtonTheme(data: ElevatedButtonThemeData(), child: SizedBox()),
    const IconButtonTheme(data: IconButtonThemeData(), child: SizedBox()),
    const SliderTheme(data: SliderThemeData(), child: SizedBox()),
    IconButton.filled(onPressed: null, icon: const Icon(Icons.add)),
    const FloatingActionButton.small(onPressed: null),
    const RefreshProgressIndicator(),
  ];
}
""");
    final app = await buildNativeApp(directory.path, 'lib/main.dart');
    final file = File('${directory.path}/app.js')
      ..writeAsStringSync(app.javascript);
    final run = await Process.run('node', [
      '-e',
      r"""
const {install,until,label,find,findAll,style}=require('./tool/browser/dom_shim.cjs');
const {host}=install();
(async()=>{require(process.argv[1]);
 await until(()=>/compiled \d+/.test(label(host)),'app ran: '+label(host).slice(0,200));
 const bg=c=>'background-color:'+c;
 const header=find(host,n=>n.tag==='header');
 if(!style(header).includes(bg('rgba(17,34,51,1)')))throw Error('app bar color '+style(header));
 if(!style(header).includes('min-height:60px'))throw Error('toolbar height '+style(header));
 if(!style(header).includes('color:rgba(250,250,250,1)'))throw Error('app bar foreground');
 const heading=find(header,n=>n.attributes.role==='heading');
 if(!style(heading).includes('justify-content:center'))throw Error('centered title');
 const card=t=>find(host,n=>style(n).includes('background-color')&&label(n)===t&&n.children.length>0);
 const base=card('base card');
 if(!style(base).includes(bg('rgba(34,51,68,1)'))||!style(base).includes('border-radius:20px')||!style(base).includes('margin:10px'))throw Error('card theme '+style(base));
 const scoped=card('scoped card');
 if(!style(scoped).includes(bg('rgba(136,153,170,1)')))throw Error('copyWith card '+style(scoped));
 const button=t=>find(host,n=>n.tag==='button'&&label(n)===t);
 if(!style(button('themed button')).includes(bg('rgba(51,68,85,1)')))throw Error('elevated theme '+style(button('themed button')));
 if(!style(button('themed button')).includes('color:rgba(238,238,238,1)'))throw Error('elevated theme foreground');
 if(!style(button('own button')).includes(bg('rgba(153,136,119,1)')))throw Error('widget style wins');
 if(!style(button('scoped text')).includes('color:rgba(135,101,67,1)'))throw Error('TextButtonTheme '+style(button('scoped text')));
 if(!style(button('themed button')).includes('--fd-press:transparent'))throw Error('NoSplash');
 const input=find(host,n=>n.tag==='input'&&n.attributes.type==='text');
 const fieldBox=find(host,n=>style(n).includes(bg('rgba(68,85,102,1)')));
 if(!fieldBox||!find(fieldBox,n=>n===input))throw Error('input fill');
 if(!style(fieldBox).includes('border:1px solid'))throw Error('outline border '+style(fieldBox));
 if(!style(input).includes('caret-color:rgba(80,80,80,1)'))throw Error('cursor color');
 if(!find(host,n=>style(n).includes(bg('rgba(85,102,119,1)'))&&label(n)==='chip'))throw Error('chip theme');
 const divider=find(host,n=>n.attributes.role==='separator');
 if(!style(divider).includes('border-top:3px solid rgba(102,119,136,1)'))throw Error('divider theme '+style(divider));
 if(!find(host,n=>style(n).includes(bg('rgba(119,136,153,1)'))&&label(n).includes('tile')))throw Error('list tile color');
 const sw=find(host,n=>n.attributes.role==='switch');
 if(!style(sw).includes('--fd-on-track:rgba(0,170,0,1)'))throw Error('switch track '+style(sw));
 const slider=find(host,n=>n.attributes.type==='range');
 if(!style(slider).includes('accent-color:rgba(170,0,0,1)'))throw Error('slider theme');
 const progress=find(host,n=>n.attributes.role==='progressbar');
 if(!style(progress).includes('--fd-indicator:rgba(0,0,170,1)'))throw Error('progress theme');
 const nav=find(host,n=>n.tag==='nav');
 if(!style(nav).includes(bg('rgba(16,16,16,1)')))throw Error('navigation bar theme');
 if(!find(nav,n=>style(n).includes(bg('rgba(32,32,32,1)'))))throw Error('navigation indicator');
 const tab=find(host,n=>n.attributes.role==='tab'&&n.attributes['aria-selected']==='true');
 if(!find(tab,n=>style(n).includes('color:rgba(48,48,48,1)')))throw Error('tab label color');
 if(!label(host).match(/platform (android|iOS|macOS|linux|windows|fuchsia)/))throw Error('platform');
 console.log('Theme passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
      file.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('Theme passed'));
  });
}

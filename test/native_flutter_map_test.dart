import 'dart:io';

import 'package:flutter_dom_compiler/native_app_builder.dart';
import 'package:test/test.dart';

void main() {
  test(
    'flutter_map renders tiles, vector layers and markers natively',
    () async {
      final directory = Directory.systemTemp.createTempSync('native-map-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Directory('${directory.path}/lib').createSync();
      File('${directory.path}/lib/main.dart').writeAsStringSync(r"""
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

final route = [
  const LatLng(47.37, 8.54),
  const LatLng(47.38, 8.55),
  const LatLng(47.375, 8.56),
];

void main() => runApp(const MaterialApp(home: Scaffold(body: MapPage())));

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final controller = MapController();
  final events = <String>[];

  @override
  void initState() {
    super.initState();
    controller.mapEventStream.listen((event) => events.add(event.source.name));
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 300,
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(route),
              padding: const EdgeInsets.all(20),
            ),
            onTap: (position, point) => setState(
              () => events.add('tap ${point.latitude.toStringAsFixed(2)}'),
            ),
            onPositionChanged: (camera, gesture) =>
                print('zoom ${camera.zoom.toStringAsFixed(1)} $gesture'),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: route,
                  strokeWidth: 4,
                  color: Colors.blue,
                  borderStrokeWidth: 1,
                  borderColor: Colors.white,
                ),
              ],
            ),
            CircleLayer(
              circles: [
                CircleMarker(point: route.last, radius: 6, color: Colors.red),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: route.first,
                  width: 20,
                  height: 20,
                  child: const Text('start'),
                ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),
      ),
      TextButton(
        onPressed: () => setState(() => controller.move(const LatLng(0, 0), 3)),
        child: const Text('reset'),
      ),
      Text('events ${events.join(',')}'),
    ],
  );
}
""");
      final app = await buildNativeApp(directory.path, 'lib/main.dart');
      expect(app.builtInBridges, contains('flutter_map'));
      final file = File('${directory.path}/app.js')
        ..writeAsStringSync(app.javascript);
      final run = await Process.run('node', [
        '-e',
        r"""
const {install,until,label,find,findAll,pointer,Element}=require('./tool/browser/dom_shim.cjs');
Element.measure=()=>400;Element.measureHeight=()=>300;
const {host}=install();
const logs=[];const log=console.log;console.log=(...a)=>logs.push(a.join(' '));
(async()=>{require(process.argv[1]);
 const tiles=()=>findAll(host,n=>n.tag==='img').map(n=>n.attributes.src||n.src).filter(Boolean);
 await until(()=>tiles().length>0,'tiles rendered');
 const zoomOf=()=>Number(/\/(\d+)\/\d+\/\d+\.png/.exec(tiles()[0])[1]);
 if(zoomOf()!==15)throw Error('fitted zoom '+tiles()[0]);
 if(!tiles().some(t=>/\/15\/1716\d\/\d+\.png/.test(t)))throw Error('tile range '+tiles().join(' '));
 const canvases=findAll(host,n=>n.tag==='canvas');
 await until(()=>canvases.some(c=>c.context&&c.context.ops.some(o=>o[0]==='lineTo')),'polyline painted');
 if(!canvases.some(c=>c.context&&c.context.ops.some(o=>o[0]==='ellipse')))throw Error('circle painted');
 if(!label(host).includes('start'))throw Error('marker');
 if(!label(host).includes('© OpenStreetMap contributors'))throw Error('attribution');
 const map=find(host,n=>n.events.pointerdown&&n.events.wheel===undefined&&n.events.pointermove);
 const wheel=find(host,n=>n.events.wheel);
 // Drag pans the map.
 const placement=()=>findAll(host,n=>n.tag==='img').map(n=>n.parent.attributes.style).join();
 const before=placement();
 pointer(map,'pointerdown',{x:200,y:150,kind:'mouse'});
 pointer(map,'pointermove',{x:120,y:150,kind:'mouse'});
 pointer(map,'pointerup',{x:120,y:150,kind:'mouse'});
 await until(()=>placement()!==before,'drag pans');
 if(!logs.some(l=>/^zoom 14\.\d true$/.test(l)))throw Error('position callback '+logs);
 // Scrolling up zooms in around the cursor.
 let prevented=false;
 wheel.events.wheel({deltaX:0,deltaY:-200,deltaMode:0,clientX:200,clientY:150,currentTarget:wheel,preventDefault(){prevented=true;}});
 await until(()=>zoomOf()===16||zoomOf()===15&&logs.some(l=>l.startsWith('zoom 15')),'wheel zoom '+logs.slice(-2));
 if(!prevented)throw Error('wheel must not scroll the page');
 // A tap reports the place under the pointer.
 pointer(map,'pointerdown',{x:200,y:150,kind:'mouse'});
 pointer(map,'pointerup',{x:200,y:150,kind:'mouse'});
 await until(()=>/tap 47\.3\d/.test(label(host)),'tap '+label(host));
 find(host,n=>n.tag==='button'&&label(n)==='reset').events.click({});
 await until(()=>zoomOf()===3,'controller move');
 const events=label(host).split('events ')[1];
 for(const e of ['dragStart','onDrag','dragEnd','scrollWheel','mapController'])if(!events.includes(e))throw Error('events '+events);
 console.log=log;console.log('Map passed');})().catch(e=>{console.error(e);process.exitCode=1;});
""",
        file.path,
      ]);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('Map passed'));
    },
  );
}

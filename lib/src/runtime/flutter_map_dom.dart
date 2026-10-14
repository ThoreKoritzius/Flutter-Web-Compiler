/// `package:flutter_map` for the native runtime: slippy maps from raster
/// tiles in Web Mercator, with polyline, polygon, circle and marker layers
/// painted from a shared [MapCamera]. Layers read the camera through
/// [MapCamera.of], as in flutter_map, so custom layers keep working.
///
/// Dragging pans, the scroll wheel and double taps zoom; rotation and
/// pinch gestures are not available.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart' show LatLng;

import 'flutter_dom.dart' hide Path;
import 'flutter_dom.dart' as ui show Path;

// ---------------------------------------------------------------------------
// Projection.

const _worldTile = 256.0;
const _maxLatitude = 85.0511287798066;

double _worldScale(double zoom) => _worldTile * math.pow(2, zoom);

Offset _project(LatLng point, double zoom) {
  final scale = _worldScale(zoom);
  final latitude =
      point.latitude.clamp(-_maxLatitude, _maxLatitude) * math.pi / 180;
  return Offset(
    (point.longitude + 180) / 360 * scale,
    (1 - math.log(math.tan(latitude) + 1 / math.cos(latitude)) / math.pi) /
        2 *
        scale,
  );
}

LatLng _unproject(Offset offset, double zoom) {
  final scale = _worldScale(zoom);
  final n = math.pi - 2 * math.pi * offset.dy / scale;
  return LatLng(
    180 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n))),
    offset.dx / scale * 360 - 180,
  );
}

double _log2(double value) => math.log(value) / math.ln2;

/// Coordinate reference systems; only Web Mercator is available.
abstract class Crs {
  const Crs();
  String get code;
}

class Epsg3857 extends Crs {
  const Epsg3857();
  @override
  String get code => 'EPSG:3857';
}

// ---------------------------------------------------------------------------
// Geometry values.

class LatLngBounds {
  LatLngBounds(LatLng corner1, LatLng corner2)
    : north = math.max(corner1.latitude, corner2.latitude),
      south = math.min(corner1.latitude, corner2.latitude),
      east = math.max(corner1.longitude, corner2.longitude),
      west = math.min(corner1.longitude, corner2.longitude);

  LatLngBounds.unsafe({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  factory LatLngBounds.fromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('LatLngBounds needs at least one point.');
    }
    var north = -90.0, south = 90.0, east = -180.0, west = 180.0;
    for (final point in points) {
      north = math.max(north, point.latitude);
      south = math.min(south, point.latitude);
      east = math.max(east, point.longitude);
      west = math.min(west, point.longitude);
    }
    return LatLngBounds.unsafe(
      north: north,
      south: south,
      east: east,
      west: west,
    );
  }

  double north, south, east, west;

  LatLng get northWest => LatLng(north, west);
  LatLng get northEast => LatLng(north, east);
  LatLng get southWest => LatLng(south, west);
  LatLng get southEast => LatLng(south, east);
  LatLng get center => LatLng((north + south) / 2, (east + west) / 2);
  LatLng get centerPoint => center;

  bool contains(LatLng point) =>
      point.latitude <= north &&
      point.latitude >= south &&
      point.longitude <= east &&
      point.longitude >= west;

  bool containsBounds(LatLngBounds other) =>
      other.north <= north &&
      other.south >= south &&
      other.east <= east &&
      other.west >= west;

  bool isOverlapping(LatLngBounds other) =>
      !(other.south > north ||
          other.north < south ||
          other.west > east ||
          other.east < west);

  void extend(LatLng point) {
    north = math.max(north, point.latitude);
    south = math.min(south, point.latitude);
    east = math.max(east, point.longitude);
    west = math.min(west, point.longitude);
  }

  void extendBounds(LatLngBounds other) {
    extend(other.northEast);
    extend(other.southWest);
  }

  @override
  bool operator ==(Object other) =>
      other is LatLngBounds &&
      other.north == north &&
      other.south == south &&
      other.east == east &&
      other.west == west;
  @override
  int get hashCode => Object.hash(north, south, east, west);
  @override
  String toString() =>
      'LatLngBounds(north: $north, south: $south, '
      'east: $east, west: $west)';
}

class TapPosition {
  const TapPosition(this.global, this.relative);
  final Offset global;
  final Offset? relative;
}

// ---------------------------------------------------------------------------
// Camera.

class MapCamera {
  MapCamera({
    this.crs = const Epsg3857(),
    required this.center,
    required this.zoom,
    this.rotation = 0,
    required this.nonRotatedSize,
    this.minZoom,
    this.maxZoom,
  });

  final Crs crs;
  final LatLng center;
  final double zoom, rotation;
  final double? minZoom, maxZoom;

  /// The map viewport size.
  final Size nonRotatedSize;
  Size get size => nonRotatedSize;

  static MapCamera of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError('No FlutterMap ancestor in this context.'));

  static MapCamera? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MapScope>()?.camera;

  /// The world pixel at the top-left corner of the viewport.
  Offset get pixelOrigin =>
      _project(center, zoom) -
      Offset(nonRotatedSize.width / 2, nonRotatedSize.height / 2);

  LatLngBounds get visibleBounds {
    final origin = pixelOrigin;
    return LatLngBounds(
      _unproject(origin, zoom),
      _unproject(
        origin + Offset(nonRotatedSize.width, nonRotatedSize.height),
        zoom,
      ),
    );
  }

  Offset projectAtZoom(LatLng latLng, [double? zoom]) =>
      _project(latLng, zoom ?? this.zoom);
  LatLng unprojectAtZoom(Offset point, [double? zoom]) =>
      _unproject(point, zoom ?? this.zoom);
  math.Point<double> project(LatLng latLng, [double? zoom]) {
    final offset = projectAtZoom(latLng, zoom);
    return math.Point(offset.dx, offset.dy);
  }

  LatLng unproject(math.Point<num> point, [double? zoom]) =>
      unprojectAtZoom(Offset(point.x.toDouble(), point.y.toDouble()), zoom);

  Offset latLngToScreenOffset(LatLng latLng) =>
      _project(latLng, zoom) - pixelOrigin;
  math.Point<double> latLngToScreenPoint(LatLng latLng) {
    final offset = latLngToScreenOffset(latLng);
    return math.Point(offset.dx, offset.dy);
  }

  Offset getOffsetFromOrigin(LatLng latLng) => latLngToScreenOffset(latLng);

  LatLng screenOffsetToLatLng(Offset offset) =>
      _unproject(pixelOrigin + offset, zoom);
  LatLng offsetToCrs(Offset offset, [double? zoom]) =>
      screenOffsetToLatLng(offset);
  LatLng pointToLatLng(math.Point<num> point) =>
      screenOffsetToLatLng(Offset(point.x.toDouble(), point.y.toDouble()));

  double getZoomScale(double toZoom, double fromZoom) =>
      math.pow(2, toZoom - fromZoom).toDouble();
  double getScaleZoom(double scale) => zoom + _log2(scale);

  double clampZoom(double zoom) =>
      zoom.clamp(minZoom ?? 0, maxZoom ?? double.infinity).toDouble();

  /// Meters per screen pixel at [latitude] for this zoom.
  double metersPerPixel(double latitude) =>
      40075016.686 * math.cos(latitude * math.pi / 180) / _worldScale(zoom);

  MapCamera withPosition({LatLng? center, double? zoom}) => MapCamera(
    crs: crs,
    center: center ?? this.center,
    zoom: zoom ?? this.zoom,
    rotation: rotation,
    nonRotatedSize: nonRotatedSize,
    minZoom: minZoom,
    maxZoom: maxZoom,
  );

  MapCamera withNonRotatedSize(Size size) => MapCamera(
    crs: crs,
    center: center,
    zoom: zoom,
    rotation: rotation,
    nonRotatedSize: size,
    minZoom: minZoom,
    maxZoom: maxZoom,
  );

  MapCamera withRotation(double rotation) => this;

  /// The camera after zooming to [zoom] while [focus] (a viewport offset)
  /// stays over the same place.
  MapCamera _zoomAround(double zoom, Offset focus) {
    final next = clampZoom(zoom);
    final place = screenOffsetToLatLng(focus);
    final centerPixel =
        _project(place, next) -
        focus +
        Offset(nonRotatedSize.width / 2, nonRotatedSize.height / 2);
    return withPosition(center: _unproject(centerPixel, next), zoom: next);
  }
}

abstract class CameraFit {
  const CameraFit();

  const factory CameraFit.bounds({
    required LatLngBounds bounds,
    EdgeInsets padding,
    double? maxZoom,
    double minZoom,
    bool forceIntegerZoomLevel,
  }) = FitBounds._;

  const factory CameraFit.insideBounds({
    required LatLngBounds bounds,
    EdgeInsets padding,
    double? maxZoom,
    double minZoom,
    bool forceIntegerZoomLevel,
  }) = FitBounds._;

  const factory CameraFit.coordinates({
    required List<LatLng> coordinates,
    EdgeInsets padding,
    double? maxZoom,
    double minZoom,
    bool forceIntegerZoomLevel,
  }) = FitCoordinates._;

  MapCamera fit(MapCamera camera);
}

MapCamera _fitBounds(
  MapCamera camera,
  LatLngBounds bounds,
  EdgeInsets padding,
  double? maxZoom,
  double minZoom,
  bool forceIntegerZoomLevel,
) {
  final size = camera.nonRotatedSize;
  final width = math.max(1.0, size.width - padding.horizontal);
  final height = math.max(1.0, size.height - padding.vertical);
  final northWest = _project(bounds.northWest, 0);
  final southEast = _project(bounds.southEast, 0);
  final spanX = (southEast.dx - northWest.dx).abs();
  final spanY = (southEast.dy - northWest.dy).abs();
  var zoom = spanX == 0 && spanY == 0
      ? (maxZoom ?? camera.maxZoom ?? 18)
      : _log2(
          math.min(
            spanX == 0 ? double.infinity : width / spanX,
            spanY == 0 ? double.infinity : height / spanY,
          ),
        );
  zoom = math.max(minZoom, math.min(zoom, maxZoom ?? double.infinity));
  zoom = camera.clampZoom(zoom);
  if (forceIntegerZoomLevel) zoom = zoom.floorToDouble();
  final middle =
      (_project(bounds.northWest, zoom) + _project(bounds.southEast, zoom)) / 2;
  // Uneven padding shifts the fitted area off the viewport center.
  final shift = Offset(
    (padding.left - padding.right) / 2,
    (padding.top - padding.bottom) / 2,
  );
  return camera.withPosition(
    center: _unproject(middle - shift, zoom),
    zoom: zoom,
  );
}

class FitBounds extends CameraFit {
  const FitBounds._({
    required this.bounds,
    this.padding = EdgeInsets.zero,
    this.maxZoom,
    this.minZoom = 0,
    this.forceIntegerZoomLevel = false,
  });
  final LatLngBounds bounds;
  final EdgeInsets padding;
  final double? maxZoom;
  final double minZoom;
  final bool forceIntegerZoomLevel;
  @override
  MapCamera fit(MapCamera camera) => _fitBounds(
    camera,
    bounds,
    padding,
    maxZoom,
    minZoom,
    forceIntegerZoomLevel,
  );
}

class FitCoordinates extends CameraFit {
  const FitCoordinates._({
    required this.coordinates,
    this.padding = EdgeInsets.zero,
    this.maxZoom,
    this.minZoom = 0,
    this.forceIntegerZoomLevel = false,
  });
  final List<LatLng> coordinates;
  final EdgeInsets padding;
  final double? maxZoom;
  final double minZoom;
  final bool forceIntegerZoomLevel;
  @override
  MapCamera fit(MapCamera camera) => _fitBounds(
    camera,
    LatLngBounds.fromPoints(coordinates),
    padding,
    maxZoom,
    minZoom,
    forceIntegerZoomLevel,
  );
}

abstract class CameraConstraint {
  const CameraConstraint();
  const factory CameraConstraint.unconstrained() = _Unconstrained;
  const factory CameraConstraint.contain({required LatLngBounds bounds}) =
      _ContainCenter;
  const factory CameraConstraint.containCenter({required LatLngBounds bounds}) =
      _ContainCenter;
  MapCamera? constrain(MapCamera camera);
}

class _Unconstrained extends CameraConstraint {
  const _Unconstrained();
  @override
  MapCamera constrain(MapCamera camera) => camera;
}

class _ContainCenter extends CameraConstraint {
  const _ContainCenter({required this.bounds});
  final LatLngBounds bounds;
  @override
  MapCamera constrain(MapCamera camera) => camera.withPosition(
    center: LatLng(
      camera.center.latitude.clamp(bounds.south, bounds.north).toDouble(),
      camera.center.longitude.clamp(bounds.west, bounds.east).toDouble(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Options, events and controller.

abstract final class InteractiveFlag {
  static const none = 0;
  static const drag = 1 << 0;
  static const flingAnimation = 1 << 1;
  static const pinchMove = 1 << 2;
  static const pinchZoom = 1 << 3;
  static const doubleTapZoom = 1 << 4;
  static const doubleTapDragZoom = 1 << 5;
  static const scrollWheelZoom = 1 << 6;
  static const rotate = 1 << 7;
  static const all =
      drag |
      flingAnimation |
      pinchMove |
      pinchZoom |
      doubleTapZoom |
      doubleTapDragZoom |
      scrollWheelZoom |
      rotate;

  static bool hasFlag(int flags, int flag) => flags & flag != 0;
  static bool hasDrag(int flags) => hasFlag(flags, drag);
  static bool hasScrollWheelZoom(int flags) => hasFlag(flags, scrollWheelZoom);
  static bool hasDoubleTapZoom(int flags) => hasFlag(flags, doubleTapZoom);
}

abstract final class MultiFingerGesture {
  static const none = 0;
  static const pinchMove = 1 << 0;
  static const pinchZoom = 1 << 1;
  static const rotate = 1 << 2;
  static const all = pinchMove | pinchZoom | rotate;
}

class InteractionOptions {
  const InteractionOptions({
    this.flags = InteractiveFlag.all,
    this.scrollWheelVelocity = 0.005,
    this.enableMultiFingerGestureRace = false,
    this.pinchZoomThreshold = 0.5,
    this.pinchMoveThreshold = 40,
    this.rotationThreshold = 20,
    this.rotationWinGestures = MultiFingerGesture.rotate,
    this.pinchZoomWinGestures =
        MultiFingerGesture.pinchZoom | MultiFingerGesture.pinchMove,
    this.pinchMoveWinGestures =
        MultiFingerGesture.pinchZoom | MultiFingerGesture.pinchMove,
  });
  final int flags;
  final double scrollWheelVelocity;
  final bool enableMultiFingerGestureRace;
  final double pinchZoomThreshold, pinchMoveThreshold, rotationThreshold;
  final int rotationWinGestures, pinchZoomWinGestures, pinchMoveWinGestures;
}

typedef TapCallback = void Function(TapPosition tapPosition, LatLng point);
typedef LongPressCallback =
    void Function(TapPosition tapPosition, LatLng point);
typedef PositionCallback = void Function(MapCamera camera, bool hasGesture);
typedef MapEventCallback = void Function(MapEvent event);

class MapOptions {
  const MapOptions({
    this.crs = const Epsg3857(),
    this.initialCenter = const LatLng(50.5, 30.51),
    this.initialZoom = 13,
    this.initialRotation = 0,
    this.initialCameraFit,
    this.cameraConstraint = const CameraConstraint.unconstrained(),
    this.interactionOptions = const InteractionOptions(),
    this.minZoom,
    this.maxZoom,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.onTap,
    this.onSecondaryTap,
    this.onLongPress,
    this.onPositionChanged,
    this.onMapEvent,
    this.onMapReady,
    this.keepAlive = false,
    this.applyPointerTranslucencyToLayers = true,
  });
  final Crs crs;
  final LatLng initialCenter;
  final double initialZoom, initialRotation;
  final CameraFit? initialCameraFit;
  final CameraConstraint cameraConstraint;
  final InteractionOptions interactionOptions;
  final double? minZoom, maxZoom;
  final Color backgroundColor;
  final TapCallback? onTap, onSecondaryTap;
  final LongPressCallback? onLongPress;
  final PositionCallback? onPositionChanged;
  final MapEventCallback? onMapEvent;
  final VoidCallback? onMapReady;
  final bool keepAlive, applyPointerTranslucencyToLayers;

  static MapOptions of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError('No FlutterMap ancestor in this context.'));
  static MapOptions? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MapScope>()?.options;
}

enum MapEventSource {
  mapController,
  tap,
  secondaryTap,
  longPress,
  doubleTap,
  dragStart,
  onDrag,
  dragEnd,
  scrollWheel,
  fitCamera,
  nonRotatedSizeChange,
  custom,
}

abstract class MapEvent {
  const MapEvent({required this.source, required this.camera});
  final MapEventSource source;
  final MapCamera camera;
}

class MapEventTap extends MapEvent {
  const MapEventTap({
    required this.tapPosition,
    required super.source,
    required super.camera,
  });
  final LatLng tapPosition;
}

class MapEventLongPress extends MapEvent {
  const MapEventLongPress({
    required this.tapPosition,
    required super.source,
    required super.camera,
  });
  final LatLng tapPosition;
}

class MapEventMoveStart extends MapEvent {
  const MapEventMoveStart({required super.source, required super.camera});
}

class MapEventMove extends MapEvent {
  const MapEventMove({
    this.id,
    required this.oldCamera,
    required super.source,
    required super.camera,
  });
  final String? id;
  final MapCamera oldCamera;
}

class MapEventMoveEnd extends MapEvent {
  const MapEventMoveEnd({required super.source, required super.camera});
}

class MapEventScrollWheelZoom extends MapEvent {
  const MapEventScrollWheelZoom({
    required this.oldCamera,
    required super.source,
    required super.camera,
  });
  final MapCamera oldCamera;
}

class MapEventDoubleTapZoom extends MapEvent {
  const MapEventDoubleTapZoom({
    required this.oldCamera,
    required super.source,
    required super.camera,
  });
  final MapCamera oldCamera;
}

class MapController {
  MapController();

  _FlutterMapState? _map;
  final _events = StreamController<MapEvent>.broadcast(sync: true);

  static MapController of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError('No FlutterMap ancestor in this context.'));
  static MapController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MapScope>()?.controller;

  MapCamera get camera =>
      _map?._camera ??
      (throw StateError(
        'The MapController is not attached to a laid-out FlutterMap.',
      ));

  Stream<MapEvent> get mapEventStream => _events.stream;

  bool move(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
    String? id,
  }) {
    final map = _map;
    final current = map?._camera;
    if (map == null || current == null) return false;
    var next = current.withPosition(
      center: center,
      zoom: current.clampZoom(zoom),
    );
    if (offset != Offset.zero) {
      next = next.withPosition(
        center: _unproject(
          _project(next.center, next.zoom) - offset,
          next.zoom,
        ),
      );
    }
    return map._moveTo(next, MapEventSource.mapController, id: id);
  }

  /// Rotation is not available; the camera keeps north up.
  bool rotate(double degree) => false;

  ({bool moveSuccess, bool rotateSuccess}) moveAndRotate(
    LatLng center,
    double zoom,
    double degree, {
    Offset offset = Offset.zero,
    String? id,
  }) => (
    moveSuccess: move(center, zoom, offset: offset, id: id),
    rotateSuccess: false,
  );

  bool fitCamera(CameraFit cameraFit) {
    final map = _map;
    final current = map?._camera;
    if (map == null || current == null) return false;
    return map._moveTo(cameraFit.fit(current), MapEventSource.fitCamera);
  }

  void dispose() {
    _map = null;
    _events.close();
  }
}

// ---------------------------------------------------------------------------
// The map widget.

class _MapScope extends InheritedWidget {
  const _MapScope({
    required this.camera,
    required this.options,
    required this.controller,
    required super.child,
  });
  final MapCamera camera;
  final MapOptions options;
  final MapController controller;
  @override
  bool updateShouldNotify(_MapScope old) =>
      old.camera != camera ||
      old.options != options ||
      old.controller != controller;
}

class FlutterMap extends StatefulWidget {
  const FlutterMap({
    super.key,
    this.mapController,
    required this.options,
    this.children = const [],
  });
  final MapController? mapController;
  final MapOptions options;
  final List<Widget> children;
  @override
  State<FlutterMap> createState() => _FlutterMapState();
}

class _FlutterMapState extends State<FlutterMap> {
  late MapController _controller;
  bool _ownsController = false;
  MapCamera? _camera;
  bool _ready = false, _dragging = false;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _ownsController = widget.mapController == null;
    _controller = widget.mapController ?? MapController();
    _controller._map = this;
  }

  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapController != widget.mapController) {
      if (_ownsController) {
        _controller.dispose();
      } else if (identical(_controller._map, this)) {
        _controller._map = null;
      }
      _attach();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    } else if (identical(_controller._map, this)) {
      _controller._map = null;
    }
    super.dispose();
  }

  MapOptions get _options => widget.options;

  MapCamera _constrained(MapCamera camera) =>
      _options.cameraConstraint.constrain(camera) ?? camera;

  /// The camera for a viewport of [size], created on first layout.
  MapCamera _cameraFor(Size size) {
    final current = _camera;
    if (current != null) {
      if (current.nonRotatedSize == size) return current;
      return _camera = current.withNonRotatedSize(size);
    }
    var camera = MapCamera(
      crs: _options.crs,
      center: _options.initialCenter,
      zoom: _options.initialZoom,
      nonRotatedSize: size,
      minZoom: _options.minZoom,
      maxZoom: _options.maxZoom,
    );
    camera = camera.withPosition(zoom: camera.clampZoom(camera.zoom));
    final fit = _options.initialCameraFit;
    if (fit != null) camera = fit.fit(camera);
    camera = _constrained(camera);
    if (!_ready) {
      _ready = true;
      final onReady = _options.onMapReady;
      if (onReady != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
      }
    }
    return _camera = camera;
  }

  void _emit(MapEvent event) {
    _options.onMapEvent?.call(event);
    if (!_controller._events.isClosed) _controller._events.add(event);
  }

  bool _moveTo(
    MapCamera next,
    MapEventSource source, {
    String? id,
    bool hasGesture = false,
  }) {
    final old = _camera;
    if (old == null) return false;
    next = _constrained(next);
    if (next.center == old.center && next.zoom == old.zoom) return false;
    setState(() => _camera = next);
    _emit(switch (source) {
      MapEventSource.scrollWheel => MapEventScrollWheelZoom(
        oldCamera: old,
        source: source,
        camera: next,
      ),
      MapEventSource.doubleTap => MapEventDoubleTapZoom(
        oldCamera: old,
        source: source,
        camera: next,
      ),
      _ => MapEventMove(id: id, oldCamera: old, source: source, camera: next),
    });
    _options.onPositionChanged?.call(next, hasGesture);
    return true;
  }

  TapPosition _tapPosition(Offset global, Offset local) =>
      TapPosition(global, local);

  @override
  Widget build(BuildContext context) => NativeSizeBuilder(
    builder: (context, size) {
      final camera = _cameraFor(size);
      final flags = _options.interactionOptions.flags;
      Widget map = ClipRect(
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: _options.backgroundColor)),
            for (final child in widget.children) Positioned.fill(child: child),
          ],
        ),
      );
      map = GestureDetector(
        onTapUp: _options.onTap == null
            ? null
            : (details) {
                final point = camera.screenOffsetToLatLng(
                  details.localPosition,
                );
                _emit(
                  MapEventTap(
                    tapPosition: point,
                    source: MapEventSource.tap,
                    camera: camera,
                  ),
                );
                _options.onTap!(
                  _tapPosition(details.globalPosition, details.localPosition),
                  point,
                );
              },
        onLongPressStart: _options.onLongPress == null
            ? null
            : (details) {
                final point = camera.screenOffsetToLatLng(
                  details.localPosition,
                );
                _emit(
                  MapEventLongPress(
                    tapPosition: point,
                    source: MapEventSource.longPress,
                    camera: camera,
                  ),
                );
                _options.onLongPress!(
                  _tapPosition(details.globalPosition, details.localPosition),
                  point,
                );
              },
        onDoubleTap: InteractiveFlag.hasDoubleTapZoom(flags)
            ? () {
                final current = _camera!;
                _moveTo(
                  current._zoomAround(
                    current.zoom + 1,
                    Offset(size.width / 2, size.height / 2),
                  ),
                  MapEventSource.doubleTap,
                  hasGesture: true,
                );
              }
            : null,
        onPanStart: InteractiveFlag.hasDrag(flags)
            ? (_) {
                _dragging = true;
                _emit(
                  MapEventMoveStart(
                    source: MapEventSource.dragStart,
                    camera: _camera!,
                  ),
                );
              }
            : null,
        onPanUpdate: InteractiveFlag.hasDrag(flags)
            ? (details) {
                final current = _camera!;
                _moveTo(
                  current.withPosition(
                    center: _unproject(
                      _project(current.center, current.zoom) - details.delta,
                      current.zoom,
                    ),
                  ),
                  MapEventSource.onDrag,
                  hasGesture: true,
                );
              }
            : null,
        onPanEnd: InteractiveFlag.hasDrag(flags)
            ? (_) {
                if (!_dragging) return;
                _dragging = false;
                _emit(
                  MapEventMoveEnd(
                    source: MapEventSource.dragEnd,
                    camera: _camera!,
                  ),
                );
              }
            : null,
        child: map,
      );
      if (InteractiveFlag.hasScrollWheelZoom(flags)) {
        map = Listener(
          onPointerSignal: (event) {
            if (event is! PointerScrollEvent || event.scrollDelta.dy == 0) {
              return;
            }
            final current = _camera!;
            _moveTo(
              current._zoomAround(
                current.zoom -
                    event.scrollDelta.dy *
                        _options.interactionOptions.scrollWheelVelocity,
                event.localPosition,
              ),
              MapEventSource.scrollWheel,
              hasGesture: true,
            );
          },
          child: map,
        );
      }
      return _MapScope(
        camera: camera,
        options: _options,
        controller: _controller,
        child: map,
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Tiles.

class TileProvider {
  TileProvider({this.headers = const {}});
  final Map<String, String> headers;
}

class NetworkTileProvider extends TileProvider {
  NetworkTileProvider({
    super.headers,
    Object? httpClient,
    bool? silenceExceptions,
  });
}

class TileLayer extends StatelessWidget {
  TileLayer({
    super.key,
    this.urlTemplate,
    this.fallbackUrl,
    double? tileSize,
    int? tileDimension,
    this.minZoom = 0,
    this.maxZoom = double.infinity,
    this.minNativeZoom = 0,
    this.maxNativeZoom = 19,
    this.zoomReverse = false,
    this.zoomOffset = 0,
    this.additionalOptions = const {},
    this.subdomains = const ['a', 'b', 'c'],
    this.tms = false,
    this.retinaMode,
    this.userAgentPackageName = 'unknown',
    this.tileProvider,
    this.errorImage,
    this.keepBuffer = 2,
    this.panBuffer = 1,
    this.wmsOptions,
  }) : tileSize = tileSize ?? tileDimension?.toDouble() ?? 256;

  final String? urlTemplate, fallbackUrl;
  final double tileSize, minZoom, maxZoom, zoomOffset;
  final int minNativeZoom, maxNativeZoom, keepBuffer, panBuffer;
  final bool zoomReverse, tms;
  final bool? retinaMode;
  final Map<String, String> additionalOptions;
  final List<String> subdomains;
  final String userAgentPackageName;
  final TileProvider? tileProvider;
  final ImageProvider? errorImage;
  final Object? wmsOptions;

  String _url(String template, int x, int y, int z) {
    final values = <String, String>{
      ...additionalOptions,
      'x': '$x',
      'y': '${tms ? (1 << z) - 1 - y : y}',
      'z': '${(zoomReverse ? maxNativeZoom - z : z) + zoomOffset.round()}',
      's': subdomains.isEmpty
          ? ''
          : subdomains[(x + y).abs() % subdomains.length],
      'r': retinaMode == true ? '@2x' : '',
      'd': '${tileSize.round()}',
    };
    return template.replaceAllMapped(
      RegExp(r'\{(\w+)\}'),
      (match) => values[match.group(1)!] ?? match.group(0)!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = urlTemplate;
    final camera = MapCamera.of(context);
    if (template == null || camera.zoom < minZoom || camera.zoom > maxZoom) {
      return const SizedBox.shrink();
    }
    final z = camera.zoom.round().clamp(minNativeZoom, maxNativeZoom);
    final scaled = tileSize * math.pow(2, camera.zoom - z) / (tileSize / 256);
    final origin = camera.pixelOrigin;
    final size = camera.nonRotatedSize;
    final count = 1 << z;
    final firstX = (origin.dx / scaled).floor();
    final lastX = ((origin.dx + size.width) / scaled).floor();
    final firstY = math.max(0, (origin.dy / scaled).floor());
    final lastY = math.min(
      count - 1,
      ((origin.dy + size.height) / scaled).floor(),
    );
    return Stack(
      children: [
        for (var y = firstY; y <= lastY; y++)
          for (var x = firstX; x <= lastX; x++)
            Positioned(
              key: ValueKey('$z/$x/$y'),
              left: x * scaled - origin.dx,
              top: y * scaled - origin.dy,
              // Half a pixel of overlap hides seams between tiles.
              width: scaled + 0.5,
              height: scaled + 0.5,
              child: Image.network(
                _url(template, x % count, y, z),
                fit: BoxFit.fill,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) =>
                    fallbackUrl == null
                    ? const SizedBox.shrink()
                    : Image.network(
                        _url(fallbackUrl!, x % count, y, z),
                        fit: BoxFit.fill,
                        excludeFromSemantics: true,
                      ),
              ),
            ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Vector layers.

class StrokePattern {
  const StrokePattern.solid() : _kind = 0, segments = null, spacingFactor = 0;
  const StrokePattern.dotted({this.spacingFactor = 1.5})
    : _kind = 1,
      segments = null;
  const StrokePattern.dashed({required List<double> this.segments})
    : _kind = 2,
      spacingFactor = 0;
  final int _kind;
  final List<double>? segments;
  final double spacingFactor;
}

class Polyline<R extends Object> {
  Polyline({
    required this.points,
    this.strokeWidth = 1,
    this.pattern = const StrokePattern.solid(),
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0,
    this.borderColor = const Color(0xFFFFFF00),
    this.gradientColors,
    this.colorsStop,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.useStrokeWidthInMeter = false,
    this.hitValue,
  });
  final List<LatLng> points;
  final double strokeWidth, borderStrokeWidth;
  final StrokePattern pattern;
  final Color color, borderColor;
  final List<Color>? gradientColors;
  final List<double>? colorsStop;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final bool useStrokeWidthInMeter;
  final R? hitValue;
}

class Polygon<R extends Object> {
  Polygon({
    required this.points,
    this.holePointsList,
    this.color,
    this.borderStrokeWidth = 0,
    this.borderColor = const Color(0xFFFFFF00),
    this.pattern = const StrokePattern.solid(),
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.label,
    this.labelStyle = const TextStyle(),
    this.hitValue,
  });
  final List<LatLng> points;
  final List<List<LatLng>>? holePointsList;
  final Color? color;
  final double borderStrokeWidth;
  final Color borderColor;
  final StrokePattern pattern;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final String? label;
  final TextStyle labelStyle;
  final R? hitValue;
}

class CircleMarker<R extends Object> {
  const CircleMarker({
    this.key,
    required this.point,
    required this.radius,
    this.useRadiusInMeter = false,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0,
    this.borderColor = const Color(0xFFFFFF00),
    this.hitValue,
  });
  final Key? key;
  final LatLng point;
  final double radius, borderStrokeWidth;
  final bool useRadiusInMeter;
  final Color color, borderColor;
  final R? hitValue;
}

/// Strokes [points] with [pattern], drawing dashes and dots explicitly.
void _strokePattern(
  Canvas canvas,
  List<Offset> points,
  StrokePattern pattern,
  Paint paint,
) {
  if (points.length < 2) return;
  if (pattern._kind == 0) {
    final path = ui.Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
    return;
  }
  final dotted = pattern._kind == 1;
  final segments = dotted
      ? [0.0, paint.strokeWidth * pattern.spacingFactor]
      : pattern.segments!;
  if (segments.isEmpty || segments.every((value) => value <= 0)) return;
  var index = 0;
  var remaining = segments[0];
  var drawing = true;
  final dot = Paint()
    ..color = paint.color
    ..style = PaintingStyle.fill;
  for (var i = 0; i + 1 < points.length; i++) {
    var start = points[i];
    final end = points[i + 1];
    var length = (end - start).distance;
    while (length > 0) {
      final step = math.min(remaining, length);
      final next = start + (end - start) * (step / length);
      if (drawing) {
        if (dotted) {
          canvas.drawCircle(start, paint.strokeWidth / 2, dot);
        } else {
          canvas.drawLine(start, next, paint);
        }
      }
      length -= step;
      remaining -= step;
      start = next;
      if (remaining <= 0) {
        index = (index + 1) % segments.length;
        remaining = segments[index];
        drawing = !drawing;
        if (dotted) drawing = index == 0;
      }
    }
  }
}

Color _gradientAt(List<Color> colors, List<double>? stops, double t) {
  if (colors.length == 1) return colors.first;
  final positions =
      stops ??
      [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)];
  if (t <= positions.first) return colors.first;
  for (var i = 1; i < colors.length; i++) {
    if (t <= positions[i]) {
      final span = positions[i] - positions[i - 1];
      return Color.lerp(
        colors[i - 1],
        colors[i],
        span <= 0 ? 1 : (t - positions[i - 1]) / span,
      )!;
    }
  }
  return colors.last;
}

class _PolylinePainter extends CustomPainter {
  _PolylinePainter(this.polylines, this.camera);
  final List<Polyline> polylines;
  final MapCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in polylines) {
      if (line.points.length < 2) continue;
      final points = [
        for (final point in line.points) camera.latLngToScreenOffset(point),
      ];
      final width = line.useStrokeWidthInMeter
          ? line.strokeWidth / camera.metersPerPixel(line.points.first.latitude)
          : line.strokeWidth;
      Paint stroke(Color color, double strokeWidth) => Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = line.strokeCap
        ..strokeJoin = line.strokeJoin;
      if (line.borderStrokeWidth > 0) {
        _strokePattern(
          canvas,
          points,
          line.pattern,
          stroke(line.borderColor, width + line.borderStrokeWidth * 2),
        );
      }
      final gradient = line.gradientColors;
      if (gradient == null || gradient.isEmpty) {
        _strokePattern(canvas, points, line.pattern, stroke(line.color, width));
        continue;
      }
      // Gradients advance along the line, segment by segment.
      for (var i = 0; i + 1 < points.length; i++) {
        _strokePattern(
          canvas,
          [points[i], points[i + 1]],
          line.pattern,
          stroke(
            _gradientAt(
              gradient,
              line.colorsStop,
              i / (points.length - 2).clamp(1, 1 << 30),
            ),
            width,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PolylinePainter old) =>
      old.polylines != polylines ||
      old.camera.center != camera.center ||
      old.camera.zoom != camera.zoom ||
      old.camera.nonRotatedSize != camera.nonRotatedSize;
}

class PolylineLayer<R extends Object> extends StatelessWidget {
  const PolylineLayer({
    super.key,
    required this.polylines,
    this.simplificationTolerance = 0.4,
    this.cullingMargin = 10,
    this.hitNotifier,
    this.minimumHitbox = 10,
  });
  final List<Polyline<R>> polylines;
  final double simplificationTolerance, minimumHitbox;
  final double? cullingMargin;
  final Object? hitNotifier;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PolylinePainter(polylines, MapCamera.of(context)));
}

class _PolygonPainter extends CustomPainter {
  _PolygonPainter(this.polygons, this.camera);
  final List<Polygon> polygons;
  final MapCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    for (final polygon in polygons) {
      if (polygon.points.length < 2) continue;
      List<Offset> ring(List<LatLng> points) => [
        for (final point in points) camera.latLngToScreenOffset(point),
      ];
      final outer = ring(polygon.points);
      final path = ui.Path()..fillType = PathFillType.evenOdd;
      for (final points in [outer, ...?polygon.holePointsList?.map(ring)]) {
        if (points.isEmpty) continue;
        path.moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        path.close();
      }
      if (polygon.color case final color?) {
        canvas.drawPath(path, Paint()..color = color);
      }
      if (polygon.borderStrokeWidth > 0) {
        final border = Paint()
          ..color = polygon.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = polygon.borderStrokeWidth
          ..strokeCap = polygon.strokeCap
          ..strokeJoin = polygon.strokeJoin;
        _strokePattern(
          canvas,
          [...outer, outer.first],
          polygon.pattern,
          border,
        );
      }
      final label = polygon.label;
      if (label != null) {
        var center = Offset.zero;
        for (final point in outer) {
          center += point;
        }
        center /= outer.length.toDouble();
        final painter = TextPainter(
          text: TextSpan(text: label, style: polygon.labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(
          canvas,
          center - Offset(painter.width / 2, painter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PolygonPainter old) =>
      old.polygons != polygons ||
      old.camera.center != camera.center ||
      old.camera.zoom != camera.zoom ||
      old.camera.nonRotatedSize != camera.nonRotatedSize;
}

class PolygonLayer<R extends Object> extends StatelessWidget {
  const PolygonLayer({
    super.key,
    required this.polygons,
    this.simplificationTolerance = 0.5,
    this.polygonCulling = true,
    this.polygonLabels = true,
    this.drawLabelsLast = false,
    this.hitNotifier,
  });
  final List<Polygon<R>> polygons;
  final double simplificationTolerance;
  final bool polygonCulling, polygonLabels, drawLabelsLast;
  final Object? hitNotifier;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PolygonPainter(polygons, MapCamera.of(context)));
}

class _CirclePainter extends CustomPainter {
  _CirclePainter(this.circles, this.camera);
  final List<CircleMarker> circles;
  final MapCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    for (final circle in circles) {
      final center = camera.latLngToScreenOffset(circle.point);
      final radius = circle.useRadiusInMeter
          ? circle.radius / camera.metersPerPixel(circle.point.latitude)
          : circle.radius;
      canvas.drawCircle(center, radius, Paint()..color = circle.color);
      if (circle.borderStrokeWidth > 0) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = circle.borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = circle.borderStrokeWidth,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.circles != circles ||
      old.camera.center != camera.center ||
      old.camera.zoom != camera.zoom ||
      old.camera.nonRotatedSize != camera.nonRotatedSize;
}

class CircleLayer<R extends Object> extends StatelessWidget {
  const CircleLayer({super.key, required this.circles, this.hitNotifier});
  final List<CircleMarker<R>> circles;
  final Object? hitNotifier;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CirclePainter(circles, MapCamera.of(context)));
}

// ---------------------------------------------------------------------------
// Markers.

class Marker {
  const Marker({
    this.key,
    required this.point,
    required this.child,
    this.width = 30,
    this.height = 30,
    this.alignment,
    this.rotate,
  });
  final Key? key;
  final LatLng point;
  final Widget child;
  final double width, height;
  final Alignment? alignment;
  final bool? rotate;
}

class MarkerLayer extends StatelessWidget {
  const MarkerLayer({
    super.key,
    required this.markers,
    this.alignment = Alignment.center,
    this.rotate = false,
  });
  final List<Marker> markers;
  final Alignment alignment;
  final bool rotate;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final size = camera.nonRotatedSize;
    return Stack(
      children: [
        for (final (index, marker) in markers.indexed)
          () {
            final point = camera.latLngToScreenOffset(marker.point);
            final align = marker.alignment ?? alignment;
            // As in flutter_map: the alignment places the marker box
            // relative to the point (center straddles it).
            final left = point.dx - marker.width * (1 - align.x) / 2;
            final top = point.dy - marker.height * (1 - align.y) / 2;
            if (left > size.width ||
                top > size.height ||
                left + marker.width < 0 ||
                top + marker.height < 0) {
              return null;
            }
            return Positioned(
              key: marker.key ?? ValueKey(index),
              left: left,
              top: top,
              width: marker.width,
              height: marker.height,
              child: marker.child,
            );
          }(),
      ].nonNulls.toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Attribution.

enum AttributionAlignment { bottomLeft, bottomRight }

abstract class SourceAttribution {
  const SourceAttribution({this.onTap});
  final VoidCallback? onTap;
  Widget _build(BuildContext context);
}

class TextSourceAttribution extends SourceAttribution {
  const TextSourceAttribution(
    this.text, {
    super.onTap,
    this.textStyle,
    this.prependCopyright = true,
  });
  final String text;
  final TextStyle? textStyle;
  final bool prependCopyright;
  @override
  Widget _build(BuildContext context) {
    final label = Text(
      '${prependCopyright ? '© ' : ''}$text',
      style: (textStyle ?? const TextStyle()).copyWith(
        fontSize: textStyle?.fontSize ?? 12,
        decoration: onTap == null ? null : TextDecoration.underline,
      ),
    );
    return onTap == null ? label : InkWell(onTap: onTap, child: label);
  }
}

class LogoSourceAttribution extends SourceAttribution {
  const LogoSourceAttribution(
    this.image, {
    super.onTap,
    this.tooltip,
    this.height = 24,
  });
  final Widget image;
  final String? tooltip;
  final double height;
  @override
  Widget _build(BuildContext context) {
    final logo = SizedBox(height: height, child: image);
    return onTap == null ? logo : InkWell(onTap: onTap, child: logo);
  }
}

Widget _attributionBox(Alignment alignment, Color background, Widget child) =>
    Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: child,
      ),
    );

class RichAttributionWidget extends StatelessWidget {
  const RichAttributionWidget({
    super.key,
    required this.attributions,
    this.alignment = AttributionAlignment.bottomRight,
    this.showFlutterMapAttribution = true,
    this.popupBackgroundColor,
    this.permanentHeight = 24,
    this.openButton,
    this.closeButton,
    this.animationConfig,
    this.popupInitialDisplayDuration = Duration.zero,
    this.popupBorder,
  });
  final List<SourceAttribution> attributions;
  final AttributionAlignment alignment;
  final bool showFlutterMapAttribution;
  final Color? popupBackgroundColor;
  final double permanentHeight;
  final Object? openButton, closeButton, animationConfig;
  final Duration popupInitialDisplayDuration;
  final BoxBorder? popupBorder;

  @override
  Widget build(BuildContext context) => _attributionBox(
    alignment == AttributionAlignment.bottomLeft
        ? Alignment.bottomLeft
        : Alignment.bottomRight,
    popupBackgroundColor ?? const Color(0xCCFFFFFF),
    Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final attribution in attributions) attribution._build(context),
      ],
    ),
  );
}

class SimpleAttributionWidget extends StatelessWidget {
  const SimpleAttributionWidget({
    super.key,
    required this.source,
    this.onTap,
    this.backgroundColor,
    this.alignment = Alignment.bottomRight,
  });
  final Text source;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => _attributionBox(
    alignment,
    backgroundColor ?? const Color(0xCCFFFFFF),
    onTap == null ? source : InkWell(onTap: onTap, child: source),
  );
}

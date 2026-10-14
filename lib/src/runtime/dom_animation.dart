part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Frames and bindings. Animation frames come from requestAnimationFrame;
// post-frame callbacks run after the owner's next flush.

typedef FrameCallback = void Function(Duration timeStamp);

class _FrameScheduler {
  final _callbacks = <int, FrameCallback>{};
  var _nextId = 0;
  bool _requested = false;

  int schedule(FrameCallback callback) {
    final id = _nextId++;
    _callbacks[id] = callback;
    if (!_requested) {
      _requested = true;
      final window = _window as JSObject;
      if (window.has('requestAnimationFrame')) {
        window.callMethod(
          'requestAnimationFrame'.toJS,
          ((JSNumber stamp) => _run(stamp.toDartDouble)).toJS,
        );
      } else {
        Timer(const Duration(milliseconds: 16), () => _run(_now()));
      }
    }
    return id;
  }

  void cancel(int id) => _callbacks.remove(id);

  void _run(double milliseconds) {
    _requested = false;
    final stamp = Duration(microseconds: (milliseconds * 1000).round());
    final callbacks = Map.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks.values) {
      callback(stamp);
    }
  }
}

double _now() {
  final global = globalContext;
  final performance = global.getProperty<JSObject?>('performance'.toJS);
  final now = performance?.callMethod<JSNumber>('now'.toJS);
  return now?.toDartDouble ?? DateTime.now().microsecondsSinceEpoch / 1000.0;
}

final _frames = _FrameScheduler();

class SchedulerBinding {
  SchedulerBinding._();
  static final instance = WidgetsBinding.instance;
}

enum AppLifecycleState { detached, resumed, inactive, hidden, paused }

abstract mixin class WidgetsBindingObserver {
  void didChangeAppLifecycleState(AppLifecycleState state) {}
  void didChangeMetrics() {}
  void didChangePlatformBrightness() {}
  void didChangeTextScaleFactor() {}
  void didChangeLocales(List<Locale>? locales) {}
  void didChangeAccessibilityFeatures() {}
  void didHaveMemoryPressure() {}
  Future<bool> didPopRoute() => Future<bool>.value(false);
  Future<bool> didPushRoute(String route) => Future<bool>.value(false);
}

/// Lifecycle callbacks from page visibility, as Flutter web reports them.
class AppLifecycleListener with WidgetsBindingObserver {
  AppLifecycleListener({
    this.binding,
    this.onResume,
    this.onInactive,
    this.onHide,
    this.onShow,
    this.onPause,
    this.onRestart,
    this.onDetach,
    this.onExitRequested,
    this.onStateChange,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }
  final WidgetsBinding? binding;
  final VoidCallback? onResume, onInactive, onHide, onShow, onPause;
  final VoidCallback? onRestart, onDetach;
  final Future<Object?> Function()? onExitRequested;
  final ValueChanged<AppLifecycleState>? onStateChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChange?.call(state);
    switch (state) {
      case AppLifecycleState.resumed:
        onShow?.call();
        onResume?.call();
      case AppLifecycleState.hidden:
        onInactive?.call();
        onHide?.call();
      case AppLifecycleState.paused:
        onPause?.call();
      case AppLifecycleState.inactive:
        onInactive?.call();
      case AppLifecycleState.detached:
        onDetach?.call();
    }
  }

  void dispose() => WidgetsBinding.instance.removeObserver(this);
}

/// The subset of Flutter's bindings that applications touch at startup and
/// for post-frame work.
class WidgetsBinding {
  WidgetsBinding._();
  static final instance = WidgetsBinding._();
  final _postFrame = <FrameCallback>[];
  final _observers = <WidgetsBindingObserver>[];

  void addPostFrameCallback(FrameCallback callback, {String? debugLabel}) {
    _postFrame.add(callback);
    final owner = _activeOwner;
    if (owner != null && !owner._disposed) {
      owner._scheduleFrame();
    } else {
      scheduleMicrotask(_runPostFrame);
    }
  }

  void _runPostFrame() {
    if (_postFrame.isEmpty) return;
    final callbacks = List.of(_postFrame);
    _postFrame.clear();
    final stamp = Duration(microseconds: (_now() * 1000).round());
    for (final callback in callbacks) {
      callback(stamp);
    }
  }

  int scheduleFrameCallback(FrameCallback callback) =>
      _frames.schedule(callback);
  void cancelFrameCallbackWithId(int id) => _frames.cancel(id);
  void scheduleFrame() => _activeOwner?._scheduleFrame();
  void addObserver(WidgetsBindingObserver observer) {
    _listenForLifecycle();
    _observers.add(observer);
  }

  AppLifecycleState? lifecycleState = AppLifecycleState.resumed;
  bool _lifecycleListening = false;

  /// Page visibility drives lifecycle changes; resizes report metrics.
  void _listenForLifecycle() {
    if (_lifecycleListening) return;
    _lifecycleListening = true;
    final document = globalContext.getProperty<JSObject?>('document'.toJS);
    document?.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'visibilitychange'.toJS,
      ((JSAny? _) {
        final hidden =
            document.getProperty<JSString?>('visibilityState'.toJS)?.toDart ==
            'hidden';
        final state = hidden
            ? AppLifecycleState.hidden
            : AppLifecycleState.resumed;
        lifecycleState = state;
        for (final observer in List.of(_observers)) {
          observer.didChangeAppLifecycleState(state);
        }
      }).toJS,
    );
    _window.addEventListener(
      'resize',
      ((JSAny? _) {
        for (final observer in List.of(_observers)) {
          observer.didChangeMetrics();
        }
      }).toJS,
    );
  }

  bool removeObserver(WidgetsBindingObserver observer) =>
      _observers.remove(observer);
}

class WidgetsFlutterBinding extends WidgetsBinding {
  WidgetsFlutterBinding._() : super._();
  static WidgetsBinding ensureInitialized() => WidgetsBinding.instance;
}

// ---------------------------------------------------------------------------
// Tickers.

typedef TickerCallback = void Function(Duration elapsed);

class TickerCanceled implements Exception {
  const TickerCanceled();
}

/// Completes when the ticker stops normally; [orCancel] errors on cancel.
class TickerFuture implements Future<void> {
  TickerFuture._();
  TickerFuture.complete() {
    _complete();
  }
  final _primary = Completer<void>();
  Completer<void>? _secondary;
  bool? _completed;

  void _complete() {
    _completed = true;
    if (!_primary.isCompleted) _primary.complete();
    if (_secondary != null && !_secondary!.isCompleted) _secondary!.complete();
  }

  void _cancel() {
    _completed = false;
    if (_secondary != null && !_secondary!.isCompleted)
      _secondary!.completeError(const TickerCanceled());
  }

  Future<void> get orCancel {
    if (_secondary == null) {
      _secondary = Completer<void>();
      if (_completed == true) _secondary!.complete();
      if (_completed == false)
        _secondary!.completeError(const TickerCanceled());
    }
    return _secondary!.future;
  }

  @override
  Stream<void> asStream() => _primary.future.asStream();
  @override
  Future<void> catchError(Function onError, {bool Function(Object)? test}) =>
      _primary.future.catchError(onError, test: test);
  @override
  Future<R> then<R>(
    FutureOr<R> Function(void value) onValue, {
    Function? onError,
  }) => _primary.future.then(onValue, onError: onError);
  @override
  Future<void> timeout(
    Duration timeLimit, {
    FutureOr<void> Function()? onTimeout,
  }) => _primary.future.timeout(timeLimit, onTimeout: onTimeout);
  @override
  Future<void> whenComplete(FutureOr<void> Function() action) =>
      _primary.future.whenComplete(action);
}

class Ticker {
  Ticker(this._onTick, {this.debugLabel});
  final TickerCallback _onTick;
  final String? debugLabel;
  TickerFuture? _future;
  int? _frame;
  Duration? _start;
  bool muted = false;
  bool _disposed = false;

  bool get isTicking => _future != null && !muted;
  bool get isActive => _future != null;

  TickerFuture start() {
    if (_disposed) throw StateError('Ticker used after dispose.');
    if (_future != null) throw StateError('Ticker already started.');
    _future = TickerFuture._();
    _start = null;
    _scheduleTick();
    return _future!;
  }

  void _scheduleTick() {
    _frame = _frames.schedule(_tick);
  }

  void _tick(Duration stamp) {
    _frame = null;
    if (_future == null) return;
    _start ??= stamp;
    if (!muted) _onTick(stamp - _start!);
    if (_future != null) _scheduleTick();
  }

  void stop({bool canceled = false}) {
    final future = _future;
    if (future == null) return;
    _future = null;
    _start = null;
    if (_frame != null) {
      _frames.cancel(_frame!);
      _frame = null;
    }
    if (canceled) {
      future._cancel();
    } else {
      future._complete();
    }
  }

  void dispose() {
    stop(canceled: true);
    _disposed = true;
  }
}

abstract interface class TickerProvider {
  Ticker createTicker(TickerCallback onTick);
}

mixin SingleTickerProviderStateMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  Ticker? _ticker;
  @override
  Ticker createTicker(TickerCallback onTick) {
    if (_ticker != null)
      throw StateError('$runtimeType created multiple tickers.');
    return _ticker = Ticker(onTick, debugLabel: 'created by $this');
  }

  @override
  void dispose() {
    if (_ticker?.isActive ?? false)
      throw StateError('$runtimeType was disposed with an active Ticker.');
    super.dispose();
  }
}

mixin TickerProviderStateMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  final _tickers = <Ticker>{};
  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = Ticker(onTick, debugLabel: 'created by $this');
    _tickers.add(ticker);
    return ticker;
  }

  @override
  void dispose() {
    if (_tickers.any((ticker) => ticker.isActive))
      throw StateError('$runtimeType was disposed with an active Ticker.');
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Curves.

abstract class Curve {
  const Curve();
  double transform(double t) {
    if (t == 0 || t == 1) return t;
    return transformInternal(t);
  }

  double transformInternal(double t) => t;
  Curve get flipped => FlippedCurve(this);
}

class _Linear extends Curve {
  const _Linear();
}

class Cubic extends Curve {
  const Cubic(this.a, this.b, this.c, this.d);
  final double a, b, c, d;
  double _evaluate(double p, double q, double m) =>
      3 * p * (1 - m) * (1 - m) * m + 3 * q * (1 - m) * m * m + m * m * m;
  @override
  double transformInternal(double t) {
    var start = 0.0, end = 1.0;
    while (true) {
      final midpoint = (start + end) / 2;
      final estimate = _evaluate(a, c, midpoint);
      if ((t - estimate).abs() < 0.001) return _evaluate(b, d, midpoint);
      if (estimate < t) {
        start = midpoint;
      } else {
        end = midpoint;
      }
    }
  }
}

class FlippedCurve extends Curve {
  const FlippedCurve(this.curve);
  final Curve curve;
  @override
  double transformInternal(double t) => 1 - curve.transform(1 - t);
}

class Interval extends Curve {
  const Interval(this.begin, this.end, {this.curve = Curves.linear});
  final double begin, end;
  final Curve curve;
  @override
  double transformInternal(double t) {
    final value = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    if (value == 0 || value == 1) return value;
    return curve.transform(value);
  }
}

class Threshold extends Curve {
  const Threshold(this.threshold);
  final double threshold;
  @override
  double transformInternal(double t) => t < threshold ? 0 : 1;
}

class SawTooth extends Curve {
  const SawTooth(this.count);
  final int count;
  @override
  double transformInternal(double t) {
    final value = t * count;
    return value - value.truncateToDouble();
  }
}

class _BounceOut extends Curve {
  const _BounceOut();
  @override
  double transformInternal(double t) {
    if (t < 1 / 2.75) return 7.5625 * t * t;
    if (t < 2 / 2.75) {
      t -= 1.5 / 2.75;
      return 7.5625 * t * t + 0.75;
    }
    if (t < 2.5 / 2.75) {
      t -= 2.25 / 2.75;
      return 7.5625 * t * t + 0.9375;
    }
    t -= 2.625 / 2.75;
    return 7.5625 * t * t + 0.984375;
  }
}

class _ElasticOut extends Curve {
  const _ElasticOut();
  static const period = 0.4;
  @override
  double transformInternal(double t) {
    final s = period / 4;
    return math.pow(2, -10 * t) * math.sin((t - s) * (math.pi * 2) / period) +
        1;
  }
}

abstract final class Curves {
  static const Curve linear = _Linear();
  static const decelerate = Cubic(0, 0, 0.58, 1);
  static const fastLinearToSlowEaseIn = Cubic(0.18, 1, 0.04, 1);
  static const ease = Cubic(0.25, 0.1, 0.25, 1);
  static const easeIn = Cubic(0.42, 0, 1, 1);
  static const easeInToLinear = Cubic(0.67, 0.03, 0.65, 0.09);
  static const easeInSine = Cubic(0.47, 0, 0.745, 0.715);
  static const easeInQuad = Cubic(0.55, 0.085, 0.68, 0.53);
  static const easeInCubic = Cubic(0.55, 0.055, 0.675, 0.19);
  static const easeInQuart = Cubic(0.895, 0.03, 0.685, 0.22);
  static const easeInQuint = Cubic(0.755, 0.05, 0.855, 0.06);
  static const easeInExpo = Cubic(0.95, 0.05, 0.795, 0.035);
  static const easeInCirc = Cubic(0.6, 0.04, 0.98, 0.335);
  static const easeInBack = Cubic(0.6, -0.28, 0.735, 0.045);
  static const easeOut = Cubic(0, 0, 0.58, 1);
  static const linearToEaseOut = Cubic(0.35, 0.91, 0.33, 0.97);
  static const easeOutSine = Cubic(0.39, 0.575, 0.565, 1);
  static const easeOutQuad = Cubic(0.25, 0.46, 0.45, 0.94);
  static const easeOutCubic = Cubic(0.215, 0.61, 0.355, 1);
  static const easeOutQuart = Cubic(0.165, 0.84, 0.44, 1);
  static const easeOutQuint = Cubic(0.23, 1, 0.32, 1);
  static const easeOutExpo = Cubic(0.19, 1, 0.22, 1);
  static const easeOutCirc = Cubic(0.075, 0.82, 0.165, 1);
  static const easeOutBack = Cubic(0.175, 0.885, 0.32, 1.275);
  static const easeInOut = Cubic(0.42, 0, 0.58, 1);
  static const easeInOutSine = Cubic(0.445, 0.05, 0.55, 0.95);
  static const easeInOutQuad = Cubic(0.455, 0.03, 0.515, 0.955);
  static const easeInOutCubic = Cubic(0.645, 0.045, 0.355, 1);
  static const easeInOutQuart = Cubic(0.77, 0, 0.175, 1);
  static const easeInOutQuint = Cubic(0.86, 0, 0.07, 1);
  static const easeInOutExpo = Cubic(1, 0, 0, 1);
  static const easeInOutCirc = Cubic(0.785, 0.135, 0.15, 0.86);
  static const easeInOutBack = Cubic(0.68, -0.55, 0.265, 1.55);
  static const fastOutSlowIn = Cubic(0.4, 0, 0.2, 1);
  static const slowMiddle = Cubic(0.15, 0.85, 0.85, 0.15);
  static const Curve bounceOut = _BounceOut();
  static const Curve bounceIn = FlippedCurve(_BounceOut());
  static const Curve elasticOut = _ElasticOut();
  static const Curve elasticIn = FlippedCurve(_ElasticOut());
  static const Curve easeInOutCubicEmphasized = Cubic(0.2, 0, 0, 1);
}

// ---------------------------------------------------------------------------
// Animations.

enum AnimationStatus {
  dismissed,
  forward,
  reverse,
  completed;

  bool get isAnimating => this == forward || this == reverse;
  bool get isCompleted => this == completed;
  bool get isDismissed => this == dismissed;
  bool get isForwardOrCompleted => this == forward || this == completed;
}

typedef AnimationStatusListener = void Function(AnimationStatus status);

abstract class Animation<T> extends Listenable implements ValueListenable<T> {
  const Animation();
  factory Animation.fromValueListenable(ValueListenable<T> listenable) =
      _ValueListenableAnimation<T>;
  void addStatusListener(AnimationStatusListener listener);
  void removeStatusListener(AnimationStatusListener listener);
  AnimationStatus get status;
  @override
  T get value;
  bool get isDismissed => status == AnimationStatus.dismissed;
  bool get isCompleted => status == AnimationStatus.completed;
  bool get isAnimating => status.isAnimating;
  bool get isForwardOrCompleted => status.isForwardOrCompleted;
  Animation<U> drive<U>(Animatable<U> child) =>
      child.animate(this as Animation<double>);
}

class _ValueListenableAnimation<T> extends Animation<T> {
  _ValueListenableAnimation(this._listenable);
  final ValueListenable<T> _listenable;
  @override
  void addListener(VoidCallback listener) => _listenable.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _listenable.removeListener(listener);
  @override
  void addStatusListener(AnimationStatusListener listener) {}
  @override
  void removeStatusListener(AnimationStatusListener listener) {}
  @override
  AnimationStatus get status => AnimationStatus.forward;
  @override
  T get value => _listenable.value;
}

mixin _Listeners<T> on Animation<T> {
  final _valueListeners = <VoidCallback>[];
  final _statusListeners = <AnimationStatusListener>[];
  @override
  void addListener(VoidCallback listener) => _valueListeners.add(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _valueListeners.remove(listener);
  @override
  void addStatusListener(AnimationStatusListener listener) =>
      _statusListeners.add(listener);
  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      _statusListeners.remove(listener);
  void notifyListeners() {
    for (final listener in List.of(_valueListeners)) {
      if (_valueListeners.contains(listener)) listener();
    }
  }

  void notifyStatusListeners(AnimationStatus status) {
    for (final listener in List.of(_statusListeners)) {
      if (_statusListeners.contains(listener)) listener(status);
    }
  }
}

class AlwaysStoppedAnimation<T> extends Animation<T> {
  const AlwaysStoppedAnimation(this.value);
  @override
  final T value;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  void addStatusListener(AnimationStatusListener listener) {}
  @override
  void removeStatusListener(AnimationStatusListener listener) {}
  @override
  AnimationStatus get status => AnimationStatus.forward;
}

const Animation<double> kAlwaysCompleteAnimation = AlwaysStoppedAnimation(1);
const Animation<double> kAlwaysDismissedAnimation = AlwaysStoppedAnimation(0);

enum AnimationBehavior { normal, preserve }

class AnimationController extends Animation<double> with _Listeners<double> {
  AnimationController({
    double? value,
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    this.lowerBound = 0,
    this.upperBound = 1,
    this.animationBehavior = AnimationBehavior.normal,
    required TickerProvider vsync,
  }) : _value = (value ?? lowerBound).clamp(lowerBound, upperBound) {
    if (upperBound < lowerBound) throw ArgumentError('Invalid bounds.');
    _ticker = vsync.createTicker(_tick);
    _status = _value == upperBound && upperBound != lowerBound
        ? AnimationStatus.completed
        : AnimationStatus.dismissed;
  }
  AnimationController.unbounded({
    double value = 0,
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    this.animationBehavior = AnimationBehavior.preserve,
    required TickerProvider vsync,
  }) : lowerBound = double.negativeInfinity,
       upperBound = double.infinity,
       _value = value {
    _ticker = vsync.createTicker(_tick);
    _status = AnimationStatus.dismissed;
  }

  Duration? duration, reverseDuration;
  final String? debugLabel;
  final double lowerBound, upperBound;
  final AnimationBehavior animationBehavior;
  late Ticker? _ticker;
  double _value;
  late AnimationStatus _status;
  AnimationStatus _lastReported = AnimationStatus.dismissed;
  // Active simulation: from → to over a duration with a curve.
  double _from = 0, _to = 0;
  Duration _span = Duration.zero;
  Curve _curve = Curves.linear;
  bool _repeat = false, _repeatReverse = false;
  double _repeatMin = 0, _repeatMax = 1;
  Duration? _repeatPeriod;
  bool _forward = true;

  @override
  double get value => _value;
  set value(double newValue) {
    stop();
    _value = newValue.clamp(lowerBound, upperBound);
    _status = _value == lowerBound
        ? AnimationStatus.dismissed
        : _value == upperBound
        ? AnimationStatus.completed
        : (_forward ? AnimationStatus.forward : AnimationStatus.reverse);
    notifyListeners();
    _reportStatus();
  }

  @override
  AnimationStatus get status => _status;
  @override
  bool get isAnimating => _ticker?.isActive ?? false;
  Duration? get lastElapsedDuration => null;
  double get velocity => 0;
  Animation<double> get view => this;

  void reset() => value = lowerBound;

  void _reportStatus() {
    if (_status != _lastReported) {
      _lastReported = _status;
      notifyStatusListeners(_status);
    }
  }

  TickerFuture forward({double? from}) {
    _forward = true;
    if (from != null) value = from;
    return _animateTo(upperBound, duration, AnimationStatus.forward);
  }

  TickerFuture reverse({double? from}) {
    _forward = false;
    if (from != null) value = from;
    return _animateTo(
      lowerBound,
      reverseDuration ?? duration,
      AnimationStatus.reverse,
    );
  }

  TickerFuture toggle({double? from}) =>
      _forward && _status != AnimationStatus.completed
      ? forward(from: from)
      : reverse(from: from);

  TickerFuture animateTo(
    double target, {
    Duration? duration,
    Curve curve = Curves.linear,
  }) {
    _forward = target >= _value;
    return _animateTo(
      target,
      duration ?? this.duration,
      _forward ? AnimationStatus.forward : AnimationStatus.reverse,
      curve: curve,
      explicitDuration: duration != null,
    );
  }

  TickerFuture animateBack(
    double target, {
    Duration? duration,
    Curve curve = Curves.linear,
  }) {
    _forward = false;
    return _animateTo(
      target,
      duration ?? reverseDuration ?? this.duration,
      AnimationStatus.reverse,
      curve: curve,
      explicitDuration: duration != null,
    );
  }

  TickerFuture _animateTo(
    double target,
    Duration? total,
    AnimationStatus direction, {
    Curve curve = Curves.linear,
    bool explicitDuration = false,
  }) {
    if (total == null)
      throw StateError('AnimationController.duration is not set.');
    _stopTicker(canceled: true);
    _repeat = false;
    target = target.clamp(lowerBound, upperBound);
    final range = upperBound - lowerBound;
    final fraction = explicitDuration || !range.isFinite || range == 0
        ? 1.0
        : (target - _value).abs() / range;
    final span = total * fraction;
    if (span == Duration.zero || target == _value) {
      _value = target;
      _status = _settledStatus(direction);
      notifyListeners();
      _reportStatus();
      return TickerFuture.complete();
    }
    _from = _value;
    _to = target;
    _span = span;
    _curve = curve;
    _status = direction;
    _reportStatus();
    return _ticker!.start();
  }

  AnimationStatus _settledStatus(AnimationStatus direction) =>
      _value == upperBound && direction == AnimationStatus.forward
      ? AnimationStatus.completed
      : _value == lowerBound && direction == AnimationStatus.reverse
      ? AnimationStatus.dismissed
      : direction;

  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    int? count,
  }) {
    if (count != null)
      throw UnsupportedError('Counted repeats are unsupported.');
    _stopTicker(canceled: true);
    _repeat = true;
    _repeatReverse = reverse;
    _repeatMin = min ?? lowerBound;
    _repeatMax = max ?? upperBound;
    _repeatPeriod = period ?? duration;
    if (_repeatPeriod == null)
      throw StateError('AnimationController.duration is not set.');
    _forward = true;
    _from = _value.clamp(_repeatMin, _repeatMax);
    _to = _repeatMax;
    _span = _repeatPeriod! * ((_to - _from) / (_repeatMax - _repeatMin));
    _curve = Curves.linear;
    _status = AnimationStatus.forward;
    _reportStatus();
    return _ticker!.start();
  }

  Duration _segmentStart = Duration.zero;

  void _tick(Duration elapsed) {
    final local = elapsed - _segmentStart;
    final t = _span == Duration.zero
        ? 1.0
        : (local.inMicroseconds / _span.inMicroseconds).clamp(0.0, 1.0);
    _value = (_from + (_to - _from) * _curve.transform(t)).clamp(
      lowerBound,
      upperBound,
    );
    if (t >= 1) {
      if (_repeat) {
        _segmentStart = elapsed;
        if (_repeatReverse) {
          _forward = !_forward;
          _from = _to;
          _to = _forward ? _repeatMax : _repeatMin;
          _status = _forward
              ? AnimationStatus.forward
              : AnimationStatus.reverse;
        } else {
          _from = _repeatMin;
          _to = _repeatMax;
        }
        _span = _repeatPeriod!;
        notifyListeners();
        _reportStatus();
        return;
      }
      _segmentStart = Duration.zero;
      _status = _settledStatus(_status);
      _stopTicker(canceled: false);
      notifyListeners();
      _reportStatus();
      return;
    }
    notifyListeners();
  }

  void _stopTicker({required bool canceled}) {
    _segmentStart = Duration.zero;
    _ticker?.stop(canceled: canceled);
  }

  void stop({bool canceled = true}) {
    _repeat = false;
    _stopTicker(canceled: canceled);
  }

  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    _valueListeners.clear();
    _statusListeners.clear();
  }
}

class CurvedAnimation extends Animation<double> {
  CurvedAnimation({
    required this.parent,
    required this.curve,
    this.reverseCurve,
  });
  final Animation<double> parent;
  Curve curve;
  Curve? reverseCurve;
  @override
  void addListener(VoidCallback listener) => parent.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => parent.removeListener(listener);
  @override
  void addStatusListener(AnimationStatusListener listener) =>
      parent.addStatusListener(listener);
  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      parent.removeStatusListener(listener);
  @override
  AnimationStatus get status => parent.status;
  @override
  double get value {
    final active = reverseCurve != null && status == AnimationStatus.reverse
        ? reverseCurve!
        : curve;
    return active.transform(parent.value);
  }

  void dispose() {}
}

class ReverseAnimation extends Animation<double> {
  ReverseAnimation(this.parent);
  final Animation<double> parent;
  @override
  void addListener(VoidCallback listener) => parent.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => parent.removeListener(listener);
  @override
  void addStatusListener(AnimationStatusListener listener) =>
      parent.addStatusListener(listener);
  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      parent.removeStatusListener(listener);
  @override
  AnimationStatus get status => switch (parent.status) {
    AnimationStatus.forward => AnimationStatus.reverse,
    AnimationStatus.reverse => AnimationStatus.forward,
    AnimationStatus.completed => AnimationStatus.dismissed,
    AnimationStatus.dismissed => AnimationStatus.completed,
  };
  @override
  double get value => 1 - parent.value;
}

abstract class Animatable<T> {
  const Animatable();
  T transform(double t);
  T evaluate(Animation<double> animation) => transform(animation.value);
  Animation<T> animate(Animation<double> parent) =>
      _AnimatedEvaluation<T>(parent, this);
  Animatable<T> chain(Animatable<double> parent) =>
      _ChainedEvaluation<T>(parent, this);
}

class _AnimatedEvaluation<T> extends Animation<T> {
  _AnimatedEvaluation(this.parent, this._evaluatable);
  final Animation<double> parent;
  final Animatable<T> _evaluatable;
  @override
  void addListener(VoidCallback listener) => parent.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => parent.removeListener(listener);
  @override
  void addStatusListener(AnimationStatusListener listener) =>
      parent.addStatusListener(listener);
  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      parent.removeStatusListener(listener);
  @override
  AnimationStatus get status => parent.status;
  @override
  T get value => _evaluatable.evaluate(parent);
}

class _ChainedEvaluation<T> extends Animatable<T> {
  _ChainedEvaluation(this._parent, this._evaluatable);
  final Animatable<double> _parent;
  final Animatable<T> _evaluatable;
  @override
  T transform(double t) => _evaluatable.transform(_parent.transform(t));
}

class Tween<T extends Object?> extends Animatable<T> {
  Tween({this.begin, this.end});
  T? begin, end;

  T lerp(double t) {
    final a = begin, b = end;
    if (a is double? && b is double?) return lerpDouble(a, b, t) as T;
    if (a is int && b is int) return (a + (b - a) * t) as T;
    return (a as dynamic) + (((b as dynamic) - (a as dynamic)) * t) as T;
  }

  @override
  T transform(double t) {
    if (t == 0) return begin as T;
    if (t == 1) return end as T;
    return lerp(t);
  }
}

class ReverseTween<T extends Object?> extends Tween<T> {
  ReverseTween(this.parent) : super(begin: parent.end, end: parent.begin);
  final Tween<T> parent;
  @override
  T lerp(double t) => parent.lerp(1 - t);
}

class ColorTween extends Tween<Color?> {
  ColorTween({super.begin, super.end});
  @override
  Color? lerp(double t) => Color.lerp(begin, end, t);
}

class SizeTween extends Tween<Size?> {
  SizeTween({super.begin, super.end});
  @override
  Size? lerp(double t) => Size.lerp(begin, end, t);
}

class RectTween extends Tween<Rect?> {
  RectTween({super.begin, super.end});
  @override
  Rect? lerp(double t) => Rect.lerp(begin, end, t);
}

class IntTween extends Tween<int> {
  IntTween({super.begin, super.end});
  @override
  int lerp(double t) => (begin! + (end! - begin!) * t).round();
}

class StepTween extends Tween<int> {
  StepTween({super.begin, super.end});
  @override
  int lerp(double t) => (begin! + (end! - begin!) * t).floor();
}

class ConstantTween<T> extends Tween<T> {
  ConstantTween(T value) : super(begin: value, end: value);
  @override
  T lerp(double t) => begin as T;
}

class CurveTween extends Animatable<double> {
  CurveTween({required this.curve});
  Curve curve;
  @override
  double transform(double t) => curve.transform(t);
}

class AlignmentTween extends Tween<Alignment> {
  AlignmentTween({super.begin, super.end});
  @override
  Alignment lerp(double t) => Alignment.lerp(begin, end, t)!;
}

class EdgeInsetsTween extends Tween<EdgeInsets> {
  EdgeInsetsTween({super.begin, super.end});
  @override
  EdgeInsets lerp(double t) => EdgeInsets.lerp(begin, end, t)!;
}

class BorderRadiusTween extends Tween<BorderRadius?> {
  BorderRadiusTween({super.begin, super.end});
  @override
  BorderRadius? lerp(double t) => BorderRadius.lerp(begin, end, t);
}

class DecorationTween extends Tween<Decoration> {
  DecorationTween({super.begin, super.end});
  @override
  Decoration lerp(double t) => Decoration.lerp(begin, end, t)!;
}

class TextStyleTween extends Tween<TextStyle> {
  TextStyleTween({super.begin, super.end});
  @override
  TextStyle lerp(double t) => TextStyle.lerp(begin, end, t)!;
}

class TweenSequenceItem<T> {
  const TweenSequenceItem({required this.tween, required this.weight});
  final Animatable<T> tween;
  final double weight;
}

class TweenSequence<T> extends Animatable<T> {
  TweenSequence(List<TweenSequenceItem<T>> items)
    : _items = List.of(items),
      _total = items.fold(0.0, (sum, item) => sum + item.weight) {
    if (_items.isEmpty || !(_total > 0))
      throw ArgumentError('TweenSequence needs positive weights.');
  }
  final List<TweenSequenceItem<T>> _items;
  final double _total;
  @override
  T transform(double t) {
    var start = 0.0;
    for (var i = 0; i < _items.length; i++) {
      final end = start + _items[i].weight / _total;
      if (t <= end || i == _items.length - 1) {
        final local = end == start ? 0.0 : (t - start) / (end - start);
        return _items[i].tween.transform(local.clamp(0.0, 1.0));
      }
      start = end;
    }
    throw StateError('Unreachable');
  }
}

// ---------------------------------------------------------------------------
// Transforms.

/// Applies a Matrix4 as a CSS 3D transform. Layout is unaffected, as in
/// Flutter; hit testing follows the browser.
class Transform extends _DomWidget {
  const Transform({
    super.key,
    required this.transform,
    this.origin,
    this.alignment,
    this.transformHitTests = true,
    this.filterQuality,
    this.child,
  });
  Transform.rotate({
    super.key,
    required double angle,
    this.origin,
    this.alignment = Alignment.center,
    this.transformHitTests = true,
    this.filterQuality,
    this.child,
  }) : transform = Matrix4.rotationZ(angle);
  Transform.translate({
    super.key,
    required Offset offset,
    this.transformHitTests = true,
    this.filterQuality,
    this.child,
  }) : transform = Matrix4.translationValues(offset.dx, offset.dy, 0),
       origin = null,
       alignment = null;
  Transform.scale({
    super.key,
    double? scale,
    double? scaleX,
    double? scaleY,
    this.origin,
    this.alignment = Alignment.center,
    this.transformHitTests = true,
    this.filterQuality,
    this.child,
  }) : transform = Matrix4.diagonal3Values(
         scale ?? scaleX ?? 1,
         scale ?? scaleY ?? 1,
         1,
       );
  Transform.flip({
    super.key,
    bool flipX = false,
    bool flipY = false,
    this.origin,
    this.transformHitTests = true,
    this.filterQuality,
    this.child,
  }) : transform = Matrix4.diagonal3Values(flipX ? -1 : 1, flipY ? -1 : 1, 1),
       alignment = Alignment.center;
  final Matrix4 transform;
  final Offset? origin;
  final AlignmentGeometry? alignment;
  final bool transformHitTests;
  final FilterQuality? filterQuality;
  final Widget? child;
  @override
  _DomLayout get _layout => _DomLayout.grid;
  @override
  void _render(_DomBuilder out) {
    final m = transform.storage;
    for (final value in m) {
      if (!value.isFinite) throw ArgumentError('Transforms must be finite.');
    }
    final a = alignment?.resolve(TextDirection.ltr);
    final x = a == null ? '0%' : '${cssNumber((a.x + 1) * 50)}%';
    final y = a == null ? '0%' : '${cssNumber((a.y + 1) * 50)}%';
    final o = origin ?? Offset.zero;
    out.css(
      'display:grid;grid-template-columns:minmax(0,1fr);transform-origin:calc($x + ${cssNumber(o.dx)}px) calc($y + ${cssNumber(o.dy)}px);transform:matrix3d(${m.map(cssNumber).join(',')});',
    );
    if (child != null) out.child(child!);
  }
}

// ---------------------------------------------------------------------------
// Explicit transitions.

abstract class AnimatedWidget extends StatefulWidget {
  const AnimatedWidget({super.key, required this.listenable});
  final Listenable listenable;
  Widget build(BuildContext context);
  @override
  State<AnimatedWidget> createState() => _AnimatedWidgetState();
}

class _AnimatedWidgetState extends State<AnimatedWidget> {
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_changed);
  }

  @override
  void didUpdateWidget(AnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.listenable, widget.listenable)) {
      oldWidget.listenable.removeListener(_changed);
      widget.listenable.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.build(context);
}

class FadeTransition extends AnimatedWidget {
  const FadeTransition({
    super.key,
    required Animation<double> opacity,
    this.child,
  }) : super(listenable: opacity);
  Animation<double> get opacity => listenable as Animation<double>;
  final Widget? child;
  @override
  Widget build(BuildContext context) =>
      Opacity(opacity: opacity.value.clamp(0.0, 1.0), child: child);
}

class ScaleTransition extends AnimatedWidget {
  const ScaleTransition({
    super.key,
    required Animation<double> scale,
    this.alignment = Alignment.center,
    this.child,
  }) : super(listenable: scale);
  Animation<double> get scale => listenable as Animation<double>;
  final Alignment alignment;
  final Widget? child;
  @override
  Widget build(BuildContext context) =>
      Transform.scale(scale: scale.value, alignment: alignment, child: child);
}

class RotationTransition extends AnimatedWidget {
  const RotationTransition({
    super.key,
    required Animation<double> turns,
    this.alignment = Alignment.center,
    this.child,
  }) : super(listenable: turns);
  Animation<double> get turns => listenable as Animation<double>;
  final Alignment alignment;
  final Widget? child;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: turns.value * math.pi * 2,
    alignment: alignment,
    child: child,
  );
}

/// Offsets are fractions of the child's size, as in Flutter.
class SlideTransition extends AnimatedWidget {
  const SlideTransition({
    super.key,
    required Animation<Offset> position,
    this.transformHitTests = true,
    this.child,
  }) : super(listenable: position);
  Animation<Offset> get position => listenable as Animation<Offset>;
  final bool transformHitTests;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final offset = position.value;
    return _Box(
      css:
          'display:grid;grid-template-columns:minmax(0,1fr);transform:translate(${cssNumber(offset.dx * 100)}%,${cssNumber(offset.dy * 100)}%);',
      layout: _DomLayout.grid,
      children: [?child],
    );
  }
}

class SizeTransition extends AnimatedWidget {
  const SizeTransition({
    super.key,
    this.axis = Axis.vertical,
    required Animation<double> sizeFactor,
    this.axisAlignment = 0,
    this.child,
  }) : super(listenable: sizeFactor);
  Animation<double> get sizeFactor => listenable as Animation<double>;
  final Axis axis;
  final double axisAlignment;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final factor = sizeFactor.value.clamp(0.0, 1.0);
    // Clip with a scale transform; layout keeps the full size.
    return ClipRect(
      child: _Box(
        css:
            'display:grid;grid-template-columns:minmax(0,1fr);transform-origin:top left;transform:scale(${axis == Axis.horizontal ? cssNumber(factor) : 1},${axis == Axis.vertical ? cssNumber(factor) : 1});',
        layout: _DomLayout.grid,
        children: [?child],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Implicit animations: each property animates from its current value to the
// new target over [duration] with [curve] whenever the widget changes.

abstract class ImplicitlyAnimatedWidget extends StatefulWidget {
  const ImplicitlyAnimatedWidget({
    super.key,
    this.curve = Curves.linear,
    required this.duration,
    this.onEnd,
  });
  final Curve curve;
  final Duration duration;
  final VoidCallback? onEnd;
}

typedef _Lerp<T> = T Function(T? a, T? b, double t);

class _Property<T> {
  _Property(this._lerp, T target) : _begin = target, _end = target;
  final _Lerp<T> _lerp;
  T _begin, _end;
  T at(double t) => t >= 1 ? _end : _lerp(_begin, _end, t);
  bool retarget(T target, double t) {
    if (target == _end) return false;
    _begin = at(t);
    _end = target;
    return true;
  }
}

abstract class _ImplicitState<W extends ImplicitlyAnimatedWidget>
    extends State<W>
    with SingleTickerProviderStateMixin<W> {
  late final AnimationController _controller = AnimationController(
    duration: widget.duration,
    vsync: this,
  )..addListener(() => setState(() {}));
  late CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );
  double get t => _curved.value;
  final _properties = <_Property<dynamic>>[];

  _Property<T> track<T>(_Lerp<T> lerp, T value) {
    final property = _Property<T>(lerp, value);
    _properties.add(property);
    return property;
  }

  /// Returns whether any property received a new target.
  bool retarget();

  @override
  void initState() {
    super.initState();
    _controller.value = 1;
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onEnd?.call();
    });
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.curve != widget.curve)
      _curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.duration = widget.duration;
    if (retarget()) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

double _lerpNum(double? a, double? b, double t) => lerpDouble(a, b, t)!;

class AnimatedOpacity extends ImplicitlyAnimatedWidget {
  const AnimatedOpacity({
    super.key,
    this.child,
    required this.opacity,
    super.curve,
    required super.duration,
    super.onEnd,
  });
  final Widget? child;
  final double opacity;
  @override
  State<AnimatedOpacity> createState() => _AnimatedOpacityState();
}

class _AnimatedOpacityState extends _ImplicitState<AnimatedOpacity> {
  late final _opacity = track<double>(_lerpNum, widget.opacity);
  @override
  bool retarget() => _opacity.retarget(widget.opacity, t);
  @override
  Widget build(BuildContext context) =>
      Opacity(opacity: _opacity.at(t).clamp(0.0, 1.0), child: widget.child);
}

class AnimatedContainer extends ImplicitlyAnimatedWidget {
  AnimatedContainer({
    super.key,
    this.alignment,
    this.padding,
    Color? color,
    Decoration? decoration,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.clipBehavior = Clip.none,
    this.child,
    super.curve,
    required super.duration,
    super.onEnd,
  }) : decoration =
           decoration ?? (color == null ? null : BoxDecoration(color: color));
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding, margin;
  final Decoration? decoration;
  final double? width, height;
  final BoxConstraints? constraints;
  final Matrix4? transform;
  final Clip clipBehavior;
  final Widget? child;
  @override
  State<AnimatedContainer> createState() => _AnimatedContainerState();
}

class _AnimatedContainerState extends _ImplicitState<AnimatedContainer> {
  late final _alignment = track<AlignmentGeometry?>(
    lerpAlignment,
    widget.alignment,
  );
  late final _padding = track<EdgeInsetsGeometry?>(
    lerpEdgeInsets,
    widget.padding,
  );
  late final _margin = track<EdgeInsetsGeometry?>(
    lerpEdgeInsets,
    widget.margin,
  );
  late final _decoration = track<Decoration?>(
    lerpDecoration,
    widget.decoration,
  );
  late final _width = track<double?>(lerpDouble, widget.width);
  late final _height = track<double?>(lerpDouble, widget.height);
  @override
  bool retarget() {
    var changed = false;
    changed |= _alignment.retarget(widget.alignment, t);
    changed |= _padding.retarget(widget.padding, t);
    changed |= _margin.retarget(widget.margin, t);
    changed |= _decoration.retarget(widget.decoration, t);
    changed |= _width.retarget(widget.width, t);
    changed |= _height.retarget(widget.height, t);
    return changed;
  }

  @override
  Widget build(BuildContext context) {
    Widget result = Container(
      alignment: _alignment.at(t),
      padding: _padding.at(t),
      margin: _margin.at(t),
      decoration: _decoration.at(t),
      width: _width.at(t),
      height: _height.at(t),
      constraints: widget.constraints,
      clipBehavior: widget.clipBehavior,
      child: widget.child,
    );
    if (widget.transform != null)
      result = Transform(transform: widget.transform!, child: result);
    return result;
  }
}

class AnimatedPadding extends ImplicitlyAnimatedWidget {
  const AnimatedPadding({
    super.key,
    required this.padding,
    this.child,
    super.curve,
    required super.duration,
    super.onEnd,
  });
  final EdgeInsetsGeometry padding;
  final Widget? child;
  @override
  State<AnimatedPadding> createState() => _AnimatedPaddingState();
}

class _AnimatedPaddingState extends _ImplicitState<AnimatedPadding> {
  late final _padding = track<EdgeInsetsGeometry?>(
    lerpEdgeInsets,
    widget.padding,
  );
  @override
  bool retarget() => _padding.retarget(widget.padding, t);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: _padding.at(t)!, child: widget.child);
}

class AnimatedAlign extends ImplicitlyAnimatedWidget {
  const AnimatedAlign({
    super.key,
    required this.alignment,
    this.child,
    this.widthFactor,
    this.heightFactor,
    super.curve,
    required super.duration,
    super.onEnd,
  });
  final AlignmentGeometry alignment;
  final double? widthFactor, heightFactor;
  final Widget? child;
  @override
  State<AnimatedAlign> createState() => _AnimatedAlignState();
}

class _AnimatedAlignState extends _ImplicitState<AnimatedAlign> {
  late final _alignment = track<AlignmentGeometry?>(
    lerpAlignment,
    widget.alignment,
  );
  @override
  bool retarget() => _alignment.retarget(widget.alignment, t);
  @override
  Widget build(BuildContext context) => Align(
    alignment: _alignment.at(t)!,
    widthFactor: widget.widthFactor,
    heightFactor: widget.heightFactor,
    child: widget.child,
  );
}

class AnimatedScale extends ImplicitlyAnimatedWidget {
  const AnimatedScale({
    super.key,
    this.child,
    required this.scale,
    this.alignment = Alignment.center,
    super.curve,
    required super.duration,
    super.onEnd,
  });
  final Widget? child;
  final double scale;
  final Alignment alignment;
  @override
  State<AnimatedScale> createState() => _AnimatedScaleState();
}

class _AnimatedScaleState extends _ImplicitState<AnimatedScale> {
  late final _scale = track<double>(_lerpNum, widget.scale);
  @override
  bool retarget() => _scale.retarget(widget.scale, t);
  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: _scale.at(t),
    alignment: widget.alignment,
    child: widget.child,
  );
}

class AnimatedRotation extends ImplicitlyAnimatedWidget {
  const AnimatedRotation({
    super.key,
    this.child,
    required this.turns,
    this.alignment = Alignment.center,
    super.curve,
    required super.duration,
    super.onEnd,
  });
  final Widget? child;
  final double turns;
  final Alignment alignment;
  @override
  State<AnimatedRotation> createState() => _AnimatedRotationState();
}

class _AnimatedRotationState extends _ImplicitState<AnimatedRotation> {
  late final _turns = track<double>(_lerpNum, widget.turns);
  @override
  bool retarget() => _turns.retarget(widget.turns, t);
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: _turns.at(t) * math.pi * 2,
    alignment: widget.alignment,
    child: widget.child,
  );
}

class AnimatedSlide extends ImplicitlyAnimatedWidget {
  const AnimatedSlide({
    super.key,
    this.child,
    required this.offset,
    super.curve,
    required super.duration,
    super.onEnd,
  });
  final Widget? child;
  final Offset offset;
  @override
  State<AnimatedSlide> createState() => _AnimatedSlideState();
}

class _AnimatedSlideState extends _ImplicitState<AnimatedSlide> {
  late final _offset = track<Offset>(
    (a, b, t) => Offset.lerp(a, b, t)!,
    widget.offset,
  );
  @override
  bool retarget() => _offset.retarget(widget.offset, t);
  @override
  Widget build(BuildContext context) => SlideTransition(
    position: AlwaysStoppedAnimation(_offset.at(t)),
    child: widget.child,
  );
}

class AnimatedPositioned extends ImplicitlyAnimatedWidget {
  const AnimatedPositioned({
    super.key,
    required this.child,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    super.curve,
    required super.duration,
    super.onEnd,
  });
  final Widget child;
  final double? left, top, right, bottom, width, height;
  @override
  State<AnimatedPositioned> createState() => _AnimatedPositionedState();
}

class _AnimatedPositionedState extends _ImplicitState<AnimatedPositioned> {
  late final _left = track<double?>(lerpDouble, widget.left);
  late final _top = track<double?>(lerpDouble, widget.top);
  late final _right = track<double?>(lerpDouble, widget.right);
  late final _bottom = track<double?>(lerpDouble, widget.bottom);
  late final _width = track<double?>(lerpDouble, widget.width);
  late final _height = track<double?>(lerpDouble, widget.height);
  @override
  bool retarget() {
    var changed = false;
    changed |= _left.retarget(widget.left, t);
    changed |= _top.retarget(widget.top, t);
    changed |= _right.retarget(widget.right, t);
    changed |= _bottom.retarget(widget.bottom, t);
    changed |= _width.retarget(widget.width, t);
    changed |= _height.retarget(widget.height, t);
    return changed;
  }

  @override
  Widget build(BuildContext context) => Positioned(
    left: _left.at(t),
    top: _top.at(t),
    right: _right.at(t),
    bottom: _bottom.at(t),
    width: _width.at(t),
    height: _height.at(t),
    child: widget.child,
  );
}

class AnimatedDefaultTextStyle extends ImplicitlyAnimatedWidget {
  const AnimatedDefaultTextStyle({
    super.key,
    required this.child,
    required this.style,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    super.curve,
    required super.duration,
    super.onEnd,
  });
  final Widget child;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  @override
  State<AnimatedDefaultTextStyle> createState() =>
      _AnimatedDefaultTextStyleState();
}

class _AnimatedDefaultTextStyleState
    extends _ImplicitState<AnimatedDefaultTextStyle> {
  late final _style = track<TextStyle?>(lerpTextStyle, widget.style);
  @override
  bool retarget() => _style.retarget(widget.style, t);
  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: _style.at(t)!,
    textAlign: widget.textAlign,
    maxLines: widget.maxLines,
    overflow: widget.overflow,
    child: widget.child,
  );
}

/// Layout changes take effect immediately; no size interpolation.
class AnimatedSize extends StatelessWidget {
  const AnimatedSize({
    super.key,
    this.child,
    this.alignment = Alignment.center,
    this.curve = Curves.linear,
    required this.duration,
    this.reverseDuration,
    this.clipBehavior = Clip.hardEdge,
    this.onEnd,
  });
  final Widget? child;
  final AlignmentGeometry alignment;
  final Curve curve;
  final Duration duration;
  final Duration? reverseDuration;
  final Clip clipBehavior;
  final VoidCallback? onEnd;
  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}

class TweenAnimationBuilder<T extends Object?> extends StatefulWidget {
  const TweenAnimationBuilder({
    super.key,
    required this.tween,
    required this.duration,
    this.curve = Curves.linear,
    required this.builder,
    this.onEnd,
    this.child,
  });
  final Tween<T> tween;
  final Duration duration;
  final Curve curve;
  final ValueWidgetBuilder<T> builder;
  final VoidCallback? onEnd;
  final Widget? child;
  @override
  State<TweenAnimationBuilder<T>> createState() =>
      _TweenAnimationBuilderState<T>();
}

class _TweenAnimationBuilderState<T extends Object?>
    extends State<TweenAnimationBuilder<T>>
    with SingleTickerProviderStateMixin<TweenAnimationBuilder<T>> {
  late final AnimationController _controller = AnimationController(
    duration: widget.duration,
    vsync: this,
  );
  late Tween<T> _current;

  @override
  void initState() {
    super.initState();
    _current = widget.tween;
    _controller
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onEnd?.call();
      });
    if (_current.begin != _current.end) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  T get _value => _current.transform(widget.curve.transform(_controller.value));

  @override
  void didUpdateWidget(TweenAnimationBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.tween.end != _current.end) {
      final from = _value;
      _current = widget.tween..begin = from;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _value, widget.child);
}

typedef AnimatedSwitcherTransitionBuilder =
    Widget Function(Widget child, Animation<double> animation);

/// Cross-fades from the previous child to the new one, keeping the outgoing
/// child mounted until its transition finishes.
class AnimatedSwitcher extends StatefulWidget {
  const AnimatedSwitcher({
    super.key,
    this.child,
    required this.duration,
    this.reverseDuration,
    this.switchInCurve = Curves.linear,
    this.switchOutCurve = Curves.linear,
    this.transitionBuilder = defaultTransitionBuilder,
  });
  final Widget? child;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve switchInCurve, switchOutCurve;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  static Widget defaultTransitionBuilder(
    Widget child,
    Animation<double> animation,
  ) => FadeTransition(opacity: animation, child: child);
  @override
  State<AnimatedSwitcher> createState() => _AnimatedSwitcherState();
}

class _SwitcherEntry {
  _SwitcherEntry(this.child, this.controller, this.key);
  final Widget child;
  final AnimationController controller;
  final Key key;
}

class _AnimatedSwitcherState extends State<AnimatedSwitcher>
    with TickerProviderStateMixin<AnimatedSwitcher> {
  final _entries = <_SwitcherEntry>[];
  var _serial = 0;

  _SwitcherEntry _add(Widget child, {required bool animate}) {
    final controller = AnimationController(
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
      vsync: this,
    );
    final entry = _SwitcherEntry(child, controller, ValueKey(_serial++));
    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        // Entries are replaced when their widget updates, so match by the
        // controller rather than by the entry captured here.
        setState(
          () =>
              _entries.removeWhere((e) => identical(e.controller, controller)),
        );
        controller.dispose();
      }
    });
    if (animate) {
      controller.forward();
    } else {
      controller.value = 1;
    }
    _entries.add(entry);
    return entry;
  }

  @override
  void initState() {
    super.initState();
    if (widget.child != null) _add(widget.child!, animate: false);
  }

  @override
  void didUpdateWidget(AnimatedSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _entries.isEmpty ? null : _entries.last;
    final next = widget.child;
    final same =
        current != null &&
        next != null &&
        Widget.canUpdate(current.child, next);
    if (same) {
      _entries[_entries.length - 1] = _SwitcherEntry(
        next,
        current.controller,
        current.key,
      );
      return;
    }
    current?.controller.reverse();
    if (next != null) _add(next, animate: true);
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Box(
    css: 'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;',
    layout: _DomLayout.grid,
    children: [
      for (final entry in _entries)
        _StackSlot(
          key: entry.key,
          alignment: Alignment.center,
          expand: true,
          child: widget.transitionBuilder(
            entry.child,
            CurvedAnimation(
              parent: entry.controller,
              curve: widget.switchInCurve,
              reverseCurve: widget.switchOutCurve,
            ),
          ),
        ),
    ],
  );
}

enum CrossFadeState { showFirst, showSecond }

class AnimatedCrossFade extends StatelessWidget {
  const AnimatedCrossFade({
    super.key,
    required this.firstChild,
    required this.secondChild,
    required this.crossFadeState,
    required this.duration,
    this.reverseDuration,
    this.firstCurve = Curves.linear,
    this.secondCurve = Curves.linear,
    this.sizeCurve = Curves.linear,
    this.alignment = Alignment.topCenter,
  });
  final Widget firstChild, secondChild;
  final CrossFadeState crossFadeState;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve firstCurve, secondCurve, sizeCurve;
  final AlignmentGeometry alignment;
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: duration,
    reverseDuration: reverseDuration,
    child: KeyedSubtree(
      key: ValueKey(crossFadeState),
      child: crossFadeState == CrossFadeState.showFirst
          ? firstChild
          : secondChild,
    ),
  );
}

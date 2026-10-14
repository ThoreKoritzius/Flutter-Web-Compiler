// ignore_for_file: implementation_imports, invalid_use_of_internal_member, deprecated_member_use, subtype_of_sealed_class

/// flutter_riverpod's `ChangeNotifierProvider` on the official Riverpod 2.6.1
/// engine, following flutter_riverpod 2.6.1: the provider exposes the
/// notifier itself, and every `notifyListeners` notifies its listeners.
library;

import 'package:riverpod/src/internals.dart';

import 'foundation_dom.dart';

abstract class ChangeNotifierProviderRef<NotifierT extends ChangeNotifier?>
    implements Ref<NotifierT> {
  NotifierT get notifier;
}

abstract class AutoDisposeChangeNotifierProviderRef<
  NotifierT extends ChangeNotifier?
>
    extends ChangeNotifierProviderRef<NotifierT>
    implements AutoDisposeRef<NotifierT> {}

abstract class _ChangeNotifierProviderBase<NotifierT extends ChangeNotifier?>
    extends ProviderBase<NotifierT> {
  const _ChangeNotifierProviderBase({
    required super.name,
    required super.from,
    required super.argument,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
  });

  /// The notifier, without rebuilding when it notifies.
  ProviderListenable<NotifierT> get notifier;

  NotifierT _create(covariant ChangeNotifierProviderElement<NotifierT> ref);
}

ProviderElementProxy<NotifierT, NotifierT>
_notifier<NotifierT extends ChangeNotifier?>(
  _ChangeNotifierProviderBase<NotifierT> that,
) => ProviderElementProxy<NotifierT, NotifierT>(
  that,
  (element) =>
      (element as ChangeNotifierProviderElement<NotifierT>)._notifierNotifier,
);

class ChangeNotifierProvider<NotifierT extends ChangeNotifier?>
    extends _ChangeNotifierProviderBase<NotifierT>
    with AlwaysAliveProviderBase<NotifierT> {
  ChangeNotifierProvider(
    this._createFn, {
    super.name,
    super.dependencies,
    super.from,
    super.argument,
    super.debugGetCreateSourceHash,
  }) : super(
         allTransitiveDependencies: computeAllTransitiveDependencies(
           dependencies,
         ),
       );

  ChangeNotifierProvider.internal(
    this._createFn, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    super.from,
    super.argument,
  });

  static const autoDispose = AutoDisposeChangeNotifierProviderBuilder();
  static const family = ChangeNotifierProviderFamilyBuilder();

  final NotifierT Function(ChangeNotifierProviderRef<NotifierT> ref) _createFn;

  @override
  NotifierT _create(ChangeNotifierProviderElement<NotifierT> ref) =>
      _createFn(ref);

  @override
  ChangeNotifierProviderElement<NotifierT> createElement() =>
      ChangeNotifierProviderElement<NotifierT>._(this);

  @override
  late final AlwaysAliveRefreshable<NotifierT> notifier = _notifier<NotifierT>(
    this,
  );

  Override overrideWith(
    Create<NotifierT, ChangeNotifierProviderRef<NotifierT>> create,
  ) => ProviderOverride(
    origin: this,
    override: ChangeNotifierProvider<NotifierT>.internal(
      create,
      from: from,
      argument: argument,
      dependencies: null,
      allTransitiveDependencies: null,
      debugGetCreateSourceHash: null,
      name: null,
    ),
  );
}

class ChangeNotifierProviderElement<NotifierT extends ChangeNotifier?>
    extends ProviderElementBase<NotifierT>
    implements ChangeNotifierProviderRef<NotifierT> {
  ChangeNotifierProviderElement._(
    _ChangeNotifierProviderBase<NotifierT> super._provider,
  );

  @override
  NotifierT get notifier => _notifierNotifier.value;
  final _notifierNotifier = ProxyElementValueNotifier<NotifierT>();

  void Function()? _removeListener;

  @override
  void create({required bool didChangeDependency}) {
    final provider = this.provider as _ChangeNotifierProviderBase<NotifierT>;
    final notifier = _notifierNotifier.result = Result.guard(
      () => provider._create(this),
    );
    final value = notifier.requireState;
    setState(value);
    if (value != null) {
      void listener() => setState(value);
      value.addListener(listener);
      _removeListener = () => value.removeListener(listener);
    }
  }

  // The same notifier instance changed: always notify.
  @override
  bool updateShouldNotify(NotifierT previous, NotifierT next) => true;

  @override
  void runOnDispose() {
    super.runOnDispose();
    _removeListener?.call();
    _removeListener = null;
    final notifier = _notifierNotifier.result?.stateOrNull;
    if (notifier != null) runGuarded(notifier.dispose);
    _notifierNotifier.result = null;
  }

  @override
  void visitChildren({
    required void Function(ProviderElementBase element) elementVisitor,
    required void Function(ProxyElementValueNotifier element) notifierVisitor,
  }) {
    super.visitChildren(
      elementVisitor: elementVisitor,
      notifierVisitor: notifierVisitor,
    );
    notifierVisitor(_notifierNotifier);
  }
}

class AutoDisposeChangeNotifierProvider<NotifierT extends ChangeNotifier?>
    extends _ChangeNotifierProviderBase<NotifierT> {
  AutoDisposeChangeNotifierProvider(
    this._createFn, {
    super.name,
    super.dependencies,
    super.from,
    super.argument,
    super.debugGetCreateSourceHash,
  }) : super(
         allTransitiveDependencies: computeAllTransitiveDependencies(
           dependencies,
         ),
       );

  AutoDisposeChangeNotifierProvider.internal(
    this._createFn, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    super.from,
    super.argument,
  });

  static const family = AutoDisposeChangeNotifierProviderFamily.new;

  final NotifierT Function(AutoDisposeChangeNotifierProviderRef<NotifierT> ref)
  _createFn;

  @override
  NotifierT _create(AutoDisposeChangeNotifierProviderElement<NotifierT> ref) =>
      _createFn(ref);

  @override
  AutoDisposeChangeNotifierProviderElement<NotifierT> createElement() =>
      AutoDisposeChangeNotifierProviderElement<NotifierT>._(this);

  @override
  late final Refreshable<NotifierT> notifier = _notifier<NotifierT>(this);

  Override overrideWith(
    Create<NotifierT, AutoDisposeChangeNotifierProviderRef<NotifierT>> create,
  ) => ProviderOverride(
    origin: this,
    override: AutoDisposeChangeNotifierProvider<NotifierT>.internal(
      create,
      from: from,
      argument: argument,
      dependencies: null,
      allTransitiveDependencies: null,
      debugGetCreateSourceHash: null,
      name: null,
    ),
  );
}

class AutoDisposeChangeNotifierProviderElement<
  NotifierT extends ChangeNotifier?
>
    extends ChangeNotifierProviderElement<NotifierT>
    with AutoDisposeProviderElementMixin<NotifierT>
    implements AutoDisposeChangeNotifierProviderRef<NotifierT> {
  AutoDisposeChangeNotifierProviderElement._(
    AutoDisposeChangeNotifierProvider<NotifierT> super.provider,
  ) : super._();
}

class ChangeNotifierProviderFamily<NotifierT extends ChangeNotifier?, Arg>
    extends
        FamilyBase<
          ChangeNotifierProviderRef<NotifierT>,
          NotifierT,
          Arg,
          NotifierT,
          ChangeNotifierProvider<NotifierT>
        > {
  ChangeNotifierProviderFamily(
    super._createFn, {
    super.name,
    super.dependencies,
  }) : super(
         providerFactory: ChangeNotifierProvider.internal,
         allTransitiveDependencies: computeAllTransitiveDependencies(
           dependencies,
         ),
         debugGetCreateSourceHash: null,
       );
}

class AutoDisposeChangeNotifierProviderFamily<
  NotifierT extends ChangeNotifier?,
  Arg
>
    extends
        AutoDisposeFamilyBase<
          AutoDisposeChangeNotifierProviderRef<NotifierT>,
          NotifierT,
          Arg,
          NotifierT,
          AutoDisposeChangeNotifierProvider<NotifierT>
        > {
  AutoDisposeChangeNotifierProviderFamily(
    super._createFn, {
    super.name,
    super.dependencies,
  }) : super(
         providerFactory: AutoDisposeChangeNotifierProvider.internal,
         allTransitiveDependencies: computeAllTransitiveDependencies(
           dependencies,
         ),
         debugGetCreateSourceHash: null,
       );
}

class AutoDisposeChangeNotifierProviderBuilder {
  const AutoDisposeChangeNotifierProviderBuilder();

  AutoDisposeChangeNotifierProvider<NotifierT>
  call<NotifierT extends ChangeNotifier?>(
    NotifierT Function(AutoDisposeChangeNotifierProviderRef<NotifierT> ref)
    create, {
    String? name,
    Iterable<ProviderOrFamily>? dependencies,
  }) => AutoDisposeChangeNotifierProvider<NotifierT>(
    create,
    name: name,
    dependencies: dependencies,
  );

  AutoDisposeChangeNotifierProviderFamilyBuilder get family =>
      const AutoDisposeChangeNotifierProviderFamilyBuilder();
}

class ChangeNotifierProviderFamilyBuilder {
  const ChangeNotifierProviderFamilyBuilder();

  ChangeNotifierProviderFamily<NotifierT, Arg>
  call<NotifierT extends ChangeNotifier?, Arg>(
    NotifierT Function(ChangeNotifierProviderRef<NotifierT> ref, Arg arg)
    create, {
    String? name,
    Iterable<ProviderOrFamily>? dependencies,
  }) => ChangeNotifierProviderFamily<NotifierT, Arg>(
    create,
    name: name,
    dependencies: dependencies,
  );

  AutoDisposeChangeNotifierProviderFamilyBuilder get autoDispose =>
      const AutoDisposeChangeNotifierProviderFamilyBuilder();
}

class AutoDisposeChangeNotifierProviderFamilyBuilder {
  const AutoDisposeChangeNotifierProviderFamilyBuilder();

  AutoDisposeChangeNotifierProviderFamily<NotifierT, Arg>
  call<NotifierT extends ChangeNotifier?, Arg>(
    NotifierT Function(
      AutoDisposeChangeNotifierProviderRef<NotifierT> ref,
      Arg arg,
    )
    create, {
    String? name,
    Iterable<ProviderOrFamily>? dependencies,
  }) => AutoDisposeChangeNotifierProviderFamily<NotifierT, Arg>(
    create,
    name: name,
    dependencies: dependencies,
  );
}

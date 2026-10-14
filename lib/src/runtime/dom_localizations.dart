part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Localizations. Delegates load per locale; synchronous delegates (the usual
// case, via SynchronousFuture) build without an empty first frame.

abstract class LocalizationsDelegate<T> {
  const LocalizationsDelegate();
  bool isSupported(Locale locale);
  Future<T> load(Locale locale);
  bool shouldReload(covariant LocalizationsDelegate<T> old);
  Type get type => T;
}

typedef LocaleResolutionCallback =
    Locale? Function(Locale? locale, Iterable<Locale> supportedLocales);
typedef LocaleListResolutionCallback =
    Locale? Function(List<Locale>? locales, Iterable<Locale> supportedLocales);

class _LocalizationsScope extends InheritedWidget {
  const _LocalizationsScope({
    required this.locale,
    required this.resources,
    required this.delegates,
    required super.child,
  });
  final Locale locale;
  final Map<Type, Object?> resources;
  final List<LocalizationsDelegate<dynamic>> delegates;
  @override
  bool updateShouldNotify(_LocalizationsScope oldWidget) =>
      oldWidget.locale != locale || !identical(oldWidget.resources, resources);
}

class Localizations extends StatefulWidget {
  const Localizations({
    super.key,
    required this.locale,
    required this.delegates,
    this.child,
    this.isApplicationLevel = false,
  });

  /// Adds [delegates] (and optionally a new [locale]) to the enclosing
  /// localizations for [child].
  static Widget override({
    Key? key,
    required BuildContext context,
    Locale? locale,
    List<LocalizationsDelegate<dynamic>>? delegates,
    Widget? child,
  }) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_LocalizationsScope>();
    return Localizations(
      key: key,
      locale: locale ?? scope?.locale ?? const Locale('en', 'US'),
      delegates: [...?delegates, ...?scope?.delegates],
      child: child,
    );
  }

  final Locale locale;
  final List<LocalizationsDelegate<dynamic>> delegates;
  final Widget? child;
  final bool isApplicationLevel;

  static Locale localeOf(BuildContext context) =>
      maybeLocaleOf(context) ??
      (throw FlutterError('No Localizations ancestor in this context.'));

  static Locale? maybeLocaleOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LocalizationsScope>()?.locale;

  static T? of<T>(BuildContext context, Type type) =>
      context
              .dependOnInheritedWidgetOfExactType<_LocalizationsScope>()
              ?.resources[type]
          as T?;

  // `@override` would resolve to the static [override] member here.
  State<Localizations> createState() => _LocalizationsState();
}

class _LocalizationsState extends State<Localizations> {
  Map<Type, Object?>? _resources;
  Locale? _loadedLocale;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(Localizations oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reload =
        oldWidget.locale != widget.locale ||
        oldWidget.delegates.length != widget.delegates.length ||
        [
          for (var i = 0; i < widget.delegates.length; i++)
            widget.delegates[i].runtimeType !=
                    oldWidget.delegates[i].runtimeType ||
                widget.delegates[i].shouldReload(oldWidget.delegates[i]),
        ].any((changed) => changed);
    if (reload) _load();
  }

  void _load() {
    final generation = ++_generation;
    final locale = widget.locale;
    final types = <Type>{};
    final pending = <Type, Future<dynamic>>{};
    for (final delegate in widget.delegates) {
      // The first delegate for a type wins, as in Flutter.
      if (!types.add(delegate.type) || !delegate.isSupported(locale)) continue;
      pending[delegate.type] = delegate.load(locale);
    }
    final loaded = <Type, Object?>{};
    var synchronous = true;
    for (final entry in pending.entries) {
      var done = false;
      entry.value.then<void>((value) {
        loaded[entry.key] = value;
        done = true;
      });
      if (!done) synchronous = false;
    }
    if (synchronous) {
      _resources = loaded;
      _loadedLocale = locale;
      return;
    }
    Future.wait(
      pending.entries.map(
        (entry) => entry.value.then((value) => MapEntry(entry.key, value)),
      ),
    ).then((entries) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _resources = Map.fromEntries(entries);
        _loadedLocale = locale;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final resources = _resources;
    if (resources == null) return const SizedBox.shrink();
    return _LocalizationsScope(
      locale: _loadedLocale!,
      resources: resources,
      delegates: widget.delegates,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}

/// Flutter's default resolution: exact match, then language and script,
/// language and country, language, country, else the first supported.
Locale basicLocaleListResolution(
  List<Locale>? preferredLocales,
  Iterable<Locale> supportedLocales,
) {
  final supported = supportedLocales.toList();
  if (supported.isEmpty) return const Locale('en', 'US');
  if (preferredLocales == null || preferredLocales.isEmpty)
    return supported.first;
  for (final preferred in preferredLocales) {
    if (supported.contains(preferred)) return preferred;
  }
  for (final preferred in preferredLocales) {
    for (final locale in supported) {
      if (locale.languageCode == preferred.languageCode &&
          locale.scriptCode == preferred.scriptCode &&
          preferred.scriptCode != null)
        return locale;
    }
  }
  for (final preferred in preferredLocales) {
    for (final locale in supported) {
      if (locale.languageCode == preferred.languageCode &&
          locale.countryCode == preferred.countryCode &&
          preferred.countryCode != null)
        return locale;
    }
  }
  for (final preferred in preferredLocales) {
    for (final locale in supported) {
      if (locale.languageCode == preferred.languageCode) return locale;
    }
  }
  for (final preferred in preferredLocales) {
    for (final locale in supported) {
      if (preferred.countryCode != null &&
          locale.countryCode == preferred.countryCode)
        return locale;
    }
  }
  return supported.first;
}

/// The browser's preferred locales (navigator.languages).
List<Locale> _browserLocales() {
  final window = _window as JSObject;
  if (!window.has('navigator')) return const [Locale('en', 'US')];
  final navigator = window.getProperty<JSObject>('navigator'.toJS);
  final languages = navigator.getProperty<JSArray<JSString>?>('languages'.toJS);
  final tags = languages == null
      ? [navigator.getProperty<JSString?>('language'.toJS)?.toDart ?? 'en-US']
      : [for (final tag in languages.toDart) tag.toDart];
  return [for (final tag in tags) Locale.parse(tag)];
}

abstract class WidgetsLocalizations {
  const WidgetsLocalizations();
  TextDirection get textDirection;
  String get reorderItemToStart => 'Move to the start';
  String get reorderItemToEnd => 'Move to the end';
  static WidgetsLocalizations of(BuildContext context) =>
      Localizations.of<WidgetsLocalizations>(context, WidgetsLocalizations) ??
      const DefaultWidgetsLocalizations();
}

class DefaultWidgetsLocalizations extends WidgetsLocalizations {
  const DefaultWidgetsLocalizations();
  @override
  TextDirection get textDirection => TextDirection.ltr;
  static const LocalizationsDelegate<WidgetsLocalizations> delegate =
      _DefaultWidgetsLocalizationsDelegate();
  static Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultWidgetsLocalizations());
}

class _DefaultWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _DefaultWidgetsLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      DefaultWidgetsLocalizations.load(locale);
  @override
  bool shouldReload(_DefaultWidgetsLocalizationsDelegate old) => false;
}

/// Common Material strings and formats. Only the English defaults are
/// provided; locale-specific Material strings are not bundled.
abstract class MaterialLocalizations {
  String get okButtonLabel;
  String get cancelButtonLabel;
  String get closeButtonLabel;
  String get closeButtonTooltip;
  String get backButtonTooltip;
  String get openAppDrawerTooltip;
  String get searchFieldLabel;
  String get deleteButtonTooltip;
  String get moreButtonTooltip;
  String get showMenuTooltip;
  String get continueButtonLabel;
  String get copyButtonLabel;
  String get cutButtonLabel;
  String get pasteButtonLabel;
  String get selectAllButtonLabel;
  String get nextPageTooltip;
  String get previousPageTooltip;
  String get firstPageTooltip;
  String get lastPageTooltip;
  String get refreshIndicatorSemanticLabel;
  String get modalBarrierDismissLabel;
  String get dialogLabel;
  String get alertDialogLabel;
  String get viewLicensesButtonLabel;
  String get licensesPageTitle;
  String get datePickerHelpText;
  String get timePickerDialHelpText;
  String formatYear(DateTime date);
  String formatShortDate(DateTime date);
  String formatMediumDate(DateTime date);
  String formatFullDate(DateTime date);
  String formatMonthYear(DateTime date);
  String formatShortMonthDay(DateTime date);
  String formatDecimal(int number);
  String formatCompactDate(DateTime date);
  String tabLabel({required int tabIndex, required int tabCount});
  String pageRowsInfoTitle(
    int firstRow,
    int lastRow,
    int rowCount,
    bool rowCountIsApproximate,
  );
  String remainingTextFieldCharacterCount(int remaining);
  String get scriptCategory => 'English-like';

  static MaterialLocalizations of(BuildContext context) =>
      Localizations.of<MaterialLocalizations>(context, MaterialLocalizations) ??
      const DefaultMaterialLocalizations();
}

class DefaultMaterialLocalizations implements MaterialLocalizations {
  const DefaultMaterialLocalizations();
  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _DefaultMaterialLocalizationsDelegate();
  static Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultMaterialLocalizations());

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  String get okButtonLabel => 'OK';
  @override
  String get cancelButtonLabel => 'Cancel';
  @override
  String get closeButtonLabel => 'Close';
  @override
  String get closeButtonTooltip => 'Close';
  @override
  String get backButtonTooltip => 'Back';
  @override
  String get openAppDrawerTooltip => 'Open navigation menu';
  @override
  String get searchFieldLabel => 'Search';
  @override
  String get deleteButtonTooltip => 'Delete';
  @override
  String get moreButtonTooltip => 'More';
  @override
  String get showMenuTooltip => 'Show menu';
  @override
  String get continueButtonLabel => 'Continue';
  @override
  String get copyButtonLabel => 'Copy';
  @override
  String get cutButtonLabel => 'Cut';
  @override
  String get pasteButtonLabel => 'Paste';
  @override
  String get selectAllButtonLabel => 'Select all';
  @override
  String get nextPageTooltip => 'Next page';
  @override
  String get previousPageTooltip => 'Previous page';
  @override
  String get firstPageTooltip => 'First page';
  @override
  String get lastPageTooltip => 'Last page';
  @override
  String get refreshIndicatorSemanticLabel => 'Refresh';
  @override
  String get modalBarrierDismissLabel => 'Dismiss';
  @override
  String get dialogLabel => 'Dialog';
  @override
  String get alertDialogLabel => 'Alert';
  @override
  String get viewLicensesButtonLabel => 'View licenses';
  @override
  String get licensesPageTitle => 'Licenses';
  @override
  String get datePickerHelpText => 'Select date';
  @override
  String get timePickerDialHelpText => 'Select time';
  @override
  String get scriptCategory => 'English-like';
  @override
  String formatYear(DateTime date) => '${date.year}';
  @override
  String formatShortDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  @override
  String formatMediumDate(DateTime date) =>
      '${_weekdays[date.weekday - 1].substring(0, 3)}, ${_months[date.month - 1].substring(0, 3)} ${date.day}';
  @override
  String formatFullDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}, ${date.year}';
  @override
  String formatMonthYear(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';
  @override
  String formatShortMonthDay(DateTime date) =>
      '${_months[date.month - 1].substring(0, 3)} ${date.day}';
  @override
  String formatCompactDate(DateTime date) => formatShortDate(date);
  @override
  String formatDecimal(int number) {
    final digits = number.abs().toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
      grouped.write(digits[i]);
    }
    return number < 0 ? '-$grouped' : grouped.toString();
  }

  @override
  String tabLabel({required int tabIndex, required int tabCount}) =>
      'Tab $tabIndex of $tabCount';
  @override
  String pageRowsInfoTitle(
    int firstRow,
    int lastRow,
    int rowCount,
    bool rowCountIsApproximate,
  ) => rowCountIsApproximate
      ? '$firstRow–$lastRow of about $rowCount'
      : '$firstRow–$lastRow of $rowCount';
  @override
  String remainingTextFieldCharacterCount(int remaining) => switch (remaining) {
    0 => 'No characters remaining',
    1 => '1 character remaining',
    _ => '$remaining characters remaining',
  };
}

class _DefaultMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _DefaultMaterialLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);
  @override
  bool shouldReload(_DefaultMaterialLocalizationsDelegate old) => false;
}

/// Mirrors the resolved application locale into `<html lang>`.
class _DocumentLanguage extends StatefulWidget {
  const _DocumentLanguage({required this.locale, required this.child});
  final Locale locale;
  final Widget child;
  @override
  State<_DocumentLanguage> createState() => _DocumentLanguageState();
}

class _DocumentLanguageState extends State<_DocumentLanguage> {
  void _apply() {
    final document = _document as JSObject;
    final root = document.getProperty<JSObject?>('documentElement'.toJS);
    root?.setProperty('lang'.toJS, widget.locale.toLanguageTag().toJS);
  }

  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(_DocumentLanguage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale) _apply();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

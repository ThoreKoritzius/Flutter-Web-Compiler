part of 'flutter_dom.dart';

// The flutter_localizations bridge: delegates for every locale that load
// the English Material and Cupertino strings and the widgets text direction.
// Application strings (for example gen_l10n AppLocalizations) are compiled
// from the app itself. Locale-specific Material strings are not bundled.

const _rtlLanguages = {'ar', 'fa', 'he', 'ps', 'ur'};

abstract class GlobalMaterialLocalizations implements MaterialLocalizations {
  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _GlobalMaterialDelegate();
  static const List<LocalizationsDelegate<dynamic>> delegates = [
    delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}

class _GlobalMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _GlobalMaterialDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultMaterialLocalizations());
  @override
  bool shouldReload(_GlobalMaterialDelegate old) => false;
}

class GlobalWidgetsLocalizations extends WidgetsLocalizations {
  GlobalWidgetsLocalizations(this._locale);
  final Locale _locale;
  static const LocalizationsDelegate<WidgetsLocalizations> delegate =
      _GlobalWidgetsDelegate();

  /// Right-to-left locales report rtl; the DOM runtime still lays out
  /// left-to-right.
  @override
  TextDirection get textDirection =>
      _rtlLanguages.contains(_locale.languageCode)
      ? TextDirection.rtl
      : TextDirection.ltr;
}

class _GlobalWidgetsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _GlobalWidgetsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(GlobalWidgetsLocalizations(locale));
  @override
  bool shouldReload(_GlobalWidgetsDelegate old) => false;
}

abstract class CupertinoLocalizations {
  String get alertDialogLabel;
  String get copyButtonLabel;
  String get cutButtonLabel;
  String get pasteButtonLabel;
  String get selectAllButtonLabel;
  String get searchTextFieldPlaceholderLabel;
  static CupertinoLocalizations of(BuildContext context) =>
      Localizations.of<CupertinoLocalizations>(
        context,
        CupertinoLocalizations,
      ) ??
      const DefaultCupertinoLocalizations();
}

class DefaultCupertinoLocalizations implements CupertinoLocalizations {
  const DefaultCupertinoLocalizations();
  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      GlobalCupertinoLocalizations.delegate;
  @override
  String get alertDialogLabel => 'Alert';
  @override
  String get copyButtonLabel => 'Copy';
  @override
  String get cutButtonLabel => 'Cut';
  @override
  String get pasteButtonLabel => 'Paste';
  @override
  String get selectAllButtonLabel => 'Select All';
  @override
  String get searchTextFieldPlaceholderLabel => 'Search';
}

abstract class GlobalCupertinoLocalizations implements CupertinoLocalizations {
  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _GlobalCupertinoDelegate();
  static const List<LocalizationsDelegate<dynamic>> delegates = [
    delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}

class _GlobalCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _GlobalCupertinoDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultCupertinoLocalizations());
  @override
  bool shouldReload(_GlobalCupertinoDelegate old) => false;
}

const kMaterialSupportedLanguages = {
  'af', 'am', 'ar', 'as', 'az', 'be', 'bg', 'bn', 'bs', 'ca', 'cs', 'cy', //
  'da', 'de', 'el', 'en', 'es', 'et', 'eu', 'fa', 'fi', 'fil', 'fr', 'gl',
  'gsw', 'gu', 'he', 'hi', 'hr', 'hu', 'hy', 'id', 'is', 'it', 'ja', 'ka',
  'kk', 'km', 'kn', 'ko', 'ky', 'lo', 'lt', 'lv', 'mk', 'ml', 'mn', 'mr',
  'ms', 'my', 'nb', 'ne', 'nl', 'no', 'or', 'pa', 'pl', 'ps', 'pt', 'ro',
  'ru', 'si', 'sk', 'sl', 'sq', 'sr', 'sv', 'sw', 'ta', 'te', 'th', 'tl',
  'tr', 'uk', 'ur', 'uz', 'vi', 'zh', 'zu',
};

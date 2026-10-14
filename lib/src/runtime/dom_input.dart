part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Focus. Focus follows the browser: DOM focus and blur events update nodes,
// and requests call the native element's focus().

class FocusNode extends ChangeNotifier {
  FocusNode({
    this.debugLabel,
    this.skipTraversal = false,
    this.canRequestFocus = true,
    this.onKeyEvent,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
  });
  final String? debugLabel;

  /// Called for key events while this node or a descendant has focus.
  FocusOnKeyEventCallback? onKeyEvent;
  bool descendantsAreFocusable, descendantsAreTraversable;

  /// Moves focus to the next or previous focusable element in document
  /// order, like Tab and Shift+Tab.
  bool nextFocus() => _moveDomFocus(1);
  bool previousFocus() => _moveDomFocus(-1);
  bool skipTraversal;
  bool canRequestFocus;
  _Node? _node;
  bool _hasFocus = false;
  bool _pending = false;
  bool _autofocused = false;

  bool get hasFocus => _hasFocus;
  bool get hasPrimaryFocus => _hasFocus;

  void requestFocus([FocusNode? node]) {
    if (node != null) return node.requestFocus();
    if (!canRequestFocus) return;
    final target = _node;
    if (target == null) {
      _pending = true;
    } else {
      target.focus();
    }
  }

  void unfocus() {
    _pending = false;
    _node?.blur();
  }

  void _attach(_Node node) {
    if (identical(_node, node)) return;
    _node = node;
    if (_pending) {
      _pending = false;
      scheduleMicrotask(() => _node?.focus());
    }
  }

  void _detach(_Node node) {
    if (!identical(_node, node)) return;
    _node = null;
    _setFocus(false);
  }

  void _setFocus(bool value) {
    if (_hasFocus == value) return;
    _hasFocus = value;
    if (value) FocusManager.instance._primary = this;
    if (!value && identical(FocusManager.instance._primary, this))
      FocusManager.instance._primary = null;
    notifyListeners();
  }
}

class FocusScopeNode extends FocusNode {
  FocusScopeNode({super.debugLabel});
  @override
  void unfocus() => FocusManager.instance.primaryFocus?.unfocus();
  @override
  void requestFocus([FocusNode? node]) => node?.requestFocus();
}

class FocusManager {
  FocusManager._();
  static final instance = FocusManager._();
  FocusNode? _primary;
  FocusNode? get primaryFocus => _primary;
  final rootScope = FocusScopeNode(debugLabel: 'root');
}

class FocusScope {
  static FocusScopeNode of(BuildContext context) =>
      FocusManager.instance.rootScope;
}

// ---------------------------------------------------------------------------
// Controllers.

class TextEditingController extends ValueNotifier<TextEditingValue> {
  TextEditingController({String? text})
    : super(
        text == null
            ? TextEditingValue.empty
            : TextEditingValue(
                text: text,
                selection: TextSelection.collapsed(offset: text.length),
              ),
      );
  TextEditingController.fromValue(TextEditingValue? value)
    : super(value ?? TextEditingValue.empty);
  String get text => value.text;
  set text(String newText) => value = value.copyWith(
    text: newText,
    selection: const TextSelection.collapsed(offset: -1),
    composing: TextRange.empty,
  );
  TextSelection get selection => value.selection;
  set selection(TextSelection newSelection) =>
      value = value.copyWith(selection: newSelection);
  void clear() => value = const TextEditingValue(
    selection: TextSelection.collapsed(offset: 0),
  );
}

// ---------------------------------------------------------------------------
// Input decoration.

abstract class InputBorder {
  const InputBorder({this.borderSide = const BorderSide()});
  final BorderSide borderSide;
  static const InputBorder none = _NoInputBorder();
  String _css(Color color, double width);
}

class _NoInputBorder extends InputBorder {
  const _NoInputBorder() : super(borderSide: BorderSide.none);
  @override
  String _css(Color color, double width) => 'border:0;';
}

class OutlineInputBorder extends InputBorder {
  const OutlineInputBorder({
    super.borderSide,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.gapPadding = 4,
  });
  final BorderRadius borderRadius;
  final double gapPadding;
  @override
  String _css(Color color, double width) =>
      'border:${px(width)} solid ${colorCss(color)};${borderRadiusCss(borderRadius)}';
}

class UnderlineInputBorder extends InputBorder {
  const UnderlineInputBorder({
    super.borderSide,
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(4),
    ),
  });
  final BorderRadius borderRadius;
  @override
  String _css(Color color, double width) =>
      'border:0;border-bottom:${px(width)} solid ${colorCss(color)};${borderRadiusCss(borderRadius)}';
}

enum FloatingLabelBehavior { never, auto, always }

class InputDecoration {
  const InputDecoration({
    this.icon,
    this.iconColor,
    this.label,
    this.labelText,
    this.labelStyle,
    this.floatingLabelStyle,
    this.helper,
    this.helperText,
    this.helperStyle,
    this.helperMaxLines,
    this.hintText,
    this.hint,
    this.hintStyle,
    this.hintTextDirection,
    this.hintMaxLines,
    this.hintFadeDuration,
    this.maintainHintHeight = true,
    this.maintainHintSize,
    this.error,
    this.errorText,
    this.errorStyle,
    this.errorMaxLines,
    this.floatingLabelBehavior,
    this.floatingLabelAlignment,
    this.isCollapsed,
    this.isDense,
    this.contentPadding,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.prefix,
    this.prefixText,
    this.prefixStyle,
    this.prefixIconColor,
    this.suffixIcon,
    this.suffix,
    this.suffixText,
    this.suffixStyle,
    this.suffixIconColor,
    this.suffixIconConstraints,
    this.counter,
    this.counterText,
    this.counterStyle,
    this.filled,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.errorBorder,
    this.focusedBorder,
    this.focusedErrorBorder,
    this.disabledBorder,
    this.enabledBorder,
    this.border,
    this.enabled = true,
    this.semanticCounterText,
    this.alignLabelWithHint,
    this.constraints,
  });
  const InputDecoration.collapsed({
    required this.hintText,
    this.hintStyle,
    this.hintTextDirection,
    this.hintMaxLines,
    this.hintFadeDuration,
    this.maintainHintHeight = true,
    this.maintainHintSize,
    this.floatingLabelBehavior,
    this.floatingLabelAlignment,
    this.filled = false,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.border = InputBorder.none,
    this.enabled = true,
    this.constraints,
  }) : icon = null,
       iconColor = null,
       label = null,
       labelText = null,
       labelStyle = null,
       floatingLabelStyle = null,
       helper = null,
       helperText = null,
       helperStyle = null,
       helperMaxLines = null,
       hint = null,
       error = null,
       errorText = null,
       errorStyle = null,
       errorMaxLines = null,
       isCollapsed = true,
       isDense = true,
       contentPadding = EdgeInsets.zero,
       prefixIcon = null,
       prefixIconConstraints = null,
       prefix = null,
       prefixText = null,
       prefixStyle = null,
       prefixIconColor = null,
       suffixIcon = null,
       suffix = null,
       suffixText = null,
       suffixStyle = null,
       suffixIconColor = null,
       suffixIconConstraints = null,
       counter = null,
       counterText = null,
       counterStyle = null,
       errorBorder = null,
       focusedBorder = null,
       focusedErrorBorder = null,
       disabledBorder = null,
       enabledBorder = null,
       semanticCounterText = null,
       alignLabelWithHint = null;
  final Widget? icon;
  final Color? iconColor;
  final Widget? label;
  final String? labelText;
  final TextStyle? labelStyle;
  final TextStyle? floatingLabelStyle;
  final Widget? helper;
  final String? helperText;
  final TextStyle? helperStyle;
  final int? helperMaxLines;
  final String? hintText;
  final Widget? hint;
  final TextStyle? hintStyle;
  final TextDirection? hintTextDirection;
  final int? hintMaxLines;
  final Duration? hintFadeDuration;
  final bool maintainHintHeight;
  final bool? maintainHintSize;
  final Widget? error;
  final String? errorText;
  final TextStyle? errorStyle;
  final int? errorMaxLines;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final FloatingLabelAlignment? floatingLabelAlignment;
  final bool? isCollapsed;
  final bool? isDense;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final Widget? prefix;
  final String? prefixText;
  final TextStyle? prefixStyle;
  final Color? prefixIconColor;
  final Widget? suffixIcon;
  final Widget? suffix;
  final String? suffixText;
  final TextStyle? suffixStyle;
  final Color? suffixIconColor;
  final BoxConstraints? suffixIconConstraints;
  final Widget? counter;
  final String? counterText;
  final TextStyle? counterStyle;
  final bool? filled;
  final Color? fillColor;
  final Color? focusColor;
  final Color? hoverColor;
  final InputBorder? errorBorder;
  final InputBorder? focusedBorder;
  final InputBorder? focusedErrorBorder;
  final InputBorder? disabledBorder;
  final InputBorder? enabledBorder;
  final InputBorder? border;
  final bool enabled;
  final String? semanticCounterText;
  final bool? alignLabelWithHint;
  final BoxConstraints? constraints;

  /// Fills null properties from [theme], as Flutter's `applyDefaults`.
  InputDecoration applyDefaults(InputDecorationTheme theme) => copyWith(
    labelStyle: labelStyle ?? theme.labelStyle,
    floatingLabelStyle: floatingLabelStyle ?? theme.floatingLabelStyle,
    helperStyle: helperStyle ?? theme.helperStyle,
    helperMaxLines: helperMaxLines ?? theme.helperMaxLines,
    hintStyle: hintStyle ?? theme.hintStyle,
    errorStyle: errorStyle ?? theme.errorStyle,
    errorMaxLines: errorMaxLines ?? theme.errorMaxLines,
    floatingLabelBehavior: floatingLabelBehavior ?? theme.floatingLabelBehavior,
    floatingLabelAlignment:
        floatingLabelAlignment ?? theme.floatingLabelAlignment,
    isDense: isDense ?? theme.isDense,
    contentPadding: contentPadding ?? theme.contentPadding,
    isCollapsed: isCollapsed ?? theme.isCollapsed,
    iconColor: iconColor ?? theme.iconColor,
    prefixStyle: prefixStyle ?? theme.prefixStyle,
    prefixIconColor: prefixIconColor ?? theme.prefixIconColor,
    prefixIconConstraints: prefixIconConstraints ?? theme.prefixIconConstraints,
    suffixStyle: suffixStyle ?? theme.suffixStyle,
    suffixIconColor: suffixIconColor ?? theme.suffixIconColor,
    suffixIconConstraints: suffixIconConstraints ?? theme.suffixIconConstraints,
    counterStyle: counterStyle ?? theme.counterStyle,
    filled: filled ?? theme.filled,
    fillColor: fillColor ?? theme.fillColor,
    focusColor: focusColor ?? theme.focusColor,
    hoverColor: hoverColor ?? theme.hoverColor,
    errorBorder: errorBorder ?? theme.errorBorder,
    focusedBorder: focusedBorder ?? theme.focusedBorder,
    focusedErrorBorder: focusedErrorBorder ?? theme.focusedErrorBorder,
    disabledBorder: disabledBorder ?? theme.disabledBorder,
    enabledBorder: enabledBorder ?? theme.enabledBorder,
    border: border ?? theme.border,
    alignLabelWithHint: alignLabelWithHint ?? theme.alignLabelWithHint,
    constraints: constraints ?? theme.constraints,
  );

  InputDecoration copyWith({
    Widget? icon,
    Color? iconColor,
    Widget? label,
    String? labelText,
    TextStyle? labelStyle,
    TextStyle? floatingLabelStyle,
    Widget? helper,
    String? helperText,
    TextStyle? helperStyle,
    int? helperMaxLines,
    String? hintText,
    Widget? hint,
    TextStyle? hintStyle,
    TextDirection? hintTextDirection,
    int? hintMaxLines,
    Duration? hintFadeDuration,
    bool? maintainHintHeight,
    bool? maintainHintSize,
    Widget? error,
    String? errorText,
    TextStyle? errorStyle,
    int? errorMaxLines,
    FloatingLabelBehavior? floatingLabelBehavior,
    FloatingLabelAlignment? floatingLabelAlignment,
    bool? isCollapsed,
    bool? isDense,
    EdgeInsetsGeometry? contentPadding,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
    Widget? prefix,
    String? prefixText,
    TextStyle? prefixStyle,
    Color? prefixIconColor,
    Widget? suffixIcon,
    Widget? suffix,
    String? suffixText,
    TextStyle? suffixStyle,
    Color? suffixIconColor,
    BoxConstraints? suffixIconConstraints,
    Widget? counter,
    String? counterText,
    TextStyle? counterStyle,
    bool? filled,
    Color? fillColor,
    Color? focusColor,
    Color? hoverColor,
    InputBorder? errorBorder,
    InputBorder? focusedBorder,
    InputBorder? focusedErrorBorder,
    InputBorder? disabledBorder,
    InputBorder? enabledBorder,
    InputBorder? border,
    bool? enabled,
    String? semanticCounterText,
    bool? alignLabelWithHint,
    BoxConstraints? constraints,
  }) => InputDecoration(
    icon: icon ?? this.icon,
    iconColor: iconColor ?? this.iconColor,
    label: label ?? this.label,
    labelText: labelText ?? this.labelText,
    labelStyle: labelStyle ?? this.labelStyle,
    floatingLabelStyle: floatingLabelStyle ?? this.floatingLabelStyle,
    helper: helper ?? this.helper,
    helperText: helperText ?? this.helperText,
    helperStyle: helperStyle ?? this.helperStyle,
    helperMaxLines: helperMaxLines ?? this.helperMaxLines,
    hintText: hintText ?? this.hintText,
    hint: hint ?? this.hint,
    hintStyle: hintStyle ?? this.hintStyle,
    hintTextDirection: hintTextDirection ?? this.hintTextDirection,
    hintMaxLines: hintMaxLines ?? this.hintMaxLines,
    hintFadeDuration: hintFadeDuration ?? this.hintFadeDuration,
    maintainHintHeight: maintainHintHeight ?? this.maintainHintHeight,
    maintainHintSize: maintainHintSize ?? this.maintainHintSize,
    error: error ?? this.error,
    errorText: errorText ?? this.errorText,
    errorStyle: errorStyle ?? this.errorStyle,
    errorMaxLines: errorMaxLines ?? this.errorMaxLines,
    floatingLabelBehavior: floatingLabelBehavior ?? this.floatingLabelBehavior,
    floatingLabelAlignment:
        floatingLabelAlignment ?? this.floatingLabelAlignment,
    isCollapsed: isCollapsed ?? this.isCollapsed,
    isDense: isDense ?? this.isDense,
    contentPadding: contentPadding ?? this.contentPadding,
    prefixIcon: prefixIcon ?? this.prefixIcon,
    prefixIconConstraints: prefixIconConstraints ?? this.prefixIconConstraints,
    prefix: prefix ?? this.prefix,
    prefixText: prefixText ?? this.prefixText,
    prefixStyle: prefixStyle ?? this.prefixStyle,
    prefixIconColor: prefixIconColor ?? this.prefixIconColor,
    suffixIcon: suffixIcon ?? this.suffixIcon,
    suffix: suffix ?? this.suffix,
    suffixText: suffixText ?? this.suffixText,
    suffixStyle: suffixStyle ?? this.suffixStyle,
    suffixIconColor: suffixIconColor ?? this.suffixIconColor,
    suffixIconConstraints: suffixIconConstraints ?? this.suffixIconConstraints,
    counter: counter ?? this.counter,
    counterText: counterText ?? this.counterText,
    counterStyle: counterStyle ?? this.counterStyle,
    filled: filled ?? this.filled,
    fillColor: fillColor ?? this.fillColor,
    focusColor: focusColor ?? this.focusColor,
    hoverColor: hoverColor ?? this.hoverColor,
    errorBorder: errorBorder ?? this.errorBorder,
    focusedBorder: focusedBorder ?? this.focusedBorder,
    focusedErrorBorder: focusedErrorBorder ?? this.focusedErrorBorder,
    disabledBorder: disabledBorder ?? this.disabledBorder,
    enabledBorder: enabledBorder ?? this.enabledBorder,
    border: border ?? this.border,
    enabled: enabled ?? this.enabled,
    semanticCounterText: semanticCounterText ?? this.semanticCounterText,
    alignLabelWithHint: alignLabelWithHint ?? this.alignLabelWithHint,
    constraints: constraints ?? this.constraints,
  );
}

var _nextFieldId = 0;

// ---------------------------------------------------------------------------
// Text fields.

/// Vertical alignment of text within an input; carried, as browsers center
/// single-line inputs.
class TextAlignVertical {
  const TextAlignVertical({required this.y});
  final double y;
  static const top = TextAlignVertical(y: -1.0);
  static const center = TextAlignVertical(y: 0.0);
  static const bottom = TextAlignVertical(y: 1.0);
}

/// Minimum line metrics for a paragraph; carried as a value.
class StrutStyle {
  const StrutStyle({
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontSize,
    this.height,
    this.leading,
    this.fontWeight,
    this.fontStyle,
    this.forceStrutHeight,
    this.debugLabel,
    String? package,
  });
  final String? fontFamily;
  final List<String>? fontFamilyFallback;
  final double? fontSize, height, leading;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final bool? forceStrutHeight;
  final String? debugLabel;
  static const StrutStyle disabled = StrutStyle(height: 0, leading: 0);
}

enum SmartDashesType { disabled, enabled }

enum SmartQuotesType { disabled, enabled }

/// Text selection handles and toolbars are the browser's own.
abstract class TextSelectionControls {
  const TextSelectionControls();
}

class _BrowserSelectionControls extends TextSelectionControls {
  const _BrowserSelectionControls();
}

const TextSelectionControls materialTextSelectionControls =
    _BrowserSelectionControls();
const TextSelectionControls emptyTextSelectionControls =
    _BrowserSelectionControls();

typedef TapRegionCallback = void Function(PointerDownEvent event);

/// The state of an editable text field, as passed to context menu
/// builders. The browser provides the context menu; builders are not called.
abstract class EditableTextState {}

typedef EditableTextContextMenuBuilder =
    Widget Function(BuildContext context, EditableTextState editableTextState);

typedef AppPrivateCommandCallback =
    void Function(String action, Map<String, dynamic> data);

/// Spell checking is the browser's; configurations are carried only.
class SpellCheckConfiguration {
  const SpellCheckConfiguration({
    this.spellCheckService,
    this.misspelledSelectionColor,
    this.misspelledTextStyle,
    this.spellCheckSuggestionsToolbarBuilder,
  });
  const SpellCheckConfiguration.disabled()
    : spellCheckService = null,
      misspelledSelectionColor = null,
      misspelledTextStyle = null,
      spellCheckSuggestionsToolbarBuilder = null;
  final Object? spellCheckService;
  final Color? misspelledSelectionColor;
  final TextStyle? misspelledTextStyle;
  final Object? spellCheckSuggestionsToolbarBuilder;
}

class TextMagnifierConfiguration {
  const TextMagnifierConfiguration({
    this.magnifierBuilder,
    this.shouldDisplayHandlesInMagnifier = true,
  });
  static const TextMagnifierConfiguration disabled =
      TextMagnifierConfiguration();
  final Object? magnifierBuilder;
  final bool shouldDisplayHandlesInMagnifier;
}

/// Undo history is the browser's; the controller is accepted only.
class UndoHistoryController extends ChangeNotifier {
  UndoHistoryController();
  void undo() {}
  void redo() {}
}

typedef InputCounterWidgetBuilder =
    Widget? Function(
      BuildContext context, {
      required int currentLength,
      required int? maxLength,
      required bool isFocused,
    });

class TextField extends StatefulWidget {
  const TextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.enabled,
    this.readOnly = false,
    this.autofillHints,
    this.buildCounter,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorOpacityAnimates,
    this.cursorColor,
    this.cursorErrorColor,
    this.showCursor,
    this.textAlignVertical,
    this.textDirection,
    this.strutStyle,
    this.obscuringCharacter = '•',
    this.smartDashesType,
    this.smartQuotesType,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection,
    this.selectionControls,
    this.onTapAlwaysCalled = false,
    this.onTapOutside,
    this.mouseCursor,
    this.scrollController,
    this.scrollPhysics,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.stylusHandwritingEnabled = true,
    this.enableIMEPersonalizedLearning = true,
    this.contextMenuBuilder,
    this.canRequestFocus = true,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
    this.undoController,
    this.onAppPrivateCommand,
    this.groupId = TextField,
    this.ignorePointers,
    this.statesController,
  });
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final bool? cursorOpacityAnimates;
  final Color? cursorColor;
  final Color? cursorErrorColor;
  final bool? showCursor;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final StrutStyle? strutStyle;
  final String obscuringCharacter;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final DragStartBehavior dragStartBehavior;
  final bool? enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final bool onTapAlwaysCalled;
  final TapRegionCallback? onTapOutside;
  final MouseCursor? mouseCursor;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final Clip clipBehavior;
  final String? restorationId;
  final bool stylusHandwritingEnabled;
  final bool enableIMEPersonalizedLearning;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final bool canRequestFocus;
  final SpellCheckConfiguration? spellCheckConfiguration;
  final TextMagnifierConfiguration? magnifierConfiguration;
  final UndoHistoryController? undoController;
  final AppPrivateCommandCallback? onAppPrivateCommand;
  final Object groupId;
  final bool? ignorePointers;
  final WidgetStatesController? statesController;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool autofocus, obscureText, autocorrect, enableSuggestions;
  final int? maxLines, minLines, maxLength;
  final bool expands;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final bool readOnly;
  final Iterable<String>? autofillHints;
  final InputCounterWidgetBuilder? buildCounter;
  @override
  State<TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<TextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  final _id = 'fd-field-${_nextFieldId++}';
  _Node? _inputNode;
  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _focus.addListener(_changed);
    if (widget.autofocus) _focus.requestFocus();
  }

  @override
  void didUpdateWidget(TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController = oldWidget.controller ?? _ownController;
    if (!identical(oldController, _controller)) {
      oldController?.removeListener(_changed);
      _controller.addListener(_changed);
    }
    final oldFocus = oldWidget.focusNode ?? _ownFocus;
    if (!identical(oldFocus, _focus)) {
      oldFocus?.removeListener(_changed);
      if (_inputNode != null) oldFocus?._detach(_inputNode!);
      _focus.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _focus.removeListener(_changed);
    if (_inputNode != null) _focus._detach(_inputNode!);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  bool get _enabled => widget.enabled ?? widget.decoration?.enabled ?? true;

  void _edit(TextEditingValue next, _DomElement element) {
    var value = next;
    final old = _controller.value;
    final formatters = [
      ...?widget.inputFormatters,
      if (widget.maxLength != null &&
          widget.maxLengthEnforcement != MaxLengthEnforcement.none)
        LengthLimitingTextInputFormatter(widget.maxLength),
    ];
    for (final formatter in formatters) {
      value = formatter.formatEditUpdate(old, value);
    }
    if (value.text != next.text) {
      element._setLiveProperty('value', value.text);
    }
    final textChanged = value.text != old.text;
    _controller.value = value;
    if (textChanged) widget.onChanged?.call(value.text);
  }

  void _submit() {
    widget.onEditingComplete?.call();
    widget.onSubmitted?.call(_controller.text);
    final action = widget.textInputAction;
    if (widget.onEditingComplete == null &&
        (action == null ||
            action == TextInputAction.done ||
            action == TextInputAction.go ||
            action == TextInputAction.search ||
            action == TextInputAction.send))
      _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration ?? const InputDecoration();
    final lines = widget.maxLines;
    final multiline = lines == null || lines > 1 || widget.expands;
    final counter = widget.maxLength == null
        ? null
        : widget.buildCounter != null
        ? widget.buildCounter!(
            context,
            currentLength: _controller.text.runes.length,
            maxLength: widget.maxLength,
            isFocused: _focus.hasFocus,
          )
        : Text(
            decoration.counterText ??
                '${_controller.text.runes.length}/${widget.maxLength}',
          );
    return _InputDecorator(
      id: _id,
      decoration: decoration,
      focused: _focus.hasFocus,
      enabled: _enabled,
      counter: counter,
      child: _EditableInput(
        id: _id,
        state: this,
        multiline: multiline,
        value: _controller.value,
        enabled: _enabled,
        decoration: decoration,
      ),
    );
  }
}

class _EditableInput extends _DomWidget {
  const _EditableInput({
    required this.id,
    required this.state,
    required this.multiline,
    required this.value,
    required this.enabled,
    required this.decoration,
  });
  final String id;
  final _TextFieldState state;
  final bool multiline, enabled;
  final TextEditingValue value;
  final InputDecoration decoration;
  @override
  String get _tag => multiline ? 'textarea' : 'input';
  @override
  _Fill get _fill => _Fill.expand;

  @override
  void _render(_DomBuilder out) {
    final widget = state.widget;
    final element = out.context;
    final theme = Theme.of(element);
    final style = theme.textTheme.bodyLarge!
        .copyWith(
          color: enabled
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.38),
        )
        .merge(widget.style);
    out.css(
      'display:block;box-sizing:border-box;width:100%;min-width:0;margin:0;padding:0;border:0;outline:none;background:transparent;font:inherit;',
    );
    out.css(textStyleCss(style));
    out.css(_textAlignCss(widget.textAlign));
    final hasError = decoration.errorText != null || decoration.error != null;
    final caret = widget.showCursor == false
        ? null
        : hasError
        ? widget.cursorErrorColor ?? theme.colorScheme.error
        : widget.cursorColor ?? theme.textSelectionTheme.cursorColor;
    if (widget.showCursor == false) {
      out.css('caret-color:transparent;');
    } else if (caret != null) {
      out.css('caret-color:${colorCss(caret)};');
    }
    if (widget.mouseCursor case final cursor?)
      out.css('cursor:${cursor._css};');
    if (widget.enableInteractiveSelection == false)
      out.css('user-select:none;-webkit-user-select:none;');
    if (widget.ignorePointers == true) out.css('pointer-events:none;');
    if (!widget.canRequestFocus) out.attributes['tabindex'] = '-1';
    if (widget.textDirection != null)
      out.attributes['dir'] = widget.textDirection == TextDirection.rtl
          ? 'rtl'
          : 'ltr';
    if (multiline) {
      final rows = widget.minLines ?? (widget.maxLines ?? 1);
      out.attributes['rows'] = '$rows';
      out.css(
        widget.maxLines == null
            ? 'resize:none;field-sizing:content;'
            : 'resize:vertical;',
      );
    } else {
      final (type, inputMode) =
          (widget.keyboardType ?? TextInputType.text).htmlInput;
      out.attributes['type'] = widget.obscureText ? 'password' : type;
      if (inputMode != null) out.attributes['inputmode'] = inputMode;
    }
    out.attributes['id'] = id;
    final autocomplete =
        widget.autofillHints?.firstOrNull ?? widget.keyboardType?.autocomplete;
    if (autocomplete != null) out.attributes['autocomplete'] = autocomplete;
    if (!widget.autocorrect) out.attributes['autocorrect'] = 'off';
    if (!widget.enableSuggestions) out.attributes['spellcheck'] = 'false';
    if (widget.textCapitalization != TextCapitalization.none)
      out.attributes['autocapitalize'] = switch (widget.textCapitalization) {
        TextCapitalization.words => 'words',
        TextCapitalization.sentences => 'sentences',
        TextCapitalization.characters => 'characters',
        TextCapitalization.none => 'off',
      };
    final enterKey = switch (widget.textInputAction) {
      TextInputAction.done => 'done',
      TextInputAction.go => 'go',
      TextInputAction.search => 'search',
      TextInputAction.send => 'send',
      TextInputAction.next => 'next',
      TextInputAction.previous => 'previous',
      _ => null,
    };
    if (enterKey != null) out.attributes['enterkeyhint'] = enterKey;
    if (decoration.hintText != null)
      out.attributes['placeholder'] = decoration.hintText!;
    if (!enabled) out.attributes['disabled'] = '';
    if (widget.readOnly) out.attributes['readonly'] = '';
    if (decoration.errorText != null) {
      out.attributes['aria-invalid'] = 'true';
      out.attributes['aria-describedby'] = '$id-message';
    } else if (decoration.helperText != null) {
      out.attributes['aria-describedby'] = '$id-message';
    }
    if (decoration.labelText == null && decoration.hintText != null)
      out.attributes['aria-label'] = decoration.hintText!;
    out.properties['value'] = value.text;
    out.on('input', (_) {
      final node = element.node as JSObject;
      final text = node.getProperty<JSString>('value'.toJS).toDart;
      final start = node.getProperty<JSNumber?>('selectionStart'.toJS);
      final end = node.getProperty<JSNumber?>('selectionEnd'.toJS);
      state._edit(
        TextEditingValue(
          text: text,
          selection: start == null || end == null
              ? TextSelection.collapsed(offset: text.length)
              : TextSelection(
                  baseOffset: start.toDartInt,
                  extentOffset: end.toDartInt,
                ),
        ),
        element,
      );
    });
    out.on('focus', (_) => state._focus._setFocus(true));
    out.on('blur', (_) => state._focus._setFocus(false));
    if (widget.onTap != null) out.on('click', (_) => widget.onTap!());
    if (!multiline) {
      out.on('keydown', (event) {
        if (event?.key == 'Enter') {
          event?.preventDefault();
          state._submit();
        }
      });
    }
    state._inputNode = element.node;
    state._focus._attach(element.node);
  }
}

class _InputDecorator extends StatelessWidget {
  const _InputDecorator({
    required this.id,
    required this.decoration,
    required this.focused,
    required this.enabled,
    required this.counter,
    required this.child,
  });
  final String id;
  final InputDecoration decoration;
  final bool focused, enabled;
  final Widget? counter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // As in Flutter, the theme fills whatever the decoration leaves null.
    final decoration = this.decoration.applyDefaults(
      theme.inputDecorationTheme,
    );
    final error = decoration.errorText != null || decoration.error != null;
    final borderColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.12)
        : error
        ? scheme.error
        : focused
        ? scheme.primary
        : scheme.outline;
    final chosen =
        (!enabled ? decoration.disabledBorder : null) ??
        (error && focused ? decoration.focusedErrorBorder : null) ??
        (error ? decoration.errorBorder : null) ??
        (focused ? decoration.focusedBorder : null) ??
        (enabled ? decoration.enabledBorder : null) ??
        decoration.border ??
        const UnderlineInputBorder();
    final side = chosen.borderSide;
    final explicitColor =
        identical(chosen, decoration.border) ||
        side.color == const Color(0xff000000);
    final color = explicitColor ? borderColor : side.color;
    final width = focused && chosen is! _NoInputBorder
        ? (explicitColor ? 2.0 : side.width)
        : (explicitColor ? 1.0 : side.width);
    final filled = decoration.filled ?? false;
    final dense = decoration.isDense ?? false;
    final collapsed = decoration.isCollapsed ?? false;
    final padding =
        decoration.contentPadding ??
        (collapsed
            ? EdgeInsets.zero
            : chosen is OutlineInputBorder
            ? EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 8 : 12)
            : EdgeInsets.symmetric(
                horizontal: filled ? 12 : 0,
                vertical: dense ? 6 : 8,
              ));
    final labelColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : error
        ? scheme.error
        : focused
        ? scheme.primary
        : scheme.onSurfaceVariant;
    final label =
        decoration.label ??
        (decoration.labelText == null ? null : Text(decoration.labelText!));
    final labelStyle = theme.textTheme.bodySmall!
        .copyWith(color: labelColor)
        .merge(
          focused
              ? decoration.floatingLabelStyle ?? decoration.labelStyle
              : decoration.labelStyle,
        );
    final messageText = decoration.errorText ?? decoration.helperText;
    final messageWidget = error ? decoration.error : decoration.helper;
    final messageStyle = theme.textTheme.bodySmall!
        .copyWith(color: error ? scheme.error : scheme.onSurfaceVariant)
        .merge(error ? decoration.errorStyle : decoration.helperStyle);
    final maxLines = error
        ? decoration.errorMaxLines
        : decoration.helperMaxLines;
    IconThemeData iconTheme(Color? color) => IconThemeData(
      color: error ? scheme.error : color ?? scheme.onSurfaceVariant,
      size: 24,
    );
    final affixStyle = theme.textTheme.bodyLarge!.copyWith(
      color: scheme.onSurfaceVariant,
    );
    Widget constrained(Widget icon, BoxConstraints? constraints) =>
        constraints == null
        ? icon
        : ConstrainedBox(constraints: constraints, child: icon);
    final limits = decoration.constraints;
    final field = _Box(
      css: 'display:flex;flex-direction:column;min-width:0;',
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [
        _Box(
          css:
              'display:flex;flex-direction:row;align-items:center;gap:12px;box-sizing:border-box;min-width:0;'
              '${chosen._css(color, chosen is _NoInputBorder ? 0 : width)}'
              '${filled ? 'background-color:${colorCss(decoration.fillColor ?? scheme.surfaceContainerHighest)};' : ''}'
              '${edgeInsetsCss('padding', padding)}'
              '${limits == null ? '' : '${limits.minHeight > 0 ? 'min-height:${px(limits.minHeight)};' : ''}${limits.maxHeight.isFinite ? 'max-height:${px(limits.maxHeight)};' : ''}${limits.maxWidth.isFinite ? 'max-width:${px(limits.maxWidth)};' : ''}'}'
              '${decoration.hoverColor == null ? '' : '--fd-hover:${colorCss(decoration.hoverColor!)};'}',
          layout: _DomLayout.row,
          fill: _Fill.expand,
          children: [
            if (decoration.prefixIcon != null)
              IconTheme.merge(
                data: iconTheme(
                  decoration.prefixIconColor ?? decoration.iconColor,
                ),
                child: constrained(
                  decoration.prefixIcon!,
                  decoration.prefixIconConstraints,
                ),
              ),
            _Box(
              css: 'flex:1 1 0;min-width:0;display:flex;flex-direction:column;',
              layout: _DomLayout.column,
              children: [
                if (label != null &&
                    decoration.floatingLabelBehavior !=
                        FloatingLabelBehavior.never)
                  _Box(
                    tag: 'label',
                    css:
                        decoration.floatingLabelAlignment ==
                            FloatingLabelAlignment.center
                        ? 'align-self:center;'
                        : '',
                    attributes: {'for': id},
                    fill: _Fill.none,
                    children: [
                      DefaultTextStyle(style: labelStyle, child: label),
                    ],
                  ),
                _Box(
                  css:
                      'display:flex;flex-direction:row;align-items:baseline;gap:4px;min-width:0;',
                  layout: _DomLayout.row,
                  fill: _Fill.expand,
                  children: [
                    if (decoration.prefix != null) decoration.prefix!,
                    if (decoration.prefixText != null)
                      Text(
                        decoration.prefixText!,
                        style: affixStyle.merge(decoration.prefixStyle),
                      ),
                    _Box(css: 'flex:1 1 0;min-width:0;', children: [child]),
                    if (decoration.suffixText != null)
                      Text(
                        decoration.suffixText!,
                        style: affixStyle.merge(decoration.suffixStyle),
                      ),
                    if (decoration.suffix != null) decoration.suffix!,
                  ],
                ),
              ],
            ),
            if (decoration.suffixIcon != null)
              IconTheme.merge(
                data: iconTheme(
                  decoration.suffixIconColor ?? decoration.iconColor,
                ),
                child: constrained(
                  decoration.suffixIcon!,
                  decoration.suffixIconConstraints,
                ),
              ),
          ],
        ),
        if (messageText != null ||
            messageWidget != null ||
            counter != null ||
            decoration.counter != null)
          _Box(
            css:
                'display:flex;flex-direction:row;gap:16px;padding:4px ${chosen is OutlineInputBorder || filled ? 16 : 0}px 0;',
            layout: _DomLayout.row,
            fill: _Fill.expand,
            children: [
              _Box(
                css: 'flex:1 1 0;min-width:0;',
                attributes: {'id': '$id-message', if (error) 'role': 'alert'},
                children: [
                  if (messageWidget != null)
                    DefaultTextStyle(style: messageStyle, child: messageWidget)
                  else if (messageText != null)
                    Text(
                      messageText,
                      style: messageStyle,
                      maxLines: maxLines,
                      overflow: maxLines == null ? null : TextOverflow.ellipsis,
                    ),
                ],
              ),
              if (decoration.counter ?? counter case final shown?)
                DefaultTextStyle(
                  style: theme.textTheme.bodySmall!
                      .copyWith(color: scheme.onSurfaceVariant)
                      .merge(decoration.counterStyle),
                  child: shown,
                ),
            ],
          ),
      ],
    );
    if (decoration.icon == null) return field;
    return _Box(
      css:
          'display:flex;flex-direction:row;align-items:center;gap:16px;min-width:0;',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        IconTheme.merge(
          data: IconThemeData(
            color: decoration.iconColor ?? scheme.onSurfaceVariant,
            size: 24,
          ),
          child: decoration.icon!,
        ),
        field,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Forms.

enum AutovalidateMode { disabled, always, onUserInteraction, onUnfocus }

typedef FormFieldValidator<T> = String? Function(T? value);
typedef FormFieldSetter<T> = void Function(T? newValue);
typedef FormFieldBuilder<T> = Widget Function(FormFieldState<T> field);

class Form extends StatefulWidget {
  const Form({
    super.key,
    required this.child,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.onChanged,
  });
  final Widget child;
  final AutovalidateMode autovalidateMode;
  final VoidCallback? onChanged;
  static FormState of(BuildContext context) =>
      maybeOf(context) ?? (throw StateError('No Form ancestor in context.'));
  static FormState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FormScope>()?.form;
  @override
  State<Form> createState() => FormState();
}

class FormState extends State<Form> {
  final _fields = <FormFieldState<dynamic>>{};
  int _generation = 0;

  void _changed() {
    widget.onChanged?.call();
    if (widget.autovalidateMode != AutovalidateMode.disabled) {
      setState(() => _generation++);
    }
  }

  bool validate() {
    var valid = true;
    for (final field in _fields) {
      valid = field.validate() && valid;
    }
    setState(() => _generation++);
    return valid;
  }

  void save() {
    for (final field in _fields) {
      field.save();
    }
  }

  void reset() {
    for (final field in _fields) {
      field.reset();
    }
    setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) => _Box(
    tag: 'form',
    attributes: const {'novalidate': ''},
    handlers: {'submit': (event) => event?.preventDefault()},
    layout: _DomLayout.grid,
    css:
        'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;margin:0;',
    children: [
      _FormScope(form: this, generation: _generation, child: widget.child),
    ],
  );
}

class _FormScope extends InheritedWidget {
  const _FormScope({
    required this.form,
    required this.generation,
    required super.child,
  });
  final FormState form;
  final int generation;
  @override
  bool updateShouldNotify(_FormScope oldWidget) =>
      oldWidget.generation != generation;
}

class FormField<T> extends StatefulWidget {
  const FormField({
    super.key,
    required this.builder,
    this.onSaved,
    this.validator,
    this.initialValue,
    this.enabled = true,
    this.autovalidateMode,
    this.forceErrorText,
  });
  final FormFieldBuilder<T> builder;
  final FormFieldSetter<T>? onSaved;
  final FormFieldValidator<T>? validator;
  final T? initialValue;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;
  final String? forceErrorText;
  @override
  FormFieldState<T> createState() => FormFieldState<T>();
}

class FormFieldState<T> extends State<FormField<T>> {
  late T? _value = widget.initialValue;
  String? _errorText;
  bool _interacted = false;
  FormState? _form;

  T? get value => _value;
  String? get errorText => widget.forceErrorText ?? _errorText;
  bool get hasError => errorText != null;
  bool get isValid => widget.validator?.call(_value) == null;
  bool get hasInteractedByUser => _interacted;

  void save() => widget.onSaved?.call(_value);

  void reset() {
    setState(() {
      _value = widget.initialValue;
      _interacted = false;
      _errorText = null;
    });
  }

  bool validate() {
    setState(() => _errorText = widget.validator?.call(_value));
    return _errorText == null;
  }

  void didChange(T? value) {
    setState(() {
      _value = value;
      _interacted = true;
    });
    _form?._changed();
  }

  void setValue(T? value) => _value = value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final form = Form.maybeOf(context);
    if (!identical(form, _form)) {
      _form?._fields.remove(this);
      _form = form;
      form?._fields.add(this);
    }
  }

  @override
  void dispose() {
    _form?._fields.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode =
        widget.autovalidateMode ??
        _form?.widget.autovalidateMode ??
        AutovalidateMode.disabled;
    if (widget.enabled &&
        (mode == AutovalidateMode.always ||
            (mode == AutovalidateMode.onUserInteraction && _interacted))) {
      _errorText = widget.validator?.call(_value);
    }
    return widget.builder(this);
  }
}

class TextFormField extends FormField<String> {
  TextFormField({
    super.key,
    this.controller,
    String? initialValue,
    FocusNode? focusNode,
    InputDecoration? decoration = const InputDecoration(),
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextStyle? style,
    TextAlign textAlign = TextAlign.start,
    bool autofocus = false,
    bool obscureText = false,
    bool autocorrect = true,
    bool enableSuggestions = true,
    int? maxLines = 1,
    int? minLines,
    int? maxLength,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onFieldSubmitted,
    VoidCallback? onTap,
    super.onSaved,
    super.validator,
    List<TextInputFormatter>? inputFormatters,
    bool? enabled,
    bool readOnly = false,
    Iterable<String>? autofillHints,
    super.autovalidateMode,
    super.forceErrorText,
    bool expands = false,
    MaxLengthEnforcement? maxLengthEnforcement,
    InputCounterWidgetBuilder? buildCounter,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    bool? cursorOpacityAnimates,
    Color? cursorColor,
    Color? cursorErrorColor,
    bool? showCursor,
    TextAlignVertical? textAlignVertical,
    TextDirection? textDirection,
    StrutStyle? strutStyle,
    String obscuringCharacter = '•',
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    bool? enableInteractiveSelection,
    TextSelectionControls? selectionControls,
    bool onTapAlwaysCalled = false,
    TapRegionCallback? onTapOutside,
    MouseCursor? mouseCursor,
    ScrollController? scrollController,
    ScrollPhysics? scrollPhysics,
    Clip clipBehavior = Clip.hardEdge,
    String? restorationId,
    bool stylusHandwritingEnabled = true,
    bool enableIMEPersonalizedLearning = true,
    EditableTextContextMenuBuilder? contextMenuBuilder,
    bool canRequestFocus = true,
    SpellCheckConfiguration? spellCheckConfiguration,
    TextMagnifierConfiguration? magnifierConfiguration,
    UndoHistoryController? undoController,
    AppPrivateCommandCallback? onAppPrivateCommand,
    Object groupId = TextField,
    bool? ignorePointers,
    WidgetStatesController? statesController,
  }) : super(
         initialValue: controller?.text ?? initialValue ?? '',
         enabled: enabled ?? decoration?.enabled ?? true,
         builder: (field) {
           final state = field as _TextFormFieldState;
           return TextField(
             controller: state._effectiveController,
             focusNode: focusNode,
             decoration: (decoration ?? const InputDecoration()).copyWith(
               errorText: field.errorText,
             ),
             keyboardType: keyboardType,
             textInputAction: textInputAction,
             textCapitalization: textCapitalization,
             style: style,
             textAlign: textAlign,
             autofocus: autofocus,
             obscureText: obscureText,
             autocorrect: autocorrect,
             enableSuggestions: enableSuggestions,
             maxLines: maxLines,
             minLines: minLines,
             maxLength: maxLength,
             onChanged: (value) {
               field.didChange(value);
               onChanged?.call(value);
             },
             onEditingComplete: onEditingComplete,
             onSubmitted: onFieldSubmitted,
             onTap: onTap,
             inputFormatters: inputFormatters,
             enabled: enabled ?? decoration?.enabled ?? true,
             readOnly: readOnly,
             autofillHints: autofillHints,
             expands: expands,
             maxLengthEnforcement: maxLengthEnforcement,
             buildCounter: buildCounter,
             cursorWidth: cursorWidth,
             cursorHeight: cursorHeight,
             cursorRadius: cursorRadius,
             cursorOpacityAnimates: cursorOpacityAnimates,
             cursorColor: cursorColor,
             cursorErrorColor: cursorErrorColor,
             showCursor: showCursor,
             textAlignVertical: textAlignVertical,
             textDirection: textDirection,
             strutStyle: strutStyle,
             obscuringCharacter: obscuringCharacter,
             smartDashesType: smartDashesType,
             smartQuotesType: smartQuotesType,
             keyboardAppearance: keyboardAppearance,
             scrollPadding: scrollPadding,
             dragStartBehavior: dragStartBehavior,
             enableInteractiveSelection: enableInteractiveSelection,
             selectionControls: selectionControls,
             onTapAlwaysCalled: onTapAlwaysCalled,
             onTapOutside: onTapOutside,
             mouseCursor: mouseCursor,
             scrollController: scrollController,
             scrollPhysics: scrollPhysics,
             clipBehavior: clipBehavior,
             restorationId: restorationId,
             stylusHandwritingEnabled: stylusHandwritingEnabled,
             enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
             contextMenuBuilder: contextMenuBuilder,
             canRequestFocus: canRequestFocus,
             spellCheckConfiguration: spellCheckConfiguration,
             magnifierConfiguration: magnifierConfiguration,
             undoController: undoController,
             onAppPrivateCommand: onAppPrivateCommand,
             groupId: groupId,
             ignorePointers: ignorePointers,
             statesController: statesController,
           );
         },
       );
  final TextEditingController? controller;
  @override
  FormFieldState<String> createState() => _TextFormFieldState();
}

class _TextFormFieldState extends FormFieldState<String> {
  TextEditingController? _own;
  TextEditingController get _effectiveController =>
      (widget as TextFormField).controller ??
      (_own ??= TextEditingController(text: widget.initialValue));

  void _controllerChanged() {
    if (_effectiveController.text != value)
      didChange(_effectiveController.text);
  }

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_controllerChanged);
  }

  @override
  void didUpdateWidget(FormField<String> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = (oldWidget as TextFormField).controller ?? _own;
    if (!identical(old, _effectiveController)) {
      old?.removeListener(_controllerChanged);
      _effectiveController.addListener(_controllerChanged);
    }
  }

  @override
  void reset() {
    _effectiveController.text = widget.initialValue ?? '';
    super.reset();
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_controllerChanged);
    _own?.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Selection controls. These are controlled: the DOM state is reset to the
// widget value after each event and changes only when the app rebuilds.

class _NativeControl extends _DomWidget {
  const _NativeControl({
    required this.tag,
    required this.css,
    required this.attributes,
    required this.properties,
    required this.events,
  });
  final String tag, css;
  final Map<String, String> attributes;
  final Map<String, Object?> properties;
  final Map<String, void Function(_DomElement element, _Event? event)> events;
  @override
  String get _tag => tag;
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) {
    out.css(css);
    out.attributes.addAll(attributes);
    out.properties.addAll(properties);
    final element = out.context;
    for (final entry in events.entries) {
      out.on(entry.key, (event) {
        entry.value(element, event);
        // Restore the controlled value until the app rebuilds.
        final current = element.widget as _NativeControl;
        for (final property in current.properties.entries) {
          element._setLiveProperty(property.key, property.value);
        }
      });
    }
  }
}

typedef ImageErrorListener =
    void Function(Object exception, StackTrace? stackTrace);

class Checkbox extends StatelessWidget {
  const Checkbox({
    super.key,
    required this.value,
    this.tristate = false,
    required this.onChanged,
    this.mouseCursor,
    this.activeColor,
    this.fillColor,
    this.checkColor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusNode,
    this.autofocus = false,
    this.shape,
    this.side,
    this.isError = false,
    this.semanticLabel,
  });
  const Checkbox.adaptive({
    super.key,
    required this.value,
    this.tristate = false,
    required this.onChanged,
    this.mouseCursor,
    this.activeColor,
    this.fillColor,
    this.checkColor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusNode,
    this.autofocus = false,
    this.shape,
    this.side,
    this.isError = false,
    this.semanticLabel,
  });
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate;
  final MouseCursor? mouseCursor;
  final Color? activeColor, checkColor, focusColor, hoverColor;
  final WidgetStateProperty<Color?>? fillColor, overlayColor;
  final double? splashRadius;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;
  final OutlinedBorder? shape;
  final BorderSide? side;
  final bool isError;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;
  static const double width = 18.0;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final checkboxTheme = CheckboxTheme.of(context);
    final states = {
      if (value != false) WidgetState.selected,
      if (onChanged == null) WidgetState.disabled,
      if (isError) WidgetState.error,
    };
    final color = isError
        ? scheme.error
        : fillColor?.resolve(states) ??
              activeColor ??
              checkboxTheme.fillColor?.resolve(states) ??
              scheme.primary;
    final cursor = mouseCursor ?? checkboxTheme.mouseCursor?.resolve(states);
    return _NativeControl(
      tag: 'input',
      css:
          'width:18px;height:18px;margin:11px;flex-shrink:0;accent-color:${colorCss(color)};cursor:${cursor?._css ?? (onChanged == null ? 'default' : 'pointer')};',
      attributes: {
        'type': 'checkbox',
        if (onChanged == null) 'disabled': '',
        if (semanticLabel != null) 'aria-label': semanticLabel!,
        if (isError) 'aria-invalid': 'true',
        if (autofocus) 'autofocus': '',
      },
      properties: {'checked': value == true, 'indeterminate': value == null},
      events: {
        'change': (_, _) {
          final next = tristate
              ? (value == false ? true : (value == true ? null : false))
              : !(value ?? false);
          onChanged?.call(next);
        },
      },
    );
  }
}

class Switch extends StatelessWidget {
  const Switch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeThumbColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.onActiveThumbImageError,
    this.inactiveThumbImage,
    this.onInactiveThumbImageError,
    this.thumbColor,
    this.trackColor,
    this.trackOutlineColor,
    this.trackOutlineWidth,
    this.thumbIcon,
    this.materialTapTargetSize,
    this.dragStartBehavior = DragStartBehavior.start,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    this.padding,
  }) : applyCupertinoTheme = null;
  const Switch.adaptive({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeThumbColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.onActiveThumbImageError,
    this.inactiveThumbImage,
    this.onInactiveThumbImageError,
    this.thumbColor,
    this.trackColor,
    this.trackOutlineColor,
    this.trackOutlineWidth,
    this.thumbIcon,
    this.materialTapTargetSize,
    this.dragStartBehavior = DragStartBehavior.start,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    this.padding,
    this.applyCupertinoTheme,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor, activeThumbColor, activeTrackColor;
  final Color? inactiveThumbColor, inactiveTrackColor;
  final ImageProvider? activeThumbImage, inactiveThumbImage;
  final ImageErrorListener? onActiveThumbImageError, onInactiveThumbImageError;
  final WidgetStateProperty<Color?>? thumbColor, trackColor, trackOutlineColor;
  final WidgetStateProperty<double?>? trackOutlineWidth;
  final WidgetStateProperty<Icon?>? thumbIcon;
  final MaterialTapTargetSize? materialTapTargetSize;
  final DragStartBehavior dragStartBehavior;
  final MouseCursor? mouseCursor;
  final Color? focusColor, hoverColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final EdgeInsetsGeometry? padding;
  final bool? applyCupertinoTheme;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final switchTheme = SwitchTheme.of(context);
    final disabled = onChanged == null;
    final on = {WidgetState.selected, if (disabled) WidgetState.disabled};
    final off = {if (disabled) WidgetState.disabled};
    final onTrack =
        trackColor?.resolve(on) ??
        activeTrackColor ??
        switchTheme.trackColor?.resolve(on) ??
        activeColor ??
        scheme.primary;
    final onThumb =
        thumbColor?.resolve(on) ??
        activeThumbColor ??
        switchTheme.thumbColor?.resolve(on) ??
        scheme.onPrimary;
    final offTrack =
        trackColor?.resolve(off) ??
        inactiveTrackColor ??
        switchTheme.trackColor?.resolve(off) ??
        scheme.surfaceContainerHighest;
    final offThumb =
        thumbColor?.resolve(off) ??
        inactiveThumbColor ??
        switchTheme.thumbColor?.resolve(off) ??
        scheme.outline;
    final offBorder =
        trackOutlineColor?.resolve(off) ??
        switchTheme.trackOutlineColor?.resolve(off) ??
        scheme.outline;
    final cursor =
        mouseCursor ?? switchTheme.mouseCursor?.resolve(value ? on : off);
    return _NativeControl(
      tag: 'input',
      css:
          '--fd-on-track:${colorCss(onTrack)};--fd-on-thumb:${colorCss(onThumb)};'
          '--fd-off-track:${colorCss(offTrack)};--fd-off-thumb:${colorCss(offThumb)};--fd-off-border:${colorCss(offBorder)};'
          '${cursor == null ? '' : 'cursor:${cursor._css};'}',
      attributes: {
        'type': 'checkbox',
        'role': 'switch',
        'class': 'fd-switch',
        if (disabled) 'disabled': '',
        if (autofocus) 'autofocus': '',
      },
      properties: {'checked': value},
      events: {
        'change': (_, _) => onChanged?.call(!value),
        if (onFocusChange != null) 'focus': (_, _) => onFocusChange!(true),
        if (onFocusChange != null) 'blur': (_, _) => onFocusChange!(false),
      },
    );
  }
}

class Radio<T> extends StatelessWidget {
  const Radio({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusNode,
    this.autofocus = false,
    this.enabled,
    this.backgroundColor,
    this.side,
    this.innerRadius,
  }) : useCupertinoCheckmarkStyle = false;
  const Radio.adaptive({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusNode,
    this.autofocus = false,
    this.useCupertinoCheckmarkStyle = false,
    this.enabled,
    this.backgroundColor,
    this.side,
    this.innerRadius,
  });
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final MouseCursor? mouseCursor;
  final bool toggleable;
  final Color? activeColor, focusColor, hoverColor;
  final WidgetStateProperty<Color?>? fillColor, overlayColor;
  final double? splashRadius;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool useCupertinoCheckmarkStyle;
  final bool? enabled;
  final WidgetStateProperty<Color?>? backgroundColor;
  final BorderSide? side;
  final WidgetStateProperty<double?>? innerRadius;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radioTheme = RadioTheme.of(context);
    final selected = value == groupValue;
    final active = (enabled ?? true) && onChanged != null;
    final states = {
      if (selected) WidgetState.selected,
      if (!active) WidgetState.disabled,
    };
    final color =
        fillColor?.resolve(states) ??
        activeColor ??
        radioTheme.fillColor?.resolve(states) ??
        scheme.primary;
    final cursor = mouseCursor ?? radioTheme.mouseCursor?.resolve(states);
    return _NativeControl(
      tag: 'input',
      css:
          'width:20px;height:20px;margin:10px;flex-shrink:0;accent-color:${colorCss(color)};cursor:${cursor?._css ?? (active ? 'pointer' : 'default')};',
      attributes: {
        'type': 'radio',
        if (!active) 'disabled': '',
        if (autofocus) 'autofocus': '',
      },
      properties: {'checked': selected},
      events: {
        'click': (_, _) {
          if (!active) return;
          if (selected && toggleable) {
            onChanged?.call(null);
          } else if (!selected) {
            onChanged?.call(value);
          }
        },
      },
    );
  }
}

class Slider extends StatelessWidget {
  const Slider({
    super.key,
    required this.value,
    this.secondaryTrackValue,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.secondaryActiveColor,
    this.thumbColor,
    this.overlayColor,
    this.mouseCursor,
    this.semanticFormatterCallback,
    this.focusNode,
    this.autofocus = false,
    this.allowedInteraction,
    this.padding,
    this.showValueIndicator,
    this.year2023,
  });
  const Slider.adaptive({
    super.key,
    required this.value,
    this.secondaryTrackValue,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.mouseCursor,
    this.activeColor,
    this.inactiveColor,
    this.secondaryActiveColor,
    this.thumbColor,
    this.overlayColor,
    this.semanticFormatterCallback,
    this.focusNode,
    this.autofocus = false,
    this.allowedInteraction,
    this.showValueIndicator,
    this.year2023,
  }) : padding = null;
  final double value, min, max;
  final double? secondaryTrackValue;
  final ValueChanged<double>? onChanged, onChangeStart, onChangeEnd;
  final int? divisions;
  final String? label;
  final Color? activeColor, inactiveColor, secondaryActiveColor, thumbColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final MouseCursor? mouseCursor;
  final String Function(double value)? semanticFormatterCallback;
  final FocusNode? focusNode;
  final bool autofocus;
  final SliderInteraction? allowedInteraction;
  final EdgeInsetsGeometry? padding;
  final ShowValueIndicator? showValueIndicator;
  final bool? year2023;
  @override
  Widget build(BuildContext context) {
    if (!(min < max) || !min.isFinite || !max.isFinite)
      throw ArgumentError('Slider requires finite min < max.');
    if (value < min || value > max)
      throw ArgumentError('Slider value must lie between min and max.');
    final sliderTheme = SliderTheme.of(context);
    final disabled = onChanged == null;
    final color = disabled
        ? sliderTheme.disabledActiveTrackColor ??
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
        : activeColor ??
              sliderTheme.activeTrackColor ??
              thumbColor ??
              sliderTheme.thumbColor ??
              Theme.of(context).colorScheme.primary;
    final cursor =
        mouseCursor ??
        sliderTheme.mouseCursor?.resolve({if (disabled) WidgetState.disabled});
    double read(_DomElement element) => double.parse(
      (element.node as JSObject).getProperty<JSString>('value'.toJS).toDart,
    );
    return _NativeControl(
      tag: 'input',
      css:
          'display:block;width:100%;min-width:0;margin:12px 0;accent-color:${colorCss(color)};${padding == null ? '' : edgeInsetsCss('padding', padding)}${cursor == null ? '' : 'cursor:${cursor._css};'}',
      attributes: {
        'type': 'range',
        'min': cssNumber(min),
        'max': cssNumber(max),
        'step': divisions == null || divisions! < 1
            ? 'any'
            : '${(max - min) / divisions!}',
        if (disabled) 'disabled': '',
        if (autofocus) 'autofocus': '',
        if (label != null) 'aria-valuetext': label!,
        if (label == null && semanticFormatterCallback != null)
          'aria-valuetext': semanticFormatterCallback!(value),
      },
      properties: {'value': '$value'},
      events: {
        'input': (element, _) => onChanged?.call(read(element)),
        'pointerdown': (element, _) => onChangeStart?.call(value),
        'change': (element, _) => onChangeEnd?.call(read(element)),
      },
    );
  }
}

class DropdownMenuItem<T> extends StatelessWidget {
  const DropdownMenuItem({
    super.key,
    this.value,
    this.enabled = true,
    required this.child,
    this.onTap,
  });
  final T? value;
  final bool enabled;
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => child;
}

String _optionLabel(Widget child) {
  if (child is Text) {
    final data = child.data ?? child.textSpan?.toPlainText();
    if (data != null) return data;
  }
  throw UnsupportedError('Native dropdown options require Text item children.');
}

/// A native `<select>`: options are plain text, as browsers require.
typedef DropdownButtonBuilder = List<Widget> Function(BuildContext context);

class DropdownButton<T> extends StatelessWidget {
  const DropdownButton({
    super.key,
    required this.items,
    this.selectedItemBuilder,
    this.value,
    this.hint,
    this.disabledHint,
    required this.onChanged,
    this.onTap,
    this.elevation = 8,
    this.style,
    this.underline,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = false,
    this.isExpanded = false,
    this.itemHeight,
    this.menuWidth,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.menuMaxHeight,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius,
    this.padding,
  });
  final List<DropdownMenuItem<T>>? items;
  final DropdownButtonBuilder? selectedItemBuilder;
  final T? value;
  final Widget? hint, disabledHint, underline, icon;
  final ValueChanged<T?>? onChanged;
  final VoidCallback? onTap;
  final int elevation;
  final bool isExpanded, isDense, autofocus;
  final TextStyle? style;
  final Color? iconDisabledColor, iconEnabledColor, focusColor;
  final double iconSize;
  final double? itemHeight, menuWidth, menuMaxHeight;
  final FocusNode? focusNode;
  final Color? dropdownColor;
  final bool? enableFeedback;
  final AlignmentGeometry alignment;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) => _Select<T>(
    entries: [
      for (final item in items ?? <DropdownMenuItem<T>>[])
        (item.value, _optionLabel(item.child), item.enabled),
    ],
    value: value,
    placeholder: hint == null ? null : _optionLabel(hint!),
    onChanged: items == null || items!.isEmpty ? null : onChanged,
    expanded: isExpanded,
    style: style,
    // Flutter draws a default underline unless one is given or an ancestor
    // hides it; a given underline other than an empty box draws a line.
    underline: underline == null
        ? context
                  .dependOnInheritedWidgetOfExactType<
                    DropdownButtonHideUnderline
                  >() ==
              null
        : underline is! SizedBox,
    background: dropdownColor,
    onTap: onTap,
  );
}

/// Hides the default underline of descendant [DropdownButton]s.
class DropdownButtonHideUnderline extends InheritedWidget {
  const DropdownButtonHideUnderline({super.key, required super.child});
  @override
  bool updateShouldNotify(DropdownButtonHideUnderline oldWidget) => false;
}

class _Select<T> extends StatelessWidget {
  const _Select({
    required this.entries,
    required this.value,
    required this.placeholder,
    required this.onChanged,
    required this.expanded,
    required this.style,
    this.underline = true,
    this.label,
    this.background,
    this.onTap,
  });
  final Color? background;
  final VoidCallback? onTap;
  final List<(T?, String, bool)> entries;
  final T? value;
  final String? placeholder, label;
  final ValueChanged<T?>? onChanged;
  final bool expanded, underline;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = entries.indexWhere((entry) => entry.$1 == value);
    final textStyle = theme.textTheme.titleMedium!
        .copyWith(color: theme.colorScheme.onSurface)
        .merge(style);
    final placeholderOption = placeholder != null || index < 0;
    return _SelectBox(
      css:
          'font:inherit;${textStyleCss(textStyle)}box-sizing:border-box;min-height:48px;padding:8px 4px;border:0;${underline ? 'border-bottom:1px solid ${colorCss(theme.colorScheme.outline)};' : ''}background-color:${background == null ? 'transparent' : colorCss(background!)};${expanded ? 'width:100%;' : ''}',
      attributes: {
        if (onChanged == null) 'disabled': '',
        if (label != null) 'aria-label': label!,
      },
      expanded: expanded,
      // The DOM option index of the selected entry.
      selectedIndex: index < 0 ? 0 : index + (placeholderOption ? 1 : 0),
      onSelect: (i) => onChanged?.call(entries[i].$1),
      onTap: onTap,
      options: [
        if (placeholderOption)
          _Box(
            tag: 'option',
            attributes: const {'value': '-1', 'disabled': ''},
            fill: _Fill.none,
            children: [Text(placeholder ?? '')],
          ),
        for (var i = 0; i < entries.length; i++)
          _Box(
            tag: 'option',
            attributes: {'value': '$i', if (!entries[i].$3) 'disabled': ''},
            fill: _Fill.none,
            children: [Text(entries[i].$2)],
          ),
      ],
    );
  }
}

class _SelectBox extends _DomWidget {
  const _SelectBox({
    required this.css,
    required this.attributes,
    required this.expanded,
    required this.selectedIndex,
    required this.onSelect,
    required this.options,
    this.onTap,
  });
  final VoidCallback? onTap;
  final String css;
  final Map<String, String> attributes;
  final bool expanded;
  final int selectedIndex;
  final void Function(int index) onSelect;
  final List<Widget> options;
  @override
  String get _tag => 'select';
  @override
  _Fill get _fill => expanded ? _Fill.expand : _Fill.none;
  @override
  void _render(_DomBuilder out) {
    out.css(css);
    out.attributes.addAll(attributes);
    out.children = options;
    out.properties['selectedIndex'] = selectedIndex;
    final element = out.context;
    if (onTap != null) out.on('click', (_) => onTap!());
    out.on('change', (_) {
      final raw = (element.node as JSObject)
          .getProperty<JSString>('value'.toJS)
          .toDart;
      final selected = int.tryParse(raw) ?? -1;
      if (selected >= 0) onSelect(selected);
      // Controlled: show the widget's selection until the app rebuilds.
      element._setLiveProperty(
        'selectedIndex',
        (element.widget as _SelectBox).selectedIndex,
      );
    });
  }
}

class DropdownButtonFormField<T> extends FormField<T> {
  DropdownButtonFormField({
    super.key,
    required List<DropdownMenuItem<T>>? items,
    DropdownButtonBuilder? selectedItemBuilder,
    T? value,
    T? initialValue,
    Widget? hint,
    Widget? disabledHint,
    required ValueChanged<T?>? onChanged,
    VoidCallback? onTap,
    int elevation = 8,
    TextStyle? style,
    Widget? icon,
    Color? iconDisabledColor,
    Color? iconEnabledColor,
    double iconSize = 24.0,
    bool isDense = true,
    bool isExpanded = false,
    double? itemHeight,
    Color? focusColor,
    FocusNode? focusNode,
    bool autofocus = false,
    Color? dropdownColor,
    InputDecoration? decoration,
    super.onSaved,
    super.validator,
    super.forceErrorText,
    super.autovalidateMode,
    double? menuMaxHeight,
    bool? enableFeedback,
    AlignmentGeometry alignment = AlignmentDirectional.centerStart,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) : super(
         initialValue: initialValue ?? value,
         builder: (field) => _InputDecorator(
           id: 'fd-select-${field.hashCode}',
           decoration: (decoration ?? const InputDecoration()).copyWith(
             errorText: field.errorText,
           ),
           focused: false,
           enabled: onChanged != null,
           counter: null,
           child: DropdownButton<T>(
             items: items,
             value: field.value,
             hint: hint,
             disabledHint: disabledHint,
             isExpanded: true,
             style: style,
             onTap: onTap,
             dropdownColor: dropdownColor,
             underline: const SizedBox.shrink(),
             onChanged: onChanged == null
                 ? null
                 : (next) {
                     field.didChange(next);
                     onChanged(next);
                   },
           ),
         ),
       );
}

typedef FilterCallback<T> =
    List<DropdownMenuEntry<T>> Function(
      List<DropdownMenuEntry<T>> entries,
      String filter,
    );

typedef SearchCallback<T> =
    int? Function(List<DropdownMenuEntry<T>> entries, String query);

enum DropdownMenuCloseBehavior { all, self, none }

class DropdownMenuEntry<T> {
  const DropdownMenuEntry({
    required this.value,
    required this.label,
    this.labelWidget,
    this.leadingIcon,
    this.trailingIcon,
    this.enabled = true,
    this.style,
  });
  final T value;
  final String label;
  final Widget? labelWidget, leadingIcon, trailingIcon;
  final bool enabled;
  final ButtonStyle? style;
}

/// A Material dropdown menu rendered as a native `<select>` inside an
/// outlined field. Filtering and search are left to the browser's select.
class DropdownMenu<T> extends StatelessWidget {
  const DropdownMenu({
    super.key,
    this.enabled = true,
    this.width,
    this.menuHeight,
    this.leadingIcon,
    this.trailingIcon,
    this.showTrailingIcon = true,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.selectedTrailingIcon,
    this.enableFilter = false,
    this.enableSearch = true,
    this.keyboardType,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.inputDecorationTheme,
    this.menuStyle,
    this.controller,
    this.initialSelection,
    this.onSelected,
    this.focusNode,
    this.requestFocusOnTap,
    this.expandedInsets,
    this.filterCallback,
    this.searchCallback,
    this.alignmentOffset,
    required this.dropdownMenuEntries,
    this.inputFormatters,
    this.closeBehavior = DropdownMenuCloseBehavior.all,
    this.maxLines = 1,
    this.textInputAction,
    this.restorationId,
  });
  final bool enabled;
  final double? width, menuHeight;
  final Widget? leadingIcon, trailingIcon, selectedTrailingIcon, label;
  final bool showTrailingIcon;
  final String? hintText, helperText, errorText;
  final bool enableFilter, enableSearch;
  final TextInputType? keyboardType;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final InputDecorationTheme? inputDecorationTheme;
  final MenuStyle? menuStyle;
  final TextEditingController? controller;
  final T? initialSelection;
  final ValueChanged<T?>? onSelected;
  final FocusNode? focusNode;
  final bool? requestFocusOnTap;
  final EdgeInsetsGeometry? expandedInsets;
  final FilterCallback<T>? filterCallback;
  final SearchCallback<T>? searchCallback;
  final Offset? alignmentOffset;
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;
  final List<TextInputFormatter>? inputFormatters;
  final DropdownMenuCloseBehavior closeBehavior;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final String? restorationId;
  @override
  Widget build(BuildContext context) => _DropdownMenuBody<T>(menu: this);
}

class _DropdownMenuBody<T> extends StatefulWidget {
  const _DropdownMenuBody({required this.menu});
  final DropdownMenu<T> menu;
  @override
  State<_DropdownMenuBody<T>> createState() => _DropdownMenuBodyState<T>();
}

class _DropdownMenuBodyState<T> extends State<_DropdownMenuBody<T>> {
  late T? selected = widget.menu.initialSelection;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  void _syncController() {
    final controller = widget.menu.controller;
    if (controller == null) return;
    for (final entry in widget.menu.dropdownMenuEntries) {
      if (entry.value == selected) {
        if (controller.text != entry.label) controller.text = entry.label;
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final menuTheme = DropdownMenuTheme.of(context);
    final fieldTheme =
        menu.inputDecorationTheme ?? menuTheme.inputDecorationTheme;
    var decoration = InputDecoration(
      label: menu.label,
      helperText: menu.helperText,
      errorText: menu.errorText,
      prefixIcon: menu.leadingIcon,
      suffixIcon: menu.showTrailingIcon ? menu.trailingIcon : null,
    );
    decoration = fieldTheme == null
        ? decoration.copyWith(border: const OutlineInputBorder())
        : decoration.applyDefaults(fieldTheme);
    decoration = decoration.copyWith(
      border: decoration.border ?? const OutlineInputBorder(),
    );
    final field = _InputDecorator(
      id: 'fd-menu-$hashCode',
      decoration: decoration,
      focused: false,
      enabled: menu.enabled,
      counter: null,
      child: _Select<T>(
        entries: [
          for (final entry in menu.dropdownMenuEntries)
            (entry.value, entry.label, entry.enabled),
        ],
        value: selected,
        placeholder: menu.hintText,
        expanded: true,
        style: menu.textStyle ?? menuTheme.textStyle,
        underline: false,
        background: menu.menuStyle?.backgroundColor?.resolve(const {}),
        label: menu.label is Text ? (menu.label as Text).data : null,
        onChanged: menu.enabled
            ? (value) {
                setState(() => selected = value);
                _syncController();
                menu.onSelected?.call(value);
              }
            : null,
      ),
    );
    final insets = menu.expandedInsets;
    if (insets != null) return Padding(padding: insets, child: field);
    return menu.width == null
        ? field
        : SizedBox(width: menu.width, child: field);
  }
}

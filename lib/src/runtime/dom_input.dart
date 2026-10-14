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
    this.label,
    this.labelText,
    this.labelStyle,
    this.floatingLabelBehavior,
    this.helperText,
    this.helperStyle,
    this.hintText,
    this.hintStyle,
    this.errorText,
    this.errorStyle,
    this.isDense,
    this.contentPadding,
    this.prefixIcon,
    this.prefix,
    this.prefixText,
    this.suffixIcon,
    this.suffix,
    this.suffixText,
    this.counterText,
    this.filled,
    this.fillColor,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.enabled = true,
    this.semanticCounterText,
  });
  const InputDecoration.collapsed({
    required this.hintText,
    this.hintStyle,
    this.filled = false,
    this.fillColor,
    this.border = InputBorder.none,
    this.enabled = true,
  }) : icon = null,
       label = null,
       labelText = null,
       labelStyle = null,
       floatingLabelBehavior = null,
       helperText = null,
       helperStyle = null,
       errorText = null,
       errorStyle = null,
       isDense = true,
       contentPadding = EdgeInsets.zero,
       prefixIcon = null,
       prefix = null,
       prefixText = null,
       suffixIcon = null,
       suffix = null,
       suffixText = null,
       counterText = null,
       enabledBorder = null,
       focusedBorder = null,
       errorBorder = null,
       semanticCounterText = null;
  final Widget? icon, label, prefixIcon, prefix, suffixIcon, suffix;
  final String? labelText, helperText, hintText, errorText;
  final String? prefixText, suffixText, counterText, semanticCounterText;
  final TextStyle? labelStyle, helperStyle, hintStyle, errorStyle;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final bool? isDense, filled;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final InputBorder? border, enabledBorder, focusedBorder, errorBorder;
  final bool enabled;

  InputDecoration copyWith({
    String? labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? counterText,
    bool? filled,
    Color? fillColor,
    InputBorder? border,
    EdgeInsetsGeometry? contentPadding,
    bool? isDense,
    bool? enabled,
  }) => InputDecoration(
    icon: icon,
    label: label,
    labelText: labelText ?? this.labelText,
    labelStyle: labelStyle,
    floatingLabelBehavior: floatingLabelBehavior,
    helperText: helperText ?? this.helperText,
    helperStyle: helperStyle,
    hintText: hintText ?? this.hintText,
    hintStyle: hintStyle,
    errorText: errorText ?? this.errorText,
    errorStyle: errorStyle,
    isDense: isDense ?? this.isDense,
    contentPadding: contentPadding ?? this.contentPadding,
    prefixIcon: prefixIcon ?? this.prefixIcon,
    prefix: prefix,
    prefixText: prefixText,
    suffixIcon: suffixIcon ?? this.suffixIcon,
    suffix: suffix,
    suffixText: suffixText,
    counterText: counterText ?? this.counterText,
    filled: filled ?? this.filled,
    fillColor: fillColor ?? this.fillColor,
    border: border ?? this.border,
    enabledBorder: enabledBorder,
    focusedBorder: focusedBorder,
    errorBorder: errorBorder,
    enabled: enabled ?? this.enabled,
    semanticCounterText: semanticCounterText,
  );
}

var _nextFieldId = 0;

// ---------------------------------------------------------------------------
// Text fields.

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
  });
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
    final error = decoration.errorText != null;
    final borderColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.12)
        : error
        ? scheme.error
        : focused
        ? scheme.primary
        : scheme.outline;
    final chosen =
        (error ? decoration.errorBorder : null) ??
        (focused ? decoration.focusedBorder : decoration.enabledBorder) ??
        decoration.border ??
        const UnderlineInputBorder();
    final side = chosen.borderSide;
    final explicitColor =
        identical(chosen, decoration.border) ||
        side.color == const Color(0xff000000);
    final color = explicitColor ? borderColor : side.color;
    final width = focused && !(chosen is _NoInputBorder) ? 2.0 : 1.0;
    final filled = decoration.filled ?? false;
    final dense = decoration.isDense ?? false;
    final padding =
        decoration.contentPadding ??
        (chosen is OutlineInputBorder
            ? EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 8 : 12)
            : EdgeInsets.symmetric(
                horizontal: filled ? 12 : 0,
                vertical: dense ? 6 : 8,
              ));
    final labelColor = error
        ? scheme.error
        : focused
        ? scheme.primary
        : scheme.onSurfaceVariant;
    final label =
        decoration.label ??
        (decoration.labelText == null ? null : Text(decoration.labelText!));
    final message = decoration.errorText ?? decoration.helperText;
    final messageStyle = theme.textTheme.bodySmall!
        .copyWith(color: error ? scheme.error : scheme.onSurfaceVariant)
        .merge(error ? decoration.errorStyle : decoration.helperStyle);
    final iconTheme = IconThemeData(
      color: error ? scheme.error : scheme.onSurfaceVariant,
      size: 24,
    );
    return _Box(
      css: 'display:flex;flex-direction:column;min-width:0;',
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [
        _Box(
          css:
              'display:flex;flex-direction:row;align-items:center;gap:12px;box-sizing:border-box;min-width:0;'
              '${chosen._css(color, chosen is _NoInputBorder ? 0 : width)}'
              '${filled ? 'background-color:${colorCss(decoration.fillColor ?? scheme.surfaceContainerHighest)};' : ''}'
              '${edgeInsetsCss('padding', padding)}',
          layout: _DomLayout.row,
          fill: _Fill.expand,
          children: [
            if (decoration.prefixIcon != null)
              IconTheme.merge(data: iconTheme, child: decoration.prefixIcon!),
            _Box(
              css: 'flex:1 1 0;min-width:0;display:flex;flex-direction:column;',
              layout: _DomLayout.column,
              children: [
                if (label != null)
                  _Box(
                    tag: 'label',
                    attributes: {'for': id},
                    fill: _Fill.none,
                    children: [
                      DefaultTextStyle(
                        style: theme.textTheme.bodySmall!
                            .copyWith(color: labelColor)
                            .merge(decoration.labelStyle),
                        child: label,
                      ),
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
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    _Box(css: 'flex:1 1 0;min-width:0;', children: [child]),
                    if (decoration.suffixText != null)
                      Text(
                        decoration.suffixText!,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (decoration.suffix != null) decoration.suffix!,
                  ],
                ),
              ],
            ),
            if (decoration.suffixIcon != null)
              IconTheme.merge(data: iconTheme, child: decoration.suffixIcon!),
          ],
        ),
        if (message != null || counter != null)
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
                  if (message != null) Text(message, style: messageStyle),
                ],
              ),
              if (counter != null)
                DefaultTextStyle(
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  child: counter!,
                ),
            ],
          ),
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

class Checkbox extends StatelessWidget {
  const Checkbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.activeColor,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate;
  final Color? activeColor;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;
  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? Theme.of(context).colorScheme.primary;
    return _NativeControl(
      tag: 'input',
      css:
          'width:18px;height:18px;margin:11px;flex-shrink:0;accent-color:${colorCss(color)};cursor:${onChanged == null ? 'default' : 'pointer'};',
      attributes: {
        'type': 'checkbox',
        if (onChanged == null) 'disabled': '',
        if (semanticLabel != null) 'aria-label': semanticLabel!,
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
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.thumbIcon,
    this.focusNode,
    this.autofocus = false,
  });
  const Switch.adaptive({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.thumbIcon,
    this.focusNode,
    this.autofocus = false,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor, activeTrackColor;
  final Color? inactiveThumbColor, inactiveTrackColor;
  final Object? thumbIcon;
  final FocusNode? focusNode;
  final bool autofocus;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _NativeControl(
      tag: 'input',
      css:
          '--fd-on-track:${colorCss(activeTrackColor ?? activeColor ?? scheme.primary)};--fd-on-thumb:${colorCss(scheme.onPrimary)};'
          '--fd-off-track:${colorCss(inactiveTrackColor ?? scheme.surfaceContainerHighest)};--fd-off-thumb:${colorCss(inactiveThumbColor ?? scheme.outline)};--fd-off-border:${colorCss(scheme.outline)};',
      attributes: {
        'type': 'checkbox',
        'role': 'switch',
        'class': 'fd-switch',
        if (onChanged == null) 'disabled': '',
      },
      properties: {'checked': value},
      events: {'change': (_, _) => onChanged?.call(!value)},
    );
  }
}

class Radio<T> extends StatelessWidget {
  const Radio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.toggleable = false,
    this.activeColor,
    this.focusNode,
    this.autofocus = false,
  });
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final bool toggleable;
  final Color? activeColor;
  final FocusNode? focusNode;
  final bool autofocus;
  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? Theme.of(context).colorScheme.primary;
    final selected = value == groupValue;
    return _NativeControl(
      tag: 'input',
      css:
          'width:20px;height:20px;margin:10px;flex-shrink:0;accent-color:${colorCss(color)};cursor:${onChanged == null ? 'default' : 'pointer'};',
      attributes: {'type': 'radio', if (onChanged == null) 'disabled': ''},
      properties: {'checked': selected},
      events: {
        'click': (_, _) {
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
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.activeColor,
    this.semanticFormatterCallback,
  });
  final double value, min, max;
  final ValueChanged<double>? onChanged, onChangeStart, onChangeEnd;
  final int? divisions;
  final String? label;
  final Color? activeColor;
  final String Function(double value)? semanticFormatterCallback;
  @override
  Widget build(BuildContext context) {
    if (!(min < max) || !min.isFinite || !max.isFinite)
      throw ArgumentError('Slider requires finite min < max.');
    if (value < min || value > max)
      throw ArgumentError('Slider value must lie between min and max.');
    final color = activeColor ?? Theme.of(context).colorScheme.primary;
    double read(_DomElement element) => double.parse(
      (element.node as JSObject).getProperty<JSString>('value'.toJS).toDart,
    );
    return _NativeControl(
      tag: 'input',
      css:
          'display:block;width:100%;min-width:0;margin:12px 0;accent-color:${colorCss(color)};',
      attributes: {
        'type': 'range',
        'min': cssNumber(min),
        'max': cssNumber(max),
        'step': divisions == null || divisions! < 1
            ? 'any'
            : '${(max - min) / divisions!}',
        if (onChanged == null) 'disabled': '',
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
class DropdownButton<T> extends StatelessWidget {
  const DropdownButton({
    super.key,
    required this.items,
    this.value,
    this.hint,
    this.disabledHint,
    required this.onChanged,
    this.isExpanded = false,
    this.style,
    this.underline,
    this.icon,
    this.isDense = false,
    this.dropdownColor,
    this.borderRadius,
    this.selectedItemBuilder,
    this.onTap,
    this.elevation = 8,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24,
    this.itemHeight,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.menuMaxHeight,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
    this.padding,
  });
  final List<Widget> Function(BuildContext context)? selectedItemBuilder;
  final VoidCallback? onTap;
  final int elevation;
  final Color? iconDisabledColor, iconEnabledColor, focusColor;
  final double iconSize;
  final double? itemHeight, menuMaxHeight;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool? enableFeedback;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;
  final List<DropdownMenuItem<T>>? items;
  final T? value;
  final Widget? hint, disabledHint, underline, icon;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded, isDense;
  final TextStyle? style;
  final Color? dropdownColor;
  final BorderRadius? borderRadius;
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
  });
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
          'font:inherit;${textStyleCss(textStyle)}box-sizing:border-box;min-height:48px;padding:8px 4px;border:0;${underline ? 'border-bottom:1px solid ${colorCss(theme.colorScheme.outline)};' : ''}background-color:transparent;${expanded ? 'width:100%;' : ''}',
      attributes: {
        if (onChanged == null) 'disabled': '',
        if (label != null) 'aria-label': label!,
      },
      expanded: expanded,
      // The DOM option index of the selected entry.
      selectedIndex: index < 0 ? 0 : index + (placeholderOption ? 1 : 0),
      onSelect: (i) => onChanged?.call(entries[i].$1),
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
  });
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
    T? value,
    T? initialValue,
    Widget? hint,
    required ValueChanged<T?>? onChanged,
    InputDecoration? decoration,
    super.onSaved,
    super.validator,
    super.autovalidateMode,
    bool isExpanded = false,
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
             isExpanded: true,
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

class DropdownMenuEntry<T> {
  const DropdownMenuEntry({
    required this.value,
    required this.label,
    this.enabled = true,
    this.leadingIcon,
  });
  final T value;
  final String label;
  final bool enabled;
  final Widget? leadingIcon;
}

class DropdownMenu<T> extends StatelessWidget {
  const DropdownMenu({
    super.key,
    required this.dropdownMenuEntries,
    this.initialSelection,
    this.onSelected,
    this.label,
    this.hintText,
    this.width,
    this.enabled = true,
    this.expandedInsets,
  });
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;
  final T? initialSelection;
  final ValueChanged<T?>? onSelected;
  final Widget? label;
  final String? hintText;
  final double? width;
  final bool enabled;
  final EdgeInsetsGeometry? expandedInsets;
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
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final field = _InputDecorator(
      id: 'fd-menu-$hashCode',
      decoration: InputDecoration(
        label: menu.label,
        border: const OutlineInputBorder(),
      ),
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
        style: null,
        underline: false,
        label: menu.label is Text ? (menu.label as Text).data : null,
        onChanged: menu.enabled
            ? (value) {
                setState(() => selected = value);
                menu.onSelected?.call(value);
              }
            : null,
      ),
    );
    return menu.width == null
        ? field
        : SizedBox(width: menu.width, child: field);
  }
}

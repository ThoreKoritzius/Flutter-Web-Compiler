part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Autocomplete: a text field with an ARIA combobox and a listbox of options
// below it; arrow keys move the highlight and Enter selects.

typedef AutocompleteOptionsBuilder<T extends Object> =
    FutureOr<Iterable<T>> Function(TextEditingValue textEditingValue);
typedef AutocompleteOnSelected<T extends Object> = void Function(T option);
typedef AutocompleteOptionToString<T extends Object> =
    String Function(T option);
typedef AutocompleteFieldViewBuilder =
    Widget Function(
      BuildContext context,
      TextEditingController textEditingController,
      FocusNode focusNode,
      VoidCallback onFieldSubmitted,
    );
typedef AutocompleteOptionsViewBuilder<T extends Object> =
    Widget Function(
      BuildContext context,
      AutocompleteOnSelected<T> onSelected,
      Iterable<T> options,
    );

enum OptionsViewOpenDirection { up, down }

/// The index of the highlighted option, for custom options views.
class AutocompleteHighlightedOption extends InheritedWidget {
  const AutocompleteHighlightedOption({
    super.key,
    required this.highlightIndexNotifier,
    required super.child,
  });
  final ValueNotifier<int> highlightIndexNotifier;
  static int of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AutocompleteHighlightedOption>()
          ?.highlightIndexNotifier
          .value ??
      0;
  @override
  bool updateShouldNotify(AutocompleteHighlightedOption oldWidget) =>
      oldWidget.highlightIndexNotifier != highlightIndexNotifier;
}

class RawAutocomplete<T extends Object> extends StatefulWidget {
  const RawAutocomplete({
    super.key,
    required this.optionsViewBuilder,
    required this.optionsBuilder,
    this.optionsViewOpenDirection = OptionsViewOpenDirection.down,
    this.displayStringForOption = defaultStringForOption,
    this.fieldViewBuilder,
    this.focusNode,
    this.onSelected,
    this.textEditingController,
    this.initialValue,
  });
  final AutocompleteOptionsViewBuilder<T> optionsViewBuilder;
  final AutocompleteOptionsBuilder<T> optionsBuilder;
  final OptionsViewOpenDirection optionsViewOpenDirection;
  final AutocompleteOptionToString<T> displayStringForOption;
  final AutocompleteFieldViewBuilder? fieldViewBuilder;
  final FocusNode? focusNode;
  final AutocompleteOnSelected<T>? onSelected;
  final TextEditingController? textEditingController;
  final TextEditingValue? initialValue;

  static String defaultStringForOption(Object? option) => option.toString();

  @override
  State<RawAutocomplete<T>> createState() => _RawAutocompleteState<T>();
}

class _RawAutocompleteState<T extends Object>
    extends State<RawAutocomplete<T>> {
  late final TextEditingController _controller =
      widget.textEditingController ??
      TextEditingController.fromValue(widget.initialValue);
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  final _highlight = ValueNotifier<int>(0);
  Iterable<T> _options = const [];
  bool _open = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _focus.addListener(_focusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _focus.removeListener(_focusChanged);
    if (widget.textEditingController == null) _controller.dispose();
    if (widget.focusNode == null) _focus.dispose();
    _highlight.dispose();
    super.dispose();
  }

  void _focusChanged() {
    if (_focus.hasFocus) {
      _changed();
    } else {
      // Let a click on an option land before closing.
      Timer(const Duration(milliseconds: 150), () {
        if (mounted && !_focus.hasFocus) setState(() => _open = false);
      });
    }
  }

  Future<void> _changed() async {
    final request = ++_request;
    final options = await widget.optionsBuilder(_controller.value);
    if (!mounted || request != _request) return;
    setState(() {
      _options = options;
      _open = _focus.hasFocus && options.isNotEmpty;
      _highlight.value = 0;
    });
  }

  void _select(T option) {
    final text = widget.displayStringForOption(option);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _open = false);
    widget.onSelected?.call(option);
  }

  void _submit() {
    if (_open && _options.isNotEmpty) {
      _select(
        _options.elementAt(_highlight.value.clamp(0, _options.length - 1)),
      );
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || !_open || _options.isEmpty) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      final step = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      setState(
        () => _highlight.value = (_highlight.value + step) % _options.length,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      setState(() => _open = false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter) {
      _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final field =
        widget.fieldViewBuilder?.call(context, _controller, _focus, _submit) ??
        TextField(
          controller: _controller,
          focusNode: _focus,
          onSubmitted: (_) => _submit(),
        );
    final up = widget.optionsViewOpenDirection == OptionsViewOpenDirection.up;
    return Focus(
      onKeyEvent: _key,
      child: _Box(
        css:
            'position:relative;display:grid;grid-template-columns:minmax(0,1fr);',
        attributes: {
          'role': 'combobox',
          'aria-expanded': '$_open',
          'aria-haspopup': 'listbox',
        },
        layout: _DomLayout.grid,
        fill: _Fill.expand,
        children: [
          field,
          if (_open)
            _Box(
              key: const ValueKey('options'),
              css:
                  'position:absolute;left:0;right:0;${up ? 'bottom:100%;' : 'top:100%;'}z-index:10;',
              attributes: const {'role': 'listbox'},
              fill: _Fill.expand,
              children: [
                AutocompleteHighlightedOption(
                  highlightIndexNotifier: _highlight,
                  child: Builder(
                    builder: (context) =>
                        widget.optionsViewBuilder(context, _select, _options),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class Autocomplete<T extends Object> extends StatelessWidget {
  const Autocomplete({
    super.key,
    required this.optionsBuilder,
    this.displayStringForOption = RawAutocomplete.defaultStringForOption,
    this.fieldViewBuilder = _defaultFieldView,
    this.onSelected,
    this.optionsMaxHeight = 200,
    this.optionsViewBuilder,
    this.optionsViewOpenDirection = OptionsViewOpenDirection.down,
    this.initialValue,
    this.textEditingController,
    this.focusNode,
  });
  final AutocompleteOptionsBuilder<T> optionsBuilder;
  final AutocompleteOptionToString<T> displayStringForOption;
  final AutocompleteFieldViewBuilder fieldViewBuilder;
  final AutocompleteOnSelected<T>? onSelected;
  final double optionsMaxHeight;
  final AutocompleteOptionsViewBuilder<T>? optionsViewBuilder;
  final OptionsViewOpenDirection optionsViewOpenDirection;
  final TextEditingValue? initialValue;
  final TextEditingController? textEditingController;
  final FocusNode? focusNode;

  static Widget _defaultFieldView(
    BuildContext context,
    TextEditingController controller,
    FocusNode focusNode,
    VoidCallback onFieldSubmitted,
  ) => TextField(
    controller: controller,
    focusNode: focusNode,
    onSubmitted: (_) => onFieldSubmitted(),
  );

  @override
  Widget build(BuildContext context) => RawAutocomplete<T>(
    optionsBuilder: optionsBuilder,
    displayStringForOption: displayStringForOption,
    fieldViewBuilder: fieldViewBuilder,
    onSelected: onSelected,
    initialValue: initialValue,
    textEditingController: textEditingController,
    focusNode: focusNode,
    optionsViewOpenDirection: optionsViewOpenDirection,
    optionsViewBuilder:
        optionsViewBuilder ??
        (context, onSelected, options) {
          final highlighted = AutocompleteHighlightedOption.of(context);
          final scheme = Theme.of(context).colorScheme;
          return Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: optionsMaxHeight),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final (index, option) in options.indexed)
                    _Box(
                      key: ValueKey(index),
                      tag: 'div',
                      css:
                          'padding:16px;cursor:pointer;${index == highlighted ? 'background-color:${colorCss(scheme.onSurface.withValues(alpha: 0.08))};' : ''}',
                      attributes: {
                        'role': 'option',
                        'aria-selected': '${index == highlighted}',
                      },
                      handlers: {
                        // Selecting on pointerdown keeps the field focused.
                        'pointerdown': (event) {
                          event?.preventDefault();
                          onSelected(option);
                        },
                      },
                      fill: _Fill.expand,
                      children: [Text(displayStringForOption(option))],
                    ),
                ],
              ),
            ),
          );
        },
  );
}

// ---------------------------------------------------------------------------
// Material 3 search: a pill-shaped bar, and a view of suggestions that
// opens over the page.

class SearchController extends TextEditingController {
  SearchController();
  _SearchViewHost? _host;
  bool get isAttached => _host != null;
  bool get isOpen => _host?.open ?? false;
  void openView() => _host?.openView();
  void closeView(String? selectedText) => _host?.closeView(selectedText);
}

abstract class _SearchViewHost {
  bool get open;
  void openView();
  void closeView(String? selectedText);
}

class SearchBar extends StatelessWidget {
  const SearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.leading,
    this.trailing,
    this.onTap,
    this.onTapOutside,
    this.onChanged,
    this.onSubmitted,
    this.constraints,
    this.elevation,
    this.backgroundColor,
    this.shadowColor,
    this.surfaceTintColor,
    this.overlayColor,
    this.side,
    this.shape,
    this.padding,
    this.textStyle,
    this.hintStyle,
    this.textCapitalization,
    this.enabled = true,
    this.autoFocus = false,
    this.textInputAction,
    this.keyboardType,
    this.scrollPadding = const EdgeInsets.all(20),
    this.contextMenuBuilder,
  });
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final Widget? leading;
  final Iterable<Widget>? trailing;
  final GestureTapCallback? onTap;
  final Object? onTapOutside, contextMenuBuilder;
  final ValueChanged<String>? onChanged, onSubmitted;
  final BoxConstraints? constraints;
  final WidgetStateProperty<double?>? elevation;
  final WidgetStateProperty<Color?>? backgroundColor, shadowColor;
  final WidgetStateProperty<Color?>? surfaceTintColor, overlayColor;
  final WidgetStateProperty<BorderSide?>? side;
  final WidgetStateProperty<OutlinedBorder?>? shape;
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;
  final WidgetStateProperty<TextStyle?>? textStyle, hintStyle;
  final TextCapitalization? textCapitalization;
  final bool enabled, autoFocus;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final EdgeInsets scrollPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const states = <WidgetState>{};
    final background =
        backgroundColor?.resolve(states) ?? scheme.surfaceContainerHigh;
    final shapeValue = shape?.resolve(states) ?? const StadiumBorder();
    final sideValue = side?.resolve(states);
    final style = theme.textTheme.bodyLarge!
        .copyWith(color: scheme.onSurface)
        .merge(textStyle?.resolve(states));
    final hint = theme.textTheme.bodyLarge!
        .copyWith(color: scheme.onSurfaceVariant)
        .merge(hintStyle?.resolve(states));
    final box =
        constraints ?? const BoxConstraints(minWidth: 360, minHeight: 56);
    return _Box(
      css:
          'display:flex;align-items:center;gap:8px;box-sizing:border-box;min-height:${px(box.minHeight)};max-width:${box.maxWidth.isFinite ? px(box.maxWidth) : '100%'};${edgeInsetsCss('padding', padding?.resolve(states) ?? const EdgeInsets.symmetric(horizontal: 8))}background-color:${colorCss(background)};${shapeCss(shapeValue)}${sideValue == null ? '' : borderSideCss('border', sideValue)}${elevationCss(elevation?.resolve(states) ?? 6, shadowColor?.resolve(states) ?? scheme.shadow)}',
      attributes: const {'role': 'search'},
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        if (leading != null)
          IconTheme.merge(
            data: IconThemeData(color: scheme.onSurface),
            child: leading!,
          ),
        _FlexFill(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onTap: onTap,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            enabled: enabled,
            autofocus: autoFocus,
            textInputAction: textInputAction ?? TextInputAction.search,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization ?? TextCapitalization.none,
            style: style,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: hint,
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        if (trailing != null)
          IconTheme.merge(
            data: IconThemeData(color: scheme.onSurfaceVariant),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [...trailing!],
            ),
          ),
      ],
    );
  }
}

typedef SearchAnchorChildBuilder =
    Widget Function(BuildContext context, SearchController controller);
typedef SuggestionsBuilder =
    FutureOr<Iterable<Widget>> Function(
      BuildContext context,
      SearchController controller,
    );
typedef ViewBuilder = Widget Function(Iterable<Widget> suggestions);

class SearchAnchor extends StatefulWidget {
  const SearchAnchor({
    super.key,
    this.isFullScreen,
    this.searchController,
    this.viewBuilder,
    this.viewLeading,
    this.viewTrailing,
    this.viewHintText,
    this.viewBackgroundColor,
    this.viewElevation,
    this.viewSurfaceTintColor,
    this.viewSide,
    this.viewShape,
    this.viewBarPadding,
    this.headerHeight,
    this.headerTextStyle,
    this.headerHintStyle,
    this.dividerColor,
    this.viewConstraints,
    this.viewPadding,
    this.shrinkWrap,
    this.textCapitalization,
    this.viewOnChanged,
    this.viewOnSubmitted,
    this.viewOnClose,
    this.viewOnOpen,
    required this.builder,
    required this.suggestionsBuilder,
    this.textInputAction,
    this.keyboardType,
    this.enabled = true,
  }) : _bar = null;

  SearchAnchor.bar({
    super.key,
    Widget? barLeading,
    Iterable<Widget>? barTrailing,
    String? barHintText,
    GestureTapCallback? onTap,
    ValueChanged<String>? onSubmitted,
    ValueChanged<String>? onChanged,
    VoidCallback? onClose,
    WidgetStateProperty<double?>? barElevation,
    WidgetStateProperty<Color?>? barBackgroundColor,
    WidgetStateProperty<Color?>? barOverlayColor,
    WidgetStateProperty<BorderSide?>? barSide,
    WidgetStateProperty<OutlinedBorder?>? barShape,
    WidgetStateProperty<EdgeInsetsGeometry?>? barPadding,
    WidgetStateProperty<TextStyle?>? barTextStyle,
    WidgetStateProperty<TextStyle?>? barHintStyle,
    BoxConstraints? constraints,
    this.viewBuilder,
    this.viewLeading,
    this.viewTrailing,
    String? viewHintText,
    this.viewBackgroundColor,
    this.viewElevation,
    this.viewSide,
    this.viewShape,
    this.viewBarPadding,
    this.headerHeight,
    this.headerTextStyle,
    this.headerHintStyle,
    this.dividerColor,
    this.viewConstraints,
    this.viewPadding,
    this.shrinkWrap,
    this.textCapitalization,
    this.viewOnClose,
    this.viewOnOpen,
    bool showFullScreenView = true,
    this.textInputAction,
    this.keyboardType,
    this.searchController,
    required this.suggestionsBuilder,
    this.enabled = true,
  }) : isFullScreen = showFullScreenView,
       viewHintText = viewHintText ?? barHintText,
       viewSurfaceTintColor = null,
       viewOnChanged = onChanged,
       viewOnSubmitted = onSubmitted,
       builder = _unusedBuilder,
       _bar = (
         leading: barLeading,
         trailing: barTrailing,
         hintText: barHintText,
         onTap: onTap,
         elevation: barElevation,
         backgroundColor: barBackgroundColor,
         side: barSide,
         shape: barShape,
         padding: barPadding,
         textStyle: barTextStyle,
         hintStyle: barHintStyle,
         constraints: constraints,
       );

  static Widget _unusedBuilder(BuildContext context, SearchController c) =>
      const SizedBox.shrink();

  final bool? isFullScreen, shrinkWrap;
  final SearchController? searchController;
  final ViewBuilder? viewBuilder;
  final Widget? viewLeading;
  final Iterable<Widget>? viewTrailing;
  final String? viewHintText;
  final Color? viewBackgroundColor, viewSurfaceTintColor, dividerColor;
  final double? viewElevation, headerHeight;
  final BorderSide? viewSide;
  final OutlinedBorder? viewShape;
  final EdgeInsetsGeometry? viewBarPadding, viewPadding;
  final TextStyle? headerTextStyle, headerHintStyle;
  final BoxConstraints? viewConstraints;
  final TextCapitalization? textCapitalization;
  final ValueChanged<String>? viewOnChanged, viewOnSubmitted;
  final VoidCallback? viewOnClose, viewOnOpen;
  final SearchAnchorChildBuilder builder;
  final SuggestionsBuilder suggestionsBuilder;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool enabled;
  final ({
    Widget? leading,
    Iterable<Widget>? trailing,
    String? hintText,
    GestureTapCallback? onTap,
    WidgetStateProperty<double?>? elevation,
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<BorderSide?>? side,
    WidgetStateProperty<OutlinedBorder?>? shape,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<TextStyle?>? hintStyle,
    BoxConstraints? constraints,
  })?
  _bar;

  @override
  State<SearchAnchor> createState() => _SearchAnchorState();
}

class _SearchAnchorState extends State<SearchAnchor>
    implements _SearchViewHost {
  late SearchController _controller =
      widget.searchController ?? SearchController();
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller._host = this;
  }

  @override
  void didUpdateWidget(SearchAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchController != null &&
        widget.searchController != _controller) {
      _controller._host = null;
      _controller = widget.searchController!.._host = this;
    }
  }

  @override
  void dispose() {
    if (identical(_controller._host, this)) _controller._host = null;
    if (widget.searchController == null) _controller.dispose();
    super.dispose();
  }

  @override
  bool get open => _open;

  @override
  void openView() {
    if (_open || !widget.enabled) return;
    _open = true;
    widget.viewOnOpen?.call();
    final full = widget.isFullScreen ?? true;
    Navigator.of(context)
        .push<void>(
          _OverlayRoute<void>(
            builder: (context) =>
                _SearchView(anchor: widget, controller: _controller),
            dismissible: true,
            color: full ? const Color(0x00000000) : const Color(0x33000000),
            sheet: false,
          ),
        )
        .whenComplete(() {
          _open = false;
          widget.viewOnClose?.call();
        });
  }

  @override
  void closeView(String? selectedText) {
    if (!_open) return;
    if (selectedText != null) {
      _controller.value = TextEditingValue(
        text: selectedText,
        selection: TextSelection.collapsed(offset: selectedText.length),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bar = widget._bar;
    if (bar == null) return widget.builder(context, _controller);
    return SearchBar(
      controller: _controller,
      leading: bar.leading ?? const Icon(Icons.search),
      trailing: bar.trailing,
      hintText: bar.hintText,
      elevation: bar.elevation,
      backgroundColor: bar.backgroundColor,
      side: bar.side,
      shape: bar.shape,
      padding: bar.padding,
      textStyle: bar.textStyle,
      hintStyle: bar.hintStyle,
      constraints: bar.constraints,
      onTap: () {
        bar.onTap?.call();
        openView();
      },
      onChanged: (value) {
        widget.viewOnChanged?.call(value);
        openView();
      },
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView({required this.anchor, required this.controller});
  final SearchAnchor anchor;
  final SearchController controller;
  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  Iterable<Widget> _suggestions = const [];
  int _request = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final request = ++_request;
    final suggestions = await widget.anchor.suggestionsBuilder(
      context,
      widget.controller,
    );
    if (mounted && request == _request) {
      setState(() => _suggestions = suggestions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchor = widget.anchor;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final full = anchor.isFullScreen ?? true;
    final list =
        anchor.viewBuilder?.call(_suggestions) ??
        ListView(shrinkWrap: true, children: [..._suggestions]);
    return _Box(
      css:
          '${full ? 'position:fixed;inset:0;' : 'width:min(720px,100vw - 32px);max-height:min(80vh,600px);border-radius:28px;'}box-sizing:border-box;display:flex;flex-direction:column;overflow:hidden;background-color:${colorCss(anchor.viewBackgroundColor ?? scheme.surfaceContainerHigh)};',
      attributes: const {'role': 'dialog', 'aria-modal': 'true'},
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [
        _Box(
          css:
              'display:flex;align-items:center;gap:8px;min-height:${px(anchor.headerHeight ?? 72)};padding:0 8px;box-sizing:border-box;',
          layout: _DomLayout.row,
          fill: _Fill.expand,
          children: [
            anchor.viewLeading ??
                BackButton(onPressed: () => Navigator.of(context).pop()),
            _FlexFill(
              child: TextField(
                controller: widget.controller,
                autofocus: true,
                textInputAction:
                    anchor.textInputAction ?? TextInputAction.search,
                keyboardType: anchor.keyboardType,
                style: theme.textTheme.bodyLarge!
                    .copyWith(color: scheme.onSurface)
                    .merge(anchor.headerTextStyle),
                decoration: InputDecoration(
                  hintText: anchor.viewHintText,
                  hintStyle: anchor.headerHintStyle,
                  border: InputBorder.none,
                ),
                onChanged: anchor.viewOnChanged,
                onSubmitted: anchor.viewOnSubmitted,
              ),
            ),
            if (anchor.viewTrailing != null)
              ...anchor.viewTrailing!
            else
              IconButton(
                onPressed: widget.controller.clear,
                tooltip: 'Clear',
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        Divider(height: 1, color: anchor.dividerColor ?? scheme.outline),
        _Box(
          css: 'flex:1 1 auto;min-height:0;overflow-y:auto;',
          fill: _Fill.expand,
          children: [list],
        ),
      ],
    );
  }
}

part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Bottom navigation.

class NavigationDestination extends StatelessWidget {
  const NavigationDestination({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
    this.enabled = true,
  });
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? tooltip;
  final bool enabled;
  @override
  Widget build(BuildContext context) => icon;
}

enum NavigationDestinationLabelBehavior {
  alwaysShow,
  alwaysHide,
  onlyShowSelected,
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.showLabel,
    required this.onTap,
    required this.indicator,
    this.indicatorColor,
    this.indicatorShape,
    this.iconTheme,
    this.labelStyle,
    this.labelPadding,
    this.overlay,
  });
  final Widget icon;
  final String label;
  final bool selected, enabled, showLabel, indicator;
  final VoidCallback onTap;
  final Color? indicatorColor, overlay;
  final ShapeBorder? indicatorShape;
  final IconThemeData? iconTheme;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? labelPadding;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : selected
        ? (indicator ? scheme.onSecondaryContainer : scheme.primary)
        : scheme.onSurfaceVariant;
    final labelColor = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    final text = Text(
      label,
      style: theme.textTheme.labelMedium!
          .copyWith(
            color: labelColor,
            fontWeight: selected ? FontWeight.w600 : null,
          )
          .merge(labelStyle),
    );
    return _Box(
      tag: 'button',
      css:
          'flex:1 1 0;min-width:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;box-sizing:border-box;margin:0;border:0;padding:12px 0 16px;background:transparent;font:inherit;${_stateLayerCss(overlay ?? scheme.onSurface)}',
      attributes: {
        'type': 'button',
        'class': 'fd-ink fd-button',
        if (selected) 'aria-current': 'page',
        if (!enabled) 'disabled': '',
        if (!showLabel) 'aria-label': label,
      },
      handlers: {if (enabled) 'click': (_) => onTap()},
      layout: _DomLayout.column,
      fill: _Fill.none,
      children: [
        _Box(
          css:
              'display:flex;align-items:center;justify-content:center;width:64px;height:32px;${selected && indicator ? '${indicatorShape == null ? 'border-radius:16px;' : shapeCss(indicatorShape)}background-color:${colorCss(indicatorColor ?? scheme.secondaryContainer)};' : 'border-radius:16px;'}',
          layout: _DomLayout.align,
          fill: _Fill.none,
          children: [
            IconTheme(
              data: IconThemeData(color: iconColor, size: 24).merge(iconTheme),
              child: icon,
            ),
          ],
        ),
        if (showLabel)
          labelPadding == null
              ? text
              : Padding(padding: labelPadding!, child: text),
      ],
    );
  }
}

class NavigationBar extends StatelessWidget {
  const NavigationBar({
    super.key,
    this.animationDuration,
    this.selectedIndex = 0,
    required this.destinations,
    this.onDestinationSelected,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.indicatorColor,
    this.indicatorShape,
    this.height,
    this.labelBehavior,
    this.overlayColor,
    this.labelTextStyle,
    this.labelPadding,
    this.maintainBottomViewPadding = false,
  });
  final Duration? animationDuration;
  final List<Widget> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Color? backgroundColor, shadowColor, surfaceTintColor;
  final Color? indicatorColor;
  final double? elevation, height;
  final ShapeBorder? indicatorShape;
  final NavigationDestinationLabelBehavior? labelBehavior;
  final WidgetStateProperty<Color?>? overlayColor;
  final WidgetStateProperty<TextStyle?>? labelTextStyle;
  final EdgeInsetsGeometry? labelPadding;
  final bool maintainBottomViewPadding;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final barTheme = NavigationBarTheme.of(context);
    final behavior =
        labelBehavior ??
        barTheme.labelBehavior ??
        NavigationDestinationLabelBehavior.alwaysShow;
    final depth = elevation ?? barTheme.elevation ?? 3;
    return _Box(
      tag: 'nav',
      css:
          'display:flex;flex-direction:row;box-sizing:border-box;min-height:${px(height ?? barTheme.height ?? 80)};background-color:${colorCss(backgroundColor ?? barTheme.backgroundColor ?? scheme.surfaceContainer)};${depth > 3 ? elevationCss(depth, shadowColor ?? barTheme.shadowColor ?? scheme.shadow) : ''}',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        for (var i = 0; i < destinations.length; i++)
          () {
            final selected = i == selectedIndex;
            final enabled =
                destinations[i] is! NavigationDestination ||
                (destinations[i] as NavigationDestination).enabled;
            final states = {
              if (selected) WidgetState.selected,
              if (!enabled) WidgetState.disabled,
            };
            return _NavItem(
              icon: _destinationIcon(destinations[i], selected),
              label: _destinationLabel(destinations[i]),
              selected: selected,
              enabled: enabled,
              indicator: true,
              indicatorColor: indicatorColor ?? barTheme.indicatorColor,
              indicatorShape: indicatorShape ?? barTheme.indicatorShape,
              iconTheme: barTheme.iconTheme?.resolve(states),
              labelStyle:
                  labelTextStyle?.resolve(states) ??
                  barTheme.labelTextStyle?.resolve(states),
              labelPadding: labelPadding ?? barTheme.labelPadding,
              overlay:
                  overlayColor?.resolve({...states, WidgetState.hovered}) ??
                  barTheme.overlayColor?.resolve({
                    ...states,
                    WidgetState.hovered,
                  }),
              showLabel: switch (behavior) {
                NavigationDestinationLabelBehavior.alwaysShow => true,
                NavigationDestinationLabelBehavior.alwaysHide => false,
                NavigationDestinationLabelBehavior.onlyShowSelected => selected,
              },
              onTap: () => onDestinationSelected?.call(i),
            );
          }(),
      ],
    );
  }
}

Widget _destinationIcon(Widget destination, bool selected) {
  if (destination is NavigationDestination) {
    return selected
        ? destination.selectedIcon ?? destination.icon
        : destination.icon;
  }
  throw UnsupportedError(
    'NavigationBar destinations must be NavigationDestination.',
  );
}

String _destinationLabel(Widget destination) =>
    (destination as NavigationDestination).label;

class BottomNavigationBarItem {
  const BottomNavigationBarItem({
    this.key,
    required this.icon,
    this.label,
    Widget? activeIcon,
    this.backgroundColor,
    this.tooltip,
  }) : activeIcon = activeIcon ?? icon;
  final Key? key;
  final Widget icon;
  final Widget activeIcon;
  final String? label;
  final String? tooltip;
  final Color? backgroundColor;
}

enum BottomNavigationBarType { fixed, shifting }

class BottomNavigationBar extends StatelessWidget {
  const BottomNavigationBar({
    super.key,
    required this.items,
    this.onTap,
    this.currentIndex = 0,
    this.elevation,
    this.type,
    Color? fixedColor,
    this.backgroundColor,
    this.iconSize = 24.0,
    Color? selectedItemColor,
    this.unselectedItemColor,
    this.selectedIconTheme,
    this.unselectedIconTheme,
    this.selectedFontSize = 14.0,
    this.unselectedFontSize = 12.0,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.showSelectedLabels,
    this.showUnselectedLabels,
    this.mouseCursor,
    this.enableFeedback,
    this.landscapeLayout,
    this.useLegacyColorScheme = true,
  }) : selectedItemColor = selectedItemColor ?? fixedColor;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int>? onTap;
  final int currentIndex;
  final double? elevation;
  final BottomNavigationBarType? type;
  final Color? backgroundColor, selectedItemColor, unselectedItemColor;
  final double iconSize, selectedFontSize, unselectedFontSize;
  final IconThemeData? selectedIconTheme, unselectedIconTheme;
  final TextStyle? selectedLabelStyle, unselectedLabelStyle;
  final bool? showSelectedLabels, showUnselectedLabels;
  final MouseCursor? mouseCursor;
  final bool? enableFeedback;
  final BottomNavigationBarLandscapeLayout? landscapeLayout;
  final bool useLegacyColorScheme;
  Color? get fixedColor => selectedItemColor;
  @override
  Widget build(BuildContext context) {
    if (items.length < 2)
      throw ArgumentError('BottomNavigationBar requires at least two items.');
    final scheme = Theme.of(context).colorScheme;
    final barTheme = BottomNavigationBarTheme.of(context);
    final shifting =
        (type ?? barTheme.type ?? BottomNavigationBarType.fixed) ==
        BottomNavigationBarType.shifting;
    final selectedColor =
        selectedItemColor ?? barTheme.selectedItemColor ?? scheme.primary;
    final unselectedColor =
        unselectedItemColor ??
        barTheme.unselectedItemColor ??
        scheme.onSurfaceVariant;
    final background =
        (shifting ? items[currentIndex].backgroundColor : null) ??
        backgroundColor ??
        barTheme.backgroundColor ??
        scheme.surfaceContainer;
    return _Box(
      tag: 'nav',
      css:
          'display:flex;flex-direction:row;box-sizing:border-box;min-height:56px;background-color:${colorCss(background)};${elevationCss(elevation ?? barTheme.elevation ?? 8, scheme.shadow)}',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        for (var i = 0; i < items.length; i++)
          () {
            final selected = i == currentIndex;
            final color = selected ? selectedColor : unselectedColor;
            final iconTheme = IconThemeData(color: color, size: iconSize)
                .merge(
                  selected
                      ? barTheme.selectedIconTheme
                      : barTheme.unselectedIconTheme,
                )
                .merge(selected ? selectedIconTheme : unselectedIconTheme);
            final labelStyle =
                TextStyle(
                      color: color,
                      fontSize: selected
                          ? selectedFontSize
                          : unselectedFontSize,
                    )
                    .merge(
                      selected
                          ? barTheme.selectedLabelStyle
                          : barTheme.unselectedLabelStyle,
                    )
                    .merge(
                      selected ? selectedLabelStyle : unselectedLabelStyle,
                    );
            return _NavItem(
              icon: selected ? items[i].activeIcon : items[i].icon,
              label: items[i].label ?? '',
              selected: selected,
              enabled: true,
              indicator: false,
              iconTheme: iconTheme,
              labelStyle: labelStyle,
              showLabel: selected
                  ? showSelectedLabels ?? barTheme.showSelectedLabels ?? true
                  : showUnselectedLabels ??
                        barTheme.showUnselectedLabels ??
                        !shifting,
              onTap: () => onTap?.call(i),
            );
          }(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tabs. Only the selected tab view is built, matching Flutter's default of
// not keeping off-screen pages alive.

class TabController extends ChangeNotifier {
  TabController({
    required this.length,
    int initialIndex = 0,
    Object? vsync,
    Duration? animationDuration,
  }) : _index = initialIndex {
    if (length < 0 ||
        initialIndex < 0 ||
        (length > 0 && initialIndex >= length))
      throw ArgumentError('Invalid tab index.');
  }
  final int length;
  int _index;
  int _previous = 0;
  int get index => _index;
  int get previousIndex => _previous;
  bool get indexIsChanging => false;
  set index(int value) => animateTo(value);
  void animateTo(int value, {Duration? duration, Object? curve}) {
    if (value < 0 || value >= length) throw RangeError.index(value, this);
    if (value == _index) return;
    _previous = _index;
    _index = value;
    notifyListeners();
  }
}

class DefaultTabController extends StatefulWidget {
  const DefaultTabController({
    super.key,
    required this.length,
    this.initialIndex = 0,
    required this.child,
    this.animationDuration,
  });
  final int length, initialIndex;
  final Widget child;
  final Duration? animationDuration;
  static TabController of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError('No DefaultTabController ancestor in context.'));
  static TabController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_TabControllerScope>()
      ?.controller;
  @override
  State<DefaultTabController> createState() => _DefaultTabControllerState();
}

class _DefaultTabControllerState extends State<DefaultTabController> {
  late final controller = TabController(
    length: widget.length,
    initialIndex: widget.initialIndex,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _TabControllerScope(controller: controller, child: widget.child);
}

class _TabControllerScope extends InheritedNotifier<TabController> {
  const _TabControllerScope({
    required TabController controller,
    required super.child,
  }) : super(notifier: controller);
  TabController get controller => notifier!;
}

class Tab extends StatelessWidget implements PreferredSizeWidget {
  const Tab({
    super.key,
    this.text,
    this.icon,
    this.iconMargin,
    this.height,
    this.child,
  });
  final String? text;
  final Widget? icon, child;
  final EdgeInsetsGeometry? iconMargin;
  final double? height;
  @override
  Size get preferredSize => Size(
    double.infinity,
    height ?? (icon != null && (text != null || child != null) ? 72 : 46),
  );
  @override
  Widget build(BuildContext context) {
    final label = text != null ? Text(text!) : child;
    return _Box(
      css:
          'display:flex;flex-direction:column;align-items:center;justify-content:center;${height == null ? '' : 'min-height:${px(height!)};'}',
      layout: _DomLayout.column,
      fill: _Fill.none,
      children: [
        if (icon != null)
          label == null
              ? icon!
              : Padding(
                  padding: iconMargin ?? const EdgeInsets.only(bottom: 2),
                  child: icon,
                ),
        ?label,
      ],
    );
  }
}

String _tabId(TabController controller, int index) =>
    'fd-tab-${identityHashCode(controller)}-$index';

/// The default Material tab indicator: a line under the selected tab.
class UnderlineTabIndicator extends Decoration {
  const UnderlineTabIndicator({
    this.borderRadius,
    this.borderSide = const BorderSide(width: 2.0, color: Color(0xffffffff)),
    this.insets = EdgeInsets.zero,
  });
  final BorderRadius? borderRadius;
  final BorderSide borderSide;
  final EdgeInsetsGeometry insets;
}

class TabBar extends StatelessWidget implements PreferredSizeWidget {
  const TabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.padding,
    this.indicatorColor,
    this.automaticIndicatorColorAdjustment = true,
    this.indicatorWeight = 2.0,
    this.indicatorPadding = EdgeInsets.zero,
    this.indicator,
    this.indicatorSize,
    this.dividerColor,
    this.dividerHeight,
    this.labelColor,
    this.labelStyle,
    this.labelPadding,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.overlayColor,
    this.mouseCursor,
    this.enableFeedback,
    this.onTap,
    this.onHover,
    this.onFocusChange,
    this.physics,
    this.splashFactory,
    this.splashBorderRadius,
    this.tabAlignment,
    this.textScaler,
    this.indicatorAnimation,
  }) : _secondary = false;
  const TabBar.secondary({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.padding,
    this.indicatorColor,
    this.automaticIndicatorColorAdjustment = true,
    this.indicatorWeight = 2.0,
    this.indicatorPadding = EdgeInsets.zero,
    this.indicator,
    this.indicatorSize,
    this.dividerColor,
    this.dividerHeight,
    this.labelColor,
    this.labelStyle,
    this.labelPadding,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.overlayColor,
    this.mouseCursor,
    this.enableFeedback,
    this.onTap,
    this.onHover,
    this.onFocusChange,
    this.physics,
    this.splashFactory,
    this.splashBorderRadius,
    this.tabAlignment,
    this.textScaler,
    this.indicatorAnimation,
  }) : _secondary = true;
  final List<Widget> tabs;
  final TabController? controller;
  final bool isScrollable;
  final EdgeInsetsGeometry? padding;
  final Color? indicatorColor;
  final bool automaticIndicatorColorAdjustment;
  final double indicatorWeight;
  final EdgeInsetsGeometry indicatorPadding;
  final Decoration? indicator;
  final TabBarIndicatorSize? indicatorSize;
  final Color? dividerColor;
  final double? dividerHeight;
  final Color? labelColor, unselectedLabelColor;
  final TextStyle? labelStyle, unselectedLabelStyle;
  final EdgeInsetsGeometry? labelPadding;
  final WidgetStateProperty<Color?>? overlayColor;
  final MouseCursor? mouseCursor;
  final bool? enableFeedback;
  final ValueChanged<int>? onTap;
  final void Function(bool value, int index)? onHover, onFocusChange;
  final ScrollPhysics? physics;
  final InteractiveInkFeatureFactory? splashFactory;
  final BorderRadius? splashBorderRadius;
  final TabAlignment? tabAlignment;
  final TextScaler? textScaler;
  final TabIndicatorAnimation? indicatorAnimation;
  final bool _secondary;
  @override
  Size get preferredSize {
    var height = 46.0;
    for (final tab in tabs) {
      if (tab is PreferredSizeWidget) {
        final h = tab.preferredSize.height;
        if (h > height) height = h;
      }
    }
    return Size(double.infinity, height + indicatorWeight);
  }

  @override
  Widget build(BuildContext context) {
    final tabController = controller ?? DefaultTabController.of(context);
    if (tabController.length != tabs.length)
      throw StateError('TabController length does not match the tab count.');
    return ListenableBuilder(
      listenable: tabController,
      builder: (context, _) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final tabTheme = TabBarTheme.of(context);
        final selectedColor =
            labelColor ??
            tabTheme.labelColor ??
            (_secondary ? scheme.onSurface : scheme.primary);
        final unselectedColor =
            unselectedLabelColor ??
            tabTheme.unselectedLabelColor ??
            scheme.onSurfaceVariant;
        final selectedStyle = theme.textTheme.titleSmall!.merge(
          labelStyle ?? tabTheme.labelStyle,
        );
        final unselectedStyle = theme.textTheme.titleSmall!.merge(
          unselectedLabelStyle ??
              tabTheme.unselectedLabelStyle ??
              labelStyle ??
              tabTheme.labelStyle,
        );
        final lineColor =
            indicatorColor ?? tabTheme.indicatorColor ?? scheme.primary;
        final decoration = indicator ?? tabTheme.indicator;
        final divider =
            dividerColor ?? tabTheme.dividerColor ?? scheme.outlineVariant;
        final dividerWidth = dividerHeight ?? tabTheme.dividerHeight ?? 1;
        final scrollable = isScrollable;
        final align = tabAlignment ?? tabTheme.tabAlignment;
        final tabPadding = labelPadding ?? tabTheme.labelPadding;
        final hover = (overlayColor ?? tabTheme.overlayColor)?.resolve({
          WidgetState.hovered,
        });
        final noSplash = _noSplash(splashFactory ?? tabTheme.splashFactory);
        final cursor = mouseCursor;
        String indicatorCss(bool selected) {
          if (!selected) return 'border-bottom:3px solid transparent;';
          if (decoration is UnderlineTabIndicator) {
            final side = decoration.borderSide;
            return 'border-bottom:${px(side.width)} solid ${colorCss(side.color == const Color(0xffffffff) && indicator == null ? lineColor : side.color)};';
          }
          if (decoration != null)
            return '${decorationCss(decoration)}border-bottom:3px solid transparent;';
          return 'border-bottom:${px(indicatorWeight + (_secondary ? 0 : 1))} solid ${colorCss(lineColor)};';
        }

        return _Box(
          css:
              'display:flex;flex-direction:row;box-sizing:border-box;border-bottom:${px(dividerWidth)} solid ${colorCss(divider)};${padding == null ? '' : edgeInsetsCss('padding', padding)}${scrollable ? 'overflow-x:auto;' : ''}${align == TabAlignment.center ? 'justify-content:center;' : ''}',
          attributes: const {'role': 'tablist'},
          handlers: {
            'keydown': (event) {
              final key = event?.key;
              final step = key == 'ArrowRight'
                  ? 1
                  : key == 'ArrowLeft'
                  ? -1
                  : 0;
              if (step == 0) return;
              event?.preventDefault();
              final next = (tabController.index + step) % tabController.length;
              tabController.animateTo(next);
              onTap?.call(next);
            },
          },
          layout: _DomLayout.row,
          fill: _Fill.expand,
          children: [
            for (var i = 0; i < tabs.length; i++)
              () {
                final selected = i == tabController.index;
                final color = selected ? selectedColor : unselectedColor;
                return _Box(
                  tag: 'button',
                  css:
                      '${scrollable || align == TabAlignment.start || align == TabAlignment.center ? 'flex:0 0 auto;' : 'flex:1 1 0;'}${tabPadding == null ? (scrollable ? 'padding:0 16px;' : '') : edgeInsetsCss('padding', tabPadding)}min-width:0;min-height:48px;box-sizing:border-box;margin:0;border:0;background:transparent;font:inherit;${indicatorCss(selected)}${_stateLayerCss(scheme.primary)}${hover == null ? '' : '--fd-hover:${colorCss(hover)};'}${noSplash ? '--fd-press:transparent;' : ''}${cursor == null ? '' : 'cursor:${cursor._css};'}${splashBorderRadius == null ? '' : borderRadiusCss(splashBorderRadius)}',
                  attributes: {
                    'type': 'button',
                    'role': 'tab',
                    'id': _tabId(tabController, i),
                    'class': 'fd-ink fd-button',
                    'aria-selected': '$selected',
                    'tabindex': selected ? '0' : '-1',
                  },
                  handlers: {
                    'click': (_) {
                      tabController.animateTo(i);
                      onTap?.call(i);
                    },
                    if (onHover != null) 'mouseenter': (_) => onHover!(true, i),
                    if (onHover != null)
                      'mouseleave': (_) => onHover!(false, i),
                    if (onFocusChange != null)
                      'focus': (_) => onFocusChange!(true, i),
                    if (onFocusChange != null)
                      'blur': (_) => onFocusChange!(false, i),
                  },
                  fill: _Fill.none,
                  children: [
                    IconTheme.merge(
                      data: IconThemeData(color: color),
                      child: DefaultTextStyle(
                        style: (selected ? selectedStyle : unselectedStyle)
                            .copyWith(color: color),
                        child: tabs[i],
                      ),
                    ),
                  ],
                );
              }(),
          ],
        );
      },
    );
  }
}

class TabBarView extends StatelessWidget {
  const TabBarView({super.key, required this.children, this.controller});
  final List<Widget> children;
  final TabController? controller;
  @override
  Widget build(BuildContext context) {
    final tabController = controller ?? DefaultTabController.of(context);
    if (tabController.length != children.length)
      throw StateError('TabController length does not match the view count.');
    return ListenableBuilder(
      listenable: tabController,
      builder: (context, _) => _Box(
        css: 'display:grid;grid-template-columns:minmax(0,1fr);min-width:0;',
        attributes: {
          'role': 'tabpanel',
          'aria-labelledby': _tabId(tabController, tabController.index),
        },
        layout: _DomLayout.grid,
        fill: _Fill.expand,
        children: [
          KeyedSubtree(
            key: ValueKey(tabController.index),
            child: children[tabController.index],
          ),
        ],
      ),
    );
  }
}

class KeyedSubtree extends StatelessWidget {
  const KeyedSubtree({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

// ---------------------------------------------------------------------------
// Expansion tiles.

/// Controls the expansion state of an [ExpansionTile].
class ExpansibleController extends ChangeNotifier {
  ExpansibleController();
  bool _expanded = false;
  bool get isExpanded => _expanded;
  void expand() {
    if (_expanded) return;
    _expanded = true;
    notifyListeners();
  }

  void collapse() {
    if (!_expanded) return;
    _expanded = false;
    notifyListeners();
  }

  static ExpansibleController of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError('No ExpansionTile ancestor in this context.'));
  static ExpansibleController? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<_ExpansionTileState>()?._controller;
}

typedef ExpansionTileController = ExpansibleController;

class ExpansionTile extends StatefulWidget {
  const ExpansionTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.onExpansionChanged,
    this.children = const [],
    this.trailing,
    this.showTrailingIcon = true,
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.tilePadding,
    this.expandedCrossAxisAlignment,
    this.expandedAlignment,
    this.childrenPadding,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.textColor,
    this.collapsedTextColor,
    this.iconColor,
    this.collapsedIconColor,
    this.shape,
    this.collapsedShape,
    this.clipBehavior,
    this.controlAffinity,
    this.controller,
    this.dense,
    this.splashColor,
    this.visualDensity,
    this.minTileHeight,
    this.enableFeedback = true,
    this.enabled = true,
    this.expansionAnimationStyle,
    this.internalAddSemanticForOnTap = false,
  });

  final Widget title;
  final Widget? subtitle, leading, trailing;
  final List<Widget> children;
  final bool showTrailingIcon, initiallyExpanded, maintainState;
  final ValueChanged<bool>? onExpansionChanged;
  final EdgeInsetsGeometry? childrenPadding, tilePadding;
  final CrossAxisAlignment? expandedCrossAxisAlignment;
  final Alignment? expandedAlignment;
  final Color? backgroundColor, collapsedBackgroundColor;
  final Color? textColor, collapsedTextColor, iconColor, collapsedIconColor;
  final ShapeBorder? shape, collapsedShape;
  final Clip? clipBehavior;
  final ListTileControlAffinity? controlAffinity;
  final ExpansibleController? controller;
  final bool? dense, enableFeedback;
  final Color? splashColor;
  final VisualDensity? visualDensity;
  final double? minTileHeight;
  final bool enabled;
  final AnimationStyle? expansionAnimationStyle;
  final bool internalAddSemanticForOnTap;
  @override
  State<ExpansionTile> createState() => _ExpansionTileState();
}

class _ExpansionTileState extends State<ExpansionTile> {
  late final _id = 'fd-expansion-${identityHashCode(this)}';
  ExpansibleController? _ownController;
  ExpansibleController get _controller =>
      widget.controller ?? (_ownController ??= ExpansibleController());
  bool get expanded => _controller.isExpanded;
  bool _lastExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded) _controller._expanded = true;
    _lastExpanded = expanded;
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(ExpansionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      (oldWidget.controller ?? _ownController)?.removeListener(_changed);
      _controller.addListener(_changed);
      _lastExpanded = expanded;
    }
  }

  void _changed() {
    if (!mounted) return;
    final now = expanded;
    setState(() {});
    if (now != _lastExpanded) {
      _lastExpanded = now;
      widget.onExpansionChanged?.call(now);
    }
  }

  void _toggle() => expanded ? _controller.collapse() : _controller.expand();

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tileTheme = Theme.of(context).expansionTileTheme;
    final open = expanded;
    final background = open
        ? widget.backgroundColor ?? tileTheme.backgroundColor
        : widget.collapsedBackgroundColor ?? tileTheme.collapsedBackgroundColor;
    final tileShape = open
        ? widget.shape ?? tileTheme.shape
        : widget.collapsedShape ?? tileTheme.collapsedShape;
    final iconColor = open
        ? widget.iconColor ?? tileTheme.iconColor ?? scheme.primary
        : widget.collapsedIconColor ?? tileTheme.collapsedIconColor;
    final textColor = open
        ? widget.textColor ?? tileTheme.textColor
        : widget.collapsedTextColor ?? tileTheme.collapsedTextColor;
    final clip = widget.clipBehavior ?? tileTheme.clipBehavior ?? Clip.none;
    final leadingIcon =
        widget.controlAffinity == ListTileControlAffinity.leading;
    final arrow = Icon(
      open ? Icons.expand_less : Icons.expand_more,
      color: iconColor,
    );
    final alignment = widget.expandedAlignment ?? tileTheme.expandedAlignment;
    return _Box(
      css:
          'display:flex;flex-direction:column;min-width:0;${background == null ? '' : 'background-color:${colorCss(background)};'}${tileShape == null ? '' : shapeCss(tileShape)}${clip == Clip.none ? '' : 'overflow:hidden;'}',
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [
        _Box(
          tag: 'button',
          css:
              'display:block;width:100%;box-sizing:border-box;margin:0;padding:0;border:0;background:transparent;font:inherit;text-align:left;${_stateLayerCss(scheme.onSurface)}',
          attributes: {
            'type': 'button',
            'class': 'fd-ink fd-button',
            'aria-expanded': '$open',
            'aria-controls': _id,
            if (!widget.enabled) 'disabled': '',
          },
          handlers: {if (widget.enabled) 'click': (_) => _toggle()},
          fill: _Fill.expand,
          children: [
            ListTile(
              leading: leadingIcon ? arrow : widget.leading,
              title: widget.title,
              subtitle: widget.subtitle,
              contentPadding: widget.tilePadding ?? tileTheme.tilePadding,
              dense: widget.dense,
              visualDensity: widget.visualDensity,
              minTileHeight: widget.minTileHeight,
              enabled: widget.enabled,
              iconColor: iconColor,
              textColor: textColor,
              trailing:
                  widget.trailing ??
                  (widget.showTrailingIcon && !leadingIcon ? arrow : null),
            ),
          ],
        ),
        if (open || widget.maintainState)
          _Box(
            css:
                'display:flex;flex-direction:column;align-items:${_crossCss(widget.expandedCrossAxisAlignment ?? (alignment == null
                        ? CrossAxisAlignment.center
                        : alignment.resolve(TextDirection.ltr).x < 0
                        ? CrossAxisAlignment.start
                        : alignment.resolve(TextDirection.ltr).x > 0
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.center))};min-width:0;${edgeInsetsCss('padding', widget.childrenPadding ?? tileTheme.childrenPadding)}${open ? '' : 'display:none;'}',
            attributes: {'id': _id, if (!open) 'aria-hidden': 'true'},
            layout: _DomLayout.column,
            fill: _Fill.expand,
            children: widget.children,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Drawers.

class Drawer extends StatelessWidget {
  const Drawer({
    super.key,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.width,
    this.child,
    this.semanticLabel,
    this.clipBehavior,
  });
  final Widget? child;
  final Color? backgroundColor, shadowColor, surfaceTintColor;
  final double? elevation, width;
  final ShapeBorder? shape;
  final String? semanticLabel;
  final Clip? clipBehavior;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final drawerTheme = DrawerTheme.of(context);
    final drawerShape = shape ?? drawerTheme.shape;
    final depth = elevation ?? drawerTheme.elevation ?? 1;
    return _Box(
      tag: 'nav',
      css:
          'box-sizing:border-box;height:100%;width:${px(width ?? drawerTheme.width ?? 304)};max-width:calc(100vw - 56px);overflow-y:auto;background-color:${colorCss(backgroundColor ?? drawerTheme.backgroundColor ?? scheme.surfaceContainerLow)};${drawerShape == null ? 'border-radius:0 16px 16px 0;' : shapeCss(drawerShape)}${depth > 1 ? elevationCss(depth, shadowColor ?? drawerTheme.shadowColor ?? scheme.shadow) : ''}${(clipBehavior ?? drawerTheme.clipBehavior ?? Clip.none) == Clip.none ? '' : 'overflow:hidden;'}',
      attributes: {'aria-label': semanticLabel ?? 'Navigation menu'},
      fill: _Fill.none,
      children: [?child],
    );
  }
}

class DrawerHeader extends StatelessWidget {
  const DrawerHeader({
    super.key,
    this.decoration,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 8),
    this.child,
  });
  final Decoration? decoration;
  final EdgeInsetsGeometry padding;
  final Widget? child;
  @override
  Widget build(BuildContext context) => _Box(
    css:
        'box-sizing:border-box;min-height:160px;margin-bottom:8px;${edgeInsetsCss('padding', padding)}${decorationCss(decoration)}border-bottom:1px solid ${colorCss(Theme.of(context).dividerColor)};',
    fill: _Fill.expand,
    children: [
      if (child != null)
        DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyLarge!,
          child: child!,
        ),
    ],
  );
}

class _ScaffoldScope extends InheritedWidget {
  const _ScaffoldScope({required this.state, required super.child});
  final ScaffoldState state;
  @override
  bool updateShouldNotify(_ScaffoldScope oldWidget) =>
      !identical(oldWidget.state, state);
}

class ScaffoldState extends State<Scaffold> {
  bool _drawerOpen = false, _endDrawerOpen = false;
  bool get isDrawerOpen => _drawerOpen;
  bool get isEndDrawerOpen => _endDrawerOpen;
  bool get hasDrawer => widget.drawer != null;
  bool get hasEndDrawer => widget.endDrawer != null;
  Widget? _persistentSheet;
  PersistentBottomSheetController? _sheetController;

  void _setDrawer(bool open) {
    if (_drawerOpen == open) return;
    setState(() => _drawerOpen = open);
    widget.onDrawerChanged?.call(open);
  }

  void _setEndDrawer(bool open) {
    if (_endDrawerOpen == open) return;
    setState(() => _endDrawerOpen = open);
    widget.onEndDrawerChanged?.call(open);
  }

  void openDrawer() => _setDrawer(true);
  void openEndDrawer() => _setEndDrawer(true);
  void closeDrawer() => _setDrawer(false);
  void closeEndDrawer() => _setEndDrawer(false);

  /// Shows a persistent bottom sheet in this scaffold, replacing any
  /// current one.
  PersistentBottomSheetController showBottomSheet(
    WidgetBuilder builder, {
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    bool? enableDrag,
    bool? showDragHandle,
    AnimationController? transitionAnimationController,
    AnimationStyle? sheetAnimationStyle,
  }) {
    _sheetController?.close();
    final completer = Completer<void>();
    late final PersistentBottomSheetController controller;
    void close() {
      if (completer.isCompleted) return;
      if (mounted && identical(_sheetController, controller)) {
        setState(() {
          _persistentSheet = null;
          _sheetController = null;
        });
      }
      completer.complete();
    }

    controller = PersistentBottomSheetController._(
      close,
      completer.future,
      () => setState(() {}),
    );
    setState(() {
      _sheetController = controller;
      _persistentSheet = BottomSheet(
        onClosing: close,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        constraints: constraints,
        enableDrag: enableDrag ?? true,
        showDragHandle: showDragHandle,
        builder: builder,
      );
    });
    return controller;
  }

  @override
  Widget build(BuildContext context) => _ScaffoldScope(
    state: this,
    child: _ScaffoldBody(scaffold: widget, state: this),
  );
}

class _DrawerOverlay extends StatelessWidget {
  const _DrawerOverlay({
    required this.drawer,
    required this.end,
    required this.onClose,
    this.scrim,
  });
  final Widget drawer;
  final bool end;
  final VoidCallback onClose;
  final Color? scrim;
  @override
  Widget build(BuildContext context) => _Box(
    css:
        'position:fixed;inset:0;z-index:5;display:flex;justify-content:${end ? 'flex-end' : 'flex-start'};background-color:${colorCss(scrim ?? Theme.of(context).drawerTheme.scrimColor ?? const Color(0x52000000))};',
    handlers: {
      'keydown': (event) {
        if (event?.key == 'Escape') onClose();
      },
    },
    fill: _Fill.none,
    children: [
      _Box(
        css: 'position:absolute;inset:0;',
        attributes: const {'aria-hidden': 'true'},
        handlers: {'click': (_) => onClose()},
        fill: _Fill.none,
      ),
      _Box(
        css: 'position:relative;height:100%;',
        attributes: const {'role': 'dialog', 'aria-modal': 'true'},
        fill: _Fill.none,
        children: [drawer],
      ),
    ],
  );
}

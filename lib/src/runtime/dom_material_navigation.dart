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
  });
  final Widget icon;
  final String label;
  final bool selected, enabled, showLabel, indicator;
  final VoidCallback onTap;
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
    return _Box(
      tag: 'button',
      css:
          'flex:1 1 0;min-width:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;box-sizing:border-box;margin:0;border:0;padding:12px 0 16px;background:transparent;font:inherit;${_stateLayerCss(scheme.onSurface)}',
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
              'display:flex;align-items:center;justify-content:center;width:64px;height:32px;border-radius:16px;${selected && indicator ? 'background-color:${colorCss(scheme.secondaryContainer)};' : ''}',
          layout: _DomLayout.align,
          fill: _Fill.none,
          children: [
            IconTheme(
              data: IconThemeData(color: iconColor, size: 24),
              child: icon,
            ),
          ],
        ),
        if (showLabel)
          Text(
            label,
            style: theme.textTheme.labelMedium!.copyWith(
              color: labelColor,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
          ),
      ],
    );
  }
}

class NavigationBar extends StatelessWidget {
  const NavigationBar({
    super.key,
    required this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.backgroundColor,
    this.height,
    this.labelBehavior,
  });
  final List<Widget> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Color? backgroundColor;
  final double? height;
  final NavigationDestinationLabelBehavior? labelBehavior;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final behavior =
        labelBehavior ?? NavigationDestinationLabelBehavior.alwaysShow;
    return _Box(
      tag: 'nav',
      css:
          'display:flex;flex-direction:row;box-sizing:border-box;min-height:${px(height ?? 80)};background-color:${colorCss(backgroundColor ?? scheme.surfaceContainer)};',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        for (var i = 0; i < destinations.length; i++)
          _NavItem(
            icon: _destinationIcon(destinations[i], i == selectedIndex),
            label: _destinationLabel(destinations[i]),
            selected: i == selectedIndex,
            enabled:
                destinations[i] is! NavigationDestination ||
                (destinations[i] as NavigationDestination).enabled,
            indicator: true,
            showLabel: switch (behavior) {
              NavigationDestinationLabelBehavior.alwaysShow => true,
              NavigationDestinationLabelBehavior.alwaysHide => false,
              NavigationDestinationLabelBehavior.onlyShowSelected =>
                i == selectedIndex,
            },
            onTap: () => onDestinationSelected?.call(i),
          ),
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
    required this.icon,
    this.activeIcon,
    this.label,
    this.tooltip,
    this.backgroundColor,
  });
  final Widget icon;
  final Widget? activeIcon;
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
    this.type,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.showSelectedLabels,
    this.showUnselectedLabels,
  });
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int>? onTap;
  final int currentIndex;
  final BottomNavigationBarType? type;
  final Color? backgroundColor, selectedItemColor, unselectedItemColor;
  final bool? showSelectedLabels, showUnselectedLabels;
  @override
  Widget build(BuildContext context) {
    if (items.length < 2)
      throw ArgumentError('BottomNavigationBar requires at least two items.');
    final scheme = Theme.of(context).colorScheme;
    return _Box(
      tag: 'nav',
      css:
          'display:flex;flex-direction:row;box-sizing:border-box;min-height:56px;background-color:${colorCss(backgroundColor ?? scheme.surfaceContainer)};${elevationCss(8, scheme.shadow)}',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        for (var i = 0; i < items.length; i++)
          IconTheme(
            data: IconThemeData(
              color: i == currentIndex
                  ? selectedItemColor ?? scheme.primary
                  : unselectedItemColor ?? scheme.onSurfaceVariant,
            ),
            child: _NavItem(
              icon: i == currentIndex
                  ? items[i].activeIcon ?? items[i].icon
                  : items[i].icon,
              label: items[i].label ?? '',
              selected: i == currentIndex,
              enabled: true,
              indicator: false,
              showLabel: i == currentIndex
                  ? showSelectedLabels ?? true
                  : showUnselectedLabels ?? true,
              onTap: () => onTap?.call(i),
            ),
          ),
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
  const Tab({super.key, this.text, this.icon, this.child});
  final String? text;
  final Widget? icon, child;
  @override
  Size get preferredSize => const Size(double.infinity, 48);
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [?icon, if (text != null) Text(text!), ?child],
  );
}

String _tabId(TabController controller, int index) =>
    'fd-tab-${identityHashCode(controller)}-$index';

class TabBar extends StatelessWidget implements PreferredSizeWidget {
  const TabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.onTap,
    this.labelColor,
    this.unselectedLabelColor,
    this.indicatorColor,
  });
  final List<Widget> tabs;
  final TabController? controller;
  final bool isScrollable;
  final ValueChanged<int>? onTap;
  final Color? labelColor, unselectedLabelColor, indicatorColor;
  @override
  Size get preferredSize => const Size(double.infinity, 48);
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
        return _Box(
          css:
              'display:flex;flex-direction:row;box-sizing:border-box;border-bottom:1px solid ${colorCss(scheme.surfaceContainerHighest)};${isScrollable ? 'overflow-x:auto;' : ''}',
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
              _Box(
                tag: 'button',
                css:
                    '${isScrollable ? 'flex:0 0 auto;padding:0 16px;' : 'flex:1 1 0;'}min-width:0;min-height:48px;box-sizing:border-box;margin:0;border:0;background:transparent;font:inherit;border-bottom:3px solid ${i == tabController.index ? colorCss(indicatorColor ?? scheme.primary) : 'transparent'};${_stateLayerCss(scheme.primary)}',
                attributes: {
                  'type': 'button',
                  'role': 'tab',
                  'id': _tabId(tabController, i),
                  'class': 'fd-ink fd-button',
                  'aria-selected': '${i == tabController.index}',
                  'tabindex': i == tabController.index ? '0' : '-1',
                },
                handlers: {
                  'click': (_) {
                    tabController.animateTo(i);
                    onTap?.call(i);
                  },
                },
                fill: _Fill.none,
                children: [
                  IconTheme.merge(
                    data: IconThemeData(
                      color: i == tabController.index
                          ? labelColor ?? scheme.primary
                          : unselectedLabelColor ?? scheme.onSurfaceVariant,
                    ),
                    child: DefaultTextStyle(
                      style: theme.textTheme.titleSmall!.copyWith(
                        color: i == tabController.index
                            ? labelColor ?? scheme.primary
                            : unselectedLabelColor ?? scheme.onSurfaceVariant,
                      ),
                      child: tabs[i],
                    ),
                  ),
                ],
              ),
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

class ExpansionTile extends StatefulWidget {
  const ExpansionTile({
    this.clipBehavior,
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.children = const [],
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.childrenPadding,
    this.expandedCrossAxisAlignment,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.tilePadding,
    this.maintainState = false,
  });

  /// Accepted for API compatibility; shaped boxes clip through CSS.
  final Clip? clipBehavior;
  final Widget title;
  final Widget? subtitle, leading, trailing;
  final List<Widget> children;
  final bool initiallyExpanded, maintainState;
  final ValueChanged<bool>? onExpansionChanged;
  final EdgeInsetsGeometry? childrenPadding, tilePadding;
  final CrossAxisAlignment? expandedCrossAxisAlignment;
  final Color? backgroundColor, collapsedBackgroundColor;
  @override
  State<ExpansionTile> createState() => _ExpansionTileState();
}

class _ExpansionTileState extends State<ExpansionTile> {
  late bool expanded = widget.initiallyExpanded;
  late final _id = 'fd-expansion-${identityHashCode(this)}';

  void _toggle() {
    setState(() => expanded = !expanded);
    widget.onExpansionChanged?.call(expanded);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = expanded
        ? widget.backgroundColor
        : widget.collapsedBackgroundColor;
    return _Box(
      css:
          'display:flex;flex-direction:column;min-width:0;${background == null ? '' : 'background-color:${colorCss(background)};'}',
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
            'aria-expanded': '$expanded',
            'aria-controls': _id,
          },
          handlers: {'click': (_) => _toggle()},
          fill: _Fill.expand,
          children: [
            ListTile(
              leading: widget.leading,
              title: widget.title,
              subtitle: widget.subtitle,
              contentPadding: widget.tilePadding,
              trailing:
                  widget.trailing ??
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: expanded ? scheme.primary : null,
                  ),
            ),
          ],
        ),
        if (expanded || widget.maintainState)
          _Box(
            css:
                'display:flex;flex-direction:column;align-items:${_crossCss(widget.expandedCrossAxisAlignment ?? CrossAxisAlignment.center)};min-width:0;${edgeInsetsCss('padding', widget.childrenPadding)}${expanded ? '' : 'display:none;'}',
            attributes: {'id': _id, if (!expanded) 'aria-hidden': 'true'},
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
    this.child,
    this.backgroundColor,
    this.width,
    this.semanticLabel,
  });
  final Widget? child;
  final Color? backgroundColor;
  final double? width;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Box(
      tag: 'nav',
      css:
          'box-sizing:border-box;height:100%;width:${px(width ?? 304)};max-width:calc(100vw - 56px);overflow-y:auto;background-color:${colorCss(backgroundColor ?? scheme.surfaceContainerLow)};border-radius:0 16px 16px 0;',
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
  void openDrawer() => setState(() => _drawerOpen = true);
  void openEndDrawer() => setState(() => _endDrawerOpen = true);
  void closeDrawer() => setState(() => _drawerOpen = false);
  void closeEndDrawer() => setState(() => _endDrawerOpen = false);

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
  });
  final Widget drawer;
  final bool end;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => _Box(
    css:
        'position:fixed;inset:0;z-index:5;display:flex;justify-content:${end ? 'flex-end' : 'flex-start'};background-color:rgba(0,0,0,0.32);',
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

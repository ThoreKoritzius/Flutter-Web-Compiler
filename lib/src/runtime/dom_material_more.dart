part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Popup menus.

class RelativeRect {
  const RelativeRect.fromLTRB(this.left, this.top, this.right, this.bottom);
  factory RelativeRect.fromRect(Rect rect, Rect container) =>
      RelativeRect.fromLTRB(
        rect.left - container.left,
        rect.top - container.top,
        container.right - rect.right,
        container.bottom - rect.bottom,
      );
  factory RelativeRect.fromSize(Rect rect, Size container) =>
      RelativeRect.fromLTRB(
        rect.left,
        rect.top,
        container.width - rect.right,
        container.height - rect.bottom,
      );
  factory RelativeRect.fromDirectional({
    required TextDirection textDirection,
    required double start,
    required double top,
    required double end,
    required double bottom,
  }) => textDirection == TextDirection.rtl
      ? RelativeRect.fromLTRB(end, top, start, bottom)
      : RelativeRect.fromLTRB(start, top, end, bottom);
  static const fill = RelativeRect.fromLTRB(0, 0, 0, 0);
  final double left, top, right, bottom;
  bool get hasInsets => left > 0 || top > 0 || right > 0 || bottom > 0;
  RelativeRect shift(Offset offset) => RelativeRect.fromLTRB(
    left + offset.dx,
    top + offset.dy,
    right - offset.dx,
    bottom - offset.dy,
  );
  RelativeRect inflate(double delta) => RelativeRect.fromLTRB(
    left - delta,
    top - delta,
    right - delta,
    bottom - delta,
  );
  RelativeRect deflate(double delta) => inflate(-delta);
  Rect toRect(Rect container) => Rect.fromLTRB(
    left,
    top,
    container.width - right,
    container.height - bottom,
  );
  Size toSize(Size container) =>
      Size(container.width - left - right, container.height - top - bottom);
  static RelativeRect? lerp(RelativeRect? a, RelativeRect? b, double t) {
    if (a == null || b == null) return a ?? b;
    double mix(double x, double y) => x + (y - x) * t;
    return RelativeRect.fromLTRB(
      mix(a.left, b.left),
      mix(a.top, b.top),
      mix(a.right, b.right),
      mix(a.bottom, b.bottom),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RelativeRect &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;
  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}

abstract class PopupMenuEntry<T> extends StatelessWidget {
  const PopupMenuEntry({super.key});
  double get height;
  bool represents(T? value);
}

class PopupMenuItem<T> extends PopupMenuEntry<T> {
  const PopupMenuItem({
    super.key,
    this.value,
    this.onTap,
    this.enabled = true,
    this.height = 48,
    this.padding,
    this.textStyle,
    this.labelTextStyle,
    this.mouseCursor,
    required this.child,
  });
  final WidgetStateProperty<TextStyle?>? labelTextStyle;
  final T? value;
  final VoidCallback? onTap;
  final bool enabled;
  @override
  final double height;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final MouseCursor? mouseCursor;
  final Widget? child;
  @override
  bool represents(T? value) => value == this.value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.38);
    final states = {if (!enabled) WidgetState.disabled};
    return _Box(
      tag: 'button',
      css:
          'display:flex;align-items:center;gap:12px;width:100%;box-sizing:border-box;margin:0;border:0;background:transparent;font:inherit;text-align:left;min-height:${px(height)};${edgeInsetsCss('padding', padding ?? const EdgeInsets.symmetric(horizontal: 12))}${_stateLayerCss(scheme.onSurface)}',
      attributes: {
        'type': 'button',
        'role': 'menuitem',
        'class': 'fd-ink fd-button',
        if (!enabled) 'disabled': '',
      },
      handlers: {
        if (enabled)
          'click': (_) {
            onTap?.call();
            Navigator.maybeOf(context)?.pop<T>(value);
          },
      },
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        IconTheme.merge(
          data: IconThemeData(
            color: theme.popupMenuTheme.iconColor ?? scheme.onSurfaceVariant,
            size: theme.popupMenuTheme.iconSize ?? 24,
          ),
          child: DefaultTextStyle(
            style: theme.textTheme.labelLarge!
                .copyWith(color: foreground)
                .merge(
                  labelTextStyle?.resolve(states) ??
                      theme.popupMenuTheme.labelTextStyle?.resolve(states) ??
                      textStyle ??
                      theme.popupMenuTheme.textStyle,
                ),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class CheckedPopupMenuItem<T> extends PopupMenuItem<T> {
  const CheckedPopupMenuItem({
    super.key,
    super.value,
    this.checked = false,
    super.enabled,
    super.onTap,
    super.child,
  });
  final bool checked;
  @override
  Widget build(BuildContext context) => PopupMenuItem<T>(
    value: value,
    enabled: enabled,
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Opacity(opacity: checked ? 1 : 0, child: const Icon(Icons.check)),
        ?child,
      ],
    ),
  ).build(context);
}

class PopupMenuDivider extends PopupMenuEntry<Never> {
  const PopupMenuDivider({super.key, this.height = 16});
  @override
  final double height;
  @override
  bool represents(Object? value) => false;
  @override
  Widget build(BuildContext context) => Divider(height: height);
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.items,
    this.color,
    this.shape,
    this.elevation,
    this.shadowColor,
    this.menuPadding,
    this.constraints,
    this.clipBehavior,
    this.semanticLabel,
  });
  final List<PopupMenuEntry<dynamic>> items;
  final Color? color, shadowColor;
  final ShapeBorder? shape;
  final double? elevation;
  final EdgeInsetsGeometry? menuPadding;
  final BoxConstraints? constraints;
  final Clip? clipBehavior;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final menuTheme = PopupMenuTheme.of(context);
    final menuShape = shape ?? menuTheme.shape;
    final limits = constraints;
    return _Box(
      css:
          'display:flex;flex-direction:column;box-sizing:border-box;min-width:${px(limits?.minWidth ?? 112)};max-width:${limits == null || !limits.maxWidth.isFinite ? '280px' : px(limits.maxWidth)};${edgeInsetsCss('padding', menuPadding ?? menuTheme.menuPadding ?? const EdgeInsets.symmetric(vertical: 8))}background-color:${colorCss(color ?? menuTheme.color ?? scheme.surfaceContainer)};${menuShape == null ? 'border-radius:4px;' : shapeCss(menuShape)}${elevationCss(elevation ?? menuTheme.elevation ?? 3, shadowColor ?? menuTheme.shadowColor ?? scheme.shadow)}${(clipBehavior ?? Clip.none) == Clip.none ? '' : 'overflow:hidden;'}',
      attributes: {'role': 'menu', 'aria-label': ?semanticLabel},
      handlers: {
        'keydown': (event) {
          final key = event?.key;
          if (key != 'ArrowDown' && key != 'ArrowUp') return;
          event?.preventDefault();
          _moveMenuFocus(context, key == 'ArrowDown' ? 1 : -1);
        },
      },
      layout: _DomLayout.column,
      fill: _Fill.none,
      children: items,
    );
  }
}

/// Moves focus between enabled menu items of the panel at [context].
void _moveMenuFocus(BuildContext context, int step) {
  final items = <JSObject>[];
  void collect(Element element) {
    if (element is _DomElement &&
        element._attributes['role'] == 'menuitem' &&
        !element._attributes.containsKey('disabled')) {
      items.add(element.node as JSObject);
    }
    element.visitChildren(collect);
  }

  (context as Element).visitChildren(collect);
  if (items.isEmpty) return;
  final active = (_document as JSObject).getProperty<JSObject?>(
    'activeElement'.toJS,
  );
  var index = items.indexWhere((item) => identical(item, active));
  index = index < 0
      ? (step > 0 ? 0 : items.length - 1)
      : (index + step) % items.length;
  if (index < 0) index += items.length;
  items[index].callMethod('focus'.toJS);
}

Future<T?> showMenu<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<PopupMenuEntry<T>> items,
  T? initialValue,
  double? elevation,
  Color? shadowColor,
  Color? surfaceTintColor,
  String? semanticLabel,
  ShapeBorder? shape,
  EdgeInsetsGeometry? menuPadding,
  Color? color,
  bool useRootNavigator = false,
  BoxConstraints? constraints,
  Clip clipBehavior = Clip.none,
  RouteSettings? routeSettings,
  AnimationStyle? popUpAnimationStyle,
  bool? requestFocus,
}) {
  final viewport = MediaQuery.maybeSizeOf(context) ?? const Size(1024, 768);
  final anchor = Rect.fromLTRB(
    position.left,
    position.top,
    viewport.width - position.right,
    viewport.height - position.bottom,
  );
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    _OverlayRoute<T>(
      builder: (_) => _MenuPanel(
        items: items,
        color: color,
        shape: shape,
        elevation: elevation,
        shadowColor: shadowColor,
        menuPadding: menuPadding,
        constraints: constraints,
        clipBehavior: clipBehavior,
        semanticLabel: semanticLabel,
      ),
      dismissible: true,
      color: const Color(0x00000000),
      sheet: false,
      anchor: anchor,
    ),
  );
}

enum PopupMenuPosition { over, under }

typedef PopupMenuItemBuilder<T> =
    List<PopupMenuEntry<T>> Function(BuildContext context);
typedef PopupMenuItemSelected<T> = void Function(T value);

class PopupMenuButton<T> extends StatelessWidget {
  const PopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.initialValue,
    this.onOpened,
    this.onSelected,
    this.onCanceled,
    this.tooltip,
    this.padding = const EdgeInsets.all(8),
    this.child,
    this.icon,
    this.iconSize,
    this.offset = Offset.zero,
    this.splashRadius,
    this.iconColor,
    this.enabled = true,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.color,
    this.shape,
    this.menuPadding,
    this.enableFeedback,
    this.constraints,
    this.position,
    this.clipBehavior = Clip.none,
    this.useRootNavigator = false,
    this.popUpAnimationStyle,
    this.routeSettings,
    this.style,
    this.requestFocus,
  });
  final double? splashRadius, elevation;
  final Color? iconColor, shadowColor, surfaceTintColor;
  final EdgeInsetsGeometry? menuPadding;
  final bool? enableFeedback, requestFocus;
  final BoxConstraints? constraints;
  final PopupMenuPosition? position;
  final Clip clipBehavior;
  final bool useRootNavigator;
  final AnimationStyle? popUpAnimationStyle;
  final RouteSettings? routeSettings;
  final ButtonStyle? style;
  final PopupMenuItemBuilder<T> itemBuilder;
  final T? initialValue;
  final VoidCallback? onOpened, onCanceled;
  final PopupMenuItemSelected<T>? onSelected;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final Widget? child, icon;
  final double? iconSize;
  final Offset offset;
  final bool enabled;
  final Color? color;
  final ShapeBorder? shape;

  Future<void> _open(BuildContext context) async {
    final rect = _viewportRect(context) ?? Rect.zero;
    final viewport = MediaQuery.maybeSizeOf(context) ?? const Size(1024, 768);
    onOpened?.call();
    final value = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        rect.left + offset.dx,
        (position == PopupMenuPosition.under ? rect.bottom : rect.top) +
            offset.dy,
        viewport.width - rect.right,
        0,
      ),
      items: itemBuilder(context),
      initialValue: initialValue,
      color: color,
      shape: shape,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      menuPadding: menuPadding,
      constraints: constraints,
      clipBehavior: clipBehavior,
      useRootNavigator: useRootNavigator,
    );
    if (value == null) {
      onCanceled?.call();
    } else {
      onSelected?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = tooltip ?? MaterialLocalizations.of(context).showMenuTooltip;
    return Builder(
      builder: (context) {
        final open = enabled ? () => _open(context) : null;
        if (child != null) {
          return _Box(
            css: 'display:inline-flex;',
            attributes: {
              'role': 'button',
              'aria-haspopup': 'menu',
              'aria-label': label,
              if (enabled) 'tabindex': '0',
              if (enabled) 'class': 'fd-ink',
            },
            handlers: _activationHandlers(open),
            fill: _Fill.none,
            children: [child!],
          );
        }
        return IconButton(
          onPressed: open,
          tooltip: label,
          iconSize: iconSize ?? PopupMenuTheme.of(context).iconSize,
          color: iconColor ?? PopupMenuTheme.of(context).iconColor,
          style: style,
          padding: padding,
          icon: icon ?? Icon(Icons.adaptive.more),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Date and time pickers on native inputs.

class TimeOfDay {
  const TimeOfDay({required this.hour, required this.minute});
  TimeOfDay.fromDateTime(DateTime time)
    : hour = time.hour,
      minute = time.minute;
  factory TimeOfDay.now() => TimeOfDay.fromDateTime(DateTime.now());
  final int hour, minute;
  int get hourOfPeriod => hour == 0 || hour == 12 ? 12 : hour % 12;
  DayPeriod get period => hour < 12 ? DayPeriod.am : DayPeriod.pm;
  TimeOfDay replacing({int? hour, int? minute}) =>
      TimeOfDay(hour: hour ?? this.hour, minute: minute ?? this.minute);
  bool isBefore(TimeOfDay other) =>
      hour < other.hour || (hour == other.hour && minute < other.minute);
  bool isAfter(TimeOfDay other) =>
      hour > other.hour || (hour == other.hour && minute > other.minute);
  int compareTo(TimeOfDay other) =>
      hour != other.hour ? hour - other.hour : minute - other.minute;
  String format(BuildContext context) =>
      '$hourOfPeriod:${minute.toString().padLeft(2, '0')} ${period == DayPeriod.am ? 'AM' : 'PM'}';
  @override
  bool operator ==(Object other) =>
      other is TimeOfDay && other.hour == hour && other.minute == minute;
  @override
  int get hashCode => Object.hash(hour, minute);
  @override
  String toString() =>
      'TimeOfDay(${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')})';
}

enum DayPeriod { am, pm }

class DateTimeRange {
  DateTimeRange({required this.start, required this.end}) {
    if (start.isAfter(end)) throw ArgumentError('start must not follow end.');
  }
  final DateTime start, end;
  Duration get duration => end.difference(start);
  @override
  bool operator ==(Object other) =>
      other is DateTimeRange && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
}

enum DatePickerEntryMode { calendar, input, calendarOnly, inputOnly }

enum TimePickerEntryMode { dial, input, dialOnly, inputOnly }

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime? _parseIsoDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

class _NativeValueInput extends _DomWidget {
  const _NativeValueInput({
    required this.type,
    required this.value,
    required this.label,
    required this.onChanged,
    this.min,
    this.max,
  });
  final String type, value, label;
  final String? min, max;
  final ValueChanged<String> onChanged;
  @override
  String get _tag => 'input';
  @override
  _Fill get _fill => _Fill.expand;
  @override
  void _render(_DomBuilder out) {
    final theme = Theme.of(out.context);
    out.css(
      'box-sizing:border-box;width:100%;padding:12px;font:inherit;${textStyleCss(theme.textTheme.bodyLarge!.copyWith(color: theme.colorScheme.onSurface))}border:1px solid ${colorCss(theme.colorScheme.outline)};border-radius:4px;background:transparent;',
    );
    out.attributes['type'] = type;
    out.attributes['aria-label'] = label;
    if (min != null) out.attributes['min'] = min!;
    if (max != null) out.attributes['max'] = max!;
    out.properties['value'] = value;
    final element = out.context;
    out.on('input', (_) {
      onChanged(
        (element.node as JSObject).getProperty<JSString>('value'.toJS).toDart,
      );
    });
  }
}

/// A dialog holding native inputs with Cancel/OK actions.
class _PickerDialog<T> extends StatefulWidget {
  const _PickerDialog({
    required this.title,
    required this.initial,
    required this.fields,
    required this.parse,
    this.cancelText,
    this.confirmText,
  });
  final String title;
  final List<String> initial;
  final List<(String type, String label, String? min, String? max)> fields;
  final T? Function(List<String> values) parse;
  final String? cancelText, confirmText;
  @override
  State<_PickerDialog<T>> createState() => _PickerDialogState<T>();
}

class _PickerDialogState<T> extends State<_PickerDialog<T>> {
  late final values = List.of(widget.initial);
  @override
  Widget build(BuildContext context) {
    final strings = MaterialLocalizations.of(context);
    final result = widget.parse(values);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          for (var i = 0; i < widget.fields.length; i++)
            _NativeValueInput(
              type: widget.fields[i].$1,
              label: widget.fields[i].$2,
              min: widget.fields[i].$3,
              max: widget.fields[i].$4,
              value: values[i],
              onChanged: (value) => setState(() => values[i] = value),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelText ?? strings.cancelButtonLabel),
        ),
        TextButton(
          onPressed: result == null
              ? null
              : () => Navigator.of(context).pop<T>(result),
          child: Text(widget.confirmText ?? strings.okButtonLabel),
        ),
      ],
    );
  }
}

Future<DateTime?> showDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
  bool Function(DateTime day)? selectableDayPredicate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  Locale? locale,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  String? fieldLabelText,
  String? fieldHintText,
  String? errorFormatText,
  String? errorInvalidText,
}) {
  final first = DateUtils.dateOnly(firstDate);
  final last = DateUtils.dateOnly(lastDate);
  if (last.isBefore(first)) throw ArgumentError('lastDate precedes firstDate.');
  final initial = initialDate == null ? null : DateUtils.dateOnly(initialDate);
  return showDialog<DateTime>(
    context: context,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    builder: (context) => _PickerDialog<DateTime>(
      title: helpText ?? MaterialLocalizations.of(context).datePickerHelpText,
      cancelText: cancelText,
      confirmText: confirmText,
      initial: [initial == null ? '' : _isoDate(initial)],
      fields: [
        ('date', fieldLabelText ?? 'Date', _isoDate(first), _isoDate(last)),
      ],
      parse: (values) {
        final date = _parseIsoDate(values.first);
        if (date == null || date.isBefore(first) || date.isAfter(last))
          return null;
        if (selectableDayPredicate != null && !selectableDayPredicate(date))
          return null;
        return date;
      },
    ),
  );
}

Future<DateTimeRange?> showDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  String? saveText,
  bool useRootNavigator = true,
  String? fieldStartLabelText,
  String? fieldEndLabelText,
}) {
  final first = DateUtils.dateOnly(firstDate);
  final last = DateUtils.dateOnly(lastDate);
  return showDialog<DateTimeRange>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (context) => _PickerDialog<DateTimeRange>(
      title: helpText ?? 'Select range',
      cancelText: cancelText,
      confirmText: saveText ?? confirmText,
      initial: [
        initialDateRange == null ? '' : _isoDate(initialDateRange.start),
        initialDateRange == null ? '' : _isoDate(initialDateRange.end),
      ],
      fields: [
        (
          'date',
          fieldStartLabelText ?? 'Start date',
          _isoDate(first),
          _isoDate(last),
        ),
        (
          'date',
          fieldEndLabelText ?? 'End date',
          _isoDate(first),
          _isoDate(last),
        ),
      ],
      parse: (values) {
        final start = _parseIsoDate(values[0]);
        final end = _parseIsoDate(values[1]);
        if (start == null || end == null || end.isBefore(start)) return null;
        if (start.isBefore(first) || end.isAfter(last)) return null;
        return DateTimeRange(start: start, end: end);
      },
    ),
  );
}

Future<TimeOfDay?> showTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  TimePickerEntryMode initialEntryMode = TimePickerEntryMode.dial,
  String? helpText,
  String? cancelText,
  String? confirmText,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) => showDialog<TimeOfDay>(
  context: context,
  useRootNavigator: useRootNavigator,
  routeSettings: routeSettings,
  builder: (context) => _PickerDialog<TimeOfDay>(
    title: helpText ?? MaterialLocalizations.of(context).timePickerDialHelpText,
    cancelText: cancelText,
    confirmText: confirmText,
    initial: [
      '${initialTime.hour.toString().padLeft(2, '0')}:${initialTime.minute.toString().padLeft(2, '0')}',
    ],
    fields: [('time', 'Time', null, null)],
    parse: (values) {
      final parts = values.first.split(':');
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null || hour > 23 || minute > 59)
        return null;
      return TimeOfDay(hour: hour, minute: minute);
    },
  ),
);

abstract final class DateUtils {
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static bool isSameDay(DateTime? a, DateTime? b) =>
      a != null &&
      b != null &&
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
  static bool isSameMonth(DateTime? a, DateTime? b) =>
      a != null && b != null && a.year == b.year && a.month == b.month;
  static int getDaysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
  static int monthDelta(DateTime start, DateTime end) =>
      (end.year - start.year) * 12 + end.month - start.month;
  static DateTime addMonthsToMonthDate(DateTime monthDate, int delta) =>
      DateTime(monthDate.year, monthDate.month + delta);
}

// ---------------------------------------------------------------------------
// Chips and segmented buttons.

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.checkmark,
    this.avatar,
    this.tooltip,
    this.selectedColor,
    this.backgroundColor,
    this.onDeleted,
  });
  final Widget label;
  final Widget? avatar;
  final bool? selected;
  final bool checkmark;
  final VoidCallback? onPressed, onDeleted;
  final String? tooltip;
  final Color? selectedColor, backgroundColor;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chipTheme = ChipTheme.of(context);
    final isSelected = selected ?? false;
    final enabled = onPressed != null;
    final states = {
      if (isSelected) WidgetState.selected,
      if (!enabled) WidgetState.disabled,
    };
    final themed = chipTheme.color?.resolve(states);
    final selectedBackground =
        selectedColor ?? themed ?? chipTheme.selectedColor;
    final idleBackground =
        backgroundColor ?? themed ?? chipTheme.backgroundColor;
    final labelStyle = chipTheme.labelStyle;
    final foreground = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : isSelected
        ? scheme.onSecondaryContainer
        : labelStyle?.color ?? scheme.onSurfaceVariant;
    final side = chipTheme.side;
    final chipShape = chipTheme.shape;
    return _Box(
      tag: 'button',
      css:
          'display:inline-flex;align-items:center;gap:8px;flex-shrink:0;box-sizing:border-box;margin:0;min-height:32px;padding:0 ${onDeleted == null ? 16 : 8}px 0 ${avatar != null || (checkmark && isSelected) ? 8 : 16}px;${chipShape == null ? 'border-radius:8px;' : shapeCss(chipShape)}font:inherit;'
          'background-color:${isSelected
              ? colorCss(selectedBackground ?? scheme.secondaryContainer)
              : idleBackground == null
              ? 'transparent'
              : colorCss(idleBackground)};'
          '${isSelected
              ? 'border:1px solid transparent;'
              : side != null
              ? borderSideCss('border', side)
              : 'border:1px solid ${colorCss(scheme.outlineVariant)};'}${_stateLayerCss(foreground)}',
      attributes: {
        'type': 'button',
        'class': 'fd-ink fd-button',
        if (selected != null) 'aria-pressed': '$isSelected',
        if (!enabled) 'disabled': '',
        if (tooltip != null) 'title': tooltip!,
      },
      handlers: {if (enabled) 'click': (_) => onPressed!()},
      layout: _DomLayout.row,
      fill: _Fill.none,
      children: [
        IconTheme.merge(
          data: IconThemeData(color: foreground, size: 18),
          child: DefaultTextStyle(
            style: theme.textTheme.labelLarge!
                .merge(labelStyle)
                .copyWith(color: foreground),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                if (checkmark && isSelected)
                  Icon(Icons.check, color: chipTheme.checkmarkColor),
                if (avatar != null && !(checkmark && isSelected)) avatar!,
                label,
                if (onDeleted != null)
                  _Box(
                    tag: 'span',
                    css: 'display:inline-flex;cursor:pointer;',
                    attributes: const {
                      'role': 'button',
                      'aria-label': 'Delete',
                    },
                    handlers: {'click': (event) => onDeleted!()},
                    fill: _Fill.none,
                    children: const [Icon(Icons.close)],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FilterChip extends StatelessWidget {
  const FilterChip({
    super.key,
    required this.label,
    this.avatar,
    this.selected = false,
    required this.onSelected,
    this.showCheckmark,
    this.tooltip,
    this.selectedColor,
    this.backgroundColor,
    this.onDeleted,
  });
  final Widget label;
  final Widget? avatar;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final bool? showCheckmark;
  final String? tooltip;
  final Color? selectedColor, backgroundColor;
  final VoidCallback? onDeleted;
  @override
  Widget build(BuildContext context) => _SelectableChip(
    label: label,
    avatar: avatar,
    selected: selected,
    checkmark: showCheckmark ?? true,
    tooltip: tooltip,
    selectedColor: selectedColor,
    backgroundColor: backgroundColor,
    onDeleted: onDeleted,
    onPressed: onSelected == null ? null : () => onSelected!(!selected),
  );
}

class ChoiceChip extends StatelessWidget {
  const ChoiceChip({
    super.key,
    required this.label,
    this.avatar,
    required this.selected,
    this.onSelected,
    this.showCheckmark,
    this.tooltip,
    this.selectedColor,
    this.backgroundColor,
  });
  final Widget label;
  final Widget? avatar;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final bool? showCheckmark;
  final String? tooltip;
  final Color? selectedColor, backgroundColor;
  @override
  Widget build(BuildContext context) => _SelectableChip(
    label: label,
    avatar: avatar,
    selected: selected,
    checkmark: showCheckmark ?? true,
    tooltip: tooltip,
    selectedColor: selectedColor,
    backgroundColor: backgroundColor,
    onPressed: onSelected == null ? null : () => onSelected!(!selected),
  );
}

class ActionChip extends StatelessWidget {
  const ActionChip({
    super.key,
    required this.label,
    this.avatar,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
  });
  final Widget label;
  final Widget? avatar;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  @override
  Widget build(BuildContext context) => _SelectableChip(
    label: label,
    avatar: avatar,
    selected: null,
    checkmark: false,
    tooltip: tooltip,
    backgroundColor: backgroundColor,
    onPressed: onPressed,
  );
}

class InputChip extends StatelessWidget {
  const InputChip({
    this.clipBehavior,
    super.key,
    required this.label,
    this.avatar,
    this.selected = false,
    this.onSelected,
    this.onPressed,
    this.onDeleted,
    this.tooltip,
  });

  /// Accepted for API compatibility; shaped boxes clip through CSS.
  final Clip? clipBehavior;
  final Widget label;
  final Widget? avatar;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onPressed, onDeleted;
  final String? tooltip;
  @override
  Widget build(BuildContext context) => _SelectableChip(
    label: label,
    avatar: avatar,
    selected: onSelected == null ? null : selected,
    checkmark: true,
    tooltip: tooltip,
    onDeleted: onDeleted,
    onPressed:
        onPressed ?? (onSelected == null ? null : () => onSelected!(!selected)),
  );
}

class ButtonSegment<T> {
  const ButtonSegment({
    required this.value,
    this.icon,
    this.label,
    this.tooltip,
    this.enabled = true,
  });
  final T value;
  final Widget? icon, label;
  final String? tooltip;
  final bool enabled;
}

class SegmentedButton<T> extends StatelessWidget {
  const SegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.showSelectedIcon = true,
    this.selectedIcon,
    this.style,
  });
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final void Function(Set<T> selection)? onSelectionChanged;
  final bool multiSelectionEnabled, emptySelectionAllowed, showSelectedIcon;
  final Widget? selectedIcon;
  final ButtonStyle? style;

  void _toggle(T value) {
    final next = Set<T>.of(selected);
    if (multiSelectionEnabled) {
      if (!next.remove(value)) next.add(value);
    } else {
      if (next.contains(value)) {
        if (emptySelectionAllowed) next.clear();
      } else {
        next
          ..clear()
          ..add(value);
      }
    }
    if (next.isEmpty && !emptySelectionAllowed) return;
    onSelectionChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _Box(
      css:
          'display:inline-flex;flex-shrink:0;box-sizing:border-box;border:1px solid ${colorCss(scheme.outline)};border-radius:20px;overflow:hidden;',
      attributes: const {'role': 'group'},
      layout: _DomLayout.row,
      fill: _Fill.none,
      children: [
        for (var i = 0; i < segments.length; i++)
          () {
            final segment = segments[i];
            final isSelected = selected.contains(segment.value);
            final enabled = segment.enabled && onSelectionChanged != null;
            final foreground = !enabled
                ? scheme.onSurface.withValues(alpha: 0.38)
                : isSelected
                ? scheme.onSecondaryContainer
                : scheme.onSurface;
            return _Box(
              key: ValueKey(i),
              tag: 'button',
              css:
                  'display:inline-flex;align-items:center;justify-content:center;gap:8px;box-sizing:border-box;margin:0;min-height:40px;padding:0 12px;border:0;${i > 0 ? 'border-left:1px solid ${colorCss(scheme.outline)};' : ''}font:inherit;background-color:${isSelected ? colorCss(scheme.secondaryContainer) : 'transparent'};${_stateLayerCss(foreground)}',
              attributes: {
                'type': 'button',
                'class': 'fd-ink fd-button',
                'aria-pressed': '$isSelected',
                if (!enabled) 'disabled': '',
                if (segment.tooltip != null) 'title': segment.tooltip!,
              },
              handlers: {if (enabled) 'click': (_) => _toggle(segment.value)},
              layout: _DomLayout.row,
              fill: _Fill.none,
              children: [
                IconTheme.merge(
                  data: IconThemeData(color: foreground, size: 18),
                  child: DefaultTextStyle(
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: foreground,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        if (isSelected && showSelectedIcon)
                          selectedIcon ?? const Icon(Icons.check)
                        else
                          ?segment.icon,
                        ?segment.label,
                      ],
                    ),
                  ),
                ),
              ],
            );
          }(),
      ],
    );
  }
}

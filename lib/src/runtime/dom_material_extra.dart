part of 'flutter_dom.dart';

// ---------------------------------------------------------------------------
// Shared helpers.

/// Whether [event] originated on a native control (input, button, select)
/// that handles its own activation, so an enclosing row must not react too.
bool _fromNativeControl(_Event? event) {
  final target = event?.getProperty<JSObject?>('target'.toJS);
  if (target == null) return false;
  final tag = target.getProperty<JSString?>('tagName'.toJS)?.toDart;
  return switch (tag?.toLowerCase()) {
    'input' || 'button' || 'select' || 'textarea' => true,
    _ => false,
  };
}

void _stopPropagation(_Event? event) {
  if (event != null && event.has('stopPropagation')) {
    event.callMethod<JSAny?>('stopPropagation'.toJS);
  }
}

/// Plain text of a [Text] widget, for accessible names.
String? _plainText(Widget? widget) =>
    widget is Text ? widget.data ?? widget.textSpan?.toPlainText() : null;

/// Renders [css] as a `<style>` element (for pseudo-element rules).
class _StyleSheet extends _DomWidget {
  const _StyleSheet(this.rules);
  final String rules;
  @override
  String get _tag => 'style';
  @override
  _Fill get _fill => _Fill.none;
  @override
  void _render(_DomBuilder out) => out.text = rules;
}

/// Presents [child] visually while removing it from hit testing, focus and
/// the accessibility tree; the enclosing widget owns the interaction.
Widget _inertControl(Widget child) => _Box(
  tag: 'span',
  css: 'display:inline-flex;align-items:center;pointer-events:none;',
  attributes: const {'inert': '', 'aria-hidden': 'true'},
  layout: _DomLayout.row,
  fill: _Fill.none,
  children: [child],
);

// ---------------------------------------------------------------------------
// Selection list tiles.

enum ListTileControlAffinity { leading, trailing, platform }

class _ControlListTile extends StatelessWidget {
  const _ControlListTile({
    required this.role,
    required this.checked,
    required this.control,
    required this.controlLeading,
    required this.onToggle,
    required this.title,
    required this.subtitle,
    required this.secondary,
    required this.isThreeLine,
    required this.dense,
    required this.contentPadding,
    required this.selected,
    required this.tileColor,
    required this.selectedTileColor,
    required this.shape,
    required this.visualDensity,
    required this.selectedColor,
    required this.enabled,
    this.semanticLabel,
  });
  final String role, checked;
  final Widget control;
  final bool controlLeading, isThreeLine, selected, enabled;
  final VoidCallback? onToggle;
  final Widget? title, subtitle, secondary;
  final bool? dense;
  final EdgeInsetsGeometry? contentPadding;
  final Color? tileColor, selectedTileColor, selectedColor;
  final ShapeBorder? shape;
  final VisualDensity? visualDensity;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = enabled && onToggle != null;
    final inert = _inertControl(control);
    return _Box(
      css:
          'display:block;min-width:0;cursor:${active ? 'pointer' : 'default'};${shape == null ? '' : shapeCss(shape)}${_stateLayerCss(scheme.onSurface)}',
      attributes: {
        'role': role,
        'aria-checked': checked,
        if (active) 'tabindex': '0',
        if (active) 'class': 'fd-ink',
        if (!active) 'aria-disabled': 'true',
        if (semanticLabel != null) 'aria-label': semanticLabel!,
      },
      handlers: _activationHandlers(active ? onToggle : null),
      fill: _Fill.expand,
      children: [
        ListTile(
          leading: controlLeading ? inert : secondary,
          trailing: controlLeading ? secondary : inert,
          title: title,
          subtitle: subtitle,
          isThreeLine: isThreeLine,
          dense: dense,
          contentPadding: contentPadding,
          enabled: active,
          selected: selected,
          tileColor: tileColor,
          selectedTileColor: selectedTileColor,
          selectedColor: selectedColor,
          shape: shape,
          visualDensity: visualDensity,
        ),
      ],
    );
  }
}

class SwitchListTile extends StatelessWidget {
  const SwitchListTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.trackColor,
    this.trackOutlineColor,
    this.thumbIcon,
    this.materialTapTargetSize,
    this.mouseCursor,
    this.overlayColor,
    this.splashRadius,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    this.tileColor,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.contentPadding,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.shape,
    this.selectedTileColor,
    this.visualDensity,
    this.enableFeedback,
    this.hoverColor,
    this.enabled,
  });
  const SwitchListTile.adaptive({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.trackColor,
    this.trackOutlineColor,
    this.thumbIcon,
    this.materialTapTargetSize,
    this.mouseCursor,
    this.overlayColor,
    this.splashRadius,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    this.tileColor,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.contentPadding,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.shape,
    this.selectedTileColor,
    this.visualDensity,
    this.enableFeedback,
    this.hoverColor,
    this.enabled,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor, activeTrackColor;
  final Color? inactiveThumbColor, inactiveTrackColor;
  final WidgetStateProperty<Color?>? thumbColor, trackColor;
  final WidgetStateProperty<Color?>? trackOutlineColor, overlayColor;
  final WidgetStateProperty<Icon?>? thumbIcon;
  final MaterialTapTargetSize? materialTapTargetSize;
  final MouseCursor? mouseCursor;
  final double? splashRadius;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus, isThreeLine, selected;
  final Color? tileColor, selectedTileColor, hoverColor;
  final Widget? title, subtitle, secondary;
  final bool? dense, enableFeedback, enabled;
  final EdgeInsetsGeometry? contentPadding;
  final ListTileControlAffinity controlAffinity;
  final ShapeBorder? shape;
  final VisualDensity? visualDensity;

  @override
  Widget build(BuildContext context) {
    final active = onChanged != null && enabled != false;
    final states = {if (value) WidgetState.selected};
    return _ControlListTile(
      role: 'switch',
      checked: '$value',
      control: Switch(
        value: value,
        onChanged: active ? (_) {} : null,
        activeColor: activeColor,
        activeTrackColor: activeTrackColor ?? trackColor?.resolve(states),
        inactiveThumbColor: inactiveThumbColor,
        inactiveTrackColor: inactiveTrackColor,
        thumbIcon: thumbIcon,
      ),
      controlLeading: controlAffinity == ListTileControlAffinity.leading,
      onToggle: active ? () => onChanged!(!value) : null,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      isThreeLine: isThreeLine,
      dense: dense,
      contentPadding: contentPadding,
      selected: selected,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      selectedColor: activeColor,
      shape: shape,
      visualDensity: visualDensity,
      enabled: active,
    );
  }
}

class CheckboxListTile extends StatelessWidget {
  const CheckboxListTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.mouseCursor,
    this.activeColor,
    this.fillColor,
    this.checkColor,
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
    this.enabled,
    this.tileColor,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.contentPadding,
    this.tristate = false,
    this.checkboxShape,
    this.selectedTileColor,
    this.onFocusChange,
    this.enableFeedback,
    this.checkboxSemanticLabel,
  });
  const CheckboxListTile.adaptive({
    super.key,
    required this.value,
    required this.onChanged,
    this.mouseCursor,
    this.activeColor,
    this.fillColor,
    this.checkColor,
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
    this.enabled,
    this.tileColor,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.contentPadding,
    this.tristate = false,
    this.checkboxShape,
    this.selectedTileColor,
    this.onFocusChange,
    this.enableFeedback,
    this.checkboxSemanticLabel,
  });
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final MouseCursor? mouseCursor;
  final Color? activeColor, checkColor, hoverColor;
  final WidgetStateProperty<Color?>? fillColor, overlayColor;
  final double? splashRadius;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;
  final FocusNode? focusNode;
  final bool autofocus, isError, isThreeLine, selected, tristate;
  final ShapeBorder? shape;
  final BorderSide? side;
  final bool? enabled, dense, enableFeedback;
  final Color? tileColor, selectedTileColor;
  final Widget? title, subtitle, secondary;
  final ListTileControlAffinity controlAffinity;
  final EdgeInsetsGeometry? contentPadding;
  final OutlinedBorder? checkboxShape;
  final ValueChanged<bool>? onFocusChange;
  final String? checkboxSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final active = onChanged != null && enabled != false;
    final next = tristate
        ? (value == false ? true : (value == true ? null : false))
        : !(value ?? false);
    return _ControlListTile(
      role: 'checkbox',
      checked: value == null ? 'mixed' : '$value',
      control: Checkbox(
        value: value,
        tristate: tristate,
        onChanged: active ? (_) {} : null,
        activeColor: activeColor ?? fillColor?.resolve({WidgetState.selected}),
      ),
      controlLeading: controlAffinity == ListTileControlAffinity.leading,
      onToggle: active ? () => onChanged!(next) : null,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      isThreeLine: isThreeLine,
      dense: dense,
      contentPadding: contentPadding,
      selected: selected,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      selectedColor: activeColor,
      shape: shape,
      visualDensity: visualDensity,
      enabled: active,
      semanticLabel: checkboxSemanticLabel,
    );
  }
}

class RadioListTile<T> extends StatelessWidget {
  const RadioListTile({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.fillColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.autofocus = false,
    this.contentPadding,
    this.shape,
    this.tileColor,
    this.selectedTileColor,
    this.visualDensity,
    this.focusNode,
    this.onFocusChange,
    this.enableFeedback,
    this.enabled,
  });
  const RadioListTile.adaptive({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.fillColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.autofocus = false,
    this.contentPadding,
    this.shape,
    this.tileColor,
    this.selectedTileColor,
    this.visualDensity,
    this.focusNode,
    this.onFocusChange,
    this.enableFeedback,
    this.enabled,
  });
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final MouseCursor? mouseCursor;
  final bool toggleable, isThreeLine, selected, autofocus;
  final Color? activeColor, hoverColor, tileColor, selectedTileColor;
  final WidgetStateProperty<Color?>? fillColor, overlayColor;
  final double? splashRadius;
  final MaterialTapTargetSize? materialTapTargetSize;
  final Widget? title, subtitle, secondary;
  final bool? dense, enableFeedback, enabled;
  final ListTileControlAffinity controlAffinity;
  final EdgeInsetsGeometry? contentPadding;
  final ShapeBorder? shape;
  final VisualDensity? visualDensity;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context) {
    final active = onChanged != null && enabled != false;
    final checked = value == groupValue;
    return _ControlListTile(
      role: 'radio',
      checked: '$checked',
      control: Radio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: active ? (_) {} : null,
        activeColor: activeColor ?? fillColor?.resolve({WidgetState.selected}),
      ),
      // Radios lead on the platform affinity, as in Flutter.
      controlLeading: controlAffinity != ListTileControlAffinity.trailing,
      onToggle: active
          ? () {
              if (checked && toggleable) {
                onChanged!(null);
              } else if (!checked) {
                onChanged!(value);
              }
            }
          : null,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      isThreeLine: isThreeLine,
      dense: dense,
      contentPadding: contentPadding,
      selected: selected,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      selectedColor: activeColor,
      shape: shape,
      visualDensity: visualDensity,
      enabled: active,
    );
  }
}

// ---------------------------------------------------------------------------
// Range sliders on two overlaid native range inputs.

class RangeValues {
  const RangeValues(this.start, this.end);
  final double start, end;
  @override
  bool operator ==(Object other) =>
      other is RangeValues && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
  @override
  String toString() => 'RangeValues($start, $end)';
}

class RangeLabels {
  const RangeLabels(this.start, this.end);
  final String start, end;
  @override
  bool operator ==(Object other) =>
      other is RangeLabels && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
  @override
  String toString() => 'RangeLabels($start, $end)';
}

const _rangeSliderRules =
    '.fd-range{-webkit-appearance:none;appearance:none;background:transparent;pointer-events:none;outline:none}'
    '.fd-range::-webkit-slider-runnable-track{height:40px;background:transparent}'
    '.fd-range::-webkit-slider-thumb{-webkit-appearance:none;pointer-events:auto;width:20px;height:20px;margin-top:10px;border:0;border-radius:50%;background:var(--fd-range-thumb);cursor:pointer}'
    '.fd-range::-moz-range-track{background:transparent}'
    '.fd-range::-moz-range-thumb{pointer-events:auto;width:20px;height:20px;border:0;border-radius:50%;background:var(--fd-range-thumb);cursor:pointer}'
    '.fd-range:focus-visible::-webkit-slider-thumb{outline:2px solid var(--fd-range-thumb);outline-offset:2px}'
    '.fd-range:focus-visible::-moz-range-thumb{outline:2px solid var(--fd-range-thumb);outline-offset:2px}'
    '.fd-range:disabled{opacity:.38}';

class RangeSlider extends StatelessWidget {
  const RangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.labels,
    this.activeColor,
    this.inactiveColor,
    this.overlayColor,
    this.mouseCursor,
    this.semanticFormatterCallback,
  });
  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged, onChangeStart, onChangeEnd;
  final double min, max;
  final int? divisions;
  final RangeLabels? labels;
  final Color? activeColor, inactiveColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final String Function(double value)? semanticFormatterCallback;

  @override
  Widget build(BuildContext context) {
    if (!(min < max) || !min.isFinite || !max.isFinite)
      throw ArgumentError('RangeSlider requires finite min < max.');
    if (values.start > values.end || values.start < min || values.end > max) {
      throw ArgumentError(
        'RangeSlider values must satisfy min <= start <= end <= max.',
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final enabled = onChanged != null;
    final active = enabled
        ? activeColor ?? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.38);
    final inactive = enabled
        ? inactiveColor ?? scheme.secondaryContainer
        : scheme.onSurface.withValues(alpha: 0.12);
    final span = max - min;
    final from = (values.start - min) / span;
    final to = (values.end - min) / span;
    final step = divisions == null || divisions! < 1
        ? 'any'
        : '${span / divisions!}';
    double read(_DomElement element) => double.parse(
      (element.node as JSObject).getProperty<JSString>('value'.toJS).toDart,
    );
    RangeValues next(_DomElement element, bool start) {
      final value = read(element);
      return start
          ? RangeValues(math.min(value, values.end), values.end)
          : RangeValues(values.start, math.max(value, values.start));
    }

    String? text(double value, String? label) =>
        label ?? semanticFormatterCallback?.call(value);

    Widget input(bool start) {
      final value = start ? values.start : values.end;
      final valueText = text(value, start ? labels?.start : labels?.end);
      return _NativeControl(
        tag: 'input',
        css:
            'position:absolute;left:0;top:0;width:100%;height:40px;margin:0;padding:0;${start ? '' : 'z-index:1;'}',
        attributes: {
          'type': 'range',
          'class': 'fd-range',
          'min': cssNumber(min),
          'max': cssNumber(max),
          'step': step,
          'aria-label': start ? 'Range start' : 'Range end',
          if (valueText != null) 'aria-valuetext': valueText,
          if (valueText != null) 'title': valueText,
          if (!enabled) 'disabled': '',
        },
        properties: {'value': '$value'},
        events: {
          'input': (element, _) => onChanged?.call(next(element, start)),
          'pointerdown': (element, _) => onChangeStart?.call(values),
          'change': (element, _) => onChangeEnd?.call(next(element, start)),
        },
      );
    }

    String inset(double fraction) =>
        'calc(10px + (100% - 20px) * ${cssNumber(fraction)})';
    return _Box(
      css:
          'position:relative;box-sizing:border-box;height:40px;min-width:0;margin:4px 0;--fd-range-thumb:${colorCss(active)};',
      attributes: const {'role': 'group'},
      fill: _Fill.expand,
      children: [
        const _StyleSheet(_rangeSliderRules),
        _Box(
          css:
              'position:absolute;left:10px;right:10px;top:18px;height:4px;border-radius:2px;background-color:${colorCss(inactive)};',
          fill: _Fill.none,
        ),
        _Box(
          css:
              'position:absolute;top:17px;height:6px;border-radius:3px;left:${inset(from)};width:calc((100% - 20px) * ${cssNumber(to - from)});background-color:${colorCss(active)};',
          fill: _Fill.none,
        ),
        input(true),
        input(false),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle buttons.

class ToggleButtons extends StatelessWidget {
  const ToggleButtons({
    super.key,
    required this.children,
    required this.isSelected,
    this.onPressed,
    this.mouseCursor,
    this.tapTargetSize,
    this.textStyle,
    this.constraints,
    this.color,
    this.selectedColor,
    this.disabledColor,
    this.fillColor,
    this.focusColor,
    this.highlightColor,
    this.hoverColor,
    this.splashColor,
    this.focusNodes,
    this.renderBorder = true,
    this.borderColor,
    this.selectedBorderColor,
    this.disabledBorderColor,
    this.borderRadius,
    this.borderWidth,
    this.direction = Axis.horizontal,
    this.verticalDirection = VerticalDirection.down,
  });
  final List<Widget> children;
  final List<bool> isSelected;
  final void Function(int index)? onPressed;
  final MouseCursor? mouseCursor;
  final MaterialTapTargetSize? tapTargetSize;
  final TextStyle? textStyle;
  final BoxConstraints? constraints;
  final Color? color, selectedColor, disabledColor, fillColor;
  final Color? focusColor, highlightColor, hoverColor, splashColor;
  final List<FocusNode>? focusNodes;
  final bool renderBorder;
  final Color? borderColor, selectedBorderColor, disabledBorderColor;
  final BorderRadius? borderRadius;
  final double? borderWidth;
  final Axis direction;
  final VerticalDirection verticalDirection;

  @override
  Widget build(BuildContext context) {
    if (children.length != isSelected.length)
      throw ArgumentError(
        'ToggleButtons children and isSelected must have the same length.',
      );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onPressed != null;
    final vertical = direction == Axis.vertical;
    final width = borderWidth ?? 1;
    final edge = colorCss(
      !enabled
          ? disabledBorderColor ?? scheme.onSurface.withValues(alpha: 0.12)
          : borderColor ?? scheme.onSurface.withValues(alpha: 0.12),
    );
    final minWidth = constraints?.minWidth ?? 48;
    final minHeight = constraints?.minHeight ?? 48;
    return _Box(
      css:
          'display:inline-flex;flex-direction:${vertical ? (verticalDirection == VerticalDirection.up ? 'column-reverse' : 'column') : 'row'};flex-shrink:0;box-sizing:border-box;overflow:hidden;'
          '${renderBorder ? 'border:${px(width)} solid $edge;' : ''}${borderRadiusCss(borderRadius)}',
      attributes: const {'role': 'group'},
      layout: vertical ? _DomLayout.column : _DomLayout.row,
      fill: _Fill.none,
      children: [
        for (var i = 0; i < children.length; i++)
          () {
            final selected = isSelected[i];
            final foreground = !enabled
                ? disabledColor ?? scheme.onSurface.withValues(alpha: 0.38)
                : selected
                ? selectedColor ?? scheme.primary
                : color ?? scheme.onSurface.withValues(alpha: 0.87);
            final background = selected && enabled
                ? fillColor ?? scheme.primary.withValues(alpha: 0.12)
                : null;
            final separator = i == 0 || !renderBorder
                ? ''
                : '${vertical ? 'border-top' : 'border-left'}:${px(width)} solid ${selected && selectedBorderColor != null ? colorCss(selectedBorderColor!) : edge};';
            return _Box(
              key: ValueKey(i),
              tag: 'button',
              css:
                  'display:inline-flex;align-items:center;justify-content:center;box-sizing:border-box;margin:0;padding:0 ${vertical ? 0 : 8}px;border:0;$separator'
                  'min-width:${px(minWidth)};min-height:${px(minHeight)};font:inherit;'
                  'background-color:${background == null ? 'transparent' : colorCss(background)};${_stateLayerCss(foreground)}',
              attributes: {
                'type': 'button',
                'class': 'fd-ink fd-button',
                'aria-pressed': '$selected',
                if (!enabled) 'disabled': '',
              },
              handlers: {if (enabled) 'click': (_) => onPressed!(i)},
              layout: _DomLayout.row,
              fill: _Fill.none,
              children: [
                IconTheme.merge(
                  data: IconThemeData(color: foreground, size: 24),
                  child: DefaultTextStyle(
                    style: theme.textTheme.bodyMedium!
                        .merge(textStyle)
                        .copyWith(color: foreground),
                    child: children[i],
                  ),
                ),
              ],
            );
          }(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Steppers.

enum StepState { indexed, editing, complete, disabled, error }

enum StepperType { vertical, horizontal }

class StepStyle {
  const StepStyle({
    this.color,
    this.errorColor,
    this.connectorColor,
    this.connectorThickness,
    this.border,
    this.boxShadow,
    this.gradient,
    this.indexStyle,
  });
  final Color? color, errorColor, connectorColor;
  final double? connectorThickness;
  final BoxBorder? border;
  final BoxShadow? boxShadow;
  final Gradient? gradient;
  final TextStyle? indexStyle;
}

class Step {
  const Step({
    required this.title,
    this.subtitle,
    required this.content,
    this.state = StepState.indexed,
    this.isActive = false,
    this.label,
    this.stepStyle,
  });
  final Widget title;
  final Widget? subtitle, label;
  final Widget content;
  final StepState state;
  final bool isActive;
  final StepStyle? stepStyle;
}

class ControlsDetails {
  const ControlsDetails({
    required this.currentStep,
    required this.stepIndex,
    this.onStepCancel,
    this.onStepContinue,
  });
  final int currentStep, stepIndex;
  final VoidCallback? onStepCancel, onStepContinue;
  bool get isActive => currentStep == stepIndex;
}

typedef ControlsWidgetBuilder =
    Widget Function(BuildContext context, ControlsDetails details);
typedef StepIconBuilder = Widget? Function(int stepIndex, StepState stepState);

class Stepper extends StatelessWidget {
  const Stepper({
    super.key,
    required this.steps,
    this.controller,
    this.physics,
    this.type = StepperType.vertical,
    this.currentStep = 0,
    this.onStepTapped,
    this.onStepContinue,
    this.onStepCancel,
    this.controlsBuilder,
    this.elevation,
    this.margin,
    this.connectorColor,
    this.connectorThickness,
    this.stepIconBuilder,
    this.stepIconHeight,
    this.stepIconWidth,
    this.stepIconMargin,
    this.clipBehavior = Clip.none,
  });
  final List<Step> steps;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final StepperType type;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;
  final VoidCallback? onStepContinue, onStepCancel;
  final ControlsWidgetBuilder? controlsBuilder;
  final double? elevation, connectorThickness;
  final EdgeInsetsGeometry? margin, stepIconMargin;
  final WidgetStateProperty<Color>? connectorColor;
  final StepIconBuilder? stepIconBuilder;
  final double? stepIconHeight, stepIconWidth;
  final Clip clipBehavior;

  Widget _icon(BuildContext context, int index) {
    final step = steps[index];
    final custom = stepIconBuilder?.call(index, step.state);
    final scheme = Theme.of(context).colorScheme;
    final error = step.state == StepState.error;
    final background = error
        ? step.stepStyle?.errorColor ?? scheme.error
        : step.isActive
        ? step.stepStyle?.color ?? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.38);
    final foreground = error ? scheme.onError : scheme.onPrimary;
    final size = stepIconWidth ?? stepIconHeight ?? 24;
    final glyph =
        custom ??
        switch (step.state) {
          StepState.editing => Icon(Icons.edit, size: 18, color: foreground),
          StepState.complete => Icon(Icons.check, size: 18, color: foreground),
          StepState.error => Text(
            '!',
            style: TextStyle(color: foreground, fontSize: 14),
          ),
          _ => Text(
            '${index + 1}',
            style: TextStyle(
              color: foreground,
              fontSize: 12,
            ).merge(step.stepStyle?.indexStyle),
          ),
        };
    return _Box(
      css:
          'display:flex;align-items:center;justify-content:center;flex-shrink:0;box-sizing:border-box;width:${px(size)};height:${px(stepIconHeight ?? size)};border-radius:50%;background-color:${colorCss(background)};${edgeInsetsCss('margin', stepIconMargin)}',
      attributes: const {'aria-hidden': 'true'},
      layout: _DomLayout.align,
      fill: _Fill.none,
      children: [glyph],
    );
  }

  Color _connector(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final step = steps[index];
    return step.stepStyle?.connectorColor ??
        connectorColor?.resolve({if (step.isActive) WidgetState.selected}) ??
        scheme.outline;
  }

  Widget _header(BuildContext context, int index, {required bool vertical}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final step = steps[index];
    final enabled = step.state != StepState.disabled && onStepTapped != null;
    final titleColor = step.state == StepState.disabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : step.state == StepState.error
        ? scheme.error
        : scheme.onSurface;
    return _Box(
      tag: 'button',
      css:
          'display:flex;align-items:center;gap:12px;box-sizing:border-box;margin:0;border:0;padding:${vertical ? '12px 24px' : '0 8px'};min-height:${vertical ? 48 : 72}px;background:transparent;font:inherit;text-align:left;${vertical ? 'width:100%;' : 'flex-shrink:0;'}cursor:${enabled ? 'pointer' : 'default'};${_stateLayerCss(scheme.onSurface)}',
      attributes: {
        'type': 'button',
        'class': 'fd-ink fd-button',
        if (index == currentStep) 'aria-current': 'step',
        if (!enabled) 'aria-disabled': 'true',
      },
      handlers: {if (enabled) 'click': (_) => onStepTapped!(index)},
      layout: _DomLayout.row,
      fill: vertical ? _Fill.expand : _Fill.none,
      children: [
        _icon(context, index),
        _Box(
          css: 'display:flex;flex-direction:column;min-width:0;',
          layout: _DomLayout.column,
          fill: _Fill.none,
          children: [
            DefaultTextStyle(
              style: theme.textTheme.titleSmall!.copyWith(
                color: titleColor,
                fontWeight: index == currentStep ? FontWeight.w600 : null,
              ),
              child: step.title,
            ),
            if (step.subtitle != null)
              DefaultTextStyle(
                style: theme.textTheme.bodySmall!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                child: step.subtitle!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _controls(BuildContext context, int index) {
    final details = ControlsDetails(
      currentStep: currentStep,
      stepIndex: index,
      onStepContinue: onStepContinue,
      onStepCancel: onStepCancel,
    );
    if (controlsBuilder != null) return controlsBuilder!(context, details);
    final strings = MaterialLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        spacing: 8,
        children: [
          FilledButton(
            onPressed: onStepContinue,
            child: Text(strings.continueButtonLabel),
          ),
          TextButton(
            onPressed: onStepCancel,
            child: Text(strings.cancelButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (steps.isNotEmpty && (currentStep < 0 || currentStep >= steps.length))
      throw RangeError.index(currentStep, steps, 'currentStep');
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final thickness = connectorThickness ?? 1;
    if (type == StepperType.horizontal) {
      return _Box(
        css: 'display:flex;flex-direction:column;min-width:0;',
        attributes: const {'role': 'group'},
        layout: _DomLayout.column,
        fill: _Fill.expand,
        children: [
          _Box(
            css:
                'display:flex;flex-direction:row;align-items:center;min-width:0;overflow-x:auto;padding:0 16px;background-color:${colorCss(scheme.surface)};${elevationCss(elevation ?? 2, scheme.shadow)}',
            layout: _DomLayout.row,
            fill: _Fill.expand,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                _header(context, i, vertical: false),
                if (i < steps.length - 1)
                  _Box(
                    css:
                        'flex:1 1 0;min-width:16px;height:0;border-top:${px(thickness)} solid ${colorCss(steps[i].stepStyle?.connectorColor ?? _connector(context, i))};margin:0 8px;',
                    attributes: const {'aria-hidden': 'true'},
                    fill: _Fill.none,
                  ),
              ],
            ],
          ),
          if (steps.isNotEmpty)
            _Box(
              css:
                  'display:flex;flex-direction:column;min-width:0;${edgeInsetsCss('padding', margin ?? const EdgeInsets.all(24))}',
              attributes: const {'role': 'region'},
              layout: _DomLayout.column,
              fill: _Fill.expand,
              children: [
                KeyedSubtree(
                  key: ValueKey(currentStep),
                  child: steps[currentStep].content,
                ),
                _controls(context, currentStep),
              ],
            ),
        ],
      );
    }
    return _Box(
      css: 'display:flex;flex-direction:column;min-width:0;padding:8px 0;',
      attributes: const {'role': 'group'},
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [
        for (var i = 0; i < steps.length; i++)
          _Box(
            key: ValueKey(i),
            css: 'display:flex;flex-direction:column;min-width:0;',
            layout: _DomLayout.column,
            fill: _Fill.expand,
            children: [
              _header(context, i, vertical: true),
              _Box(
                css:
                    'box-sizing:border-box;min-width:0;min-height:${i < steps.length - 1 ? 24 : 0}px;margin-left:36px;${edgeInsetsCss('padding', margin ?? const EdgeInsets.only(left: 24, right: 24, bottom: 8))}'
                    '${i < steps.length - 1 ? 'border-left:${px(thickness)} solid ${colorCss(_connector(context, i))};' : 'border-left:${px(thickness)} solid transparent;'}',
                attributes: {if (i == currentStep) 'role': 'region'},
                layout: _DomLayout.column,
                fill: _Fill.expand,
                children: [
                  if (i == currentStep) ...[
                    steps[i].content,
                    _controls(context, i),
                  ],
                ],
              ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data tables.

typedef DataColumnSortCallback = void Function(int columnIndex, bool ascending);

class DataColumn {
  const DataColumn({
    required this.label,
    this.columnWidth,
    this.tooltip,
    this.numeric = false,
    this.onSort,
    this.mouseCursor,
    this.headingRowAlignment,
  });
  final Widget label;
  final TableColumnWidth? columnWidth;
  final String? tooltip;
  final bool numeric;
  final DataColumnSortCallback? onSort;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final MainAxisAlignment? headingRowAlignment;
}

class DataRow {
  const DataRow({
    this.key,
    this.selected = false,
    this.onSelectChanged,
    this.onLongPress,
    this.color,
    this.mouseCursor,
    required this.cells,
  });
  DataRow.byIndex({
    int? index,
    this.selected = false,
    this.onSelectChanged,
    this.onLongPress,
    this.color,
    this.mouseCursor,
    required this.cells,
  }) : key = ValueKey<int?>(index);
  final LocalKey? key;
  final bool selected;
  final ValueChanged<bool?>? onSelectChanged;
  final GestureLongPressCallback? onLongPress;
  final WidgetStateProperty<Color?>? color;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final List<DataCell> cells;
}

class DataCell {
  const DataCell(
    this.child, {
    this.placeholder = false,
    this.showEditIcon = false,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.onDoubleTap,
    this.onTapCancel,
  });
  static const DataCell empty = DataCell(SizedBox.shrink());
  final Widget child;
  final bool placeholder, showEditIcon;
  final GestureTapCallback? onTap, onLongPress, onDoubleTap, onTapCancel;
  final GestureTapDownCallback? onTapDown;
}

class DataTable extends StatelessWidget {
  const DataTable({
    super.key,
    required this.columns,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
    this.decoration,
    this.dataRowColor,
    this.dataRowHeight,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.dataTextStyle,
    this.headingRowColor,
    this.headingRowHeight,
    this.headingTextStyle,
    this.horizontalMargin,
    this.columnSpacing,
    this.showCheckboxColumn = true,
    this.showBottomBorder = false,
    this.dividerThickness,
    required this.rows,
    this.checkboxHorizontalMargin,
    this.border,
    this.clipBehavior = Clip.none,
  });
  final List<DataColumn> columns;
  final int? sortColumnIndex;
  final bool sortAscending, showCheckboxColumn, showBottomBorder;
  final ValueSetter<bool?>? onSelectAll;
  final Decoration? decoration;
  final WidgetStateProperty<Color?>? dataRowColor, headingRowColor;
  final double? dataRowHeight, dataRowMinHeight, dataRowMaxHeight;
  final TextStyle? dataTextStyle, headingTextStyle;
  final double? headingRowHeight, horizontalMargin, columnSpacing;
  final double? dividerThickness, checkboxHorizontalMargin;
  final List<DataRow> rows;
  final TableBorder? border;
  final Clip clipBehavior;

  void _selectAll(bool checked) {
    if (onSelectAll != null) {
      onSelectAll!(checked);
      return;
    }
    for (final row in rows) {
      if (row.onSelectChanged != null && row.selected != checked) {
        row.onSelectChanged!(checked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sortColumnIndex != null &&
        (sortColumnIndex! < 0 || sortColumnIndex! >= columns.length))
      throw RangeError.index(sortColumnIndex!, columns, 'sortColumnIndex');
    for (final row in rows) {
      if (row.cells.length != columns.length)
        throw ArgumentError('Each DataRow needs one DataCell per DataColumn.');
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final checkboxes =
        showCheckboxColumn && rows.any((row) => row.onSelectChanged != null);
    final margin = horizontalMargin ?? 24;
    final spacing = columnSpacing ?? 56;
    final divider = dividerThickness ?? 1;
    final line = '${px(divider)} solid ${colorCss(theme.dividerColor)}';
    final headStyle = theme.textTheme.titleSmall!
        .copyWith(color: scheme.onSurface)
        .merge(headingTextStyle);
    final bodyStyle = theme.textTheme.bodyMedium!
        .copyWith(color: scheme.onSurface)
        .merge(dataTextStyle);
    final rowHeight = dataRowMinHeight ?? dataRowHeight ?? 48;
    final selectedCount = rows.where((row) => row.selected).length;
    final allSelected = rows.isNotEmpty && selectedCount == rows.length;
    final vertical = border?.verticalInside;
    final verticalCss = vertical == null
        ? ''
        : borderSideCss('border-left', vertical);

    String padding(int column) {
      final first = column == 0 && !checkboxes;
      final last = column == columns.length - 1;
      return 'padding:0 ${px(last ? margin : spacing / 2)} 0 ${px(first ? margin : spacing / 2)};';
    }

    String checkboxPadding() =>
        'padding:0 ${px(margin / 2)} 0 ${px(checkboxHorizontalMargin ?? margin)};width:1px;';

    final headingBackground = headingRowColor?.resolve(const {});
    final header = _Box(
      tag: 'tr',
      css:
          'height:${px(headingRowHeight ?? 56)};${headingBackground == null ? '' : 'background-color:${colorCss(headingBackground)};'}',
      fill: _Fill.none,
      children: [
        if (checkboxes)
          _Box(
            tag: 'th',
            css: '${checkboxPadding()}text-align:left;',
            attributes: const {'scope': 'col'},
            fill: _Fill.none,
            children: [
              Checkbox(
                value: allSelected ? true : (selectedCount > 0 ? null : false),
                tristate: true,
                semanticLabel: 'Select all',
                onChanged: (_) => _selectAll(!allSelected),
              ),
            ],
          ),
        for (var c = 0; c < columns.length; c++)
          () {
            final column = columns[c];
            final sorted = sortColumnIndex == c;
            final label = DefaultTextStyle(
              style: headStyle,
              child: column.label,
            );
            final alignment =
                column.headingRowAlignment ??
                (column.numeric
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start);
            final justify = switch (alignment) {
              MainAxisAlignment.end => 'flex-end',
              MainAxisAlignment.center => 'center',
              _ => 'flex-start',
            };
            final arrow = _Box(
              tag: 'span',
              css:
                  'display:inline-flex;transition:transform .15s;${sorted ? '' : 'opacity:0;'}${sorted && !sortAscending ? 'transform:rotate(180deg);' : ''}',
              attributes: const {'aria-hidden': 'true'},
              fill: _Fill.none,
              children: [
                Icon(Icons.arrow_upward, size: 18, color: scheme.onSurface),
              ],
            );
            final content = column.onSort == null
                ? _Box(
                    css:
                        'display:flex;align-items:center;justify-content:$justify;gap:2px;',
                    layout: _DomLayout.row,
                    fill: _Fill.none,
                    children: [label],
                  )
                : _Box(
                    tag: 'button',
                    css:
                        'display:flex;align-items:center;justify-content:$justify;gap:2px;width:100%;box-sizing:border-box;margin:0;padding:0;border:0;background:transparent;font:inherit;cursor:pointer;${_stateLayerCss(scheme.onSurface)}',
                    attributes: const {'type': 'button', 'class': 'fd-button'},
                    handlers: {
                      'click': (_) =>
                          column.onSort!(c, sorted ? !sortAscending : true),
                    },
                    layout: _DomLayout.row,
                    fill: _Fill.none,
                    children: column.numeric ? [arrow, label] : [label, arrow],
                  );
            return _Box(
              key: ValueKey(c),
              tag: 'th',
              css:
                  '${padding(c)}text-align:${column.numeric ? 'right' : 'left'};font-weight:inherit;white-space:nowrap;${c > 0 || checkboxes ? verticalCss : ''}',
              attributes: {
                'scope': 'col',
                if (sorted)
                  'aria-sort': sortAscending ? 'ascending' : 'descending',
                if (column.tooltip != null) 'title': column.tooltip!,
              },
              fill: _Fill.none,
              children: [content],
            );
          }(),
      ],
    );

    final body = <Widget>[];
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      final states = {if (row.selected) WidgetState.selected};
      final background =
          row.color?.resolve(states) ??
          dataRowColor?.resolve(states) ??
          (row.selected ? scheme.primary.withValues(alpha: 0.08) : null);
      final selectable = row.onSelectChanged != null;
      final lastRow = r == rows.length - 1;
      body.add(
        _Box(
          key: row.key ?? ValueKey(r),
          tag: 'tr',
          css:
              'height:${px(rowHeight)};${dataRowMaxHeight == null || dataRowMaxHeight == double.infinity ? '' : 'max-height:${px(dataRowMaxHeight!)};'}'
              '${lastRow && !showBottomBorder ? '' : 'border-bottom:$line;'}'
              '${background == null ? '' : 'background-color:${colorCss(background)};'}${selectable ? 'cursor:pointer;' : ''}${_stateLayerCss(scheme.onSurface)}',
          attributes: {
            if (selectable) 'aria-selected': '${row.selected}',
            if (selectable) 'class': 'fd-ink',
          },
          handlers: {
            if (selectable)
              'click': (event) {
                if (_fromNativeControl(event)) return;
                row.onSelectChanged!(!row.selected);
              },
            if (row.onLongPress != null)
              'contextmenu': (event) {
                event?.preventDefault();
                row.onLongPress!();
              },
          },
          fill: _Fill.none,
          children: [
            if (checkboxes)
              _Box(
                tag: 'td',
                css: checkboxPadding(),
                fill: _Fill.none,
                children: [
                  Checkbox(
                    value: row.selected,
                    semanticLabel: 'Select row ${r + 1}',
                    onChanged: selectable
                        ? (value) => row.onSelectChanged!(value)
                        : null,
                  ),
                ],
              ),
            for (var c = 0; c < columns.length; c++)
              () {
                final cell = row.cells[c];
                final numeric = columns[c].numeric;
                final tap = cell.onTap;
                return _Box(
                  key: ValueKey(c),
                  tag: 'td',
                  css:
                      '${padding(c)}text-align:${numeric ? 'right' : 'left'};${c > 0 || checkboxes ? verticalCss : ''}${tap == null ? '' : 'cursor:pointer;'}',
                  attributes: {if (tap != null) 'tabindex': '0'},
                  handlers: {
                    if (tap != null)
                      'click': (event) {
                        _stopPropagation(event);
                        tap();
                      },
                    if (tap != null)
                      'keydown': (event) {
                        final key = event?.key;
                        if (key == 'Enter' || key == ' ') {
                          event?.preventDefault();
                          tap();
                        }
                      },
                    if (cell.onDoubleTap != null)
                      'dblclick': (_) => cell.onDoubleTap!(),
                    if (cell.onLongPress != null)
                      'contextmenu': (event) {
                        event?.preventDefault();
                        _stopPropagation(event);
                        cell.onLongPress!();
                      },
                  },
                  fill: _Fill.none,
                  children: [
                    DefaultTextStyle(
                      style: cell.placeholder
                          ? bodyStyle.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            )
                          : bodyStyle,
                      child: cell.showEditIcon
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                Flexible(child: cell.child),
                                Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            )
                          : cell.child,
                    ),
                  ],
                );
              }(),
          ],
        ),
      );
    }

    final outer = border == null
        ? ''
        : borderSideCss('border-top', border!.top) +
              borderSideCss('border-right', border!.right) +
              borderSideCss('border-bottom', border!.bottom) +
              borderSideCss('border-left', border!.left) +
              borderRadiusCss(border!.borderRadius);
    return _Box(
      css:
          'display:inline-block;max-width:100%;overflow-x:auto;${decorationCss(decoration)}$outer${clipBehavior == Clip.none ? '' : 'overflow:hidden;'}',
      fill: _Fill.none,
      children: [
        _Box(
          tag: 'table',
          css:
              'border-collapse:collapse;border-spacing:0;${textStyleCss(bodyStyle)}',
          fill: _Fill.none,
          children: [
            _Box(
              tag: 'thead',
              css: 'border-bottom:$line;',
              fill: _Fill.none,
              children: [header],
            ),
            _Box(tag: 'tbody', fill: _Fill.none, children: body),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Expansion panels.

typedef ExpansionPanelCallback = void Function(int panelIndex, bool isExpanded);
typedef ExpansionPanelHeaderBuilder =
    Widget Function(BuildContext context, bool isExpanded);

class ExpansionPanel {
  ExpansionPanel({
    required this.headerBuilder,
    required this.body,
    this.isExpanded = false,
    this.canTapOnHeader = false,
    this.backgroundColor,
    this.splashColor,
    this.highlightColor,
  });
  final ExpansionPanelHeaderBuilder headerBuilder;
  final Widget body;
  final bool isExpanded, canTapOnHeader;
  final Color? backgroundColor, splashColor, highlightColor;
}

class ExpansionPanelRadio extends ExpansionPanel {
  ExpansionPanelRadio({
    required this.value,
    required super.headerBuilder,
    required super.body,
    super.canTapOnHeader,
    super.backgroundColor,
    super.splashColor,
    super.highlightColor,
  });
  final Object value;
}

class ExpansionPanelList extends StatefulWidget {
  const ExpansionPanelList({
    super.key,
    this.children = const <ExpansionPanel>[],
    this.expansionCallback,
    this.animationDuration = const Duration(milliseconds: 200),
    this.expandedHeaderPadding = const EdgeInsets.symmetric(vertical: 16),
    this.dividerColor,
    this.elevation = 2,
    this.expandIconColor,
    this.materialGapSize = 16,
  }) : _radio = false,
       initialOpenPanelValue = null;
  const ExpansionPanelList.radio({
    super.key,
    this.children = const <ExpansionPanelRadio>[],
    this.expansionCallback,
    this.animationDuration = const Duration(milliseconds: 200),
    this.initialOpenPanelValue,
    this.expandedHeaderPadding = const EdgeInsets.symmetric(vertical: 16),
    this.dividerColor,
    this.elevation = 2,
    this.expandIconColor,
    this.materialGapSize = 16,
  }) : _radio = true;
  final List<ExpansionPanel> children;
  final ExpansionPanelCallback? expansionCallback;
  final Duration animationDuration;
  final Object? initialOpenPanelValue;
  final EdgeInsets expandedHeaderPadding;
  final Color? dividerColor, expandIconColor;
  final double elevation, materialGapSize;
  final bool _radio;
  @override
  State<ExpansionPanelList> createState() => _ExpansionPanelListState();
}

class _ExpansionPanelListState extends State<ExpansionPanelList> {
  Object? _open;
  late final _id = 'fd-panel-${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    if (widget._radio) _open = widget.initialOpenPanelValue;
  }

  bool _expanded(int index) {
    final panel = widget.children[index];
    if (widget._radio) {
      return panel is ExpansionPanelRadio && panel.value == _open;
    }
    return panel.isExpanded;
  }

  void _toggle(int index) {
    final expanded = _expanded(index);
    widget.expansionCallback?.call(index, !expanded);
    if (!widget._radio) return;
    final panel = widget.children[index] as ExpansionPanelRadio;
    for (var i = 0; i < widget.children.length; i++) {
      final other = widget.children[i];
      if (i != index && other is ExpansionPanelRadio && other.value == _open) {
        widget.expansionCallback?.call(i, false);
      }
    }
    setState(() => _open = expanded ? null : panel.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final children = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      final panel = widget.children[i];
      final expanded = _expanded(i);
      final previousExpanded = i > 0 && _expanded(i - 1);
      final gap = i > 0 && (expanded || previousExpanded);
      final bodyId = '$_id-$i';
      final iconColor =
          widget.expandIconColor ?? scheme.onSurface.withValues(alpha: 0.54);
      final chevron = _Box(
        tag: 'span',
        css:
            'display:inline-flex;transition:transform ${widget.animationDuration.inMilliseconds}ms;${expanded ? 'transform:rotate(180deg);' : ''}',
        attributes: const {'aria-hidden': 'true'},
        fill: _Fill.none,
        children: [Icon(Icons.expand_more, color: iconColor)],
      );
      final headerContent = _Box(
        css:
            'flex:1 1 0;min-width:0;display:flex;flex-direction:column;justify-content:center;min-height:48px;${expanded ? edgeInsetsCss('padding', widget.expandedHeaderPadding) : ''}',
        layout: _DomLayout.column,
        children: [panel.headerBuilder(context, expanded)],
      );
      final ariaToggle = {
        'aria-expanded': '$expanded',
        'aria-controls': bodyId,
      };
      final header = panel.canTapOnHeader
          ? _Box(
              css:
                  'display:flex;align-items:center;box-sizing:border-box;min-height:${expanded ? 64 : 48}px;padding-right:12px;cursor:pointer;${_stateLayerCss(scheme.onSurface)}',
              attributes: {
                'role': 'button',
                'tabindex': '0',
                'class': 'fd-ink',
                ...ariaToggle,
              },
              handlers: _activationHandlers(() => _toggle(i)),
              layout: _DomLayout.row,
              fill: _Fill.expand,
              children: [headerContent, chevron],
            )
          : _Box(
              css:
                  'display:flex;align-items:center;box-sizing:border-box;min-height:${expanded ? 64 : 48}px;padding-right:4px;',
              layout: _DomLayout.row,
              fill: _Fill.expand,
              children: [
                headerContent,
                _Box(
                  tag: 'button',
                  css:
                      'display:inline-flex;align-items:center;justify-content:center;width:48px;height:48px;margin:0;padding:0;border:0;border-radius:50%;background:transparent;cursor:pointer;${_stateLayerCss(scheme.onSurface)}',
                  attributes: {
                    'type': 'button',
                    'class': 'fd-ink fd-button',
                    'aria-label': expanded ? 'Collapse' : 'Expand',
                    ...ariaToggle,
                  },
                  handlers: {'click': (_) => _toggle(i)},
                  layout: _DomLayout.align,
                  fill: _Fill.none,
                  children: [chevron],
                ),
              ],
            );
      children.add(
        _Box(
          key: panel is ExpansionPanelRadio
              ? ValueKey<Object>(panel.value)
              : ValueKey<int>(i),
          css:
              'display:flex;flex-direction:column;min-width:0;background-color:${colorCss(panel.backgroundColor ?? theme.cardColor)};'
              '${gap ? 'margin-top:${px(widget.materialGapSize)};' : (i > 0 ? 'border-top:1px solid ${colorCss(widget.dividerColor ?? theme.dividerColor)};' : '')}'
              '${elevationCss(widget.elevation, scheme.shadow)}',
          layout: _DomLayout.column,
          fill: _Fill.expand,
          children: [
            header,
            _Box(
              css:
                  'display:${expanded ? 'flex' : 'none'};flex-direction:column;min-width:0;',
              attributes: {
                'id': bodyId,
                'role': 'region',
                if (!expanded) 'aria-hidden': 'true',
              },
              layout: _DomLayout.column,
              fill: _Fill.expand,
              children: [if (expanded) panel.body],
            ),
          ],
        ),
      );
    }
    return _Box(
      css: 'display:flex;flex-direction:column;min-width:0;',
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: children,
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation rails and drawers.

enum NavigationRailLabelType { none, selected, all }

class NavigationRailDestination {
  const NavigationRailDestination({
    required this.icon,
    this.selectedIcon,
    this.indicatorColor,
    this.indicatorShape,
    required this.label,
    this.padding,
    this.disabled = false,
  });
  final Widget icon;
  final Widget? selectedIcon;
  final Color? indicatorColor;
  final ShapeBorder? indicatorShape;
  final Widget label;
  final EdgeInsetsGeometry? padding;
  final bool disabled;
}

class NavigationRail extends StatelessWidget {
  const NavigationRail({
    super.key,
    this.backgroundColor,
    this.extended = false,
    this.leading,
    this.trailing,
    required this.destinations,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.elevation,
    this.groupAlignment,
    this.labelType,
    this.unselectedLabelTextStyle,
    this.selectedLabelTextStyle,
    this.unselectedIconTheme,
    this.selectedIconTheme,
    this.minWidth,
    this.minExtendedWidth,
    this.useIndicator,
    this.indicatorColor,
    this.indicatorShape,
    this.scrollable = false,
  });
  final Color? backgroundColor, indicatorColor;
  final bool extended, scrollable;
  final Widget? leading, trailing;
  final List<NavigationRailDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final double? elevation, groupAlignment, minWidth, minExtendedWidth;
  final NavigationRailLabelType? labelType;
  final TextStyle? unselectedLabelTextStyle, selectedLabelTextStyle;
  final IconThemeData? unselectedIconTheme, selectedIconTheme;
  final bool? useIndicator;
  final ShapeBorder? indicatorShape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final type = labelType ?? NavigationRailLabelType.none;
    final indicator = useIndicator ?? true;
    final alignment = groupAlignment ?? -1;
    final justify = alignment <= -0.5
        ? 'flex-start'
        : alignment >= 0.5
        ? 'flex-end'
        : 'center';
    final width = extended ? minExtendedWidth ?? 256 : minWidth ?? 80;
    return _Box(
      tag: 'nav',
      css:
          'display:flex;flex-direction:column;align-items:${extended ? 'stretch' : 'center'};flex-shrink:0;align-self:stretch;box-sizing:border-box;width:${px(width)};min-height:100%;padding:8px 0;background-color:${colorCss(backgroundColor ?? scheme.surface)};${elevationCss(elevation ?? 0, scheme.shadow)}${scrollable ? 'overflow-y:auto;' : ''}',
      layout: _DomLayout.column,
      fill: _Fill.none,
      children: [
        if (leading != null)
          _Box(
            css: 'display:flex;justify-content:center;padding-bottom:8px;',
            layout: _DomLayout.row,
            fill: _Fill.none,
            children: [leading!],
          ),
        _Box(
          css:
              'flex:1 1 auto;display:flex;flex-direction:column;justify-content:$justify;align-items:${extended ? 'stretch' : 'center'};gap:12px;',
          layout: _DomLayout.column,
          fill: _Fill.none,
          children: [
            for (var i = 0; i < destinations.length; i++)
              () {
                final destination = destinations[i];
                final selected = i == selectedIndex;
                final enabled =
                    !destination.disabled && onDestinationSelected != null;
                final showLabel =
                    extended ||
                    type == NavigationRailLabelType.all ||
                    (type == NavigationRailLabelType.selected && selected);
                final iconTheme =
                    (selected ? selectedIconTheme : unselectedIconTheme) ??
                    IconThemeData(
                      size: 24,
                      color: !enabled
                          ? scheme.onSurface.withValues(alpha: 0.38)
                          : selected
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant,
                    );
                final labelStyle = theme.textTheme.labelMedium!
                    .copyWith(
                      color: !enabled
                          ? scheme.onSurface.withValues(alpha: 0.38)
                          : selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w600 : null,
                    )
                    .merge(
                      selected
                          ? selectedLabelTextStyle
                          : unselectedLabelTextStyle,
                    );
                final pill = _Box(
                  css:
                      'display:flex;align-items:center;justify-content:center;flex-shrink:0;width:56px;height:32px;border-radius:16px;'
                      '${selected && indicator ? 'background-color:${colorCss(destination.indicatorColor ?? indicatorColor ?? scheme.secondaryContainer)};' : ''}',
                  layout: _DomLayout.align,
                  fill: _Fill.none,
                  children: [
                    IconTheme.merge(
                      data: iconTheme,
                      child: selected
                          ? destination.selectedIcon ?? destination.icon
                          : destination.icon,
                    ),
                  ],
                );
                final text = _plainText(destination.label);
                return _Box(
                  key: ValueKey(i),
                  tag: 'button',
                  css:
                      'display:flex;flex-direction:${extended ? 'row' : 'column'};align-items:center;gap:${extended ? 12 : 4}px;box-sizing:border-box;margin:0;border:0;'
                      '${extended ? 'padding:0 16px;min-height:56px;' : 'width:${px(minWidth ?? 80)};padding:0;min-height:${showLabel ? 56 : 40}px;justify-content:center;'}'
                      'background:transparent;font:inherit;${edgeInsetsCss('padding', destination.padding)}${_stateLayerCss(scheme.onSurface)}',
                  attributes: {
                    'type': 'button',
                    'class': 'fd-ink fd-button',
                    if (selected) 'aria-current': 'page',
                    if (!enabled) 'disabled': '',
                    if (!showLabel && text != null) 'aria-label': text,
                  },
                  handlers: {
                    if (enabled) 'click': (_) => onDestinationSelected!(i),
                  },
                  layout: extended ? _DomLayout.row : _DomLayout.column,
                  fill: _Fill.none,
                  children: [
                    pill,
                    if (showLabel)
                      DefaultTextStyle(
                        style: labelStyle,
                        child: destination.label,
                      ),
                  ],
                );
              }(),
          ],
        ),
        if (trailing != null)
          _Box(
            css: 'display:flex;justify-content:center;padding-top:8px;',
            layout: _DomLayout.row,
            fill: _Fill.none,
            children: [trailing!],
          ),
      ],
    );
  }
}

class NavigationDrawerDestination extends StatelessWidget {
  const NavigationDrawerDestination({
    super.key,
    this.backgroundColor,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.enabled = true,
  });
  final Color? backgroundColor;
  final Widget icon;
  final Widget? selectedIcon;
  final Widget label;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_NavigationDrawerScope>();
    final index = scope?.indexOf(this) ?? -1;
    return _NavigationDrawerTile(
      destination: this,
      selected: scope != null && index == scope.drawer.selectedIndex,
      onTap: scope?.drawer.onDestinationSelected == null || index < 0
          ? null
          : () => scope!.drawer.onDestinationSelected!(index),
      indicatorColor: scope?.drawer.indicatorColor,
      indicatorShape: scope?.drawer.indicatorShape,
      padding: scope?.drawer.tilePadding,
    );
  }
}

class _NavigationDrawerScope extends InheritedWidget {
  const _NavigationDrawerScope({required this.drawer, required super.child});
  final NavigationDrawer drawer;
  int indexOf(NavigationDrawerDestination destination) => drawer.children
      .whereType<NavigationDrawerDestination>()
      .toList()
      .indexOf(destination);
  @override
  bool updateShouldNotify(_NavigationDrawerScope oldWidget) =>
      !identical(oldWidget.drawer, drawer);
}

class _NavigationDrawerTile extends StatelessWidget {
  const _NavigationDrawerTile({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.indicatorColor,
    this.indicatorShape,
    this.padding,
  });
  final NavigationDrawerDestination destination;
  final bool selected;
  final VoidCallback? onTap;
  final Color? indicatorColor;
  final ShapeBorder? indicatorShape;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = destination.enabled && onTap != null;
    final foreground = !destination.enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : selected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;
    final background = selected
        ? indicatorColor ?? scheme.secondaryContainer
        : destination.backgroundColor;
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
      child: _Box(
        tag: 'button',
        css:
            'display:flex;align-items:center;gap:12px;width:100%;box-sizing:border-box;margin:0;border:0;min-height:56px;padding:0 24px 0 16px;font:inherit;text-align:left;'
            '${indicatorShape == null ? 'border-radius:28px;' : shapeCss(indicatorShape)}'
            'background-color:${background == null ? 'transparent' : colorCss(background)};${_stateLayerCss(foreground)}',
        attributes: {
          'type': 'button',
          'class': 'fd-ink fd-button',
          if (selected) 'aria-current': 'page',
          if (!destination.enabled) 'disabled': '',
        },
        handlers: {if (enabled) 'click': (_) => onTap!()},
        layout: _DomLayout.row,
        fill: _Fill.expand,
        children: [
          IconTheme.merge(
            data: IconThemeData(color: foreground, size: 24),
            child: selected
                ? destination.selectedIcon ?? destination.icon
                : destination.icon,
          ),
          DefaultTextStyle(
            style: theme.textTheme.labelLarge!.copyWith(color: foreground),
            child: destination.label,
          ),
        ],
      ),
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({
    super.key,
    required this.children,
    this.backgroundColor,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.indicatorColor,
    this.indicatorShape,
    this.onDestinationSelected,
    this.selectedIndex = 0,
    this.tilePadding = const EdgeInsets.symmetric(horizontal: 12),
  });
  final List<Widget> children;
  final Color? backgroundColor, shadowColor, surfaceTintColor;
  final double? elevation;
  final Color? indicatorColor;
  final ShapeBorder? indicatorShape;
  final ValueChanged<int>? onDestinationSelected;
  final int? selectedIndex;
  final EdgeInsetsGeometry tilePadding;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _NavigationDrawerScope(
      drawer: this,
      child: _Box(
        tag: 'nav',
        css:
            'display:flex;flex-direction:column;box-sizing:border-box;height:100%;width:360px;max-width:calc(100vw - 56px);overflow-y:auto;padding:12px 0;background-color:${colorCss(backgroundColor ?? scheme.surfaceContainerLow)};border-radius:0 16px 16px 0;${elevationCss(elevation ?? 1, shadowColor ?? scheme.shadow)}',
        attributes: const {'aria-label': 'Navigation menu'},
        layout: _DomLayout.column,
        fill: _Fill.none,
        children: children,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom app bars and notched shapes.

abstract class NotchedShape {
  const NotchedShape();
  Path getOuterPath(Rect host, Rect? guest);
}

/// The notch is not cut visually; the outer path is the host rectangle.
class CircularNotchedRectangle extends NotchedShape {
  const CircularNotchedRectangle({this.inverted = false});
  final bool inverted;
  @override
  Path getOuterPath(Rect host, Rect? guest) => Path()..addRect(host);
}

class AutomaticNotchedShape extends NotchedShape {
  const AutomaticNotchedShape(this.host, [this.guest]);
  final ShapeBorder host;
  final ShapeBorder? guest;
  @override
  Path getOuterPath(Rect host, Rect? guest) => Path()..addRect(host);
}

class BottomAppBar extends StatelessWidget {
  const BottomAppBar({
    super.key,
    this.color,
    this.elevation,
    this.shape,
    this.clipBehavior = Clip.none,
    this.notchMargin = 4.0,
    this.child,
    this.padding,
    this.surfaceTintColor,
    this.shadowColor,
    this.height,
  });
  final Color? color, surfaceTintColor, shadowColor;
  final double? elevation, height;
  final NotchedShape? shape;
  final Clip clipBehavior;
  final double notchMargin;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Box(
      css:
          'display:flex;flex-direction:column;justify-content:center;box-sizing:border-box;min-height:${px(height ?? 80)};${edgeInsetsCss('padding', padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 16))}'
          'background-color:${colorCss(color ?? scheme.surfaceContainer)};${elevationCss(elevation ?? 3, shadowColor ?? scheme.shadow)}${clipBehavior == Clip.none ? '' : 'overflow:hidden;'}',
      attributes: const {'role': 'toolbar'},
      layout: _DomLayout.column,
      fill: _Fill.expand,
      children: [
        IconTheme.merge(
          data: IconThemeData(color: scheme.onSurfaceVariant),
          child: child ?? const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Material banners.

enum MaterialBannerClosedReason { dismiss, swipe, hide, remove }

class MaterialBanner extends StatelessWidget {
  const MaterialBanner({
    super.key,
    required this.content,
    this.contentTextStyle,
    required this.actions,
    this.elevation,
    this.leading,
    this.backgroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.dividerColor,
    this.padding,
    this.margin,
    this.leadingPadding,
    this.forceActionsBelow = false,
    this.overflowAlignment = OverflowBarAlignment.end,
    this.onVisible,
    this.minActionBarHeight = 52.0,
  });
  final Widget content;
  final TextStyle? contentTextStyle;
  final List<Widget> actions;
  final double? elevation;
  final Widget? leading;
  final Color? backgroundColor, surfaceTintColor, shadowColor, dividerColor;
  final EdgeInsetsGeometry? padding, margin, leadingPadding;
  final bool forceActionsBelow;
  final OverflowBarAlignment overflowAlignment;
  final VoidCallback? onVisible;
  final double minActionBarHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final below = forceActionsBelow || actions.length > 1;
    final actionBar = _Box(
      css:
          'display:flex;flex-wrap:wrap;align-items:center;justify-content:${switch (overflowAlignment) {
            OverflowBarAlignment.start => 'flex-start',
            OverflowBarAlignment.center => 'center',
            OverflowBarAlignment.end => 'flex-end',
          }};gap:8px;box-sizing:border-box;min-height:${px(minActionBarHeight)};padding:0 8px 0 8px;flex-shrink:0;',
      layout: _DomLayout.row,
      fill: below ? _Fill.expand : _Fill.none,
      children: actions,
    );
    final body = _Box(
      css:
          'display:flex;align-items:center;min-width:0;${below ? '' : 'flex:1 1 0;'}${edgeInsetsCss('padding', padding ?? EdgeInsetsDirectional.only(start: 16, top: 24, end: 16, bottom: below ? 4 : 24))}',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        if (leading != null)
          _Box(
            css:
                'display:flex;flex-shrink:0;${edgeInsetsCss('padding', leadingPadding ?? const EdgeInsetsDirectional.only(end: 16))}',
            layout: _DomLayout.row,
            fill: _Fill.none,
            children: [
              IconTheme.merge(
                data: IconThemeData(color: scheme.onSurfaceVariant),
                child: leading!,
              ),
            ],
          ),
        _Box(
          css: 'flex:1 1 0;min-width:0;',
          children: [
            DefaultTextStyle(
              style: theme.textTheme.bodyMedium!
                  .copyWith(color: scheme.onSurface)
                  .merge(contentTextStyle),
              child: content,
            ),
          ],
        ),
      ],
    );
    return _Box(
      css:
          'display:flex;flex-direction:${below ? 'column' : 'row'};${below ? '' : 'align-items:center;'}box-sizing:border-box;min-width:0;${edgeInsetsCss('margin', margin)}'
          'background-color:${colorCss(backgroundColor ?? scheme.surfaceContainerLow)};border-bottom:1px solid ${colorCss(dividerColor ?? scheme.outlineVariant)};${elevationCss(elevation ?? 0, shadowColor ?? scheme.shadow)}',
      attributes: const {'role': 'status', 'aria-live': 'polite'},
      layout: below ? _DomLayout.column : _DomLayout.row,
      fill: _Fill.expand,
      children: [body, actionBar],
    );
  }
}

/// Material banner queue of [ScaffoldMessengerState]. The current banner
/// renders at the top of the messenger, above its scaffold.
mixin _MaterialBannerHost on State<ScaffoldMessenger> {
  final _banners = <(MaterialBanner, Completer<MaterialBannerClosedReason>)>[];

  ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
  showMaterialBanner(MaterialBanner materialBanner) {
    final completer = Completer<MaterialBannerClosedReason>();
    final entry = (materialBanner, completer);
    setState(() => _banners.add(entry));
    if (_banners.length == 1) _announce();
    return ScaffoldFeatureController._(
      () => _closeBanner(entry, MaterialBannerClosedReason.hide),
      completer.future,
    );
  }

  void _announce() {
    if (_banners.isEmpty) return;
    final visible = _banners.first.$1.onVisible;
    if (visible != null) scheduleMicrotask(visible);
  }

  void _closeBanner(
    (MaterialBanner, Completer<MaterialBannerClosedReason>) entry,
    MaterialBannerClosedReason reason,
  ) {
    if (!mounted || !_banners.contains(entry)) return;
    final wasCurrent = identical(_banners.first, entry);
    setState(() => _banners.remove(entry));
    if (!entry.$2.isCompleted) entry.$2.complete(reason);
    if (wasCurrent) _announce();
  }

  void hideCurrentMaterialBanner({
    MaterialBannerClosedReason reason = MaterialBannerClosedReason.hide,
  }) {
    if (_banners.isNotEmpty) _closeBanner(_banners.first, reason);
  }

  void removeCurrentMaterialBanner({
    MaterialBannerClosedReason reason = MaterialBannerClosedReason.remove,
  }) => hideCurrentMaterialBanner(reason: reason);

  void clearMaterialBanners() {
    while (_banners.isNotEmpty) {
      _closeBanner(_banners.first, MaterialBannerClosedReason.remove);
    }
  }

  Widget? get _materialBannerView => _banners.isEmpty
      ? null
      : _Box(
          css: 'order:-1;position:sticky;top:0;z-index:4;min-width:0;',
          fill: _Fill.expand,
          children: [_banners.first.$1],
        );
}

// ---------------------------------------------------------------------------
// Grid tiles.

class GridTile extends StatelessWidget {
  const GridTile({super.key, this.header, this.footer, required this.child});
  final Widget? header, footer;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (header == null && footer == null) return child;
    return _Box(
      css:
          'position:relative;display:grid;grid-template-columns:minmax(0,1fr);grid-template-rows:minmax(0,1fr);box-sizing:border-box;width:100%;height:100%;min-width:0;overflow:hidden;',
      layout: _DomLayout.grid,
      fill: _Fill.expand,
      children: [
        child,
        if (header != null)
          _Box(
            css: 'position:absolute;top:0;left:0;right:0;',
            fill: _Fill.none,
            children: [header!],
          ),
        if (footer != null)
          _Box(
            css: 'position:absolute;bottom:0;left:0;right:0;',
            fill: _Fill.none,
            children: [footer!],
          ),
      ],
    );
  }
}

class GridTileBar extends StatelessWidget {
  const GridTileBar({
    super.key,
    this.backgroundColor,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
  });
  final Color? backgroundColor;
  final Widget? leading, title, subtitle, trailing;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const white = Color(0xffffffff);
    return _Box(
      css:
          'display:flex;align-items:center;gap:0;box-sizing:border-box;min-height:${subtitle == null ? 48 : 68}px;padding:0 ${trailing == null ? 16 : 8}px 0 ${leading == null ? 16 : 8}px;${backgroundColor == null ? '' : 'background-color:${colorCss(backgroundColor!)};'}',
      layout: _DomLayout.row,
      fill: _Fill.expand,
      children: [
        if (leading != null)
          _Box(
            css: 'display:flex;flex-shrink:0;padding-right:8px;',
            layout: _DomLayout.row,
            fill: _Fill.none,
            children: [
              IconTheme.merge(
                data: const IconThemeData(color: white),
                child: leading!,
              ),
            ],
          ),
        _Box(
          css:
              'flex:1 1 0;min-width:0;display:flex;flex-direction:column;justify-content:center;',
          layout: _DomLayout.column,
          children: [
            if (title != null)
              DefaultTextStyle(
                style: theme.textTheme.titleMedium!.copyWith(color: white),
                child: title!,
              ),
            if (subtitle != null)
              DefaultTextStyle(
                style: theme.textTheme.bodySmall!.copyWith(color: white),
                child: subtitle!,
              ),
          ],
        ),
        if (trailing != null)
          _Box(
            css: 'display:flex;flex-shrink:0;padding-left:8px;',
            layout: _DomLayout.row,
            fill: _Fill.none,
            children: [
              IconTheme.merge(
                data: const IconThemeData(color: white),
                child: trailing!,
              ),
            ],
          ),
      ],
    );
  }
}

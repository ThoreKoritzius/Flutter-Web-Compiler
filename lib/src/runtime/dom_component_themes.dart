part of 'flutter_dom.dart';

// Material component theme values. Each class mirrors the public
// constructor, copyWith and value equality of its Flutter counterpart;
// `lerp` snaps at the midpoint instead of interpolating.

class BadgeThemeData {
  const BadgeThemeData({
    this.backgroundColor,
    this.textColor,
    this.smallSize,
    this.largeSize,
    this.textStyle,
    this.padding,
    this.alignment,
    this.offset,
  });
  final Color? backgroundColor;
  final Color? textColor;
  final double? smallSize;
  final double? largeSize;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final Offset? offset;
  BadgeThemeData copyWith({
    Color? backgroundColor,
    Color? textColor,
    double? smallSize,
    double? largeSize,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    AlignmentGeometry? alignment,
    Offset? offset,
  }) => BadgeThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    textColor: textColor ?? this.textColor,
    smallSize: smallSize ?? this.smallSize,
    largeSize: largeSize ?? this.largeSize,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    alignment: alignment ?? this.alignment,
    offset: offset ?? this.offset,
  );
  static BadgeThemeData lerp(BadgeThemeData? a, BadgeThemeData? b, double t) =>
      (t < 0.5 ? a : b) ?? const BadgeThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeThemeData &&
          other.backgroundColor == backgroundColor &&
          other.textColor == textColor &&
          other.smallSize == smallSize &&
          other.largeSize == largeSize &&
          other.textStyle == textStyle &&
          other.padding == padding &&
          other.alignment == alignment &&
          other.offset == offset;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    textColor,
    smallSize,
    largeSize,
    textStyle,
    padding,
    alignment,
    offset,
  ]);
}

class MaterialBannerThemeData {
  const MaterialBannerThemeData({
    this.backgroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.dividerColor,
    this.contentTextStyle,
    this.elevation,
    this.padding,
    this.leadingPadding,
  });
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final Color? shadowColor;
  final Color? dividerColor;
  final TextStyle? contentTextStyle;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? leadingPadding;
  MaterialBannerThemeData copyWith({
    Color? backgroundColor,
    Color? surfaceTintColor,
    Color? shadowColor,
    Color? dividerColor,
    TextStyle? contentTextStyle,
    double? elevation,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? leadingPadding,
  }) => MaterialBannerThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    shadowColor: shadowColor ?? this.shadowColor,
    dividerColor: dividerColor ?? this.dividerColor,
    contentTextStyle: contentTextStyle ?? this.contentTextStyle,
    elevation: elevation ?? this.elevation,
    padding: padding ?? this.padding,
    leadingPadding: leadingPadding ?? this.leadingPadding,
  );
  static MaterialBannerThemeData lerp(
    MaterialBannerThemeData? a,
    MaterialBannerThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const MaterialBannerThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialBannerThemeData &&
          other.backgroundColor == backgroundColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.shadowColor == shadowColor &&
          other.dividerColor == dividerColor &&
          other.contentTextStyle == contentTextStyle &&
          other.elevation == elevation &&
          other.padding == padding &&
          other.leadingPadding == leadingPadding;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    surfaceTintColor,
    shadowColor,
    dividerColor,
    contentTextStyle,
    elevation,
    padding,
    leadingPadding,
  ]);
}

class BottomAppBarTheme {
  const BottomAppBarTheme({
    this.color,
    this.elevation,
    this.shape,
    this.height,
    this.surfaceTintColor,
    this.shadowColor,
    this.padding,
  });
  final Color? color;
  final double? elevation;
  final NotchedShape? shape;
  final double? height;
  final Color? surfaceTintColor;
  final Color? shadowColor;
  final EdgeInsetsGeometry? padding;
  BottomAppBarTheme copyWith({
    Color? color,
    double? elevation,
    NotchedShape? shape,
    double? height,
    Color? surfaceTintColor,
    Color? shadowColor,
    EdgeInsetsGeometry? padding,
  }) => BottomAppBarTheme(
    color: color ?? this.color,
    elevation: elevation ?? this.elevation,
    shape: shape ?? this.shape,
    height: height ?? this.height,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    shadowColor: shadowColor ?? this.shadowColor,
    padding: padding ?? this.padding,
  );
  static BottomAppBarTheme lerp(
    BottomAppBarTheme? a,
    BottomAppBarTheme? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const BottomAppBarTheme();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BottomAppBarTheme &&
          other.color == color &&
          other.elevation == elevation &&
          other.shape == shape &&
          other.height == height &&
          other.surfaceTintColor == surfaceTintColor &&
          other.shadowColor == shadowColor &&
          other.padding == padding;
  @override
  int get hashCode => Object.hashAll([
    color,
    elevation,
    shape,
    height,
    surfaceTintColor,
    shadowColor,
    padding,
  ]);
}

class BottomNavigationBarThemeData {
  const BottomNavigationBarThemeData({
    this.backgroundColor,
    this.elevation,
    this.selectedIconTheme,
    this.unselectedIconTheme,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.showSelectedLabels,
    this.showUnselectedLabels,
    this.type,
    this.enableFeedback,
    this.landscapeLayout,
    this.mouseCursor,
  });
  final Color? backgroundColor;
  final double? elevation;
  final IconThemeData? selectedIconTheme;
  final IconThemeData? unselectedIconTheme;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;
  final bool? showSelectedLabels;
  final bool? showUnselectedLabels;
  final BottomNavigationBarType? type;
  final bool? enableFeedback;
  final BottomNavigationBarLandscapeLayout? landscapeLayout;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  BottomNavigationBarThemeData copyWith({
    Color? backgroundColor,
    double? elevation,
    IconThemeData? selectedIconTheme,
    IconThemeData? unselectedIconTheme,
    Color? selectedItemColor,
    Color? unselectedItemColor,
    TextStyle? selectedLabelStyle,
    TextStyle? unselectedLabelStyle,
    bool? showSelectedLabels,
    bool? showUnselectedLabels,
    BottomNavigationBarType? type,
    bool? enableFeedback,
    BottomNavigationBarLandscapeLayout? landscapeLayout,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => BottomNavigationBarThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    elevation: elevation ?? this.elevation,
    selectedIconTheme: selectedIconTheme ?? this.selectedIconTheme,
    unselectedIconTheme: unselectedIconTheme ?? this.unselectedIconTheme,
    selectedItemColor: selectedItemColor ?? this.selectedItemColor,
    unselectedItemColor: unselectedItemColor ?? this.unselectedItemColor,
    selectedLabelStyle: selectedLabelStyle ?? this.selectedLabelStyle,
    unselectedLabelStyle: unselectedLabelStyle ?? this.unselectedLabelStyle,
    showSelectedLabels: showSelectedLabels ?? this.showSelectedLabels,
    showUnselectedLabels: showUnselectedLabels ?? this.showUnselectedLabels,
    type: type ?? this.type,
    enableFeedback: enableFeedback ?? this.enableFeedback,
    landscapeLayout: landscapeLayout ?? this.landscapeLayout,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );
  static BottomNavigationBarThemeData lerp(
    BottomNavigationBarThemeData? a,
    BottomNavigationBarThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const BottomNavigationBarThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BottomNavigationBarThemeData &&
          other.backgroundColor == backgroundColor &&
          other.elevation == elevation &&
          other.selectedIconTheme == selectedIconTheme &&
          other.unselectedIconTheme == unselectedIconTheme &&
          other.selectedItemColor == selectedItemColor &&
          other.unselectedItemColor == unselectedItemColor &&
          other.selectedLabelStyle == selectedLabelStyle &&
          other.unselectedLabelStyle == unselectedLabelStyle &&
          other.showSelectedLabels == showSelectedLabels &&
          other.showUnselectedLabels == showUnselectedLabels &&
          other.type == type &&
          other.enableFeedback == enableFeedback &&
          other.landscapeLayout == landscapeLayout &&
          other.mouseCursor == mouseCursor;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    elevation,
    selectedIconTheme,
    unselectedIconTheme,
    selectedItemColor,
    unselectedItemColor,
    selectedLabelStyle,
    unselectedLabelStyle,
    showSelectedLabels,
    showUnselectedLabels,
    type,
    enableFeedback,
    landscapeLayout,
    mouseCursor,
  ]);
}

class BottomSheetThemeData {
  const BottomSheetThemeData({
    this.backgroundColor,
    this.surfaceTintColor,
    this.elevation,
    this.modalBackgroundColor,
    this.modalBarrierColor,
    this.shadowColor,
    this.modalElevation,
    this.shape,
    this.showDragHandle,
    this.dragHandleColor,
    this.dragHandleSize,
    this.clipBehavior,
    this.constraints,
  });
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final Color? modalBackgroundColor;
  final Color? modalBarrierColor;
  final Color? shadowColor;
  final double? modalElevation;
  final ShapeBorder? shape;
  final bool? showDragHandle;
  final Color? dragHandleColor;
  final Size? dragHandleSize;
  final Clip? clipBehavior;
  final BoxConstraints? constraints;
  BottomSheetThemeData copyWith({
    Color? backgroundColor,
    Color? surfaceTintColor,
    double? elevation,
    Color? modalBackgroundColor,
    Color? modalBarrierColor,
    Color? shadowColor,
    double? modalElevation,
    ShapeBorder? shape,
    bool? showDragHandle,
    Color? dragHandleColor,
    Size? dragHandleSize,
    Clip? clipBehavior,
    BoxConstraints? constraints,
  }) => BottomSheetThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    elevation: elevation ?? this.elevation,
    modalBackgroundColor: modalBackgroundColor ?? this.modalBackgroundColor,
    modalBarrierColor: modalBarrierColor ?? this.modalBarrierColor,
    shadowColor: shadowColor ?? this.shadowColor,
    modalElevation: modalElevation ?? this.modalElevation,
    shape: shape ?? this.shape,
    showDragHandle: showDragHandle ?? this.showDragHandle,
    dragHandleColor: dragHandleColor ?? this.dragHandleColor,
    dragHandleSize: dragHandleSize ?? this.dragHandleSize,
    clipBehavior: clipBehavior ?? this.clipBehavior,
    constraints: constraints ?? this.constraints,
  );
  static BottomSheetThemeData lerp(
    BottomSheetThemeData? a,
    BottomSheetThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const BottomSheetThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BottomSheetThemeData &&
          other.backgroundColor == backgroundColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.elevation == elevation &&
          other.modalBackgroundColor == modalBackgroundColor &&
          other.modalBarrierColor == modalBarrierColor &&
          other.shadowColor == shadowColor &&
          other.modalElevation == modalElevation &&
          other.shape == shape &&
          other.showDragHandle == showDragHandle &&
          other.dragHandleColor == dragHandleColor &&
          other.dragHandleSize == dragHandleSize &&
          other.clipBehavior == clipBehavior &&
          other.constraints == constraints;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    surfaceTintColor,
    elevation,
    modalBackgroundColor,
    modalBarrierColor,
    shadowColor,
    modalElevation,
    shape,
    showDragHandle,
    dragHandleColor,
    dragHandleSize,
    clipBehavior,
    constraints,
  ]);
}

class CardThemeData {
  const CardThemeData({
    this.clipBehavior,
    this.color,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.margin,
    this.shape,
  });
  final Clip? clipBehavior;
  final Color? color;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final ShapeBorder? shape;
  CardThemeData copyWith({
    Clip? clipBehavior,
    Color? color,
    Color? shadowColor,
    Color? surfaceTintColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    ShapeBorder? shape,
  }) => CardThemeData(
    clipBehavior: clipBehavior ?? this.clipBehavior,
    color: color ?? this.color,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    elevation: elevation ?? this.elevation,
    margin: margin ?? this.margin,
    shape: shape ?? this.shape,
  );
  static CardThemeData lerp(CardThemeData? a, CardThemeData? b, double t) =>
      (t < 0.5 ? a : b) ?? const CardThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardThemeData &&
          other.clipBehavior == clipBehavior &&
          other.color == color &&
          other.shadowColor == shadowColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.elevation == elevation &&
          other.margin == margin &&
          other.shape == shape;
  @override
  int get hashCode => Object.hashAll([
    clipBehavior,
    color,
    shadowColor,
    surfaceTintColor,
    elevation,
    margin,
    shape,
  ]);
}

class CheckboxThemeData {
  const CheckboxThemeData({
    this.mouseCursor,
    this.fillColor,
    this.checkColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.shape,
    this.side,
  });
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final WidgetStateProperty<Color?>? fillColor;
  final WidgetStateProperty<Color?>? checkColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;
  final OutlinedBorder? shape;
  final BorderSide? side;
  CheckboxThemeData copyWith({
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? checkColor,
    WidgetStateProperty<Color?>? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    OutlinedBorder? shape,
    BorderSide? side,
  }) => CheckboxThemeData(
    mouseCursor: mouseCursor ?? this.mouseCursor,
    fillColor: fillColor ?? this.fillColor,
    checkColor: checkColor ?? this.checkColor,
    overlayColor: overlayColor ?? this.overlayColor,
    splashRadius: splashRadius ?? this.splashRadius,
    materialTapTargetSize: materialTapTargetSize ?? this.materialTapTargetSize,
    visualDensity: visualDensity ?? this.visualDensity,
    shape: shape ?? this.shape,
    side: side ?? this.side,
  );
  static CheckboxThemeData lerp(
    CheckboxThemeData? a,
    CheckboxThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const CheckboxThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckboxThemeData &&
          other.mouseCursor == mouseCursor &&
          other.fillColor == fillColor &&
          other.checkColor == checkColor &&
          other.overlayColor == overlayColor &&
          other.splashRadius == splashRadius &&
          other.materialTapTargetSize == materialTapTargetSize &&
          other.visualDensity == visualDensity &&
          other.shape == shape &&
          other.side == side;
  @override
  int get hashCode => Object.hashAll([
    mouseCursor,
    fillColor,
    checkColor,
    overlayColor,
    splashRadius,
    materialTapTargetSize,
    visualDensity,
    shape,
    side,
  ]);
}

class ChipThemeData {
  const ChipThemeData({
    this.color,
    this.backgroundColor,
    this.deleteIconColor,
    this.disabledColor,
    this.selectedColor,
    this.secondarySelectedColor,
    this.shadowColor,
    this.surfaceTintColor,
    this.selectedShadowColor,
    this.showCheckmark,
    this.checkmarkColor,
    this.labelPadding,
    this.padding,
    this.side,
    this.shape,
    this.labelStyle,
    this.secondaryLabelStyle,
    this.brightness,
    this.elevation,
    this.pressElevation,
    this.iconTheme,
    this.avatarBoxConstraints,
    this.deleteIconBoxConstraints,
  });
  final WidgetStateProperty<Color?>? color;
  final Color? backgroundColor;
  final Color? deleteIconColor;
  final Color? disabledColor;
  final Color? selectedColor;
  final Color? secondarySelectedColor;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final Color? selectedShadowColor;
  final bool? showCheckmark;
  final Color? checkmarkColor;
  final EdgeInsetsGeometry? labelPadding;
  final EdgeInsetsGeometry? padding;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final TextStyle? labelStyle;
  final TextStyle? secondaryLabelStyle;
  final Brightness? brightness;
  final double? elevation;
  final double? pressElevation;
  final IconThemeData? iconTheme;
  final BoxConstraints? avatarBoxConstraints;
  final BoxConstraints? deleteIconBoxConstraints;

  /// Flutter's legacy defaults constructor; the colors seed a bounded theme.
  factory ChipThemeData.fromDefaults({
    Brightness? brightness,
    Color? primaryColor,
    required Color secondaryColor,
    required TextStyle labelStyle,
  }) => ChipThemeData(
    brightness: brightness,
    backgroundColor: (primaryColor ?? const Color(0xff000000)).withValues(
      alpha: 0.12,
    ),
    selectedColor: (primaryColor ?? const Color(0xff000000)).withValues(
      alpha: 0.24,
    ),
    secondarySelectedColor: secondaryColor.withValues(alpha: 0.24),
    labelStyle: labelStyle,
    secondaryLabelStyle: labelStyle.copyWith(color: secondaryColor),
  );
  ChipThemeData copyWith({
    WidgetStateProperty<Color?>? color,
    Color? backgroundColor,
    Color? deleteIconColor,
    Color? disabledColor,
    Color? selectedColor,
    Color? secondarySelectedColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    Color? selectedShadowColor,
    bool? showCheckmark,
    Color? checkmarkColor,
    EdgeInsetsGeometry? labelPadding,
    EdgeInsetsGeometry? padding,
    BorderSide? side,
    OutlinedBorder? shape,
    TextStyle? labelStyle,
    TextStyle? secondaryLabelStyle,
    Brightness? brightness,
    double? elevation,
    double? pressElevation,
    IconThemeData? iconTheme,
    BoxConstraints? avatarBoxConstraints,
    BoxConstraints? deleteIconBoxConstraints,
  }) => ChipThemeData(
    color: color ?? this.color,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    deleteIconColor: deleteIconColor ?? this.deleteIconColor,
    disabledColor: disabledColor ?? this.disabledColor,
    selectedColor: selectedColor ?? this.selectedColor,
    secondarySelectedColor:
        secondarySelectedColor ?? this.secondarySelectedColor,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    selectedShadowColor: selectedShadowColor ?? this.selectedShadowColor,
    showCheckmark: showCheckmark ?? this.showCheckmark,
    checkmarkColor: checkmarkColor ?? this.checkmarkColor,
    labelPadding: labelPadding ?? this.labelPadding,
    padding: padding ?? this.padding,
    side: side ?? this.side,
    shape: shape ?? this.shape,
    labelStyle: labelStyle ?? this.labelStyle,
    secondaryLabelStyle: secondaryLabelStyle ?? this.secondaryLabelStyle,
    brightness: brightness ?? this.brightness,
    elevation: elevation ?? this.elevation,
    pressElevation: pressElevation ?? this.pressElevation,
    iconTheme: iconTheme ?? this.iconTheme,
    avatarBoxConstraints: avatarBoxConstraints ?? this.avatarBoxConstraints,
    deleteIconBoxConstraints:
        deleteIconBoxConstraints ?? this.deleteIconBoxConstraints,
  );
  static ChipThemeData lerp(ChipThemeData? a, ChipThemeData? b, double t) =>
      (t < 0.5 ? a : b) ?? const ChipThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChipThemeData &&
          other.color == color &&
          other.backgroundColor == backgroundColor &&
          other.deleteIconColor == deleteIconColor &&
          other.disabledColor == disabledColor &&
          other.selectedColor == selectedColor &&
          other.secondarySelectedColor == secondarySelectedColor &&
          other.shadowColor == shadowColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.selectedShadowColor == selectedShadowColor &&
          other.showCheckmark == showCheckmark &&
          other.checkmarkColor == checkmarkColor &&
          other.labelPadding == labelPadding &&
          other.padding == padding &&
          other.side == side &&
          other.shape == shape &&
          other.labelStyle == labelStyle &&
          other.secondaryLabelStyle == secondaryLabelStyle &&
          other.brightness == brightness &&
          other.elevation == elevation &&
          other.pressElevation == pressElevation &&
          other.iconTheme == iconTheme &&
          other.avatarBoxConstraints == avatarBoxConstraints &&
          other.deleteIconBoxConstraints == deleteIconBoxConstraints;
  @override
  int get hashCode => Object.hashAll([
    color,
    backgroundColor,
    deleteIconColor,
    disabledColor,
    selectedColor,
    secondarySelectedColor,
    shadowColor,
    surfaceTintColor,
    selectedShadowColor,
    showCheckmark,
    checkmarkColor,
    labelPadding,
    padding,
    side,
    shape,
    labelStyle,
    secondaryLabelStyle,
    brightness,
    elevation,
    pressElevation,
    iconTheme,
    avatarBoxConstraints,
    deleteIconBoxConstraints,
  ]);
}

class DataTableThemeData {
  const DataTableThemeData({
    this.decoration,
    this.dataRowColor,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.dataTextStyle,
    this.headingRowColor,
    this.headingRowHeight,
    this.headingTextStyle,
    this.horizontalMargin,
    this.columnSpacing,
    this.dividerThickness,
    this.checkboxHorizontalMargin,
    this.headingCellCursor,
    this.dataRowCursor,
    this.headingRowAlignment,
  });
  final Decoration? decoration;
  final WidgetStateProperty<Color?>? dataRowColor;
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;
  final TextStyle? dataTextStyle;
  final WidgetStateProperty<Color?>? headingRowColor;
  final double? headingRowHeight;
  final TextStyle? headingTextStyle;
  final double? horizontalMargin;
  final double? columnSpacing;
  final double? dividerThickness;
  final double? checkboxHorizontalMargin;
  final WidgetStateProperty<MouseCursor?>? headingCellCursor;
  final WidgetStateProperty<MouseCursor?>? dataRowCursor;
  final MainAxisAlignment? headingRowAlignment;
  DataTableThemeData copyWith({
    Decoration? decoration,
    WidgetStateProperty<Color?>? dataRowColor,
    double? dataRowMinHeight,
    double? dataRowMaxHeight,
    TextStyle? dataTextStyle,
    WidgetStateProperty<Color?>? headingRowColor,
    double? headingRowHeight,
    TextStyle? headingTextStyle,
    double? horizontalMargin,
    double? columnSpacing,
    double? dividerThickness,
    double? checkboxHorizontalMargin,
    WidgetStateProperty<MouseCursor?>? headingCellCursor,
    WidgetStateProperty<MouseCursor?>? dataRowCursor,
    MainAxisAlignment? headingRowAlignment,
  }) => DataTableThemeData(
    decoration: decoration ?? this.decoration,
    dataRowColor: dataRowColor ?? this.dataRowColor,
    dataRowMinHeight: dataRowMinHeight ?? this.dataRowMinHeight,
    dataRowMaxHeight: dataRowMaxHeight ?? this.dataRowMaxHeight,
    dataTextStyle: dataTextStyle ?? this.dataTextStyle,
    headingRowColor: headingRowColor ?? this.headingRowColor,
    headingRowHeight: headingRowHeight ?? this.headingRowHeight,
    headingTextStyle: headingTextStyle ?? this.headingTextStyle,
    horizontalMargin: horizontalMargin ?? this.horizontalMargin,
    columnSpacing: columnSpacing ?? this.columnSpacing,
    dividerThickness: dividerThickness ?? this.dividerThickness,
    checkboxHorizontalMargin:
        checkboxHorizontalMargin ?? this.checkboxHorizontalMargin,
    headingCellCursor: headingCellCursor ?? this.headingCellCursor,
    dataRowCursor: dataRowCursor ?? this.dataRowCursor,
    headingRowAlignment: headingRowAlignment ?? this.headingRowAlignment,
  );
  static DataTableThemeData lerp(
    DataTableThemeData? a,
    DataTableThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const DataTableThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataTableThemeData &&
          other.decoration == decoration &&
          other.dataRowColor == dataRowColor &&
          other.dataRowMinHeight == dataRowMinHeight &&
          other.dataRowMaxHeight == dataRowMaxHeight &&
          other.dataTextStyle == dataTextStyle &&
          other.headingRowColor == headingRowColor &&
          other.headingRowHeight == headingRowHeight &&
          other.headingTextStyle == headingTextStyle &&
          other.horizontalMargin == horizontalMargin &&
          other.columnSpacing == columnSpacing &&
          other.dividerThickness == dividerThickness &&
          other.checkboxHorizontalMargin == checkboxHorizontalMargin &&
          other.headingCellCursor == headingCellCursor &&
          other.dataRowCursor == dataRowCursor &&
          other.headingRowAlignment == headingRowAlignment;
  @override
  int get hashCode => Object.hashAll([
    decoration,
    dataRowColor,
    dataRowMinHeight,
    dataRowMaxHeight,
    dataTextStyle,
    headingRowColor,
    headingRowHeight,
    headingTextStyle,
    horizontalMargin,
    columnSpacing,
    dividerThickness,
    checkboxHorizontalMargin,
    headingCellCursor,
    dataRowCursor,
    headingRowAlignment,
  ]);
}

class DatePickerThemeData {
  const DatePickerThemeData({
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.headerBackgroundColor,
    this.headerForegroundColor,
    this.headerHeadlineStyle,
    this.headerHelpStyle,
    this.weekdayStyle,
    this.dayStyle,
    this.dayForegroundColor,
    this.dayBackgroundColor,
    this.dayOverlayColor,
    this.dayShape,
    this.todayForegroundColor,
    this.todayBackgroundColor,
    this.todayBorder,
    this.yearStyle,
    this.yearForegroundColor,
    this.yearBackgroundColor,
    this.yearOverlayColor,
    this.rangePickerBackgroundColor,
    this.rangePickerElevation,
    this.rangePickerShadowColor,
    this.rangePickerSurfaceTintColor,
    this.rangePickerShape,
    this.rangePickerHeaderBackgroundColor,
    this.rangePickerHeaderForegroundColor,
    this.rangePickerHeaderHeadlineStyle,
    this.rangePickerHeaderHelpStyle,
    this.rangeSelectionBackgroundColor,
    this.rangeSelectionOverlayColor,
    this.dividerColor,
    this.inputDecorationTheme,
    this.cancelButtonStyle,
    this.confirmButtonStyle,
    this.locale,
  });
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final ShapeBorder? shape;
  final Color? headerBackgroundColor;
  final Color? headerForegroundColor;
  final TextStyle? headerHeadlineStyle;
  final TextStyle? headerHelpStyle;
  final TextStyle? weekdayStyle;
  final TextStyle? dayStyle;
  final WidgetStateProperty<Color?>? dayForegroundColor;
  final WidgetStateProperty<Color?>? dayBackgroundColor;
  final WidgetStateProperty<Color?>? dayOverlayColor;
  final WidgetStateProperty<OutlinedBorder?>? dayShape;
  final WidgetStateProperty<Color?>? todayForegroundColor;
  final WidgetStateProperty<Color?>? todayBackgroundColor;
  final BorderSide? todayBorder;
  final TextStyle? yearStyle;
  final WidgetStateProperty<Color?>? yearForegroundColor;
  final WidgetStateProperty<Color?>? yearBackgroundColor;
  final WidgetStateProperty<Color?>? yearOverlayColor;
  final Color? rangePickerBackgroundColor;
  final double? rangePickerElevation;
  final Color? rangePickerShadowColor;
  final Color? rangePickerSurfaceTintColor;
  final ShapeBorder? rangePickerShape;
  final Color? rangePickerHeaderBackgroundColor;
  final Color? rangePickerHeaderForegroundColor;
  final TextStyle? rangePickerHeaderHeadlineStyle;
  final TextStyle? rangePickerHeaderHelpStyle;
  final Color? rangeSelectionBackgroundColor;
  final WidgetStateProperty<Color?>? rangeSelectionOverlayColor;
  final Color? dividerColor;
  final InputDecorationTheme? inputDecorationTheme;
  final ButtonStyle? cancelButtonStyle;
  final ButtonStyle? confirmButtonStyle;
  final Locale? locale;
  DatePickerThemeData copyWith({
    Color? backgroundColor,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    Color? headerBackgroundColor,
    Color? headerForegroundColor,
    TextStyle? headerHeadlineStyle,
    TextStyle? headerHelpStyle,
    TextStyle? weekdayStyle,
    TextStyle? dayStyle,
    WidgetStateProperty<Color?>? dayForegroundColor,
    WidgetStateProperty<Color?>? dayBackgroundColor,
    WidgetStateProperty<Color?>? dayOverlayColor,
    WidgetStateProperty<OutlinedBorder?>? dayShape,
    WidgetStateProperty<Color?>? todayForegroundColor,
    WidgetStateProperty<Color?>? todayBackgroundColor,
    BorderSide? todayBorder,
    TextStyle? yearStyle,
    WidgetStateProperty<Color?>? yearForegroundColor,
    WidgetStateProperty<Color?>? yearBackgroundColor,
    WidgetStateProperty<Color?>? yearOverlayColor,
    Color? rangePickerBackgroundColor,
    double? rangePickerElevation,
    Color? rangePickerShadowColor,
    Color? rangePickerSurfaceTintColor,
    ShapeBorder? rangePickerShape,
    Color? rangePickerHeaderBackgroundColor,
    Color? rangePickerHeaderForegroundColor,
    TextStyle? rangePickerHeaderHeadlineStyle,
    TextStyle? rangePickerHeaderHelpStyle,
    Color? rangeSelectionBackgroundColor,
    WidgetStateProperty<Color?>? rangeSelectionOverlayColor,
    Color? dividerColor,
    InputDecorationTheme? inputDecorationTheme,
    ButtonStyle? cancelButtonStyle,
    ButtonStyle? confirmButtonStyle,
    Locale? locale,
  }) => DatePickerThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    elevation: elevation ?? this.elevation,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    shape: shape ?? this.shape,
    headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
    headerForegroundColor: headerForegroundColor ?? this.headerForegroundColor,
    headerHeadlineStyle: headerHeadlineStyle ?? this.headerHeadlineStyle,
    headerHelpStyle: headerHelpStyle ?? this.headerHelpStyle,
    weekdayStyle: weekdayStyle ?? this.weekdayStyle,
    dayStyle: dayStyle ?? this.dayStyle,
    dayForegroundColor: dayForegroundColor ?? this.dayForegroundColor,
    dayBackgroundColor: dayBackgroundColor ?? this.dayBackgroundColor,
    dayOverlayColor: dayOverlayColor ?? this.dayOverlayColor,
    dayShape: dayShape ?? this.dayShape,
    todayForegroundColor: todayForegroundColor ?? this.todayForegroundColor,
    todayBackgroundColor: todayBackgroundColor ?? this.todayBackgroundColor,
    todayBorder: todayBorder ?? this.todayBorder,
    yearStyle: yearStyle ?? this.yearStyle,
    yearForegroundColor: yearForegroundColor ?? this.yearForegroundColor,
    yearBackgroundColor: yearBackgroundColor ?? this.yearBackgroundColor,
    yearOverlayColor: yearOverlayColor ?? this.yearOverlayColor,
    rangePickerBackgroundColor:
        rangePickerBackgroundColor ?? this.rangePickerBackgroundColor,
    rangePickerElevation: rangePickerElevation ?? this.rangePickerElevation,
    rangePickerShadowColor:
        rangePickerShadowColor ?? this.rangePickerShadowColor,
    rangePickerSurfaceTintColor:
        rangePickerSurfaceTintColor ?? this.rangePickerSurfaceTintColor,
    rangePickerShape: rangePickerShape ?? this.rangePickerShape,
    rangePickerHeaderBackgroundColor:
        rangePickerHeaderBackgroundColor ??
        this.rangePickerHeaderBackgroundColor,
    rangePickerHeaderForegroundColor:
        rangePickerHeaderForegroundColor ??
        this.rangePickerHeaderForegroundColor,
    rangePickerHeaderHeadlineStyle:
        rangePickerHeaderHeadlineStyle ?? this.rangePickerHeaderHeadlineStyle,
    rangePickerHeaderHelpStyle:
        rangePickerHeaderHelpStyle ?? this.rangePickerHeaderHelpStyle,
    rangeSelectionBackgroundColor:
        rangeSelectionBackgroundColor ?? this.rangeSelectionBackgroundColor,
    rangeSelectionOverlayColor:
        rangeSelectionOverlayColor ?? this.rangeSelectionOverlayColor,
    dividerColor: dividerColor ?? this.dividerColor,
    inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
    cancelButtonStyle: cancelButtonStyle ?? this.cancelButtonStyle,
    confirmButtonStyle: confirmButtonStyle ?? this.confirmButtonStyle,
    locale: locale ?? this.locale,
  );
  static DatePickerThemeData lerp(
    DatePickerThemeData? a,
    DatePickerThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const DatePickerThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatePickerThemeData &&
          other.backgroundColor == backgroundColor &&
          other.elevation == elevation &&
          other.shadowColor == shadowColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.shape == shape &&
          other.headerBackgroundColor == headerBackgroundColor &&
          other.headerForegroundColor == headerForegroundColor &&
          other.headerHeadlineStyle == headerHeadlineStyle &&
          other.headerHelpStyle == headerHelpStyle &&
          other.weekdayStyle == weekdayStyle &&
          other.dayStyle == dayStyle &&
          other.dayForegroundColor == dayForegroundColor &&
          other.dayBackgroundColor == dayBackgroundColor &&
          other.dayOverlayColor == dayOverlayColor &&
          other.dayShape == dayShape &&
          other.todayForegroundColor == todayForegroundColor &&
          other.todayBackgroundColor == todayBackgroundColor &&
          other.todayBorder == todayBorder &&
          other.yearStyle == yearStyle &&
          other.yearForegroundColor == yearForegroundColor &&
          other.yearBackgroundColor == yearBackgroundColor &&
          other.yearOverlayColor == yearOverlayColor &&
          other.rangePickerBackgroundColor == rangePickerBackgroundColor &&
          other.rangePickerElevation == rangePickerElevation &&
          other.rangePickerShadowColor == rangePickerShadowColor &&
          other.rangePickerSurfaceTintColor == rangePickerSurfaceTintColor &&
          other.rangePickerShape == rangePickerShape &&
          other.rangePickerHeaderBackgroundColor ==
              rangePickerHeaderBackgroundColor &&
          other.rangePickerHeaderForegroundColor ==
              rangePickerHeaderForegroundColor &&
          other.rangePickerHeaderHeadlineStyle ==
              rangePickerHeaderHeadlineStyle &&
          other.rangePickerHeaderHelpStyle == rangePickerHeaderHelpStyle &&
          other.rangeSelectionBackgroundColor ==
              rangeSelectionBackgroundColor &&
          other.rangeSelectionOverlayColor == rangeSelectionOverlayColor &&
          other.dividerColor == dividerColor &&
          other.inputDecorationTheme == inputDecorationTheme &&
          other.cancelButtonStyle == cancelButtonStyle &&
          other.confirmButtonStyle == confirmButtonStyle &&
          other.locale == locale;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    elevation,
    shadowColor,
    surfaceTintColor,
    shape,
    headerBackgroundColor,
    headerForegroundColor,
    headerHeadlineStyle,
    headerHelpStyle,
    weekdayStyle,
    dayStyle,
    dayForegroundColor,
    dayBackgroundColor,
    dayOverlayColor,
    dayShape,
    todayForegroundColor,
    todayBackgroundColor,
    todayBorder,
    yearStyle,
    yearForegroundColor,
    yearBackgroundColor,
    yearOverlayColor,
    rangePickerBackgroundColor,
    rangePickerElevation,
    rangePickerShadowColor,
    rangePickerSurfaceTintColor,
    rangePickerShape,
    rangePickerHeaderBackgroundColor,
    rangePickerHeaderForegroundColor,
    rangePickerHeaderHeadlineStyle,
    rangePickerHeaderHelpStyle,
    rangeSelectionBackgroundColor,
    rangeSelectionOverlayColor,
    dividerColor,
    inputDecorationTheme,
    cancelButtonStyle,
    confirmButtonStyle,
    locale,
  ]);
}

class DialogThemeData {
  const DialogThemeData({
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.alignment,
    this.iconColor,
    this.titleTextStyle,
    this.contentTextStyle,
    this.actionsPadding,
    this.barrierColor,
    this.insetPadding,
    this.clipBehavior,
  });
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final ShapeBorder? shape;
  final AlignmentGeometry? alignment;
  final Color? iconColor;
  final TextStyle? titleTextStyle;
  final TextStyle? contentTextStyle;
  final EdgeInsetsGeometry? actionsPadding;
  final Color? barrierColor;
  final EdgeInsets? insetPadding;
  final Clip? clipBehavior;
  DialogThemeData copyWith({
    Color? backgroundColor,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    AlignmentGeometry? alignment,
    Color? iconColor,
    TextStyle? titleTextStyle,
    TextStyle? contentTextStyle,
    EdgeInsetsGeometry? actionsPadding,
    Color? barrierColor,
    EdgeInsets? insetPadding,
    Clip? clipBehavior,
  }) => DialogThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    elevation: elevation ?? this.elevation,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    shape: shape ?? this.shape,
    alignment: alignment ?? this.alignment,
    iconColor: iconColor ?? this.iconColor,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    contentTextStyle: contentTextStyle ?? this.contentTextStyle,
    actionsPadding: actionsPadding ?? this.actionsPadding,
    barrierColor: barrierColor ?? this.barrierColor,
    insetPadding: insetPadding ?? this.insetPadding,
    clipBehavior: clipBehavior ?? this.clipBehavior,
  );
  static DialogThemeData lerp(
    DialogThemeData? a,
    DialogThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const DialogThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialogThemeData &&
          other.backgroundColor == backgroundColor &&
          other.elevation == elevation &&
          other.shadowColor == shadowColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.shape == shape &&
          other.alignment == alignment &&
          other.iconColor == iconColor &&
          other.titleTextStyle == titleTextStyle &&
          other.contentTextStyle == contentTextStyle &&
          other.actionsPadding == actionsPadding &&
          other.barrierColor == barrierColor &&
          other.insetPadding == insetPadding &&
          other.clipBehavior == clipBehavior;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    elevation,
    shadowColor,
    surfaceTintColor,
    shape,
    alignment,
    iconColor,
    titleTextStyle,
    contentTextStyle,
    actionsPadding,
    barrierColor,
    insetPadding,
    clipBehavior,
  ]);
}

class DividerThemeData {
  const DividerThemeData({
    this.color,
    this.space,
    this.thickness,
    this.indent,
    this.endIndent,
  });
  final Color? color;
  final double? space;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  DividerThemeData copyWith({
    Color? color,
    double? space,
    double? thickness,
    double? indent,
    double? endIndent,
  }) => DividerThemeData(
    color: color ?? this.color,
    space: space ?? this.space,
    thickness: thickness ?? this.thickness,
    indent: indent ?? this.indent,
    endIndent: endIndent ?? this.endIndent,
  );
  static DividerThemeData lerp(
    DividerThemeData? a,
    DividerThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const DividerThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DividerThemeData &&
          other.color == color &&
          other.space == space &&
          other.thickness == thickness &&
          other.indent == indent &&
          other.endIndent == endIndent;
  @override
  int get hashCode =>
      Object.hashAll([color, space, thickness, indent, endIndent]);
}

class DrawerThemeData {
  const DrawerThemeData({
    this.backgroundColor,
    this.scrimColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.endShape,
    this.width,
    this.clipBehavior,
  });
  final Color? backgroundColor;
  final Color? scrimColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final ShapeBorder? shape;
  final ShapeBorder? endShape;
  final double? width;
  final Clip? clipBehavior;
  DrawerThemeData copyWith({
    Color? backgroundColor,
    Color? scrimColor,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    ShapeBorder? endShape,
    double? width,
    Clip? clipBehavior,
  }) => DrawerThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    scrimColor: scrimColor ?? this.scrimColor,
    elevation: elevation ?? this.elevation,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    shape: shape ?? this.shape,
    endShape: endShape ?? this.endShape,
    width: width ?? this.width,
    clipBehavior: clipBehavior ?? this.clipBehavior,
  );
  static DrawerThemeData lerp(
    DrawerThemeData? a,
    DrawerThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const DrawerThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawerThemeData &&
          other.backgroundColor == backgroundColor &&
          other.scrimColor == scrimColor &&
          other.elevation == elevation &&
          other.shadowColor == shadowColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.shape == shape &&
          other.endShape == endShape &&
          other.width == width &&
          other.clipBehavior == clipBehavior;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    scrimColor,
    elevation,
    shadowColor,
    surfaceTintColor,
    shape,
    endShape,
    width,
    clipBehavior,
  ]);
}

class DropdownMenuThemeData {
  const DropdownMenuThemeData({
    this.textStyle,
    this.inputDecorationTheme,
    this.menuStyle,
  });
  final TextStyle? textStyle;
  final InputDecorationTheme? inputDecorationTheme;
  final MenuStyle? menuStyle;
  DropdownMenuThemeData copyWith({
    TextStyle? textStyle,
    InputDecorationTheme? inputDecorationTheme,
    MenuStyle? menuStyle,
  }) => DropdownMenuThemeData(
    textStyle: textStyle ?? this.textStyle,
    inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
    menuStyle: menuStyle ?? this.menuStyle,
  );
  static DropdownMenuThemeData lerp(
    DropdownMenuThemeData? a,
    DropdownMenuThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const DropdownMenuThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropdownMenuThemeData &&
          other.textStyle == textStyle &&
          other.inputDecorationTheme == inputDecorationTheme &&
          other.menuStyle == menuStyle;
  @override
  int get hashCode =>
      Object.hashAll([textStyle, inputDecorationTheme, menuStyle]);
}

class ElevatedButtonThemeData {
  const ElevatedButtonThemeData({this.style});
  final ButtonStyle? style;
  ElevatedButtonThemeData copyWith({ButtonStyle? style}) =>
      ElevatedButtonThemeData(style: style ?? this.style);
  static ElevatedButtonThemeData lerp(
    ElevatedButtonThemeData? a,
    ElevatedButtonThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const ElevatedButtonThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElevatedButtonThemeData && other.style == style;
  @override
  int get hashCode => style.hashCode;
}

class FilledButtonThemeData {
  const FilledButtonThemeData({this.style});
  final ButtonStyle? style;
  FilledButtonThemeData copyWith({ButtonStyle? style}) =>
      FilledButtonThemeData(style: style ?? this.style);
  static FilledButtonThemeData lerp(
    FilledButtonThemeData? a,
    FilledButtonThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const FilledButtonThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilledButtonThemeData && other.style == style;
  @override
  int get hashCode => style.hashCode;
}

class OutlinedButtonThemeData {
  const OutlinedButtonThemeData({this.style});
  final ButtonStyle? style;
  OutlinedButtonThemeData copyWith({ButtonStyle? style}) =>
      OutlinedButtonThemeData(style: style ?? this.style);
  static OutlinedButtonThemeData lerp(
    OutlinedButtonThemeData? a,
    OutlinedButtonThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const OutlinedButtonThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutlinedButtonThemeData && other.style == style;
  @override
  int get hashCode => style.hashCode;
}

class TextButtonThemeData {
  const TextButtonThemeData({this.style});
  final ButtonStyle? style;
  TextButtonThemeData copyWith({ButtonStyle? style}) =>
      TextButtonThemeData(style: style ?? this.style);
  static TextButtonThemeData lerp(
    TextButtonThemeData? a,
    TextButtonThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const TextButtonThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextButtonThemeData && other.style == style;
  @override
  int get hashCode => style.hashCode;
}

class IconButtonThemeData {
  const IconButtonThemeData({this.style});
  final ButtonStyle? style;
  IconButtonThemeData copyWith({ButtonStyle? style}) =>
      IconButtonThemeData(style: style ?? this.style);
  static IconButtonThemeData lerp(
    IconButtonThemeData? a,
    IconButtonThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const IconButtonThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconButtonThemeData && other.style == style;
  @override
  int get hashCode => style.hashCode;
}

class MenuButtonThemeData {
  const MenuButtonThemeData({this.style});
  final ButtonStyle? style;
  MenuButtonThemeData copyWith({ButtonStyle? style}) =>
      MenuButtonThemeData(style: style ?? this.style);
  static MenuButtonThemeData lerp(
    MenuButtonThemeData? a,
    MenuButtonThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const MenuButtonThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuButtonThemeData && other.style == style;
  @override
  int get hashCode => style.hashCode;
}

class ExpansionTileThemeData {
  const ExpansionTileThemeData({
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.tilePadding,
    this.expandedAlignment,
    this.childrenPadding,
    this.iconColor,
    this.collapsedIconColor,
    this.textColor,
    this.collapsedTextColor,
    this.shape,
    this.collapsedShape,
    this.clipBehavior,
  });
  final Color? backgroundColor;
  final Color? collapsedBackgroundColor;
  final EdgeInsetsGeometry? tilePadding;
  final AlignmentGeometry? expandedAlignment;
  final EdgeInsetsGeometry? childrenPadding;
  final Color? iconColor;
  final Color? collapsedIconColor;
  final Color? textColor;
  final Color? collapsedTextColor;
  final ShapeBorder? shape;
  final ShapeBorder? collapsedShape;
  final Clip? clipBehavior;
  ExpansionTileThemeData copyWith({
    Color? backgroundColor,
    Color? collapsedBackgroundColor,
    EdgeInsetsGeometry? tilePadding,
    AlignmentGeometry? expandedAlignment,
    EdgeInsetsGeometry? childrenPadding,
    Color? iconColor,
    Color? collapsedIconColor,
    Color? textColor,
    Color? collapsedTextColor,
    ShapeBorder? shape,
    ShapeBorder? collapsedShape,
    Clip? clipBehavior,
  }) => ExpansionTileThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    collapsedBackgroundColor:
        collapsedBackgroundColor ?? this.collapsedBackgroundColor,
    tilePadding: tilePadding ?? this.tilePadding,
    expandedAlignment: expandedAlignment ?? this.expandedAlignment,
    childrenPadding: childrenPadding ?? this.childrenPadding,
    iconColor: iconColor ?? this.iconColor,
    collapsedIconColor: collapsedIconColor ?? this.collapsedIconColor,
    textColor: textColor ?? this.textColor,
    collapsedTextColor: collapsedTextColor ?? this.collapsedTextColor,
    shape: shape ?? this.shape,
    collapsedShape: collapsedShape ?? this.collapsedShape,
    clipBehavior: clipBehavior ?? this.clipBehavior,
  );
  static ExpansionTileThemeData lerp(
    ExpansionTileThemeData? a,
    ExpansionTileThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const ExpansionTileThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpansionTileThemeData &&
          other.backgroundColor == backgroundColor &&
          other.collapsedBackgroundColor == collapsedBackgroundColor &&
          other.tilePadding == tilePadding &&
          other.expandedAlignment == expandedAlignment &&
          other.childrenPadding == childrenPadding &&
          other.iconColor == iconColor &&
          other.collapsedIconColor == collapsedIconColor &&
          other.textColor == textColor &&
          other.collapsedTextColor == collapsedTextColor &&
          other.shape == shape &&
          other.collapsedShape == collapsedShape &&
          other.clipBehavior == clipBehavior;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    collapsedBackgroundColor,
    tilePadding,
    expandedAlignment,
    childrenPadding,
    iconColor,
    collapsedIconColor,
    textColor,
    collapsedTextColor,
    shape,
    collapsedShape,
    clipBehavior,
  ]);
}

class FloatingActionButtonThemeData {
  const FloatingActionButtonThemeData({
    this.foregroundColor,
    this.backgroundColor,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.elevation,
    this.focusElevation,
    this.hoverElevation,
    this.disabledElevation,
    this.highlightElevation,
    this.shape,
    this.enableFeedback,
    this.iconSize,
    this.sizeConstraints,
    this.smallSizeConstraints,
    this.largeSizeConstraints,
    this.extendedSizeConstraints,
    this.extendedIconLabelSpacing,
    this.extendedPadding,
    this.extendedTextStyle,
    this.mouseCursor,
  });
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? splashColor;
  final double? elevation;
  final double? focusElevation;
  final double? hoverElevation;
  final double? disabledElevation;
  final double? highlightElevation;
  final ShapeBorder? shape;
  final bool? enableFeedback;
  final double? iconSize;
  final BoxConstraints? sizeConstraints;
  final BoxConstraints? smallSizeConstraints;
  final BoxConstraints? largeSizeConstraints;
  final BoxConstraints? extendedSizeConstraints;
  final double? extendedIconLabelSpacing;
  final EdgeInsetsGeometry? extendedPadding;
  final TextStyle? extendedTextStyle;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  FloatingActionButtonThemeData copyWith({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? focusColor,
    Color? hoverColor,
    Color? splashColor,
    double? elevation,
    double? focusElevation,
    double? hoverElevation,
    double? disabledElevation,
    double? highlightElevation,
    ShapeBorder? shape,
    bool? enableFeedback,
    double? iconSize,
    BoxConstraints? sizeConstraints,
    BoxConstraints? smallSizeConstraints,
    BoxConstraints? largeSizeConstraints,
    BoxConstraints? extendedSizeConstraints,
    double? extendedIconLabelSpacing,
    EdgeInsetsGeometry? extendedPadding,
    TextStyle? extendedTextStyle,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FloatingActionButtonThemeData(
    foregroundColor: foregroundColor ?? this.foregroundColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    focusColor: focusColor ?? this.focusColor,
    hoverColor: hoverColor ?? this.hoverColor,
    splashColor: splashColor ?? this.splashColor,
    elevation: elevation ?? this.elevation,
    focusElevation: focusElevation ?? this.focusElevation,
    hoverElevation: hoverElevation ?? this.hoverElevation,
    disabledElevation: disabledElevation ?? this.disabledElevation,
    highlightElevation: highlightElevation ?? this.highlightElevation,
    shape: shape ?? this.shape,
    enableFeedback: enableFeedback ?? this.enableFeedback,
    iconSize: iconSize ?? this.iconSize,
    sizeConstraints: sizeConstraints ?? this.sizeConstraints,
    smallSizeConstraints: smallSizeConstraints ?? this.smallSizeConstraints,
    largeSizeConstraints: largeSizeConstraints ?? this.largeSizeConstraints,
    extendedSizeConstraints:
        extendedSizeConstraints ?? this.extendedSizeConstraints,
    extendedIconLabelSpacing:
        extendedIconLabelSpacing ?? this.extendedIconLabelSpacing,
    extendedPadding: extendedPadding ?? this.extendedPadding,
    extendedTextStyle: extendedTextStyle ?? this.extendedTextStyle,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );
  static FloatingActionButtonThemeData lerp(
    FloatingActionButtonThemeData? a,
    FloatingActionButtonThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const FloatingActionButtonThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FloatingActionButtonThemeData &&
          other.foregroundColor == foregroundColor &&
          other.backgroundColor == backgroundColor &&
          other.focusColor == focusColor &&
          other.hoverColor == hoverColor &&
          other.splashColor == splashColor &&
          other.elevation == elevation &&
          other.focusElevation == focusElevation &&
          other.hoverElevation == hoverElevation &&
          other.disabledElevation == disabledElevation &&
          other.highlightElevation == highlightElevation &&
          other.shape == shape &&
          other.enableFeedback == enableFeedback &&
          other.iconSize == iconSize &&
          other.sizeConstraints == sizeConstraints &&
          other.smallSizeConstraints == smallSizeConstraints &&
          other.largeSizeConstraints == largeSizeConstraints &&
          other.extendedSizeConstraints == extendedSizeConstraints &&
          other.extendedIconLabelSpacing == extendedIconLabelSpacing &&
          other.extendedPadding == extendedPadding &&
          other.extendedTextStyle == extendedTextStyle &&
          other.mouseCursor == mouseCursor;
  @override
  int get hashCode => Object.hashAll([
    foregroundColor,
    backgroundColor,
    focusColor,
    hoverColor,
    splashColor,
    elevation,
    focusElevation,
    hoverElevation,
    disabledElevation,
    highlightElevation,
    shape,
    enableFeedback,
    iconSize,
    sizeConstraints,
    smallSizeConstraints,
    largeSizeConstraints,
    extendedSizeConstraints,
    extendedIconLabelSpacing,
    extendedPadding,
    extendedTextStyle,
    mouseCursor,
  ]);
}

class InputDecorationTheme {
  const InputDecorationTheme({
    this.labelStyle,
    this.floatingLabelStyle,
    this.helperStyle,
    this.helperMaxLines,
    this.hintStyle,
    this.errorStyle,
    this.errorMaxLines,
    this.floatingLabelBehavior = FloatingLabelBehavior.auto,
    this.floatingLabelAlignment = FloatingLabelAlignment.start,
    this.isDense = false,
    this.contentPadding,
    this.isCollapsed = false,
    this.iconColor,
    this.prefixStyle,
    this.prefixIconColor,
    this.prefixIconConstraints,
    this.suffixStyle,
    this.suffixIconColor,
    this.suffixIconConstraints,
    this.counterStyle,
    this.filled = false,
    this.fillColor,
    this.activeIndicatorBorder,
    this.outlineBorder,
    this.focusColor,
    this.hoverColor,
    this.errorBorder,
    this.focusedBorder,
    this.focusedErrorBorder,
    this.disabledBorder,
    this.enabledBorder,
    this.border,
    this.alignLabelWithHint = false,
    this.constraints,
  });
  final TextStyle? labelStyle;
  final TextStyle? floatingLabelStyle;
  final TextStyle? helperStyle;
  final int? helperMaxLines;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final int? errorMaxLines;
  final FloatingLabelBehavior floatingLabelBehavior;
  final FloatingLabelAlignment floatingLabelAlignment;
  final bool isDense;
  final EdgeInsetsGeometry? contentPadding;
  final bool isCollapsed;
  final Color? iconColor;
  final TextStyle? prefixStyle;
  final Color? prefixIconColor;
  final BoxConstraints? prefixIconConstraints;
  final TextStyle? suffixStyle;
  final Color? suffixIconColor;
  final BoxConstraints? suffixIconConstraints;
  final TextStyle? counterStyle;
  final bool filled;
  final Color? fillColor;
  final BorderSide? activeIndicatorBorder;
  final BorderSide? outlineBorder;
  final Color? focusColor;
  final Color? hoverColor;
  final InputBorder? errorBorder;
  final InputBorder? focusedBorder;
  final InputBorder? focusedErrorBorder;
  final InputBorder? disabledBorder;
  final InputBorder? enabledBorder;
  final InputBorder? border;
  final bool alignLabelWithHint;
  final BoxConstraints? constraints;

  /// Fills this theme's null properties from [inputDecorationTheme].
  InputDecorationTheme merge(InputDecorationTheme? inputDecorationTheme) {
    final other = inputDecorationTheme;
    if (other == null) return this;
    return copyWith(
      labelStyle: labelStyle ?? other.labelStyle,
      floatingLabelStyle: floatingLabelStyle ?? other.floatingLabelStyle,
      helperStyle: helperStyle ?? other.helperStyle,
      helperMaxLines: helperMaxLines ?? other.helperMaxLines,
      hintStyle: hintStyle ?? other.hintStyle,
      errorStyle: errorStyle ?? other.errorStyle,
      errorMaxLines: errorMaxLines ?? other.errorMaxLines,
      contentPadding: contentPadding ?? other.contentPadding,
      iconColor: iconColor ?? other.iconColor,
      prefixStyle: prefixStyle ?? other.prefixStyle,
      prefixIconColor: prefixIconColor ?? other.prefixIconColor,
      prefixIconConstraints:
          prefixIconConstraints ?? other.prefixIconConstraints,
      suffixStyle: suffixStyle ?? other.suffixStyle,
      suffixIconColor: suffixIconColor ?? other.suffixIconColor,
      suffixIconConstraints:
          suffixIconConstraints ?? other.suffixIconConstraints,
      counterStyle: counterStyle ?? other.counterStyle,
      fillColor: fillColor ?? other.fillColor,
      activeIndicatorBorder:
          activeIndicatorBorder ?? other.activeIndicatorBorder,
      outlineBorder: outlineBorder ?? other.outlineBorder,
      focusColor: focusColor ?? other.focusColor,
      hoverColor: hoverColor ?? other.hoverColor,
      errorBorder: errorBorder ?? other.errorBorder,
      focusedBorder: focusedBorder ?? other.focusedBorder,
      focusedErrorBorder: focusedErrorBorder ?? other.focusedErrorBorder,
      disabledBorder: disabledBorder ?? other.disabledBorder,
      enabledBorder: enabledBorder ?? other.enabledBorder,
      border: border ?? other.border,
      constraints: constraints ?? other.constraints,
    );
  }

  InputDecorationTheme copyWith({
    TextStyle? labelStyle,
    TextStyle? floatingLabelStyle,
    TextStyle? helperStyle,
    int? helperMaxLines,
    TextStyle? hintStyle,
    TextStyle? errorStyle,
    int? errorMaxLines,
    FloatingLabelBehavior? floatingLabelBehavior,
    FloatingLabelAlignment? floatingLabelAlignment,
    bool? isDense,
    EdgeInsetsGeometry? contentPadding,
    bool? isCollapsed,
    Color? iconColor,
    TextStyle? prefixStyle,
    Color? prefixIconColor,
    BoxConstraints? prefixIconConstraints,
    TextStyle? suffixStyle,
    Color? suffixIconColor,
    BoxConstraints? suffixIconConstraints,
    TextStyle? counterStyle,
    bool? filled,
    Color? fillColor,
    BorderSide? activeIndicatorBorder,
    BorderSide? outlineBorder,
    Color? focusColor,
    Color? hoverColor,
    InputBorder? errorBorder,
    InputBorder? focusedBorder,
    InputBorder? focusedErrorBorder,
    InputBorder? disabledBorder,
    InputBorder? enabledBorder,
    InputBorder? border,
    bool? alignLabelWithHint,
    BoxConstraints? constraints,
  }) => InputDecorationTheme(
    labelStyle: labelStyle ?? this.labelStyle,
    floatingLabelStyle: floatingLabelStyle ?? this.floatingLabelStyle,
    helperStyle: helperStyle ?? this.helperStyle,
    helperMaxLines: helperMaxLines ?? this.helperMaxLines,
    hintStyle: hintStyle ?? this.hintStyle,
    errorStyle: errorStyle ?? this.errorStyle,
    errorMaxLines: errorMaxLines ?? this.errorMaxLines,
    floatingLabelBehavior: floatingLabelBehavior ?? this.floatingLabelBehavior,
    floatingLabelAlignment:
        floatingLabelAlignment ?? this.floatingLabelAlignment,
    isDense: isDense ?? this.isDense,
    contentPadding: contentPadding ?? this.contentPadding,
    isCollapsed: isCollapsed ?? this.isCollapsed,
    iconColor: iconColor ?? this.iconColor,
    prefixStyle: prefixStyle ?? this.prefixStyle,
    prefixIconColor: prefixIconColor ?? this.prefixIconColor,
    prefixIconConstraints: prefixIconConstraints ?? this.prefixIconConstraints,
    suffixStyle: suffixStyle ?? this.suffixStyle,
    suffixIconColor: suffixIconColor ?? this.suffixIconColor,
    suffixIconConstraints: suffixIconConstraints ?? this.suffixIconConstraints,
    counterStyle: counterStyle ?? this.counterStyle,
    filled: filled ?? this.filled,
    fillColor: fillColor ?? this.fillColor,
    activeIndicatorBorder: activeIndicatorBorder ?? this.activeIndicatorBorder,
    outlineBorder: outlineBorder ?? this.outlineBorder,
    focusColor: focusColor ?? this.focusColor,
    hoverColor: hoverColor ?? this.hoverColor,
    errorBorder: errorBorder ?? this.errorBorder,
    focusedBorder: focusedBorder ?? this.focusedBorder,
    focusedErrorBorder: focusedErrorBorder ?? this.focusedErrorBorder,
    disabledBorder: disabledBorder ?? this.disabledBorder,
    enabledBorder: enabledBorder ?? this.enabledBorder,
    border: border ?? this.border,
    alignLabelWithHint: alignLabelWithHint ?? this.alignLabelWithHint,
    constraints: constraints ?? this.constraints,
  );
  static InputDecorationTheme lerp(
    InputDecorationTheme? a,
    InputDecorationTheme? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const InputDecorationTheme();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InputDecorationTheme &&
          other.labelStyle == labelStyle &&
          other.floatingLabelStyle == floatingLabelStyle &&
          other.helperStyle == helperStyle &&
          other.helperMaxLines == helperMaxLines &&
          other.hintStyle == hintStyle &&
          other.errorStyle == errorStyle &&
          other.errorMaxLines == errorMaxLines &&
          other.floatingLabelBehavior == floatingLabelBehavior &&
          other.floatingLabelAlignment == floatingLabelAlignment &&
          other.isDense == isDense &&
          other.contentPadding == contentPadding &&
          other.isCollapsed == isCollapsed &&
          other.iconColor == iconColor &&
          other.prefixStyle == prefixStyle &&
          other.prefixIconColor == prefixIconColor &&
          other.prefixIconConstraints == prefixIconConstraints &&
          other.suffixStyle == suffixStyle &&
          other.suffixIconColor == suffixIconColor &&
          other.suffixIconConstraints == suffixIconConstraints &&
          other.counterStyle == counterStyle &&
          other.filled == filled &&
          other.fillColor == fillColor &&
          other.activeIndicatorBorder == activeIndicatorBorder &&
          other.outlineBorder == outlineBorder &&
          other.focusColor == focusColor &&
          other.hoverColor == hoverColor &&
          other.errorBorder == errorBorder &&
          other.focusedBorder == focusedBorder &&
          other.focusedErrorBorder == focusedErrorBorder &&
          other.disabledBorder == disabledBorder &&
          other.enabledBorder == enabledBorder &&
          other.border == border &&
          other.alignLabelWithHint == alignLabelWithHint &&
          other.constraints == constraints;
  @override
  int get hashCode => Object.hashAll([
    labelStyle,
    floatingLabelStyle,
    helperStyle,
    helperMaxLines,
    hintStyle,
    errorStyle,
    errorMaxLines,
    floatingLabelBehavior,
    floatingLabelAlignment,
    isDense,
    contentPadding,
    isCollapsed,
    iconColor,
    prefixStyle,
    prefixIconColor,
    prefixIconConstraints,
    suffixStyle,
    suffixIconColor,
    suffixIconConstraints,
    counterStyle,
    filled,
    fillColor,
    activeIndicatorBorder,
    outlineBorder,
    focusColor,
    hoverColor,
    errorBorder,
    focusedBorder,
    focusedErrorBorder,
    disabledBorder,
    enabledBorder,
    border,
    alignLabelWithHint,
    constraints,
  ]);
}

class ListTileThemeData {
  const ListTileThemeData({
    this.dense,
    this.shape,
    this.style,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    this.contentPadding,
    this.tileColor,
    this.selectedTileColor,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.minTileHeight,
    this.enableFeedback,
    this.mouseCursor,
    this.visualDensity,
    this.titleAlignment,
    this.controlAffinity,
    this.isThreeLine,
  });
  final bool? dense;
  final ShapeBorder? shape;
  final ListTileStyle? style;
  final Color? selectedColor;
  final Color? iconColor;
  final Color? textColor;
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final TextStyle? leadingAndTrailingTextStyle;
  final EdgeInsetsGeometry? contentPadding;
  final Color? tileColor;
  final Color? selectedTileColor;
  final double? horizontalTitleGap;
  final double? minVerticalPadding;
  final double? minLeadingWidth;
  final double? minTileHeight;
  final bool? enableFeedback;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final VisualDensity? visualDensity;
  final ListTileTitleAlignment? titleAlignment;
  final ListTileControlAffinity? controlAffinity;
  final bool? isThreeLine;
  ListTileThemeData copyWith({
    bool? dense,
    ShapeBorder? shape,
    ListTileStyle? style,
    Color? selectedColor,
    Color? iconColor,
    Color? textColor,
    TextStyle? titleTextStyle,
    TextStyle? subtitleTextStyle,
    TextStyle? leadingAndTrailingTextStyle,
    EdgeInsetsGeometry? contentPadding,
    Color? tileColor,
    Color? selectedTileColor,
    double? horizontalTitleGap,
    double? minVerticalPadding,
    double? minLeadingWidth,
    double? minTileHeight,
    bool? enableFeedback,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    VisualDensity? visualDensity,
    ListTileTitleAlignment? titleAlignment,
    ListTileControlAffinity? controlAffinity,
    bool? isThreeLine,
  }) => ListTileThemeData(
    dense: dense ?? this.dense,
    shape: shape ?? this.shape,
    style: style ?? this.style,
    selectedColor: selectedColor ?? this.selectedColor,
    iconColor: iconColor ?? this.iconColor,
    textColor: textColor ?? this.textColor,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    subtitleTextStyle: subtitleTextStyle ?? this.subtitleTextStyle,
    leadingAndTrailingTextStyle:
        leadingAndTrailingTextStyle ?? this.leadingAndTrailingTextStyle,
    contentPadding: contentPadding ?? this.contentPadding,
    tileColor: tileColor ?? this.tileColor,
    selectedTileColor: selectedTileColor ?? this.selectedTileColor,
    horizontalTitleGap: horizontalTitleGap ?? this.horizontalTitleGap,
    minVerticalPadding: minVerticalPadding ?? this.minVerticalPadding,
    minLeadingWidth: minLeadingWidth ?? this.minLeadingWidth,
    minTileHeight: minTileHeight ?? this.minTileHeight,
    enableFeedback: enableFeedback ?? this.enableFeedback,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    visualDensity: visualDensity ?? this.visualDensity,
    titleAlignment: titleAlignment ?? this.titleAlignment,
    controlAffinity: controlAffinity ?? this.controlAffinity,
    isThreeLine: isThreeLine ?? this.isThreeLine,
  );
  static ListTileThemeData lerp(
    ListTileThemeData? a,
    ListTileThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const ListTileThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListTileThemeData &&
          other.dense == dense &&
          other.shape == shape &&
          other.style == style &&
          other.selectedColor == selectedColor &&
          other.iconColor == iconColor &&
          other.textColor == textColor &&
          other.titleTextStyle == titleTextStyle &&
          other.subtitleTextStyle == subtitleTextStyle &&
          other.leadingAndTrailingTextStyle == leadingAndTrailingTextStyle &&
          other.contentPadding == contentPadding &&
          other.tileColor == tileColor &&
          other.selectedTileColor == selectedTileColor &&
          other.horizontalTitleGap == horizontalTitleGap &&
          other.minVerticalPadding == minVerticalPadding &&
          other.minLeadingWidth == minLeadingWidth &&
          other.minTileHeight == minTileHeight &&
          other.enableFeedback == enableFeedback &&
          other.mouseCursor == mouseCursor &&
          other.visualDensity == visualDensity &&
          other.titleAlignment == titleAlignment &&
          other.controlAffinity == controlAffinity &&
          other.isThreeLine == isThreeLine;
  @override
  int get hashCode => Object.hashAll([
    dense,
    shape,
    style,
    selectedColor,
    iconColor,
    textColor,
    titleTextStyle,
    subtitleTextStyle,
    leadingAndTrailingTextStyle,
    contentPadding,
    tileColor,
    selectedTileColor,
    horizontalTitleGap,
    minVerticalPadding,
    minLeadingWidth,
    minTileHeight,
    enableFeedback,
    mouseCursor,
    visualDensity,
    titleAlignment,
    controlAffinity,
    isThreeLine,
  ]);
}

class MenuStyle {
  const MenuStyle({
    this.backgroundColor,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.padding,
    this.minimumSize,
    this.fixedSize,
    this.maximumSize,
    this.side,
    this.shape,
    this.mouseCursor,
    this.visualDensity,
    this.alignment,
  });
  final WidgetStateProperty<Color?>? backgroundColor;
  final WidgetStateProperty<Color?>? shadowColor;
  final WidgetStateProperty<Color?>? surfaceTintColor;
  final WidgetStateProperty<double?>? elevation;
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;
  final WidgetStateProperty<Size?>? minimumSize;
  final WidgetStateProperty<Size?>? fixedSize;
  final WidgetStateProperty<Size?>? maximumSize;
  final WidgetStateProperty<BorderSide?>? side;
  final WidgetStateProperty<OutlinedBorder?>? shape;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final VisualDensity? visualDensity;
  final AlignmentGeometry? alignment;

  /// Fills this style's null properties from [style].
  MenuStyle merge(MenuStyle? style) => style == null
      ? this
      : copyWith(
          backgroundColor: backgroundColor ?? style.backgroundColor,
          shadowColor: shadowColor ?? style.shadowColor,
          surfaceTintColor: surfaceTintColor ?? style.surfaceTintColor,
          elevation: elevation ?? style.elevation,
          padding: padding ?? style.padding,
          minimumSize: minimumSize ?? style.minimumSize,
          fixedSize: fixedSize ?? style.fixedSize,
          maximumSize: maximumSize ?? style.maximumSize,
          side: side ?? style.side,
          shape: shape ?? style.shape,
          mouseCursor: mouseCursor ?? style.mouseCursor,
          visualDensity: visualDensity ?? style.visualDensity,
          alignment: alignment ?? style.alignment,
        );
  MenuStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? shadowColor,
    WidgetStateProperty<Color?>? surfaceTintColor,
    WidgetStateProperty<double?>? elevation,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<Size?>? fixedSize,
    WidgetStateProperty<Size?>? maximumSize,
    WidgetStateProperty<BorderSide?>? side,
    WidgetStateProperty<OutlinedBorder?>? shape,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    VisualDensity? visualDensity,
    AlignmentGeometry? alignment,
  }) => MenuStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    elevation: elevation ?? this.elevation,
    padding: padding ?? this.padding,
    minimumSize: minimumSize ?? this.minimumSize,
    fixedSize: fixedSize ?? this.fixedSize,
    maximumSize: maximumSize ?? this.maximumSize,
    side: side ?? this.side,
    shape: shape ?? this.shape,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    visualDensity: visualDensity ?? this.visualDensity,
    alignment: alignment ?? this.alignment,
  );
  static MenuStyle lerp(MenuStyle? a, MenuStyle? b, double t) =>
      (t < 0.5 ? a : b) ?? const MenuStyle();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuStyle &&
          other.backgroundColor == backgroundColor &&
          other.shadowColor == shadowColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.elevation == elevation &&
          other.padding == padding &&
          other.minimumSize == minimumSize &&
          other.fixedSize == fixedSize &&
          other.maximumSize == maximumSize &&
          other.side == side &&
          other.shape == shape &&
          other.mouseCursor == mouseCursor &&
          other.visualDensity == visualDensity &&
          other.alignment == alignment;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    shadowColor,
    surfaceTintColor,
    elevation,
    padding,
    minimumSize,
    fixedSize,
    maximumSize,
    side,
    shape,
    mouseCursor,
    visualDensity,
    alignment,
  ]);
}

class MenuThemeData {
  const MenuThemeData({this.style});
  final MenuStyle? style;
  MenuThemeData copyWith({MenuStyle? style}) =>
      MenuThemeData(style: style ?? this.style);
  static MenuThemeData lerp(MenuThemeData? a, MenuThemeData? b, double t) =>
      (t < 0.5 ? a : b) ?? const MenuThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MenuThemeData && other.style == style;
  @override
  int get hashCode => style.hashCode;
}

class MenuBarThemeData {
  const MenuBarThemeData({this.style});
  final MenuStyle? style;
  MenuBarThemeData copyWith({MenuStyle? style}) =>
      MenuBarThemeData(style: style ?? this.style);
  static MenuBarThemeData lerp(
    MenuBarThemeData? a,
    MenuBarThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const MenuBarThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuBarThemeData && other.style == style;
  @override
  int get hashCode => style.hashCode;
}

class NavigationBarThemeData {
  const NavigationBarThemeData({
    this.height,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.indicatorColor,
    this.indicatorShape,
    this.labelTextStyle,
    this.iconTheme,
    this.labelBehavior,
    this.overlayColor,
    this.labelPadding,
  });
  final double? height;
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final Color? indicatorColor;
  final ShapeBorder? indicatorShape;
  final WidgetStateProperty<TextStyle?>? labelTextStyle;
  final WidgetStateProperty<IconThemeData?>? iconTheme;
  final NavigationDestinationLabelBehavior? labelBehavior;
  final WidgetStateProperty<Color?>? overlayColor;
  final EdgeInsetsGeometry? labelPadding;
  NavigationBarThemeData copyWith({
    double? height,
    Color? backgroundColor,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    Color? indicatorColor,
    ShapeBorder? indicatorShape,
    WidgetStateProperty<TextStyle?>? labelTextStyle,
    WidgetStateProperty<IconThemeData?>? iconTheme,
    NavigationDestinationLabelBehavior? labelBehavior,
    WidgetStateProperty<Color?>? overlayColor,
    EdgeInsetsGeometry? labelPadding,
  }) => NavigationBarThemeData(
    height: height ?? this.height,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    elevation: elevation ?? this.elevation,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    indicatorShape: indicatorShape ?? this.indicatorShape,
    labelTextStyle: labelTextStyle ?? this.labelTextStyle,
    iconTheme: iconTheme ?? this.iconTheme,
    labelBehavior: labelBehavior ?? this.labelBehavior,
    overlayColor: overlayColor ?? this.overlayColor,
    labelPadding: labelPadding ?? this.labelPadding,
  );
  static NavigationBarThemeData lerp(
    NavigationBarThemeData? a,
    NavigationBarThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const NavigationBarThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationBarThemeData &&
          other.height == height &&
          other.backgroundColor == backgroundColor &&
          other.elevation == elevation &&
          other.shadowColor == shadowColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.indicatorColor == indicatorColor &&
          other.indicatorShape == indicatorShape &&
          other.labelTextStyle == labelTextStyle &&
          other.iconTheme == iconTheme &&
          other.labelBehavior == labelBehavior &&
          other.overlayColor == overlayColor &&
          other.labelPadding == labelPadding;
  @override
  int get hashCode => Object.hashAll([
    height,
    backgroundColor,
    elevation,
    shadowColor,
    surfaceTintColor,
    indicatorColor,
    indicatorShape,
    labelTextStyle,
    iconTheme,
    labelBehavior,
    overlayColor,
    labelPadding,
  ]);
}

class NavigationDrawerThemeData {
  const NavigationDrawerThemeData({
    this.tileHeight,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.indicatorColor,
    this.indicatorShape,
    this.indicatorSize,
    this.labelTextStyle,
    this.iconTheme,
  });
  final double? tileHeight;
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final Color? indicatorColor;
  final ShapeBorder? indicatorShape;
  final Size? indicatorSize;
  final WidgetStateProperty<TextStyle?>? labelTextStyle;
  final WidgetStateProperty<IconThemeData?>? iconTheme;
  NavigationDrawerThemeData copyWith({
    double? tileHeight,
    Color? backgroundColor,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    Color? indicatorColor,
    ShapeBorder? indicatorShape,
    Size? indicatorSize,
    WidgetStateProperty<TextStyle?>? labelTextStyle,
    WidgetStateProperty<IconThemeData?>? iconTheme,
  }) => NavigationDrawerThemeData(
    tileHeight: tileHeight ?? this.tileHeight,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    elevation: elevation ?? this.elevation,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    indicatorShape: indicatorShape ?? this.indicatorShape,
    indicatorSize: indicatorSize ?? this.indicatorSize,
    labelTextStyle: labelTextStyle ?? this.labelTextStyle,
    iconTheme: iconTheme ?? this.iconTheme,
  );
  static NavigationDrawerThemeData lerp(
    NavigationDrawerThemeData? a,
    NavigationDrawerThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const NavigationDrawerThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationDrawerThemeData &&
          other.tileHeight == tileHeight &&
          other.backgroundColor == backgroundColor &&
          other.elevation == elevation &&
          other.shadowColor == shadowColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.indicatorColor == indicatorColor &&
          other.indicatorShape == indicatorShape &&
          other.indicatorSize == indicatorSize &&
          other.labelTextStyle == labelTextStyle &&
          other.iconTheme == iconTheme;
  @override
  int get hashCode => Object.hashAll([
    tileHeight,
    backgroundColor,
    elevation,
    shadowColor,
    surfaceTintColor,
    indicatorColor,
    indicatorShape,
    indicatorSize,
    labelTextStyle,
    iconTheme,
  ]);
}

class NavigationRailThemeData {
  const NavigationRailThemeData({
    this.backgroundColor,
    this.elevation,
    this.unselectedLabelTextStyle,
    this.selectedLabelTextStyle,
    this.unselectedIconTheme,
    this.selectedIconTheme,
    this.groupAlignment,
    this.labelType,
    this.useIndicator,
    this.indicatorColor,
    this.indicatorShape,
    this.minWidth,
    this.minExtendedWidth,
  });
  final Color? backgroundColor;
  final double? elevation;
  final TextStyle? unselectedLabelTextStyle;
  final TextStyle? selectedLabelTextStyle;
  final IconThemeData? unselectedIconTheme;
  final IconThemeData? selectedIconTheme;
  final double? groupAlignment;
  final NavigationRailLabelType? labelType;
  final bool? useIndicator;
  final Color? indicatorColor;
  final ShapeBorder? indicatorShape;
  final double? minWidth;
  final double? minExtendedWidth;
  NavigationRailThemeData copyWith({
    Color? backgroundColor,
    double? elevation,
    TextStyle? unselectedLabelTextStyle,
    TextStyle? selectedLabelTextStyle,
    IconThemeData? unselectedIconTheme,
    IconThemeData? selectedIconTheme,
    double? groupAlignment,
    NavigationRailLabelType? labelType,
    bool? useIndicator,
    Color? indicatorColor,
    ShapeBorder? indicatorShape,
    double? minWidth,
    double? minExtendedWidth,
  }) => NavigationRailThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    elevation: elevation ?? this.elevation,
    unselectedLabelTextStyle:
        unselectedLabelTextStyle ?? this.unselectedLabelTextStyle,
    selectedLabelTextStyle:
        selectedLabelTextStyle ?? this.selectedLabelTextStyle,
    unselectedIconTheme: unselectedIconTheme ?? this.unselectedIconTheme,
    selectedIconTheme: selectedIconTheme ?? this.selectedIconTheme,
    groupAlignment: groupAlignment ?? this.groupAlignment,
    labelType: labelType ?? this.labelType,
    useIndicator: useIndicator ?? this.useIndicator,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    indicatorShape: indicatorShape ?? this.indicatorShape,
    minWidth: minWidth ?? this.minWidth,
    minExtendedWidth: minExtendedWidth ?? this.minExtendedWidth,
  );
  static NavigationRailThemeData lerp(
    NavigationRailThemeData? a,
    NavigationRailThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const NavigationRailThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationRailThemeData &&
          other.backgroundColor == backgroundColor &&
          other.elevation == elevation &&
          other.unselectedLabelTextStyle == unselectedLabelTextStyle &&
          other.selectedLabelTextStyle == selectedLabelTextStyle &&
          other.unselectedIconTheme == unselectedIconTheme &&
          other.selectedIconTheme == selectedIconTheme &&
          other.groupAlignment == groupAlignment &&
          other.labelType == labelType &&
          other.useIndicator == useIndicator &&
          other.indicatorColor == indicatorColor &&
          other.indicatorShape == indicatorShape &&
          other.minWidth == minWidth &&
          other.minExtendedWidth == minExtendedWidth;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    elevation,
    unselectedLabelTextStyle,
    selectedLabelTextStyle,
    unselectedIconTheme,
    selectedIconTheme,
    groupAlignment,
    labelType,
    useIndicator,
    indicatorColor,
    indicatorShape,
    minWidth,
    minExtendedWidth,
  ]);
}

class PopupMenuThemeData {
  const PopupMenuThemeData({
    this.color,
    this.shape,
    this.menuPadding,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.textStyle,
    this.labelTextStyle,
    this.enableFeedback,
    this.mouseCursor,
    this.position,
    this.iconColor,
    this.iconSize,
  });
  final Color? color;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? menuPadding;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final TextStyle? textStyle;
  final WidgetStateProperty<TextStyle?>? labelTextStyle;
  final bool? enableFeedback;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final PopupMenuPosition? position;
  final Color? iconColor;
  final double? iconSize;
  PopupMenuThemeData copyWith({
    Color? color,
    ShapeBorder? shape,
    EdgeInsetsGeometry? menuPadding,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    TextStyle? textStyle,
    WidgetStateProperty<TextStyle?>? labelTextStyle,
    bool? enableFeedback,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    PopupMenuPosition? position,
    Color? iconColor,
    double? iconSize,
  }) => PopupMenuThemeData(
    color: color ?? this.color,
    shape: shape ?? this.shape,
    menuPadding: menuPadding ?? this.menuPadding,
    elevation: elevation ?? this.elevation,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    textStyle: textStyle ?? this.textStyle,
    labelTextStyle: labelTextStyle ?? this.labelTextStyle,
    enableFeedback: enableFeedback ?? this.enableFeedback,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    position: position ?? this.position,
    iconColor: iconColor ?? this.iconColor,
    iconSize: iconSize ?? this.iconSize,
  );
  static PopupMenuThemeData lerp(
    PopupMenuThemeData? a,
    PopupMenuThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const PopupMenuThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PopupMenuThemeData &&
          other.color == color &&
          other.shape == shape &&
          other.menuPadding == menuPadding &&
          other.elevation == elevation &&
          other.shadowColor == shadowColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.textStyle == textStyle &&
          other.labelTextStyle == labelTextStyle &&
          other.enableFeedback == enableFeedback &&
          other.mouseCursor == mouseCursor &&
          other.position == position &&
          other.iconColor == iconColor &&
          other.iconSize == iconSize;
  @override
  int get hashCode => Object.hashAll([
    color,
    shape,
    menuPadding,
    elevation,
    shadowColor,
    surfaceTintColor,
    textStyle,
    labelTextStyle,
    enableFeedback,
    mouseCursor,
    position,
    iconColor,
    iconSize,
  ]);
}

class ProgressIndicatorThemeData {
  const ProgressIndicatorThemeData({
    this.color,
    this.linearTrackColor,
    this.linearMinHeight,
    this.circularTrackColor,
    this.refreshBackgroundColor,
    this.borderRadius,
    this.stopIndicatorColor,
    this.stopIndicatorRadius,
    this.strokeWidth,
    this.strokeAlign,
    this.strokeCap,
    this.constraints,
    this.trackGap,
    this.circularTrackPadding,
    this.year2023,
  });
  final Color? color;
  final Color? linearTrackColor;
  final double? linearMinHeight;
  final Color? circularTrackColor;
  final Color? refreshBackgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final Color? stopIndicatorColor;
  final double? stopIndicatorRadius;
  final double? strokeWidth;
  final double? strokeAlign;
  final StrokeCap? strokeCap;
  final BoxConstraints? constraints;
  final double? trackGap;
  final EdgeInsetsGeometry? circularTrackPadding;
  final bool? year2023;
  ProgressIndicatorThemeData copyWith({
    Color? color,
    Color? linearTrackColor,
    double? linearMinHeight,
    Color? circularTrackColor,
    Color? refreshBackgroundColor,
    BorderRadiusGeometry? borderRadius,
    Color? stopIndicatorColor,
    double? stopIndicatorRadius,
    double? strokeWidth,
    double? strokeAlign,
    StrokeCap? strokeCap,
    BoxConstraints? constraints,
    double? trackGap,
    EdgeInsetsGeometry? circularTrackPadding,
    bool? year2023,
  }) => ProgressIndicatorThemeData(
    color: color ?? this.color,
    linearTrackColor: linearTrackColor ?? this.linearTrackColor,
    linearMinHeight: linearMinHeight ?? this.linearMinHeight,
    circularTrackColor: circularTrackColor ?? this.circularTrackColor,
    refreshBackgroundColor:
        refreshBackgroundColor ?? this.refreshBackgroundColor,
    borderRadius: borderRadius ?? this.borderRadius,
    stopIndicatorColor: stopIndicatorColor ?? this.stopIndicatorColor,
    stopIndicatorRadius: stopIndicatorRadius ?? this.stopIndicatorRadius,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    strokeAlign: strokeAlign ?? this.strokeAlign,
    strokeCap: strokeCap ?? this.strokeCap,
    constraints: constraints ?? this.constraints,
    trackGap: trackGap ?? this.trackGap,
    circularTrackPadding: circularTrackPadding ?? this.circularTrackPadding,
    year2023: year2023 ?? this.year2023,
  );
  static ProgressIndicatorThemeData lerp(
    ProgressIndicatorThemeData? a,
    ProgressIndicatorThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const ProgressIndicatorThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressIndicatorThemeData &&
          other.color == color &&
          other.linearTrackColor == linearTrackColor &&
          other.linearMinHeight == linearMinHeight &&
          other.circularTrackColor == circularTrackColor &&
          other.refreshBackgroundColor == refreshBackgroundColor &&
          other.borderRadius == borderRadius &&
          other.stopIndicatorColor == stopIndicatorColor &&
          other.stopIndicatorRadius == stopIndicatorRadius &&
          other.strokeWidth == strokeWidth &&
          other.strokeAlign == strokeAlign &&
          other.strokeCap == strokeCap &&
          other.constraints == constraints &&
          other.trackGap == trackGap &&
          other.circularTrackPadding == circularTrackPadding &&
          other.year2023 == year2023;
  @override
  int get hashCode => Object.hashAll([
    color,
    linearTrackColor,
    linearMinHeight,
    circularTrackColor,
    refreshBackgroundColor,
    borderRadius,
    stopIndicatorColor,
    stopIndicatorRadius,
    strokeWidth,
    strokeAlign,
    strokeCap,
    constraints,
    trackGap,
    circularTrackPadding,
    year2023,
  ]);
}

class RadioThemeData {
  const RadioThemeData({
    this.mouseCursor,
    this.fillColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
  });
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final WidgetStateProperty<Color?>? fillColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;
  RadioThemeData copyWith({
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
  }) => RadioThemeData(
    mouseCursor: mouseCursor ?? this.mouseCursor,
    fillColor: fillColor ?? this.fillColor,
    overlayColor: overlayColor ?? this.overlayColor,
    splashRadius: splashRadius ?? this.splashRadius,
    materialTapTargetSize: materialTapTargetSize ?? this.materialTapTargetSize,
    visualDensity: visualDensity ?? this.visualDensity,
  );
  static RadioThemeData lerp(RadioThemeData? a, RadioThemeData? b, double t) =>
      (t < 0.5 ? a : b) ?? const RadioThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadioThemeData &&
          other.mouseCursor == mouseCursor &&
          other.fillColor == fillColor &&
          other.overlayColor == overlayColor &&
          other.splashRadius == splashRadius &&
          other.materialTapTargetSize == materialTapTargetSize &&
          other.visualDensity == visualDensity;
  @override
  int get hashCode => Object.hashAll([
    mouseCursor,
    fillColor,
    overlayColor,
    splashRadius,
    materialTapTargetSize,
    visualDensity,
  ]);
}

class ScrollbarThemeData {
  const ScrollbarThemeData({
    this.thumbVisibility,
    this.thickness,
    this.trackVisibility,
    this.radius,
    this.thumbColor,
    this.trackColor,
    this.trackBorderColor,
    this.crossAxisMargin,
    this.mainAxisMargin,
    this.minThumbLength,
    this.interactive,
  });
  final WidgetStateProperty<bool?>? thumbVisibility;
  final WidgetStateProperty<double?>? thickness;
  final WidgetStateProperty<bool?>? trackVisibility;
  final Radius? radius;
  final WidgetStateProperty<Color?>? thumbColor;
  final WidgetStateProperty<Color?>? trackColor;
  final WidgetStateProperty<Color?>? trackBorderColor;
  final double? crossAxisMargin;
  final double? mainAxisMargin;
  final double? minThumbLength;
  final bool? interactive;
  ScrollbarThemeData copyWith({
    WidgetStateProperty<bool?>? thumbVisibility,
    WidgetStateProperty<double?>? thickness,
    WidgetStateProperty<bool?>? trackVisibility,
    Radius? radius,
    WidgetStateProperty<Color?>? thumbColor,
    WidgetStateProperty<Color?>? trackColor,
    WidgetStateProperty<Color?>? trackBorderColor,
    double? crossAxisMargin,
    double? mainAxisMargin,
    double? minThumbLength,
    bool? interactive,
  }) => ScrollbarThemeData(
    thumbVisibility: thumbVisibility ?? this.thumbVisibility,
    thickness: thickness ?? this.thickness,
    trackVisibility: trackVisibility ?? this.trackVisibility,
    radius: radius ?? this.radius,
    thumbColor: thumbColor ?? this.thumbColor,
    trackColor: trackColor ?? this.trackColor,
    trackBorderColor: trackBorderColor ?? this.trackBorderColor,
    crossAxisMargin: crossAxisMargin ?? this.crossAxisMargin,
    mainAxisMargin: mainAxisMargin ?? this.mainAxisMargin,
    minThumbLength: minThumbLength ?? this.minThumbLength,
    interactive: interactive ?? this.interactive,
  );
  static ScrollbarThemeData lerp(
    ScrollbarThemeData? a,
    ScrollbarThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const ScrollbarThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollbarThemeData &&
          other.thumbVisibility == thumbVisibility &&
          other.thickness == thickness &&
          other.trackVisibility == trackVisibility &&
          other.radius == radius &&
          other.thumbColor == thumbColor &&
          other.trackColor == trackColor &&
          other.trackBorderColor == trackBorderColor &&
          other.crossAxisMargin == crossAxisMargin &&
          other.mainAxisMargin == mainAxisMargin &&
          other.minThumbLength == minThumbLength &&
          other.interactive == interactive;
  @override
  int get hashCode => Object.hashAll([
    thumbVisibility,
    thickness,
    trackVisibility,
    radius,
    thumbColor,
    trackColor,
    trackBorderColor,
    crossAxisMargin,
    mainAxisMargin,
    minThumbLength,
    interactive,
  ]);
}

class SearchBarThemeData {
  const SearchBarThemeData({
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
    this.constraints,
    this.textCapitalization,
  });
  final WidgetStateProperty<double?>? elevation;
  final WidgetStateProperty<Color?>? backgroundColor;
  final WidgetStateProperty<Color?>? shadowColor;
  final WidgetStateProperty<Color?>? surfaceTintColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final WidgetStateProperty<BorderSide?>? side;
  final WidgetStateProperty<OutlinedBorder?>? shape;
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;
  final WidgetStateProperty<TextStyle?>? textStyle;
  final WidgetStateProperty<TextStyle?>? hintStyle;
  final BoxConstraints? constraints;
  final TextCapitalization? textCapitalization;
  SearchBarThemeData copyWith({
    WidgetStateProperty<double?>? elevation,
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? shadowColor,
    WidgetStateProperty<Color?>? surfaceTintColor,
    WidgetStateProperty<Color?>? overlayColor,
    WidgetStateProperty<BorderSide?>? side,
    WidgetStateProperty<OutlinedBorder?>? shape,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<TextStyle?>? hintStyle,
    BoxConstraints? constraints,
    TextCapitalization? textCapitalization,
  }) => SearchBarThemeData(
    elevation: elevation ?? this.elevation,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    overlayColor: overlayColor ?? this.overlayColor,
    side: side ?? this.side,
    shape: shape ?? this.shape,
    padding: padding ?? this.padding,
    textStyle: textStyle ?? this.textStyle,
    hintStyle: hintStyle ?? this.hintStyle,
    constraints: constraints ?? this.constraints,
    textCapitalization: textCapitalization ?? this.textCapitalization,
  );
  static SearchBarThemeData lerp(
    SearchBarThemeData? a,
    SearchBarThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const SearchBarThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchBarThemeData &&
          other.elevation == elevation &&
          other.backgroundColor == backgroundColor &&
          other.shadowColor == shadowColor &&
          other.surfaceTintColor == surfaceTintColor &&
          other.overlayColor == overlayColor &&
          other.side == side &&
          other.shape == shape &&
          other.padding == padding &&
          other.textStyle == textStyle &&
          other.hintStyle == hintStyle &&
          other.constraints == constraints &&
          other.textCapitalization == textCapitalization;
  @override
  int get hashCode => Object.hashAll([
    elevation,
    backgroundColor,
    shadowColor,
    surfaceTintColor,
    overlayColor,
    side,
    shape,
    padding,
    textStyle,
    hintStyle,
    constraints,
    textCapitalization,
  ]);
}

class SearchViewThemeData {
  const SearchViewThemeData({
    this.backgroundColor,
    this.elevation,
    this.surfaceTintColor,
    this.constraints,
    this.padding,
    this.barPadding,
    this.shrinkWrap,
    this.shape,
    this.headerTextStyle,
    this.headerHintStyle,
    this.dividerColor,
  });
  final Color? backgroundColor;
  final double? elevation;
  final Color? surfaceTintColor;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final double? barPadding;
  final bool? shrinkWrap;
  final OutlinedBorder? shape;
  final TextStyle? headerTextStyle;
  final TextStyle? headerHintStyle;
  final Color? dividerColor;
  SearchViewThemeData copyWith({
    Color? backgroundColor,
    double? elevation,
    Color? surfaceTintColor,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? padding,
    double? barPadding,
    bool? shrinkWrap,
    OutlinedBorder? shape,
    TextStyle? headerTextStyle,
    TextStyle? headerHintStyle,
    Color? dividerColor,
  }) => SearchViewThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    elevation: elevation ?? this.elevation,
    surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
    constraints: constraints ?? this.constraints,
    padding: padding ?? this.padding,
    barPadding: barPadding ?? this.barPadding,
    shrinkWrap: shrinkWrap ?? this.shrinkWrap,
    shape: shape ?? this.shape,
    headerTextStyle: headerTextStyle ?? this.headerTextStyle,
    headerHintStyle: headerHintStyle ?? this.headerHintStyle,
    dividerColor: dividerColor ?? this.dividerColor,
  );
  static SearchViewThemeData lerp(
    SearchViewThemeData? a,
    SearchViewThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const SearchViewThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchViewThemeData &&
          other.backgroundColor == backgroundColor &&
          other.elevation == elevation &&
          other.surfaceTintColor == surfaceTintColor &&
          other.constraints == constraints &&
          other.padding == padding &&
          other.barPadding == barPadding &&
          other.shrinkWrap == shrinkWrap &&
          other.shape == shape &&
          other.headerTextStyle == headerTextStyle &&
          other.headerHintStyle == headerHintStyle &&
          other.dividerColor == dividerColor;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    elevation,
    surfaceTintColor,
    constraints,
    padding,
    barPadding,
    shrinkWrap,
    shape,
    headerTextStyle,
    headerHintStyle,
    dividerColor,
  ]);
}

class SegmentedButtonThemeData {
  const SegmentedButtonThemeData({this.style, this.selectedIcon});
  final ButtonStyle? style;
  final Widget? selectedIcon;
  SegmentedButtonThemeData copyWith({
    ButtonStyle? style,
    Widget? selectedIcon,
  }) => SegmentedButtonThemeData(
    style: style ?? this.style,
    selectedIcon: selectedIcon ?? this.selectedIcon,
  );
  static SegmentedButtonThemeData lerp(
    SegmentedButtonThemeData? a,
    SegmentedButtonThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const SegmentedButtonThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentedButtonThemeData &&
          other.style == style &&
          other.selectedIcon == selectedIcon;
  @override
  int get hashCode => Object.hashAll([style, selectedIcon]);
}

class SliderThemeData {
  const SliderThemeData({
    this.trackHeight,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.secondaryActiveTrackColor,
    this.disabledActiveTrackColor,
    this.disabledInactiveTrackColor,
    this.disabledSecondaryActiveTrackColor,
    this.activeTickMarkColor,
    this.inactiveTickMarkColor,
    this.disabledActiveTickMarkColor,
    this.disabledInactiveTickMarkColor,
    this.thumbColor,
    this.overlappingShapeStrokeColor,
    this.disabledThumbColor,
    this.overlayColor,
    this.valueIndicatorColor,
    this.valueIndicatorStrokeColor,
    this.overlayShape,
    this.tickMarkShape,
    this.thumbShape,
    this.trackShape,
    this.valueIndicatorShape,
    this.rangeTickMarkShape,
    this.rangeThumbShape,
    this.rangeTrackShape,
    this.rangeValueIndicatorShape,
    this.showValueIndicator,
    this.valueIndicatorTextStyle,
    this.minThumbSeparation,
    this.mouseCursor,
    this.allowedInteraction,
    this.padding,
    this.thumbSize,
    this.trackGap,
    this.year2023,
  });
  final double? trackHeight;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? secondaryActiveTrackColor;
  final Color? disabledActiveTrackColor;
  final Color? disabledInactiveTrackColor;
  final Color? disabledSecondaryActiveTrackColor;
  final Color? activeTickMarkColor;
  final Color? inactiveTickMarkColor;
  final Color? disabledActiveTickMarkColor;
  final Color? disabledInactiveTickMarkColor;
  final Color? thumbColor;
  final Color? overlappingShapeStrokeColor;
  final Color? disabledThumbColor;
  final Color? overlayColor;
  final Color? valueIndicatorColor;
  final Color? valueIndicatorStrokeColor;
  final SliderComponentShape? overlayShape;
  final SliderTickMarkShape? tickMarkShape;
  final SliderComponentShape? thumbShape;
  final SliderTrackShape? trackShape;
  final SliderComponentShape? valueIndicatorShape;
  final RangeSliderTickMarkShape? rangeTickMarkShape;
  final RangeSliderThumbShape? rangeThumbShape;
  final RangeSliderTrackShape? rangeTrackShape;
  final RangeSliderValueIndicatorShape? rangeValueIndicatorShape;
  final ShowValueIndicator? showValueIndicator;
  final TextStyle? valueIndicatorTextStyle;
  final double? minThumbSeparation;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final SliderInteraction? allowedInteraction;
  final EdgeInsetsGeometry? padding;
  final WidgetStateProperty<Size?>? thumbSize;
  final double? trackGap;
  final bool? year2023;

  /// Flutter's primary-color defaults, reduced to the colors this runtime
  /// paints.
  factory SliderThemeData.fromPrimaryColors({
    required Color primaryColor,
    required Color primaryColorDark,
    required Color primaryColorLight,
    required TextStyle valueIndicatorTextStyle,
  }) => SliderThemeData(
    trackHeight: 2,
    activeTrackColor: primaryColor,
    inactiveTrackColor: primaryColor.withValues(alpha: 0.24),
    thumbColor: primaryColor,
    overlayColor: primaryColor.withValues(alpha: 0.12),
    valueIndicatorColor: primaryColor,
    valueIndicatorTextStyle: valueIndicatorTextStyle,
  );
  SliderThemeData copyWith({
    double? trackHeight,
    Color? activeTrackColor,
    Color? inactiveTrackColor,
    Color? secondaryActiveTrackColor,
    Color? disabledActiveTrackColor,
    Color? disabledInactiveTrackColor,
    Color? disabledSecondaryActiveTrackColor,
    Color? activeTickMarkColor,
    Color? inactiveTickMarkColor,
    Color? disabledActiveTickMarkColor,
    Color? disabledInactiveTickMarkColor,
    Color? thumbColor,
    Color? overlappingShapeStrokeColor,
    Color? disabledThumbColor,
    Color? overlayColor,
    Color? valueIndicatorColor,
    Color? valueIndicatorStrokeColor,
    SliderComponentShape? overlayShape,
    SliderTickMarkShape? tickMarkShape,
    SliderComponentShape? thumbShape,
    SliderTrackShape? trackShape,
    SliderComponentShape? valueIndicatorShape,
    RangeSliderTickMarkShape? rangeTickMarkShape,
    RangeSliderThumbShape? rangeThumbShape,
    RangeSliderTrackShape? rangeTrackShape,
    RangeSliderValueIndicatorShape? rangeValueIndicatorShape,
    ShowValueIndicator? showValueIndicator,
    TextStyle? valueIndicatorTextStyle,
    double? minThumbSeparation,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    SliderInteraction? allowedInteraction,
    EdgeInsetsGeometry? padding,
    WidgetStateProperty<Size?>? thumbSize,
    double? trackGap,
    bool? year2023,
  }) => SliderThemeData(
    trackHeight: trackHeight ?? this.trackHeight,
    activeTrackColor: activeTrackColor ?? this.activeTrackColor,
    inactiveTrackColor: inactiveTrackColor ?? this.inactiveTrackColor,
    secondaryActiveTrackColor:
        secondaryActiveTrackColor ?? this.secondaryActiveTrackColor,
    disabledActiveTrackColor:
        disabledActiveTrackColor ?? this.disabledActiveTrackColor,
    disabledInactiveTrackColor:
        disabledInactiveTrackColor ?? this.disabledInactiveTrackColor,
    disabledSecondaryActiveTrackColor:
        disabledSecondaryActiveTrackColor ??
        this.disabledSecondaryActiveTrackColor,
    activeTickMarkColor: activeTickMarkColor ?? this.activeTickMarkColor,
    inactiveTickMarkColor: inactiveTickMarkColor ?? this.inactiveTickMarkColor,
    disabledActiveTickMarkColor:
        disabledActiveTickMarkColor ?? this.disabledActiveTickMarkColor,
    disabledInactiveTickMarkColor:
        disabledInactiveTickMarkColor ?? this.disabledInactiveTickMarkColor,
    thumbColor: thumbColor ?? this.thumbColor,
    overlappingShapeStrokeColor:
        overlappingShapeStrokeColor ?? this.overlappingShapeStrokeColor,
    disabledThumbColor: disabledThumbColor ?? this.disabledThumbColor,
    overlayColor: overlayColor ?? this.overlayColor,
    valueIndicatorColor: valueIndicatorColor ?? this.valueIndicatorColor,
    valueIndicatorStrokeColor:
        valueIndicatorStrokeColor ?? this.valueIndicatorStrokeColor,
    overlayShape: overlayShape ?? this.overlayShape,
    tickMarkShape: tickMarkShape ?? this.tickMarkShape,
    thumbShape: thumbShape ?? this.thumbShape,
    trackShape: trackShape ?? this.trackShape,
    valueIndicatorShape: valueIndicatorShape ?? this.valueIndicatorShape,
    rangeTickMarkShape: rangeTickMarkShape ?? this.rangeTickMarkShape,
    rangeThumbShape: rangeThumbShape ?? this.rangeThumbShape,
    rangeTrackShape: rangeTrackShape ?? this.rangeTrackShape,
    rangeValueIndicatorShape:
        rangeValueIndicatorShape ?? this.rangeValueIndicatorShape,
    showValueIndicator: showValueIndicator ?? this.showValueIndicator,
    valueIndicatorTextStyle:
        valueIndicatorTextStyle ?? this.valueIndicatorTextStyle,
    minThumbSeparation: minThumbSeparation ?? this.minThumbSeparation,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    allowedInteraction: allowedInteraction ?? this.allowedInteraction,
    padding: padding ?? this.padding,
    thumbSize: thumbSize ?? this.thumbSize,
    trackGap: trackGap ?? this.trackGap,
    year2023: year2023 ?? this.year2023,
  );
  static SliderThemeData lerp(
    SliderThemeData? a,
    SliderThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const SliderThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SliderThemeData &&
          other.trackHeight == trackHeight &&
          other.activeTrackColor == activeTrackColor &&
          other.inactiveTrackColor == inactiveTrackColor &&
          other.secondaryActiveTrackColor == secondaryActiveTrackColor &&
          other.disabledActiveTrackColor == disabledActiveTrackColor &&
          other.disabledInactiveTrackColor == disabledInactiveTrackColor &&
          other.disabledSecondaryActiveTrackColor ==
              disabledSecondaryActiveTrackColor &&
          other.activeTickMarkColor == activeTickMarkColor &&
          other.inactiveTickMarkColor == inactiveTickMarkColor &&
          other.disabledActiveTickMarkColor == disabledActiveTickMarkColor &&
          other.disabledInactiveTickMarkColor ==
              disabledInactiveTickMarkColor &&
          other.thumbColor == thumbColor &&
          other.overlappingShapeStrokeColor == overlappingShapeStrokeColor &&
          other.disabledThumbColor == disabledThumbColor &&
          other.overlayColor == overlayColor &&
          other.valueIndicatorColor == valueIndicatorColor &&
          other.valueIndicatorStrokeColor == valueIndicatorStrokeColor &&
          other.overlayShape == overlayShape &&
          other.tickMarkShape == tickMarkShape &&
          other.thumbShape == thumbShape &&
          other.trackShape == trackShape &&
          other.valueIndicatorShape == valueIndicatorShape &&
          other.rangeTickMarkShape == rangeTickMarkShape &&
          other.rangeThumbShape == rangeThumbShape &&
          other.rangeTrackShape == rangeTrackShape &&
          other.rangeValueIndicatorShape == rangeValueIndicatorShape &&
          other.showValueIndicator == showValueIndicator &&
          other.valueIndicatorTextStyle == valueIndicatorTextStyle &&
          other.minThumbSeparation == minThumbSeparation &&
          other.mouseCursor == mouseCursor &&
          other.allowedInteraction == allowedInteraction &&
          other.padding == padding &&
          other.thumbSize == thumbSize &&
          other.trackGap == trackGap &&
          other.year2023 == year2023;
  @override
  int get hashCode => Object.hashAll([
    trackHeight,
    activeTrackColor,
    inactiveTrackColor,
    secondaryActiveTrackColor,
    disabledActiveTrackColor,
    disabledInactiveTrackColor,
    disabledSecondaryActiveTrackColor,
    activeTickMarkColor,
    inactiveTickMarkColor,
    disabledActiveTickMarkColor,
    disabledInactiveTickMarkColor,
    thumbColor,
    overlappingShapeStrokeColor,
    disabledThumbColor,
    overlayColor,
    valueIndicatorColor,
    valueIndicatorStrokeColor,
    overlayShape,
    tickMarkShape,
    thumbShape,
    trackShape,
    valueIndicatorShape,
    rangeTickMarkShape,
    rangeThumbShape,
    rangeTrackShape,
    rangeValueIndicatorShape,
    showValueIndicator,
    valueIndicatorTextStyle,
    minThumbSeparation,
    mouseCursor,
    allowedInteraction,
    padding,
    thumbSize,
    trackGap,
    year2023,
  ]);
}

class SnackBarThemeData {
  const SnackBarThemeData({
    this.backgroundColor,
    this.actionTextColor,
    this.disabledActionTextColor,
    this.contentTextStyle,
    this.elevation,
    this.shape,
    this.behavior,
    this.width,
    this.insetPadding,
    this.showCloseIcon,
    this.closeIconColor,
    this.actionOverflowThreshold,
    this.actionBackgroundColor,
    this.disabledActionBackgroundColor,
    this.dismissDirection,
  });
  final Color? backgroundColor;
  final Color? actionTextColor;
  final Color? disabledActionTextColor;
  final TextStyle? contentTextStyle;
  final double? elevation;
  final ShapeBorder? shape;
  final SnackBarBehavior? behavior;
  final double? width;
  final EdgeInsets? insetPadding;
  final bool? showCloseIcon;
  final Color? closeIconColor;
  final double? actionOverflowThreshold;
  final Color? actionBackgroundColor;
  final Color? disabledActionBackgroundColor;
  final DismissDirection? dismissDirection;
  SnackBarThemeData copyWith({
    Color? backgroundColor,
    Color? actionTextColor,
    Color? disabledActionTextColor,
    TextStyle? contentTextStyle,
    double? elevation,
    ShapeBorder? shape,
    SnackBarBehavior? behavior,
    double? width,
    EdgeInsets? insetPadding,
    bool? showCloseIcon,
    Color? closeIconColor,
    double? actionOverflowThreshold,
    Color? actionBackgroundColor,
    Color? disabledActionBackgroundColor,
    DismissDirection? dismissDirection,
  }) => SnackBarThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    actionTextColor: actionTextColor ?? this.actionTextColor,
    disabledActionTextColor:
        disabledActionTextColor ?? this.disabledActionTextColor,
    contentTextStyle: contentTextStyle ?? this.contentTextStyle,
    elevation: elevation ?? this.elevation,
    shape: shape ?? this.shape,
    behavior: behavior ?? this.behavior,
    width: width ?? this.width,
    insetPadding: insetPadding ?? this.insetPadding,
    showCloseIcon: showCloseIcon ?? this.showCloseIcon,
    closeIconColor: closeIconColor ?? this.closeIconColor,
    actionOverflowThreshold:
        actionOverflowThreshold ?? this.actionOverflowThreshold,
    actionBackgroundColor: actionBackgroundColor ?? this.actionBackgroundColor,
    disabledActionBackgroundColor:
        disabledActionBackgroundColor ?? this.disabledActionBackgroundColor,
    dismissDirection: dismissDirection ?? this.dismissDirection,
  );
  static SnackBarThemeData lerp(
    SnackBarThemeData? a,
    SnackBarThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const SnackBarThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SnackBarThemeData &&
          other.backgroundColor == backgroundColor &&
          other.actionTextColor == actionTextColor &&
          other.disabledActionTextColor == disabledActionTextColor &&
          other.contentTextStyle == contentTextStyle &&
          other.elevation == elevation &&
          other.shape == shape &&
          other.behavior == behavior &&
          other.width == width &&
          other.insetPadding == insetPadding &&
          other.showCloseIcon == showCloseIcon &&
          other.closeIconColor == closeIconColor &&
          other.actionOverflowThreshold == actionOverflowThreshold &&
          other.actionBackgroundColor == actionBackgroundColor &&
          other.disabledActionBackgroundColor ==
              disabledActionBackgroundColor &&
          other.dismissDirection == dismissDirection;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    actionTextColor,
    disabledActionTextColor,
    contentTextStyle,
    elevation,
    shape,
    behavior,
    width,
    insetPadding,
    showCloseIcon,
    closeIconColor,
    actionOverflowThreshold,
    actionBackgroundColor,
    disabledActionBackgroundColor,
    dismissDirection,
  ]);
}

class SwitchThemeData {
  const SwitchThemeData({
    this.thumbColor,
    this.trackColor,
    this.trackOutlineColor,
    this.trackOutlineWidth,
    this.materialTapTargetSize,
    this.mouseCursor,
    this.overlayColor,
    this.splashRadius,
    this.thumbIcon,
    this.padding,
  });
  final WidgetStateProperty<Color?>? thumbColor;
  final WidgetStateProperty<Color?>? trackColor;
  final WidgetStateProperty<Color?>? trackOutlineColor;
  final WidgetStateProperty<double?>? trackOutlineWidth;
  final MaterialTapTargetSize? materialTapTargetSize;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final WidgetStateProperty<Icon?>? thumbIcon;
  final EdgeInsetsGeometry? padding;
  SwitchThemeData copyWith({
    WidgetStateProperty<Color?>? thumbColor,
    WidgetStateProperty<Color?>? trackColor,
    WidgetStateProperty<Color?>? trackOutlineColor,
    WidgetStateProperty<double?>? trackOutlineWidth,
    MaterialTapTargetSize? materialTapTargetSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    WidgetStateProperty<Color?>? overlayColor,
    double? splashRadius,
    WidgetStateProperty<Icon?>? thumbIcon,
    EdgeInsetsGeometry? padding,
  }) => SwitchThemeData(
    thumbColor: thumbColor ?? this.thumbColor,
    trackColor: trackColor ?? this.trackColor,
    trackOutlineColor: trackOutlineColor ?? this.trackOutlineColor,
    trackOutlineWidth: trackOutlineWidth ?? this.trackOutlineWidth,
    materialTapTargetSize: materialTapTargetSize ?? this.materialTapTargetSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    overlayColor: overlayColor ?? this.overlayColor,
    splashRadius: splashRadius ?? this.splashRadius,
    thumbIcon: thumbIcon ?? this.thumbIcon,
    padding: padding ?? this.padding,
  );
  static SwitchThemeData lerp(
    SwitchThemeData? a,
    SwitchThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const SwitchThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwitchThemeData &&
          other.thumbColor == thumbColor &&
          other.trackColor == trackColor &&
          other.trackOutlineColor == trackOutlineColor &&
          other.trackOutlineWidth == trackOutlineWidth &&
          other.materialTapTargetSize == materialTapTargetSize &&
          other.mouseCursor == mouseCursor &&
          other.overlayColor == overlayColor &&
          other.splashRadius == splashRadius &&
          other.thumbIcon == thumbIcon &&
          other.padding == padding;
  @override
  int get hashCode => Object.hashAll([
    thumbColor,
    trackColor,
    trackOutlineColor,
    trackOutlineWidth,
    materialTapTargetSize,
    mouseCursor,
    overlayColor,
    splashRadius,
    thumbIcon,
    padding,
  ]);
}

class TabBarThemeData {
  const TabBarThemeData({
    this.indicator,
    this.indicatorColor,
    this.indicatorSize,
    this.dividerColor,
    this.dividerHeight,
    this.labelColor,
    this.labelPadding,
    this.labelStyle,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.overlayColor,
    this.splashFactory,
    this.mouseCursor,
    this.tabAlignment,
    this.textScaler,
    this.indicatorAnimation,
    this.splashBorderRadius,
  });
  final Decoration? indicator;
  final Color? indicatorColor;
  final TabBarIndicatorSize? indicatorSize;
  final Color? dividerColor;
  final double? dividerHeight;
  final Color? labelColor;
  final EdgeInsetsGeometry? labelPadding;
  final TextStyle? labelStyle;
  final Color? unselectedLabelColor;
  final TextStyle? unselectedLabelStyle;
  final WidgetStateProperty<Color?>? overlayColor;
  final InteractiveInkFeatureFactory? splashFactory;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final TabAlignment? tabAlignment;
  final TextScaler? textScaler;
  final TabIndicatorAnimation? indicatorAnimation;
  final BorderRadius? splashBorderRadius;
  TabBarThemeData copyWith({
    Decoration? indicator,
    Color? indicatorColor,
    TabBarIndicatorSize? indicatorSize,
    Color? dividerColor,
    double? dividerHeight,
    Color? labelColor,
    EdgeInsetsGeometry? labelPadding,
    TextStyle? labelStyle,
    Color? unselectedLabelColor,
    TextStyle? unselectedLabelStyle,
    WidgetStateProperty<Color?>? overlayColor,
    InteractiveInkFeatureFactory? splashFactory,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    TabAlignment? tabAlignment,
    TextScaler? textScaler,
    TabIndicatorAnimation? indicatorAnimation,
    BorderRadius? splashBorderRadius,
  }) => TabBarThemeData(
    indicator: indicator ?? this.indicator,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    indicatorSize: indicatorSize ?? this.indicatorSize,
    dividerColor: dividerColor ?? this.dividerColor,
    dividerHeight: dividerHeight ?? this.dividerHeight,
    labelColor: labelColor ?? this.labelColor,
    labelPadding: labelPadding ?? this.labelPadding,
    labelStyle: labelStyle ?? this.labelStyle,
    unselectedLabelColor: unselectedLabelColor ?? this.unselectedLabelColor,
    unselectedLabelStyle: unselectedLabelStyle ?? this.unselectedLabelStyle,
    overlayColor: overlayColor ?? this.overlayColor,
    splashFactory: splashFactory ?? this.splashFactory,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    tabAlignment: tabAlignment ?? this.tabAlignment,
    textScaler: textScaler ?? this.textScaler,
    indicatorAnimation: indicatorAnimation ?? this.indicatorAnimation,
    splashBorderRadius: splashBorderRadius ?? this.splashBorderRadius,
  );
  static TabBarThemeData lerp(
    TabBarThemeData? a,
    TabBarThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const TabBarThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TabBarThemeData &&
          other.indicator == indicator &&
          other.indicatorColor == indicatorColor &&
          other.indicatorSize == indicatorSize &&
          other.dividerColor == dividerColor &&
          other.dividerHeight == dividerHeight &&
          other.labelColor == labelColor &&
          other.labelPadding == labelPadding &&
          other.labelStyle == labelStyle &&
          other.unselectedLabelColor == unselectedLabelColor &&
          other.unselectedLabelStyle == unselectedLabelStyle &&
          other.overlayColor == overlayColor &&
          other.splashFactory == splashFactory &&
          other.mouseCursor == mouseCursor &&
          other.tabAlignment == tabAlignment &&
          other.textScaler == textScaler &&
          other.indicatorAnimation == indicatorAnimation &&
          other.splashBorderRadius == splashBorderRadius;
  @override
  int get hashCode => Object.hashAll([
    indicator,
    indicatorColor,
    indicatorSize,
    dividerColor,
    dividerHeight,
    labelColor,
    labelPadding,
    labelStyle,
    unselectedLabelColor,
    unselectedLabelStyle,
    overlayColor,
    splashFactory,
    mouseCursor,
    tabAlignment,
    textScaler,
    indicatorAnimation,
    splashBorderRadius,
  ]);
}

class TextSelectionThemeData {
  const TextSelectionThemeData({
    this.cursorColor,
    this.selectionColor,
    this.selectionHandleColor,
  });
  final Color? cursorColor;
  final Color? selectionColor;
  final Color? selectionHandleColor;
  TextSelectionThemeData copyWith({
    Color? cursorColor,
    Color? selectionColor,
    Color? selectionHandleColor,
  }) => TextSelectionThemeData(
    cursorColor: cursorColor ?? this.cursorColor,
    selectionColor: selectionColor ?? this.selectionColor,
    selectionHandleColor: selectionHandleColor ?? this.selectionHandleColor,
  );
  static TextSelectionThemeData lerp(
    TextSelectionThemeData? a,
    TextSelectionThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const TextSelectionThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSelectionThemeData &&
          other.cursorColor == cursorColor &&
          other.selectionColor == selectionColor &&
          other.selectionHandleColor == selectionHandleColor;
  @override
  int get hashCode =>
      Object.hashAll([cursorColor, selectionColor, selectionHandleColor]);
}

class TimePickerThemeData {
  const TimePickerThemeData({
    this.backgroundColor,
    this.cancelButtonStyle,
    this.confirmButtonStyle,
    this.dayPeriodBorderSide,
    this.dayPeriodColor,
    this.dayPeriodShape,
    this.dayPeriodTextColor,
    this.dayPeriodTextStyle,
    this.dialBackgroundColor,
    this.dialHandColor,
    this.dialTextColor,
    this.dialTextStyle,
    this.elevation,
    this.entryModeIconColor,
    this.helpTextStyle,
    this.hourMinuteColor,
    this.hourMinuteShape,
    this.hourMinuteTextColor,
    this.hourMinuteTextStyle,
    this.inputDecorationTheme,
    this.padding,
    this.shape,
    this.timeSelectorSeparatorColor,
    this.timeSelectorSeparatorTextStyle,
  });
  final Color? backgroundColor;
  final ButtonStyle? cancelButtonStyle;
  final ButtonStyle? confirmButtonStyle;
  final BorderSide? dayPeriodBorderSide;
  final Color? dayPeriodColor;
  final OutlinedBorder? dayPeriodShape;
  final Color? dayPeriodTextColor;
  final TextStyle? dayPeriodTextStyle;
  final Color? dialBackgroundColor;
  final Color? dialHandColor;
  final Color? dialTextColor;
  final TextStyle? dialTextStyle;
  final double? elevation;
  final Color? entryModeIconColor;
  final TextStyle? helpTextStyle;
  final Color? hourMinuteColor;
  final ShapeBorder? hourMinuteShape;
  final Color? hourMinuteTextColor;
  final TextStyle? hourMinuteTextStyle;
  final InputDecorationTheme? inputDecorationTheme;
  final EdgeInsetsGeometry? padding;
  final ShapeBorder? shape;
  final WidgetStateProperty<Color?>? timeSelectorSeparatorColor;
  final WidgetStateProperty<TextStyle?>? timeSelectorSeparatorTextStyle;
  TimePickerThemeData copyWith({
    Color? backgroundColor,
    ButtonStyle? cancelButtonStyle,
    ButtonStyle? confirmButtonStyle,
    BorderSide? dayPeriodBorderSide,
    Color? dayPeriodColor,
    OutlinedBorder? dayPeriodShape,
    Color? dayPeriodTextColor,
    TextStyle? dayPeriodTextStyle,
    Color? dialBackgroundColor,
    Color? dialHandColor,
    Color? dialTextColor,
    TextStyle? dialTextStyle,
    double? elevation,
    Color? entryModeIconColor,
    TextStyle? helpTextStyle,
    Color? hourMinuteColor,
    ShapeBorder? hourMinuteShape,
    Color? hourMinuteTextColor,
    TextStyle? hourMinuteTextStyle,
    InputDecorationTheme? inputDecorationTheme,
    EdgeInsetsGeometry? padding,
    ShapeBorder? shape,
    WidgetStateProperty<Color?>? timeSelectorSeparatorColor,
    WidgetStateProperty<TextStyle?>? timeSelectorSeparatorTextStyle,
  }) => TimePickerThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    cancelButtonStyle: cancelButtonStyle ?? this.cancelButtonStyle,
    confirmButtonStyle: confirmButtonStyle ?? this.confirmButtonStyle,
    dayPeriodBorderSide: dayPeriodBorderSide ?? this.dayPeriodBorderSide,
    dayPeriodColor: dayPeriodColor ?? this.dayPeriodColor,
    dayPeriodShape: dayPeriodShape ?? this.dayPeriodShape,
    dayPeriodTextColor: dayPeriodTextColor ?? this.dayPeriodTextColor,
    dayPeriodTextStyle: dayPeriodTextStyle ?? this.dayPeriodTextStyle,
    dialBackgroundColor: dialBackgroundColor ?? this.dialBackgroundColor,
    dialHandColor: dialHandColor ?? this.dialHandColor,
    dialTextColor: dialTextColor ?? this.dialTextColor,
    dialTextStyle: dialTextStyle ?? this.dialTextStyle,
    elevation: elevation ?? this.elevation,
    entryModeIconColor: entryModeIconColor ?? this.entryModeIconColor,
    helpTextStyle: helpTextStyle ?? this.helpTextStyle,
    hourMinuteColor: hourMinuteColor ?? this.hourMinuteColor,
    hourMinuteShape: hourMinuteShape ?? this.hourMinuteShape,
    hourMinuteTextColor: hourMinuteTextColor ?? this.hourMinuteTextColor,
    hourMinuteTextStyle: hourMinuteTextStyle ?? this.hourMinuteTextStyle,
    inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
    padding: padding ?? this.padding,
    shape: shape ?? this.shape,
    timeSelectorSeparatorColor:
        timeSelectorSeparatorColor ?? this.timeSelectorSeparatorColor,
    timeSelectorSeparatorTextStyle:
        timeSelectorSeparatorTextStyle ?? this.timeSelectorSeparatorTextStyle,
  );
  static TimePickerThemeData lerp(
    TimePickerThemeData? a,
    TimePickerThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const TimePickerThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimePickerThemeData &&
          other.backgroundColor == backgroundColor &&
          other.cancelButtonStyle == cancelButtonStyle &&
          other.confirmButtonStyle == confirmButtonStyle &&
          other.dayPeriodBorderSide == dayPeriodBorderSide &&
          other.dayPeriodColor == dayPeriodColor &&
          other.dayPeriodShape == dayPeriodShape &&
          other.dayPeriodTextColor == dayPeriodTextColor &&
          other.dayPeriodTextStyle == dayPeriodTextStyle &&
          other.dialBackgroundColor == dialBackgroundColor &&
          other.dialHandColor == dialHandColor &&
          other.dialTextColor == dialTextColor &&
          other.dialTextStyle == dialTextStyle &&
          other.elevation == elevation &&
          other.entryModeIconColor == entryModeIconColor &&
          other.helpTextStyle == helpTextStyle &&
          other.hourMinuteColor == hourMinuteColor &&
          other.hourMinuteShape == hourMinuteShape &&
          other.hourMinuteTextColor == hourMinuteTextColor &&
          other.hourMinuteTextStyle == hourMinuteTextStyle &&
          other.inputDecorationTheme == inputDecorationTheme &&
          other.padding == padding &&
          other.shape == shape &&
          other.timeSelectorSeparatorColor == timeSelectorSeparatorColor &&
          other.timeSelectorSeparatorTextStyle ==
              timeSelectorSeparatorTextStyle;
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    cancelButtonStyle,
    confirmButtonStyle,
    dayPeriodBorderSide,
    dayPeriodColor,
    dayPeriodShape,
    dayPeriodTextColor,
    dayPeriodTextStyle,
    dialBackgroundColor,
    dialHandColor,
    dialTextColor,
    dialTextStyle,
    elevation,
    entryModeIconColor,
    helpTextStyle,
    hourMinuteColor,
    hourMinuteShape,
    hourMinuteTextColor,
    hourMinuteTextStyle,
    inputDecorationTheme,
    padding,
    shape,
    timeSelectorSeparatorColor,
    timeSelectorSeparatorTextStyle,
  ]);
}

class ToggleButtonsThemeData {
  const ToggleButtonsThemeData({
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
    this.borderColor,
    this.selectedBorderColor,
    this.disabledBorderColor,
    this.borderRadius,
    this.borderWidth,
  });
  final TextStyle? textStyle;
  final BoxConstraints? constraints;
  final Color? color;
  final Color? selectedColor;
  final Color? disabledColor;
  final Color? fillColor;
  final Color? focusColor;
  final Color? highlightColor;
  final Color? hoverColor;
  final Color? splashColor;
  final Color? borderColor;
  final Color? selectedBorderColor;
  final Color? disabledBorderColor;
  final BorderRadius? borderRadius;
  final double? borderWidth;
  ToggleButtonsThemeData copyWith({
    TextStyle? textStyle,
    BoxConstraints? constraints,
    Color? color,
    Color? selectedColor,
    Color? disabledColor,
    Color? fillColor,
    Color? focusColor,
    Color? highlightColor,
    Color? hoverColor,
    Color? splashColor,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? disabledBorderColor,
    BorderRadius? borderRadius,
    double? borderWidth,
  }) => ToggleButtonsThemeData(
    textStyle: textStyle ?? this.textStyle,
    constraints: constraints ?? this.constraints,
    color: color ?? this.color,
    selectedColor: selectedColor ?? this.selectedColor,
    disabledColor: disabledColor ?? this.disabledColor,
    fillColor: fillColor ?? this.fillColor,
    focusColor: focusColor ?? this.focusColor,
    highlightColor: highlightColor ?? this.highlightColor,
    hoverColor: hoverColor ?? this.hoverColor,
    splashColor: splashColor ?? this.splashColor,
    borderColor: borderColor ?? this.borderColor,
    selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
    disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
    borderRadius: borderRadius ?? this.borderRadius,
    borderWidth: borderWidth ?? this.borderWidth,
  );
  static ToggleButtonsThemeData lerp(
    ToggleButtonsThemeData? a,
    ToggleButtonsThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const ToggleButtonsThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToggleButtonsThemeData &&
          other.textStyle == textStyle &&
          other.constraints == constraints &&
          other.color == color &&
          other.selectedColor == selectedColor &&
          other.disabledColor == disabledColor &&
          other.fillColor == fillColor &&
          other.focusColor == focusColor &&
          other.highlightColor == highlightColor &&
          other.hoverColor == hoverColor &&
          other.splashColor == splashColor &&
          other.borderColor == borderColor &&
          other.selectedBorderColor == selectedBorderColor &&
          other.disabledBorderColor == disabledBorderColor &&
          other.borderRadius == borderRadius &&
          other.borderWidth == borderWidth;
  @override
  int get hashCode => Object.hashAll([
    textStyle,
    constraints,
    color,
    selectedColor,
    disabledColor,
    fillColor,
    focusColor,
    highlightColor,
    hoverColor,
    splashColor,
    borderColor,
    selectedBorderColor,
    disabledBorderColor,
    borderRadius,
    borderWidth,
  ]);
}

class TooltipThemeData {
  const TooltipThemeData({
    this.height,
    this.constraints,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.preferBelow,
    this.excludeFromSemantics,
    this.decoration,
    this.textStyle,
    this.textAlign,
    this.waitDuration,
    this.showDuration,
    this.exitDuration,
    this.triggerMode,
    this.enableFeedback,
  });
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? verticalOffset;
  final bool? preferBelow;
  final bool? excludeFromSemantics;
  final Decoration? decoration;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final Duration? waitDuration;
  final Duration? showDuration;
  final Duration? exitDuration;
  final TooltipTriggerMode? triggerMode;
  final bool? enableFeedback;
  TooltipThemeData copyWith({
    double? height,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? verticalOffset,
    bool? preferBelow,
    bool? excludeFromSemantics,
    Decoration? decoration,
    TextStyle? textStyle,
    TextAlign? textAlign,
    Duration? waitDuration,
    Duration? showDuration,
    Duration? exitDuration,
    TooltipTriggerMode? triggerMode,
    bool? enableFeedback,
  }) => TooltipThemeData(
    height: height ?? this.height,
    constraints: constraints ?? this.constraints,
    padding: padding ?? this.padding,
    margin: margin ?? this.margin,
    verticalOffset: verticalOffset ?? this.verticalOffset,
    preferBelow: preferBelow ?? this.preferBelow,
    excludeFromSemantics: excludeFromSemantics ?? this.excludeFromSemantics,
    decoration: decoration ?? this.decoration,
    textStyle: textStyle ?? this.textStyle,
    textAlign: textAlign ?? this.textAlign,
    waitDuration: waitDuration ?? this.waitDuration,
    showDuration: showDuration ?? this.showDuration,
    exitDuration: exitDuration ?? this.exitDuration,
    triggerMode: triggerMode ?? this.triggerMode,
    enableFeedback: enableFeedback ?? this.enableFeedback,
  );
  static TooltipThemeData lerp(
    TooltipThemeData? a,
    TooltipThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const TooltipThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TooltipThemeData &&
          other.height == height &&
          other.constraints == constraints &&
          other.padding == padding &&
          other.margin == margin &&
          other.verticalOffset == verticalOffset &&
          other.preferBelow == preferBelow &&
          other.excludeFromSemantics == excludeFromSemantics &&
          other.decoration == decoration &&
          other.textStyle == textStyle &&
          other.textAlign == textAlign &&
          other.waitDuration == waitDuration &&
          other.showDuration == showDuration &&
          other.exitDuration == exitDuration &&
          other.triggerMode == triggerMode &&
          other.enableFeedback == enableFeedback;
  @override
  int get hashCode => Object.hashAll([
    height,
    constraints,
    padding,
    margin,
    verticalOffset,
    preferBelow,
    excludeFromSemantics,
    decoration,
    textStyle,
    textAlign,
    waitDuration,
    showDuration,
    exitDuration,
    triggerMode,
    enableFeedback,
  ]);
}

class ActionIconThemeData {
  const ActionIconThemeData({
    this.backButtonIconBuilder,
    this.closeButtonIconBuilder,
    this.drawerButtonIconBuilder,
    this.endDrawerButtonIconBuilder,
  });
  final WidgetBuilder? backButtonIconBuilder;
  final WidgetBuilder? closeButtonIconBuilder;
  final WidgetBuilder? drawerButtonIconBuilder;
  final WidgetBuilder? endDrawerButtonIconBuilder;
  ActionIconThemeData copyWith({
    WidgetBuilder? backButtonIconBuilder,
    WidgetBuilder? closeButtonIconBuilder,
    WidgetBuilder? drawerButtonIconBuilder,
    WidgetBuilder? endDrawerButtonIconBuilder,
  }) => ActionIconThemeData(
    backButtonIconBuilder: backButtonIconBuilder ?? this.backButtonIconBuilder,
    closeButtonIconBuilder:
        closeButtonIconBuilder ?? this.closeButtonIconBuilder,
    drawerButtonIconBuilder:
        drawerButtonIconBuilder ?? this.drawerButtonIconBuilder,
    endDrawerButtonIconBuilder:
        endDrawerButtonIconBuilder ?? this.endDrawerButtonIconBuilder,
  );
  static ActionIconThemeData lerp(
    ActionIconThemeData? a,
    ActionIconThemeData? b,
    double t,
  ) => (t < 0.5 ? a : b) ?? const ActionIconThemeData();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionIconThemeData &&
          other.backButtonIconBuilder == backButtonIconBuilder &&
          other.closeButtonIconBuilder == closeButtonIconBuilder &&
          other.drawerButtonIconBuilder == drawerButtonIconBuilder &&
          other.endDrawerButtonIconBuilder == endDrawerButtonIconBuilder;
  @override
  int get hashCode => Object.hashAll([
    backButtonIconBuilder,
    closeButtonIconBuilder,
    drawerButtonIconBuilder,
    endDrawerButtonIconBuilder,
  ]);
}

// Inherited component themes. `of` falls back to the enclosing ThemeData.

class ElevatedButtonTheme extends InheritedTheme {
  const ElevatedButtonTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final ElevatedButtonThemeData data;
  static ElevatedButtonThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ElevatedButtonTheme>()?.data ??
      Theme.of(context).elevatedButtonTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      ElevatedButtonTheme(data: data, child: child);
  @override
  bool updateShouldNotify(ElevatedButtonTheme oldWidget) =>
      data != oldWidget.data;
}

class FilledButtonTheme extends InheritedTheme {
  const FilledButtonTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final FilledButtonThemeData data;
  static FilledButtonThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FilledButtonTheme>()?.data ??
      Theme.of(context).filledButtonTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      FilledButtonTheme(data: data, child: child);
  @override
  bool updateShouldNotify(FilledButtonTheme oldWidget) =>
      data != oldWidget.data;
}

class OutlinedButtonTheme extends InheritedTheme {
  const OutlinedButtonTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final OutlinedButtonThemeData data;
  static OutlinedButtonThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OutlinedButtonTheme>()?.data ??
      Theme.of(context).outlinedButtonTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      OutlinedButtonTheme(data: data, child: child);
  @override
  bool updateShouldNotify(OutlinedButtonTheme oldWidget) =>
      data != oldWidget.data;
}

class TextButtonTheme extends InheritedTheme {
  const TextButtonTheme({super.key, required this.data, required super.child});
  final TextButtonThemeData data;
  static TextButtonThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TextButtonTheme>()?.data ??
      Theme.of(context).textButtonTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      TextButtonTheme(data: data, child: child);
  @override
  bool updateShouldNotify(TextButtonTheme oldWidget) => data != oldWidget.data;
}

class IconButtonTheme extends InheritedTheme {
  const IconButtonTheme({super.key, required this.data, required super.child});
  final IconButtonThemeData data;
  static IconButtonThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IconButtonTheme>()?.data ??
      Theme.of(context).iconButtonTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      IconButtonTheme(data: data, child: child);
  @override
  bool updateShouldNotify(IconButtonTheme oldWidget) => data != oldWidget.data;
}

class MenuButtonTheme extends InheritedTheme {
  const MenuButtonTheme({super.key, required this.data, required super.child});
  final MenuButtonThemeData data;
  static MenuButtonThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MenuButtonTheme>()?.data ??
      Theme.of(context).menuButtonTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      MenuButtonTheme(data: data, child: child);
  @override
  bool updateShouldNotify(MenuButtonTheme oldWidget) => data != oldWidget.data;
}

class ChipTheme extends InheritedTheme {
  const ChipTheme({super.key, required this.data, required super.child});
  final ChipThemeData data;
  static ChipThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChipTheme>()?.data ??
      Theme.of(context).chipTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      ChipTheme(data: data, child: child);
  @override
  bool updateShouldNotify(ChipTheme oldWidget) => data != oldWidget.data;
}

class DividerTheme extends InheritedTheme {
  const DividerTheme({super.key, required this.data, required super.child});
  final DividerThemeData data;
  static DividerThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DividerTheme>()?.data ??
      Theme.of(context).dividerTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      DividerTheme(data: data, child: child);
  @override
  bool updateShouldNotify(DividerTheme oldWidget) => data != oldWidget.data;
}

class SliderTheme extends InheritedTheme {
  const SliderTheme({super.key, required this.data, required super.child});
  final SliderThemeData data;
  static SliderThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SliderTheme>()?.data ??
      Theme.of(context).sliderTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      SliderTheme(data: data, child: child);
  @override
  bool updateShouldNotify(SliderTheme oldWidget) => data != oldWidget.data;
}

class CheckboxTheme extends InheritedTheme {
  const CheckboxTheme({super.key, required this.data, required super.child});
  final CheckboxThemeData data;
  static CheckboxThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CheckboxTheme>()?.data ??
      Theme.of(context).checkboxTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      CheckboxTheme(data: data, child: child);
  @override
  bool updateShouldNotify(CheckboxTheme oldWidget) => data != oldWidget.data;
}

class RadioTheme extends InheritedTheme {
  const RadioTheme({super.key, required this.data, required super.child});
  final RadioThemeData data;
  static RadioThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RadioTheme>()?.data ??
      Theme.of(context).radioTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      RadioTheme(data: data, child: child);
  @override
  bool updateShouldNotify(RadioTheme oldWidget) => data != oldWidget.data;
}

class SwitchTheme extends InheritedTheme {
  const SwitchTheme({super.key, required this.data, required super.child});
  final SwitchThemeData data;
  static SwitchThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SwitchTheme>()?.data ??
      Theme.of(context).switchTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      SwitchTheme(data: data, child: child);
  @override
  bool updateShouldNotify(SwitchTheme oldWidget) => data != oldWidget.data;
}

class PopupMenuTheme extends InheritedTheme {
  const PopupMenuTheme({super.key, required this.data, required super.child});
  final PopupMenuThemeData data;
  static PopupMenuThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PopupMenuTheme>()?.data ??
      Theme.of(context).popupMenuTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      PopupMenuTheme(data: data, child: child);
  @override
  bool updateShouldNotify(PopupMenuTheme oldWidget) => data != oldWidget.data;
}

class ProgressIndicatorTheme extends InheritedTheme {
  const ProgressIndicatorTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final ProgressIndicatorThemeData data;
  static ProgressIndicatorThemeData of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ProgressIndicatorTheme>()
          ?.data ??
      Theme.of(context).progressIndicatorTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      ProgressIndicatorTheme(data: data, child: child);
  @override
  bool updateShouldNotify(ProgressIndicatorTheme oldWidget) =>
      data != oldWidget.data;
}

class TooltipTheme extends InheritedTheme {
  const TooltipTheme({super.key, required this.data, required super.child});
  final TooltipThemeData data;
  static TooltipThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TooltipTheme>()?.data ??
      Theme.of(context).tooltipTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      TooltipTheme(data: data, child: child);
  @override
  bool updateShouldNotify(TooltipTheme oldWidget) => data != oldWidget.data;
}

class NavigationBarTheme extends InheritedTheme {
  const NavigationBarTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final NavigationBarThemeData data;
  static NavigationBarThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavigationBarTheme>()?.data ??
      Theme.of(context).navigationBarTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      NavigationBarTheme(data: data, child: child);
  @override
  bool updateShouldNotify(NavigationBarTheme oldWidget) =>
      data != oldWidget.data;
}

class NavigationDrawerTheme extends InheritedTheme {
  const NavigationDrawerTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final NavigationDrawerThemeData data;
  static NavigationDrawerThemeData of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<NavigationDrawerTheme>()
          ?.data ??
      Theme.of(context).navigationDrawerTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      NavigationDrawerTheme(data: data, child: child);
  @override
  bool updateShouldNotify(NavigationDrawerTheme oldWidget) =>
      data != oldWidget.data;
}

class NavigationRailTheme extends InheritedTheme {
  const NavigationRailTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final NavigationRailThemeData data;
  static NavigationRailThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavigationRailTheme>()?.data ??
      Theme.of(context).navigationRailTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      NavigationRailTheme(data: data, child: child);
  @override
  bool updateShouldNotify(NavigationRailTheme oldWidget) =>
      data != oldWidget.data;
}

class BottomNavigationBarTheme extends InheritedTheme {
  const BottomNavigationBarTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final BottomNavigationBarThemeData data;
  static BottomNavigationBarThemeData of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BottomNavigationBarTheme>()
          ?.data ??
      Theme.of(context).bottomNavigationBarTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      BottomNavigationBarTheme(data: data, child: child);
  @override
  bool updateShouldNotify(BottomNavigationBarTheme oldWidget) =>
      data != oldWidget.data;
}

class DrawerTheme extends InheritedTheme {
  const DrawerTheme({super.key, required this.data, required super.child});
  final DrawerThemeData data;
  static DrawerThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DrawerTheme>()?.data ??
      Theme.of(context).drawerTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      DrawerTheme(data: data, child: child);
  @override
  bool updateShouldNotify(DrawerTheme oldWidget) => data != oldWidget.data;
}

class ExpansionTileTheme extends InheritedTheme {
  const ExpansionTileTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final ExpansionTileThemeData data;
  static ExpansionTileThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExpansionTileTheme>()?.data ??
      Theme.of(context).expansionTileTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      ExpansionTileTheme(data: data, child: child);
  @override
  bool updateShouldNotify(ExpansionTileTheme oldWidget) =>
      data != oldWidget.data;
}

class DataTableTheme extends InheritedTheme {
  const DataTableTheme({super.key, required this.data, required super.child});
  final DataTableThemeData data;
  static DataTableThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DataTableTheme>()?.data ??
      Theme.of(context).dataTableTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      DataTableTheme(data: data, child: child);
  @override
  bool updateShouldNotify(DataTableTheme oldWidget) => data != oldWidget.data;
}

class BadgeTheme extends InheritedTheme {
  const BadgeTheme({super.key, required this.data, required super.child});
  final BadgeThemeData data;
  static BadgeThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BadgeTheme>()?.data ??
      Theme.of(context).badgeTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      BadgeTheme(data: data, child: child);
  @override
  bool updateShouldNotify(BadgeTheme oldWidget) => data != oldWidget.data;
}

class SegmentedButtonTheme extends InheritedTheme {
  const SegmentedButtonTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final SegmentedButtonThemeData data;
  static SegmentedButtonThemeData of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SegmentedButtonTheme>()
          ?.data ??
      Theme.of(context).segmentedButtonTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      SegmentedButtonTheme(data: data, child: child);
  @override
  bool updateShouldNotify(SegmentedButtonTheme oldWidget) =>
      data != oldWidget.data;
}

class SearchBarTheme extends InheritedTheme {
  const SearchBarTheme({super.key, required this.data, required super.child});
  final SearchBarThemeData data;
  static SearchBarThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SearchBarTheme>()?.data ??
      Theme.of(context).searchBarTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      SearchBarTheme(data: data, child: child);
  @override
  bool updateShouldNotify(SearchBarTheme oldWidget) => data != oldWidget.data;
}

class SearchViewTheme extends InheritedTheme {
  const SearchViewTheme({super.key, required this.data, required super.child});
  final SearchViewThemeData data;
  static SearchViewThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SearchViewTheme>()?.data ??
      Theme.of(context).searchViewTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      SearchViewTheme(data: data, child: child);
  @override
  bool updateShouldNotify(SearchViewTheme oldWidget) => data != oldWidget.data;
}

class MenuTheme extends InheritedTheme {
  const MenuTheme({super.key, required this.data, required super.child});
  final MenuThemeData data;
  static MenuThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MenuTheme>()?.data ??
      Theme.of(context).menuTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      MenuTheme(data: data, child: child);
  @override
  bool updateShouldNotify(MenuTheme oldWidget) => data != oldWidget.data;
}

class MenuBarTheme extends InheritedTheme {
  const MenuBarTheme({super.key, required this.data, required super.child});
  final MenuBarThemeData data;
  static MenuBarThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MenuBarTheme>()?.data ??
      Theme.of(context).menuBarTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      MenuBarTheme(data: data, child: child);
  @override
  bool updateShouldNotify(MenuBarTheme oldWidget) => data != oldWidget.data;
}

class DropdownMenuTheme extends InheritedTheme {
  const DropdownMenuTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final DropdownMenuThemeData data;
  static DropdownMenuThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DropdownMenuTheme>()?.data ??
      Theme.of(context).dropdownMenuTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      DropdownMenuTheme(data: data, child: child);
  @override
  bool updateShouldNotify(DropdownMenuTheme oldWidget) =>
      data != oldWidget.data;
}

class TimePickerTheme extends InheritedTheme {
  const TimePickerTheme({super.key, required this.data, required super.child});
  final TimePickerThemeData data;
  static TimePickerThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TimePickerTheme>()?.data ??
      Theme.of(context).timePickerTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      TimePickerTheme(data: data, child: child);
  @override
  bool updateShouldNotify(TimePickerTheme oldWidget) => data != oldWidget.data;
}

class DatePickerTheme extends InheritedTheme {
  const DatePickerTheme({super.key, required this.data, required super.child});
  final DatePickerThemeData data;
  static DatePickerThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DatePickerTheme>()?.data ??
      Theme.of(context).datePickerTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      DatePickerTheme(data: data, child: child);
  @override
  bool updateShouldNotify(DatePickerTheme oldWidget) => data != oldWidget.data;
}

class ToggleButtonsTheme extends InheritedTheme {
  const ToggleButtonsTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final ToggleButtonsThemeData data;
  static ToggleButtonsThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ToggleButtonsTheme>()?.data ??
      Theme.of(context).toggleButtonsTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      ToggleButtonsTheme(data: data, child: child);
  @override
  bool updateShouldNotify(ToggleButtonsTheme oldWidget) =>
      data != oldWidget.data;
}

class TextSelectionTheme extends InheritedTheme {
  const TextSelectionTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final TextSelectionThemeData data;
  static TextSelectionThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TextSelectionTheme>()?.data ??
      Theme.of(context).textSelectionTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      TextSelectionTheme(data: data, child: child);
  @override
  bool updateShouldNotify(TextSelectionTheme oldWidget) =>
      data != oldWidget.data;
}

class ScrollbarTheme extends InheritedTheme {
  const ScrollbarTheme({super.key, required this.data, required super.child});
  final ScrollbarThemeData data;
  static ScrollbarThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ScrollbarTheme>()?.data ??
      Theme.of(context).scrollbarTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      ScrollbarTheme(data: data, child: child);
  @override
  bool updateShouldNotify(ScrollbarTheme oldWidget) => data != oldWidget.data;
}

class MaterialBannerTheme extends InheritedTheme {
  const MaterialBannerTheme({
    super.key,
    required this.data,
    required super.child,
  });
  final MaterialBannerThemeData data;
  static MaterialBannerThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MaterialBannerTheme>()?.data ??
      Theme.of(context).bannerTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      MaterialBannerTheme(data: data, child: child);
  @override
  bool updateShouldNotify(MaterialBannerTheme oldWidget) =>
      data != oldWidget.data;
}

class ActionIconTheme extends InheritedTheme {
  const ActionIconTheme({super.key, required this.data, required super.child});
  final ActionIconThemeData data;
  static ActionIconThemeData? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActionIconTheme>()?.data ??
      Theme.of(context).actionIconTheme;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      ActionIconTheme(data: data, child: child);
  @override
  bool updateShouldNotify(ActionIconTheme oldWidget) => data != oldWidget.data;
}

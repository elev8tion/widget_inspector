import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Layout properties extracted from RenderObject
/// Based on Flutter DevTools inspector_data_models.dart
class LayoutProperties {
  final Size size;
  final BoxConstraints? constraints;
  final double? flexFactor;
  final FlexFit? flexFit;
  final bool isOverflowWidth;
  final bool isOverflowHeight;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Alignment? alignment;

  const LayoutProperties({
    required this.size,
    this.constraints,
    this.flexFactor,
    this.flexFit,
    this.isOverflowWidth = false,
    this.isOverflowHeight = false,
    this.padding,
    this.margin,
    this.alignment,
  });

  bool get hasOverflow => isOverflowWidth || isOverflowHeight;

  Map<String, dynamic> toJson() => {
    'width': size.width,
    'height': size.height,
    if (constraints != null) 'constraints': {
      'minWidth': constraints!.minWidth,
      'maxWidth': constraints!.maxWidth,
      'minHeight': constraints!.minHeight,
      'maxHeight': constraints!.maxHeight,
    },
    if (flexFactor != null) 'flexFactor': flexFactor,
    if (flexFit != null) 'flexFit': flexFit.toString(),
    if (hasOverflow) 'overflow': {
      'width': isOverflowWidth,
      'height': isOverflowHeight,
    },
    if (padding != null) 'padding': padding.toString(),
    if (margin != null) 'margin': margin.toString(),
    if (alignment != null) 'alignment': alignment.toString(),
  };
}

/// Enhanced hit test processor that uses specificity scoring to find
/// the most precise widget at a click point.
class EnhancedHitTestProcessor {
  /// Corner zone size constraints
  static const double _minCornerZone = 12.0;
  static const double _maxCornerZone = 24.0;

  // Singleton pattern
  static final EnhancedHitTestProcessor _instance = EnhancedHitTestProcessor._internal();
  static EnhancedHitTestProcessor get instance => _instance;
  EnhancedHitTestProcessor._internal();

  /// Internal Flutter widgets to skip (not user-facing)
  static const Set<String> _internalWidgets = {
    'Semantics', 'MergeSemantics', 'BlockSemantics', 'ExcludeSemantics',
    'Actions', 'Focus', 'FocusScope', 'FocusTrap', 'FocusTraversalGroup',
    'Shortcuts', 'PrimaryScrollController', 'ScrollConfiguration',
    'NotificationListener', 'RepaintBoundary', 'IgnorePointer',
    'AbsorbPointer', 'MetaData', 'KeyedSubtree', 'Offstage', 'TickerMode',
    'MediaQuery', 'DefaultTextStyle', 'DefaultTextHeightBehavior',
    'IconTheme', 'AnimatedBuilder', 'ListenableBuilder',
    'ValueListenableBuilder', 'StreamBuilder', 'FutureBuilder',
    'Builder', 'StatefulBuilder', 'LayoutBuilder', 'OrientationBuilder',
    'CustomPaint', 'RawGestureDetector', 'Listener', 'MouseRegion',
    '_FocusMarker', '_EffectiveTickerMode', '_InheritedTheme',
    '_LocalizationsScope',
  };

  /// User-facing widgets that should be prioritized
  static const Set<String> _userFacingWidgets = {
    'Text', 'RichText', 'Icon', 'Image', 'Container', 'DecoratedBox',
    'Card', 'ListTile', 'AppBar', 'Scaffold', 'FloatingActionButton',
    'ElevatedButton', 'TextButton', 'OutlinedButton', 'IconButton',
    'TextField', 'TextFormField', 'Checkbox', 'Radio', 'Switch',
    'Slider', 'DropdownButton', 'PopupMenuButton', 'Chip', 'Avatar',
    'CircleAvatar', 'Badge', 'Tooltip', 'SnackBar', 'Dialog',
    'AlertDialog', 'BottomSheet', 'Drawer', 'NavigationBar',
    'NavigationRail', 'TabBar', 'Tab', 'DataTable', 'PaginatedDataTable',
    'GridView', 'ListView', 'SingleChildScrollView', 'CustomScrollView',
    'SizedBox', 'Padding', 'Center', 'Align', 'Expanded', 'Flexible',
    'Spacer', 'Row', 'Column', 'Stack', 'Positioned', 'Wrap', 'Flow',
  };

  /// Find the most specific widget at the given click point
  WidgetMatch? findMostSpecificWidget(
    BoxHitTestResult result,
    Offset globalClickPoint,
  ) {
    final candidates = <_WidgetCandidate>[];

    for (final entry in result.path) {
      if (entry.target is! RenderBox) continue;
      final box = entry.target as RenderBox;

      final creator = box.debugCreator;
      if (creator is! DebugCreator) continue;

      final element = creator.element;
      final widget = element.widget;
      final widgetType = widget.runtimeType.toString();

      if (_isInternalWidget(widgetType)) continue;

      final score = _calculateSpecificityScore(box, globalClickPoint, widgetType);

      candidates.add(_WidgetCandidate(
        renderBox: box,
        element: element,
        widget: widget,
        widgetType: widgetType,
        score: score,
      ));
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.score.compareTo(a.score));

    final best = candidates.first;
    return _createWidgetMatch(best, globalClickPoint);
  }

  /// Find widget with corner-aware selection
  WidgetMatch? findWidgetWithCornerAwareness(
    BoxHitTestResult result,
    Offset globalClickPoint, {
    bool debugOutput = false,
  }) {
    final candidates = <_WidgetCandidate>[];

    for (final entry in result.path) {
      if (entry.target is! RenderBox) continue;
      final box = entry.target as RenderBox;

      final creator = box.debugCreator;
      if (creator is! DebugCreator) continue;

      final element = creator.element;
      final widget = element.widget;
      final widgetType = widget.runtimeType.toString();

      if (_isInternalWidget(widgetType)) continue;

      final score = _calculateSpecificityScore(box, globalClickPoint, widgetType);

      candidates.add(_WidgetCandidate(
        renderBox: box,
        element: element,
        widget: widget,
        widgetType: widgetType,
        score: score,
      ));
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.score.compareTo(a.score));

    final best = candidates.first;
    final cornerZone = _detectCornerZone(best.renderBox, globalClickPoint);

    if (cornerZone != CornerZone.center && candidates.length > 1) {
      final parent = candidates[1];
      final match = _createWidgetMatch(parent, globalClickPoint);
      return match.copyWith(cornerZone: cornerZone, isCornerSelected: true);
    }

    return _createWidgetMatch(best, globalClickPoint).copyWith(cornerZone: cornerZone);
  }

  double _getCornerZoneSize(Size size) {
    final smallestDim = size.width < size.height ? size.width : size.height;
    final proportional = smallestDim * 0.15;
    return proportional.clamp(_minCornerZone, _maxCornerZone);
  }

  CornerZone _detectCornerZone(RenderBox box, Offset globalClickPoint) {
    final localClick = box.globalToLocal(globalClickPoint);
    final size = box.size;
    final zoneSize = _getCornerZoneSize(size);

    final isNearLeft = localClick.dx < zoneSize;
    final isNearRight = localClick.dx > size.width - zoneSize;
    final isNearTop = localClick.dy < zoneSize;
    final isNearBottom = localClick.dy > size.height - zoneSize;

    if (isNearTop && isNearLeft) return CornerZone.topLeft;
    if (isNearTop && isNearRight) return CornerZone.topRight;
    if (isNearBottom && isNearLeft) return CornerZone.bottomLeft;
    if (isNearBottom && isNearRight) return CornerZone.bottomRight;

    return CornerZone.center;
  }

  /// Extract layout properties from a RenderBox
  LayoutProperties extractLayoutProperties(RenderBox box) {
    final size = box.size;

    BoxConstraints? constraints;
    try {
      constraints = box.constraints;
    } catch (_) {}

    double? flexFactor;
    FlexFit? flexFit;
    try {
      final parentData = box.parentData;
      if (parentData is FlexParentData) {
        flexFactor = parentData.flex?.toDouble();
        flexFit = parentData.fit;
      }
    } catch (_) {}

    bool isOverflowWidth = false;
    bool isOverflowHeight = false;
    if (constraints != null) {
      isOverflowWidth = size.width > constraints.maxWidth;
      isOverflowHeight = size.height > constraints.maxHeight;
    }

    EdgeInsets? padding;
    if (box is RenderPadding) {
      padding = box.padding.resolve(TextDirection.ltr);
    }

    Alignment? alignment;
    if (box is RenderPositionedBox) {
      final align = box.alignment;
      if (align is Alignment) {
        alignment = align;
      }
    }

    return LayoutProperties(
      size: size,
      constraints: constraints,
      flexFactor: flexFactor,
      flexFit: flexFit,
      isOverflowWidth: isOverflowWidth,
      isOverflowHeight: isOverflowHeight,
      padding: padding,
      alignment: alignment,
    );
  }

  double _calculateSpecificityScore(
    RenderBox box,
    Offset globalClickPoint,
    String widgetType,
  ) {
    final size = box.size;

    final area = size.width * size.height;
    final areaScore = area > 0 ? 1.0 / (area + 1) * 10000 : 0.0;

    final localClick = box.globalToLocal(globalClickPoint);
    final center = Offset(size.width / 2, size.height / 2);
    final distanceFromCenter = (localClick - center).distance;
    final maxDistance = (Offset.zero - center).distance;
    final centerScore = maxDistance > 0
        ? 1.0 - (distanceFromCenter / maxDistance).clamp(0.0, 1.0)
        : 1.0;

    final userFacingBonus = _userFacingWidgets.contains(widgetType) ? 0.2 : 0.0;

    final score = (areaScore * 0.5) + (centerScore * 0.3) + userFacingBonus;

    return score;
  }

  bool _isInternalWidget(String widgetType) {
    if (_internalWidgets.contains(widgetType)) return true;
    if (widgetType.startsWith('_')) return true;
    if (widgetType.startsWith('_Render')) return true;
    if (widgetType.startsWith('_Inherited')) return true;
    if (widgetType.startsWith('_Default')) return true;
    return false;
  }

  WidgetMatch _createWidgetMatch(_WidgetCandidate candidate, Offset globalClickPoint) {
    final box = candidate.renderBox;
    final size = box.size;
    final globalOffset = box.localToGlobal(Offset.zero);

    final parentChain = <String>[];
    candidate.element.visitAncestorElements((ancestor) {
      final ancestorType = ancestor.widget.runtimeType.toString();
      if (!_isInternalWidget(ancestorType)) {
        parentChain.add(ancestorType);
      }
      return parentChain.length < 10;
    });

    return WidgetMatch(
      widget: candidate.widget,
      element: candidate.element,
      renderBox: candidate.renderBox,
      widgetType: candidate.widgetType,
      size: size,
      globalOffset: globalOffset,
      specificityScore: candidate.score,
      parentChain: parentChain,
    );
  }

  /// Get all widget candidates at a position (for debugging)
  List<WidgetMatch> getAllCandidates(
    BoxHitTestResult result,
    Offset globalClickPoint,
  ) {
    final candidates = <_WidgetCandidate>[];

    for (final entry in result.path) {
      if (entry.target is! RenderBox) continue;
      final box = entry.target as RenderBox;

      final creator = box.debugCreator;
      if (creator is! DebugCreator) continue;

      final element = creator.element;
      final widget = element.widget;
      final widgetType = widget.runtimeType.toString();

      if (_isInternalWidget(widgetType)) continue;

      final score = _calculateSpecificityScore(box, globalClickPoint, widgetType);

      candidates.add(_WidgetCandidate(
        renderBox: box,
        element: element,
        widget: widget,
        widgetType: widgetType,
        score: score,
      ));
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    return candidates.map((c) => _createWidgetMatch(c, globalClickPoint)).toList();
  }
}

class _WidgetCandidate {
  final RenderBox renderBox;
  final Element element;
  final Widget widget;
  final String widgetType;
  final double score;

  _WidgetCandidate({
    required this.renderBox,
    required this.element,
    required this.widget,
    required this.widgetType,
    required this.score,
  });
}

/// Corner zone indicator for selection behavior
enum CornerZone {
  center,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Result of widget matching with specificity scoring
class WidgetMatch {
  final Widget widget;
  final Element element;
  final RenderBox renderBox;
  final String widgetType;
  final Size size;
  final Offset globalOffset;
  final double specificityScore;
  final List<String> parentChain;
  final CornerZone cornerZone;
  final bool isCornerSelected;
  final LayoutProperties? layoutProperties;

  WidgetMatch({
    required this.widget,
    required this.element,
    required this.renderBox,
    required this.widgetType,
    required this.size,
    required this.globalOffset,
    required this.specificityScore,
    required this.parentChain,
    this.cornerZone = CornerZone.center,
    this.isCornerSelected = false,
    this.layoutProperties,
  });

  Rect get bounds => globalOffset & size;

  WidgetMatch copyWith({
    Widget? widget,
    Element? element,
    RenderBox? renderBox,
    String? widgetType,
    Size? size,
    Offset? globalOffset,
    double? specificityScore,
    List<String>? parentChain,
    CornerZone? cornerZone,
    bool? isCornerSelected,
    LayoutProperties? layoutProperties,
  }) {
    return WidgetMatch(
      widget: widget ?? this.widget,
      element: element ?? this.element,
      renderBox: renderBox ?? this.renderBox,
      widgetType: widgetType ?? this.widgetType,
      size: size ?? this.size,
      globalOffset: globalOffset ?? this.globalOffset,
      specificityScore: specificityScore ?? this.specificityScore,
      parentChain: parentChain ?? this.parentChain,
      cornerZone: cornerZone ?? this.cornerZone,
      isCornerSelected: isCornerSelected ?? this.isCornerSelected,
      layoutProperties: layoutProperties ?? this.layoutProperties,
    );
  }

  @override
  String toString() {
    final cornerInfo = isCornerSelected ? ' [corner→parent]' : '';
    return 'WidgetMatch($widgetType, score: ${specificityScore.toStringAsFixed(3)}, '
           'size: ${size.width.toInt()}x${size.height.toInt()}$cornerInfo)';
  }
}

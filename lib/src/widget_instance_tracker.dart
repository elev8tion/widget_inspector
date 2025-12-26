import 'package:flutter/widgets.dart';

/// Tracks widget instances to differentiate between multiple widgets
/// of the same type (e.g., two Container widgets in a Column).
///
/// Generates unique IDs that combine widget type, hash, and sibling index.
class WidgetInstanceTracker {
  // Singleton pattern
  static final WidgetInstanceTracker _instance = WidgetInstanceTracker._internal();
  static WidgetInstanceTracker get instance => _instance;
  WidgetInstanceTracker._internal();

  /// Map of widget type -> List of tracked instances
  final Map<String, List<_WidgetInstance>> _instances = {};

  /// Counter for generating sequential IDs
  int _idCounter = 0;

  /// Register a widget instance for tracking
  void registerInstance(String widgetType, Element element, Rect bounds) {
    _instances.putIfAbsent(widgetType, () => []);
    _instances[widgetType]!.add(_WidgetInstance(
      element: element,
      bounds: bounds,
      registrationOrder: _idCounter++,
    ));
  }

  /// Register all visible widgets from an element tree
  void registerFromElement(Element rootElement) {
    clear();
    _visitElement(rootElement);
  }

  void _visitElement(Element element) {
    final widget = element.widget;
    final widgetType = widget.runtimeType.toString();

    // Get render object bounds if available
    Rect? bounds;
    final renderObject = element.renderObject;
    if (renderObject is RenderBox && renderObject.hasSize) {
      final size = renderObject.size;
      final offset = renderObject.localToGlobal(Offset.zero);
      bounds = offset & size;
    }

    if (bounds != null) {
      registerInstance(widgetType, element, bounds);
    }

    // Visit children
    element.visitChildren((child) {
      _visitElement(child);
    });
  }

  /// Find index of a specific widget among siblings of same type
  int findSiblingIndex(String widgetType, Element element) {
    final instances = _instances[widgetType];
    if (instances == null) return 0;

    for (int i = 0; i < instances.length; i++) {
      if (instances[i].element == element) return i;
    }
    return 0;
  }

  /// Find sibling index by matching bounds (useful when element reference is lost)
  int findSiblingIndexByBounds(String widgetType, Rect bounds, {double tolerance = 1.0}) {
    final instances = _instances[widgetType];
    if (instances == null) return 0;

    for (int i = 0; i < instances.length; i++) {
      final instanceBounds = instances[i].bounds;
      if (_boundsMatch(instanceBounds, bounds, tolerance)) {
        return i;
      }
    }
    return 0;
  }

  bool _boundsMatch(Rect a, Rect b, double tolerance) {
    return (a.left - b.left).abs() <= tolerance &&
           (a.top - b.top).abs() <= tolerance &&
           (a.width - b.width).abs() <= tolerance &&
           (a.height - b.height).abs() <= tolerance;
  }

  /// Generate a unique ID for a widget instance
  /// Format: WidgetType_hash_siblingIndex
  String generateUniqueId(Widget widget, Element element) {
    final widgetType = widget.runtimeType.toString();
    final hash = widget.hashCode.toRadixString(16).substring(0, 6);
    final siblingIndex = findSiblingIndex(widgetType, element);

    return '${widgetType}_${hash}_$siblingIndex';
  }

  /// Generate unique ID using bounds (when element is available)
  String generateUniqueIdWithBounds(String widgetType, Rect bounds) {
    final hash = bounds.hashCode.toRadixString(16).substring(0, 6);
    final siblingIndex = findSiblingIndexByBounds(widgetType, bounds);

    return '${widgetType}_${hash}_$siblingIndex';
  }

  /// Get count of instances for a widget type
  int getInstanceCount(String widgetType) {
    return _instances[widgetType]?.length ?? 0;
  }

  /// Get all instances of a widget type
  List<WidgetInstanceInfo> getInstances(String widgetType) {
    final instances = _instances[widgetType];
    if (instances == null) return [];

    return instances.asMap().entries.map((entry) {
      final index = entry.key;
      final instance = entry.value;
      return WidgetInstanceInfo(
        widgetType: widgetType,
        siblingIndex: index,
        bounds: instance.bounds,
        uniqueId: '${widgetType}_${instance.element.widget.hashCode.toRadixString(16).substring(0, 6)}_$index',
      );
    }).toList();
  }

  /// Clear all tracked instances (call before each inspection session)
  void clear() {
    _instances.clear();
    _idCounter = 0;
  }

  /// Get total tracked widget count
  int get totalTrackedWidgets {
    return _instances.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Get all tracked widget types
  Set<String> get trackedWidgetTypes => _instances.keys.toSet();
}

/// Internal class for tracking widget instance data
class _WidgetInstance {
  final Element element;
  final Rect bounds;
  final int registrationOrder;

  _WidgetInstance({
    required this.element,
    required this.bounds,
    required this.registrationOrder,
  });
}

/// Public info about a widget instance
class WidgetInstanceInfo {
  final String widgetType;
  final int siblingIndex;
  final Rect bounds;
  final String uniqueId;

  WidgetInstanceInfo({
    required this.widgetType,
    required this.siblingIndex,
    required this.bounds,
    required this.uniqueId,
  });

  @override
  String toString() {
    return 'WidgetInstanceInfo($widgetType #$siblingIndex at ${bounds.topLeft})';
  }
}

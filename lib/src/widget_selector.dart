import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'inspector_service.dart';
import 'inspector_widgets.dart';
import 'models.dart';

/// Holds exact source location for a widget
class WidgetSourceLocation {
  final String file;
  final int line;
  final int? column;

  WidgetSourceLocation({required this.file, required this.line, this.column});

  @override
  String toString() => '$file:$line${column != null ? ':$column' : ''}';

  /// Get just the filename without the full path
  String get shortFile {
    final parts = file.split('/');
    return parts.length > 1 ? parts.sublist(parts.length - 2).join('/') : file;
  }
}

/// Try to extract widget creation location using multiple methods
WidgetSourceLocation? _extractWidgetSourceLocation(Widget widget, Element? element) {
  // Method 1: Try via DiagnosticsNode JSON (works with --track-widget-creation)
  try {
    final node = widget.toDiagnosticsNode();
    final json = node.toJsonMap(const DiagnosticsSerializationDelegate(
      subtreeDepth: 0,
      includeProperties: true,
    ));

    if (json.containsKey('creationLocation')) {
      final loc = json['creationLocation'] as Map<String, dynamic>?;
      if (loc != null) {
        final file = loc['file'] as String?;
        final line = loc['line'] as int?;
        final column = loc['column'] as int?;
        if (file != null && line != null) {
          debugPrint('📍 Found location via JSON: $file:$line');
          return WidgetSourceLocation(file: file, line: line, column: column);
        }
      }
    }

    // Check properties for location info
    final props = node.getProperties();
    for (final prop in props) {
      final name = prop.name?.toLowerCase() ?? '';
      if (name.contains('location') || name.contains('source') || name.contains('file')) {
        final value = prop.value;
        if (value != null) {
          final str = value.toString();
          final match = RegExp(r'([^:]+\.dart):(\d+)(?::(\d+))?').firstMatch(str);
          if (match != null) {
            debugPrint('📍 Found location via property: $str');
            return WidgetSourceLocation(
              file: match.group(1)!,
              line: int.parse(match.group(2)!),
              column: match.group(3) != null ? int.parse(match.group(3)!) : null,
            );
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Method 1 (JSON) failed: $e');
  }

  // Method 2: Try via Element's widget debug info
  if (element != null) {
    try {
      final widgetNode = element.widget.toDiagnosticsNode();
      final desc = widgetNode.toDescription();
      final match = RegExp(r'([^:]+\.dart):(\d+)(?::(\d+))?').firstMatch(desc);
      if (match != null) {
        debugPrint('📍 Found location via description: $desc');
        return WidgetSourceLocation(
          file: match.group(1)!,
          line: int.parse(match.group(2)!),
          column: match.group(3) != null ? int.parse(match.group(3)!) : null,
        );
      }
    } catch (e) {
      debugPrint('Method 2 (description) failed: $e');
    }
  }

  // Method 3: Check if widget has any debug properties with location
  try {
    final props = widget.toDiagnosticsNode().getProperties();
    for (final prop in props) {
      try {
        final propJson = prop.toJsonMap(const DiagnosticsSerializationDelegate());
        if (propJson.containsKey('locationUri') || propJson.containsKey('file')) {
          final file = propJson['locationUri'] ?? propJson['file'];
          final line = propJson['locationLine'] ?? propJson['line'];
          if (file != null && line != null) {
            debugPrint('📍 Found location via prop JSON: $file:$line');
            return WidgetSourceLocation(file: file.toString(), line: line as int);
          }
        }
      } catch (_) {}
    }
  } catch (e) {
    debugPrint('Method 3 (prop JSON) failed: $e');
  }

  // Method 4: Parse from widget's debug representation
  try {
    final widgetString = widget.toString();
    final fileMatch = RegExp(r'(?:file:\/\/\/)?([^:]+\.dart):(\d+)(?::(\d+))?').firstMatch(widgetString);
    if (fileMatch != null) {
      final file = fileMatch.group(1)!;
      final line = int.parse(fileMatch.group(2)!);
      final column = fileMatch.group(3) != null ? int.parse(fileMatch.group(3)!) : null;
      debugPrint('📍 Found location via toString: $file:$line');
      return WidgetSourceLocation(file: file, line: line, column: column);
    }
  } catch (e) {
    debugPrint('Method 4 (toString) failed: $e');
  }

  // Method 5: Try accessing widget's toStringShort or toStringDeep
  if (element != null) {
    try {
      final elementDesc = element.toStringShort();
      final match = RegExp(r'(?:file:\/\/\/)?([^:]+\.dart):(\d+)(?::(\d+))?').firstMatch(elementDesc);
      if (match != null) {
        debugPrint('📍 Found location via element toStringShort: ${match.group(0)}');
        return WidgetSourceLocation(
          file: match.group(1)!,
          line: int.parse(match.group(2)!),
          column: match.group(3) != null ? int.parse(match.group(3)!) : null,
        );
      }
    } catch (e) {
      debugPrint('Method 5 (toStringShort) failed: $e');
    }

    try {
      final deepString = element.toStringDeep();
      final match = RegExp(r'(?:file:\/\/\/)?([^:\s]+\.dart):(\d+)(?::(\d+))?').firstMatch(deepString);
      if (match != null) {
        debugPrint('📍 Found location via toStringDeep: ${match.group(0)}');
        return WidgetSourceLocation(
          file: match.group(1)!,
          line: int.parse(match.group(2)!),
          column: match.group(3) != null ? int.parse(match.group(3)!) : null,
        );
      }
    } catch (e) {
      debugPrint('Method 6 (toStringDeep) failed: $e');
    }
  }

  return null;
}

/// A widget inspector overlay that wraps your app to enable click-to-inspect functionality.
///
/// Usage:
/// ```dart
/// InspectorOverlay(
///   child: MyApp(),
/// )
/// ```
///
/// Then use [InspectorService] to toggle the inspector:
/// ```dart
/// InspectorService().toggle();
/// ```
class InspectorOverlay extends StatefulWidget {
  /// The child widget (usually your app's root)
  final Widget child;

  /// Callback when a widget is selected
  final ValueChanged<WidgetInfo>? onWidgetSelected;

  /// Callback when a note is sent
  final ValueChanged<WidgetNote>? onNoteSent;

  /// Custom location detector (optional)
  final String Function(List<String> hierarchy, Offset position, BuildContext context)? locationDetector;

  /// Custom source file detector (optional)
  final String Function(String location)? sourceFileDetector;

  const InspectorOverlay({
    super.key,
    required this.child,
    this.onWidgetSelected,
    this.onNoteSent,
    this.locationDetector,
    this.sourceFileDetector,
  });

  @override
  State<InspectorOverlay> createState() => _InspectorOverlayState();
}

class _InspectorOverlayState extends State<InspectorOverlay> {
  final _inspector = InspectorService();
  bool _isActive = false;
  WidgetBounds? _selectedWidget;
  WidgetBounds? _hoveredWidget;
  List<WidgetInfo> _widgetPath = [];
  final _noteController = TextEditingController();
  NoteAction _selectedAction = NoteAction.discuss;

  final GlobalKey _childKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _inspector.activeStream.listen((active) {
      if (mounted) {
        setState(() {
          _isActive = active;
          if (!active) {
            _clearSelection();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedWidget = null;
      _hoveredWidget = null;
      _widgetPath = [];
    });
  }

  void _handlePointerHover(Offset localPosition) {
    if (!_isActive) return;

    final RenderBox? childBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (childBox == null) return;

    final widgetBounds = _findWidgetAtPosition(localPosition, childBox);
    if (widgetBounds != null && widgetBounds != _hoveredWidget) {
      setState(() => _hoveredWidget = widgetBounds);
    }
  }

  void _handlePointerDown(Offset localPosition) {
    if (!_isActive) return;

    final RenderBox? childBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (childBox == null) return;

    final widgetBounds = _findWidgetAtPosition(localPosition, childBox);
    if (widgetBounds != null) {
      setState(() {
        _selectedWidget = widgetBounds;
        _hoveredWidget = null;
        _widgetPath = _buildWidgetPath(widgetBounds.info);
      });
      _inspector.selectWidget(widgetBounds.info);
      widget.onWidgetSelected?.call(widgetBounds.info);
    }
  }

  List<WidgetInfo> _buildWidgetPath(WidgetInfo widgetInfo) {
    final path = <WidgetInfo>[];
    for (int i = 0; i < widgetInfo.parentChain.length; i++) {
      path.add(WidgetInfo(
        widgetType: widgetInfo.parentChain[i],
        location: widgetInfo.location,
        sourceFile: widgetInfo.sourceFile,
        size: Size.zero,
        position: Offset.zero,
        parentChain: widgetInfo.parentChain.sublist(0, i),
      ));
    }
    path.add(widgetInfo);
    return path;
  }

  WidgetBounds? _findWidgetAtPosition(Offset position, RenderBox rootBox) {
    final result = BoxHitTestResult();
    rootBox.hitTest(result, position: position);

    RenderObject? bestTarget;
    final List<String> hierarchy = [];
    final pathList = result.path.toList();

    // Build hierarchy from result path
    for (var entry in pathList) {
      if (entry.target is RenderBox) {
        final widgetName = _getCleanWidgetName(entry.target as RenderObject);
        if (widgetName.isNotEmpty) {
          hierarchy.add(widgetName);
        }
      }
    }

    // Iterate FORWARD to find innermost (deepest) semantic widget
    // Flutter's hit test path goes DEEPEST → ROOT
    for (var i = 0; i < pathList.length; i++) {
      final entry = pathList[i];
      if (entry.target is RenderBox) {
        final target = entry.target as RenderObject;
        final widgetName = _getCleanWidgetName(target);
        final isSemantic = widgetName.isNotEmpty && _isSemanticWidget(widgetName);

        if (isSemantic) {
          bestTarget = target;
          break;
        }

        bestTarget ??= target;
      }
    }

    if (bestTarget == null || bestTarget is! RenderBox) return null;

    return _extractWidgetBounds(bestTarget, hierarchy, position);
  }

  String _getCleanWidgetName(RenderObject renderObject) {
    String name = renderObject.runtimeType.toString();

    if (name.startsWith('Render')) {
      name = name.substring(6);
    }

    const internalPrefixes = [
      '_', 'Listener', 'Semantics', 'Pipeline', 'Offstage', 'View',
      'RepaintBoundary', 'AnnotatedRegion', 'Focus', 'Actions',
      'Shortcuts', 'DefaultTextEditingShortcuts', 'Scrollable',
    ];

    for (final prefix in internalPrefixes) {
      if (name.startsWith(prefix)) return '';
    }

    return name;
  }

  bool _isSemanticWidget(String name) {
    const highPriorityWidgets = [
      'Paragraph', 'EditableText', 'RichText',
      'Button', 'InkWell', 'GestureDetector', 'Ink',
      'Icon', 'Image', 'CircleAvatar',
      'TextField', 'Checkbox', 'Switch', 'Slider',
      'Card', 'Chip', 'Tooltip',
    ];

    const layoutWidgets = [
      'Container', 'DecoratedBox', 'ConstrainedBox', 'SizedBox',
      'Padding', 'Center', 'Align', 'ClipRRect', 'ClipOval',
      'Row', 'Column', 'Flex', 'Wrap',
      'Stack', 'Positioned', 'Expanded', 'Flexible',
      'ListView', 'GridView', 'CustomScrollView',
      'Scaffold', 'AppBar', 'Drawer', 'Dialog', 'Material',
      'Transform', 'Opacity', 'AnimatedContainer', 'AnimatedOpacity',
    ];

    for (final widget in highPriorityWidgets) {
      if (name.contains(widget)) return true;
    }

    for (final widget in layoutWidgets) {
      if (name.contains(widget)) return true;
    }

    return false;
  }

  WidgetBounds _extractWidgetBounds(RenderBox box, List<String> hierarchy, Offset tapPosition) {
    final size = box.size;
    final position = box.localToGlobal(Offset.zero);

    String uiLocation = widget.locationDetector?.call(hierarchy, position, context)
        ?? _defaultLocationDetector(hierarchy, position);
    String sourceFile = widget.sourceFileDetector?.call(uiLocation)
        ?? _defaultSourceFileDetector(uiLocation);
    int? lineNumber;

    final properties = <String, dynamic>{};

    if (box is RenderParagraph) {
      properties['text'] = box.text.toPlainText();
    }

    if (box is RenderDecoratedBox) {
      final decoration = box.decoration;
      if (decoration is BoxDecoration && decoration.color != null) {
        properties['color'] = decoration.color.toString();
      }
    }

    // Get actual Widget name from Element tree (not just RenderObject name)
    String widgetType = _getActualWidgetName(box);
    Element? targetElement;
    Widget? targetWidget;

    // Try to get Element via DebugCreator for source location extraction
    final creator = box.debugCreator;
    if (creator is DebugCreator) {
      targetElement = creator.element;
      targetWidget = targetElement.widget;

      // Try to extract exact source file and line number
      final sourceLocation = _extractWidgetSourceLocation(targetWidget, targetElement);
      if (sourceLocation != null) {
        sourceFile = sourceLocation.file;
        lineNumber = sourceLocation.line;
        debugPrint('🎯 EXACT LOCATION: ${sourceLocation.shortFile}:$lineNumber');
      }
    }

    if (widgetType.isEmpty) {
      widgetType = _getCleanWidgetName(box);
    }
    if (widgetType.isEmpty) {
      widgetType = hierarchy.isNotEmpty ? hierarchy.last : 'Widget';
    }

    // Get widget hierarchy with actual widget names
    final widgetHierarchy = _getWidgetHierarchy(box);

    final info = WidgetInfo(
      widgetType: widgetType,
      location: uiLocation,
      sourceFile: sourceFile,
      lineNumber: lineNumber,
      size: size,
      position: position,
      properties: properties,
      parentChain: widgetHierarchy.isNotEmpty ? widgetHierarchy : hierarchy,
    );

    return WidgetBounds(
      rect: Rect.fromLTWH(position.dx, position.dy, size.width, size.height),
      info: info,
    );
  }

  /// Get the actual Widget class name from the RenderObject using DebugCreator
  String _getActualWidgetName(RenderObject renderObject) {
    final creator = renderObject.debugCreator;
    if (creator is DebugCreator) {
      Element element = creator.element;

      // Walk up the Element tree to find a user-facing widget
      Element? current = element;
      while (current != null) {
        final widgetName = current.widget.runtimeType.toString();
        if (_isUserFacingWidget(widgetName)) {
          debugPrint('🎯 Found widget via DebugCreator: $widgetName');
          return widgetName;
        }
        current = _getParentElement(current);
      }

      // If no user-facing widget found, return the direct widget name
      return element.widget.runtimeType.toString();
    }

    // Fallback: map RenderObject names to Widget names
    return _mapRenderToWidgetName(renderObject);
  }

  /// Get the widget hierarchy with actual Widget names using DebugCreator
  List<String> _getWidgetHierarchy(RenderObject renderObject) {
    final hierarchy = <String>[];

    final creator = renderObject.debugCreator;
    if (creator is DebugCreator) {
      Element? element = creator.element;
      int depth = 0;

      while (element != null && depth < 25) {
        final widgetName = element.widget.runtimeType.toString();

        // Only include user-facing widgets
        if (_isUserFacingWidget(widgetName)) {
          hierarchy.add(widgetName);
        }

        element = _getParentElement(element);
        depth++;
      }
    }

    return hierarchy;
  }

  Element? _getParentElement(Element element) {
    Element? parent;
    element.visitAncestorElements((ancestor) {
      parent = ancestor;
      return false;
    });
    return parent;
  }

  /// Map common RenderObject names to their Widget equivalents
  String _mapRenderToWidgetName(RenderObject renderObject) {
    final renderName = renderObject.runtimeType.toString();

    const mappings = {
      'RenderParagraph': 'Text',
      'RenderFlex': 'Row/Column',
      'RenderDecoratedBox': 'Container/DecoratedBox',
      'RenderPadding': 'Padding',
      'RenderConstrainedBox': 'SizedBox/ConstrainedBox',
      'RenderPositionedBox': 'Center/Align',
      'RenderClipRRect': 'ClipRRect',
      'RenderClipOval': 'ClipOval',
      'RenderClipRect': 'ClipRect',
      'RenderOpacity': 'Opacity',
      'RenderTransform': 'Transform',
      'RenderImage': 'Image',
      'RenderPhysicalModel': 'Material/PhysicalModel',
      'RenderStack': 'Stack',
      'RenderWrap': 'Wrap',
      'RenderTable': 'Table',
      'RenderEditable': 'TextField',
    };

    return mappings[renderName] ?? renderName.replaceFirst('Render', '');
  }

  bool _isUserFacingWidget(String name) {
    if (name.startsWith('_')) return false;

    // Skip internal/implementation Flutter widgets
    const internalWidgets = {
      // Framework internals
      'RenderObjectToWidgetAdapter', 'View', 'RawView',
      'Semantics', 'MergeSemantics', 'BlockSemantics',
      'ExcludeSemantics', 'IndexedSemantics',
      'Focus', 'FocusScope', 'FocusTrap', 'TapRegionSurface',
      'Actions', 'Shortcuts', 'DefaultTextEditingShortcuts',
      'CallbackShortcuts', 'PrimaryScrollController',
      'ScrollConfiguration', 'ScrollNotificationObserver',
      'NotificationListener', 'RepaintBoundary',
      'KeepAlive', 'AutomaticKeepAlive', 'SliverKeepAlive',
      'KeyedSubtree', 'Builder', 'StatefulBuilder',
      'IgnorePointer', 'AbsorbPointer', 'MetaData',
      'Listener', 'MouseRegion', 'RawGestureDetector',
      'CustomPaint', 'CustomSingleChildLayout', 'CustomMultiChildLayout',
      'LayoutBuilder', 'OrientationBuilder', 'MediaQuery',
      'InheritedElement', 'InheritedWidget', 'InheritedTheme',
      'TickerMode', 'Offstage', 'Visibility',
      'Directionality',

      // Low-level rendering widgets (Container uses these internally)
      'DecoratedBox', 'ColoredBox', 'ConstrainedBox', 'LimitedBox',
      'OverflowBox', 'SizedOverflowBox', 'FractionallySizedBox',
      'Padding', 'Align', 'Center', 'FittedBox', 'AspectRatio',
      'IntrinsicWidth', 'IntrinsicHeight', 'Baseline',
      'ClipRect', 'ClipRRect', 'ClipOval', 'ClipPath',
      'PhysicalModel', 'PhysicalShape', 'Transform',
      'CompositedTransformTarget', 'CompositedTransformFollower',
      'FadeTransition', 'ScaleTransition', 'RotationTransition',
      'SlideTransition', 'SizeTransition', 'PositionedTransition',
      'DecoratedBoxTransition', 'AlignTransition', 'DefaultTextStyleTransition',

      // Text rendering internals
      'RichText', 'RawImage',

      // Layout internals
      'Expanded', 'Flexible', 'Spacer', 'SizedBox',
      'Positioned', 'PositionedDirectional',

      // Scroll internals
      'Scrollable', 'Viewport', 'ShrinkWrappingViewport',
      'SingleChildScrollView',
    };

    return !internalWidgets.contains(name);
  }

  String _defaultLocationDetector(List<String> hierarchy, Offset position) {
    final hierarchyStr = hierarchy.join(' ');
    final screenWidth = MediaQuery.of(context).size.width;

    if (position.dx < 300) return 'Left Panel';
    if (position.dx > screenWidth - 400) return 'Right Panel';
    if (position.dy < 60) return 'Top Bar';
    if (position.dy > MediaQuery.of(context).size.height - 100) return 'Bottom Panel';

    if (hierarchyStr.contains('AppBar')) return 'App Bar';
    if (hierarchyStr.contains('Drawer')) return 'Drawer';
    if (hierarchyStr.contains('BottomNavigation')) return 'Bottom Navigation';

    return 'Main Content';
  }

  String _defaultSourceFileDetector(String location) {
    return 'lib/main.dart';
  }

  Widget _cornerHandle() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        shape: BoxShape.circle,
      ),
    );
  }

  Future<void> _sendNoteToAI() async {
    if (_selectedWidget == null || _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note about what you want changed')),
      );
      return;
    }

    final note = WidgetNote(
      widget: _selectedWidget!.info,
      userNote: _noteController.text.trim(),
      action: _selectedAction,
      timestamp: DateTime.now(),
    );

    final success = await _inspector.sendNoteToAI(
      _selectedWidget!.info,
      _noteController.text.trim(),
      action: _selectedAction,
    );

    widget.onNoteSent?.call(note);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Note copied to clipboard! Paste it to Claude for precise changes.'),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Failed to copy to clipboard. Try again or copy manually.'),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red.withValues(alpha: 0.15),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    _noteController.clear();
  }

  Rect _globalToLocal(Rect globalRect) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return globalRect;
    final localOffset = box.globalToLocal(Offset(globalRect.left, globalRect.top));
    return Rect.fromLTWH(localOffset.dx, localOffset.dy, globalRect.width, globalRect.height);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app content
        KeyedSubtree(
          key: _childKey,
          child: widget.child,
        ),

        // Event interception overlay
        if (_isActive)
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) => _handlePointerDown(details.localPosition),
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                onHover: (event) => _handlePointerHover(event.localPosition),
                onExit: (_) => setState(() => _hoveredWidget = null),
                child: Container(color: Colors.black.withValues(alpha: 0.01)),
              ),
            ),
          ),

        // Hover highlight overlay
        if (_isActive && _hoveredWidget != null && _hoveredWidget != _selectedWidget)
          Builder(builder: (context) {
            final localRect = _globalToLocal(_hoveredWidget!.rect);
            return Positioned(
              left: localRect.left,
              top: localRect.top,
              width: localRect.width,
              height: localRect.height,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.orange.shade600, width: 2),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Transform.translate(
                      offset: const Offset(0, -22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _hoveredWidget!.info.widgetType,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

        // Selection highlight overlay
        if (_isActive && _selectedWidget != null)
          Builder(builder: (context) {
            final localRect = _globalToLocal(_selectedWidget!.rect);
            return Positioned(
              left: localRect.left,
              top: localRect.top,
              width: localRect.width,
              height: localRect.height,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.blue.shade700, width: 3),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -24,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedWidget!.info.widgetType,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Positioned(top: -5, left: -5, child: _cornerHandle()),
                      Positioned(top: -5, right: -5, child: _cornerHandle()),
                      Positioned(bottom: -5, left: -5, child: _cornerHandle()),
                      Positioned(bottom: -5, right: -5, child: _cornerHandle()),
                      Positioned(
                        bottom: -20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '${_selectedWidget!.rect.width.toInt()}px',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

        // Inspector UI elements
        if (_isActive) ...[
          Positioned(
            top: 8,
            left: 8,
            child: InspectorBanner(onClose: () => _inspector.disable()),
          ),

          if (_widgetPath.isNotEmpty)
            Positioned(
              top: 60,
              left: 8,
              right: MediaQuery.of(context).size.width / 2,
              child: WidgetPathBreadcrumb(
                path: _widgetPath,
                onSelect: (widgetInfo) {
                  final bounds = WidgetBounds(
                    rect: Rect.fromLTWH(
                      widgetInfo.position.dx,
                      widgetInfo.position.dy,
                      widgetInfo.size.width,
                      widgetInfo.size.height,
                    ),
                    info: widgetInfo,
                  );
                  setState(() => _selectedWidget = bounds);
                },
              ),
            ),

          if (_selectedWidget != null)
            Positioned(
              top: 8,
              right: 8,
              bottom: 8,
              child: EnhancedNotePanel(
                widget: _selectedWidget!.info,
                noteController: _noteController,
                selectedAction: _selectedAction,
                onActionChanged: (action) => setState(() => _selectedAction = action),
                onSendNote: _sendNoteToAI,
                onClose: _clearSelection,
              ),
            ),
        ],
      ],
    );
  }
}

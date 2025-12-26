import 'package:flutter/material.dart';

/// Layout properties for detailed widget inspection
/// Based on Flutter DevTools inspector_data_models.dart
class WidgetLayoutInfo {
  final double width;
  final double height;
  final double? flexFactor;
  final String? flexFit;
  final bool hasOverflow;
  final String? constraints;
  final String? padding;
  final String? alignment;

  const WidgetLayoutInfo({
    required this.width,
    required this.height,
    this.flexFactor,
    this.flexFit,
    this.hasOverflow = false,
    this.constraints,
    this.padding,
    this.alignment,
  });

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    if (flexFactor != null) 'flexFactor': flexFactor,
    if (flexFit != null) 'flexFit': flexFit,
    if (hasOverflow) 'hasOverflow': hasOverflow,
    if (constraints != null) 'constraints': constraints,
    if (padding != null) 'padding': padding,
    if (alignment != null) 'alignment': alignment,
  };

  factory WidgetLayoutInfo.fromJson(Map<String, dynamic> json) {
    return WidgetLayoutInfo(
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      flexFactor: json['flexFactor']?.toDouble(),
      flexFit: json['flexFit'],
      hasOverflow: json['hasOverflow'] ?? false,
      constraints: json['constraints'],
      padding: json['padding'],
      alignment: json['alignment'],
    );
  }
}

/// Information about an inspected widget
class WidgetInfo {
  final String widgetType;
  final String location;
  final String sourceFile;
  final int? lineNumber;
  final Size size;
  final Offset position;
  final Map<String, dynamic> properties;
  final List<String> parentChain;

  // New fields for precise widget identification
  final String? uniqueInstanceId;
  final int siblingIndex;
  final double matchConfidence;
  final int? columnNumber;

  // Enhanced fields for precise code extraction
  final String? preciseWidgetCode;
  final WidgetLayoutInfo? layoutInfo;
  final Map<String, dynamic>? diagnosticProperties;

  WidgetInfo({
    required this.widgetType,
    required this.location,
    required this.sourceFile,
    this.lineNumber,
    required this.size,
    required this.position,
    this.properties = const {},
    this.parentChain = const [],
    this.uniqueInstanceId,
    this.siblingIndex = 0,
    this.matchConfidence = 1.0,
    this.columnNumber,
    this.preciseWidgetCode,
    this.layoutInfo,
    this.diagnosticProperties,
  });

  /// Check if this has precise widget code
  bool get hasPreciseCode => preciseWidgetCode != null && preciseWidgetCode!.isNotEmpty;

  /// Check if this is an exact match (high confidence)
  bool get isExactMatch => matchConfidence > 0.95;

  /// Get formatted location string
  String get locationString {
    if (columnNumber != null) {
      return '$sourceFile:$lineNumber:$columnNumber';
    }
    if (lineNumber != null) {
      return '$sourceFile:$lineNumber';
    }
    return sourceFile;
  }

  /// Get short description for display
  String get shortDescription {
    final siblingInfo = siblingIndex > 0 ? ' #$siblingIndex' : '';
    return '$widgetType$siblingInfo';
  }

  /// Get layout summary for display
  String get layoutSummary {
    if (layoutInfo == null) return '';
    final li = layoutInfo!;
    final parts = <String>[];
    parts.add('${li.width.toInt()}×${li.height.toInt()}');
    if (li.flexFactor != null) parts.add('flex:${li.flexFactor}');
    if (li.hasOverflow) parts.add('OVERFLOW');
    return parts.join(' | ');
  }

  Map<String, dynamic> toJson() => {
    'widgetType': widgetType,
    'location': location,
    'sourceFile': sourceFile,
    'lineNumber': lineNumber,
    'size': {'width': size.width, 'height': size.height},
    'position': {'x': position.dx, 'y': position.dy},
    'properties': properties,
    'parentChain': parentChain,
    if (uniqueInstanceId != null) 'uniqueInstanceId': uniqueInstanceId,
    'siblingIndex': siblingIndex,
    'matchConfidence': matchConfidence,
    if (columnNumber != null) 'columnNumber': columnNumber,
    if (preciseWidgetCode != null) 'preciseWidgetCode': preciseWidgetCode,
    if (layoutInfo != null) 'layoutInfo': layoutInfo!.toJson(),
    if (diagnosticProperties != null) 'diagnosticProperties': diagnosticProperties,
  };

  WidgetInfo copyWith({
    String? widgetType,
    String? location,
    String? sourceFile,
    int? lineNumber,
    Size? size,
    Offset? position,
    Map<String, dynamic>? properties,
    List<String>? parentChain,
    String? uniqueInstanceId,
    int? siblingIndex,
    double? matchConfidence,
    int? columnNumber,
    String? preciseWidgetCode,
    WidgetLayoutInfo? layoutInfo,
    Map<String, dynamic>? diagnosticProperties,
  }) {
    return WidgetInfo(
      widgetType: widgetType ?? this.widgetType,
      location: location ?? this.location,
      sourceFile: sourceFile ?? this.sourceFile,
      lineNumber: lineNumber ?? this.lineNumber,
      size: size ?? this.size,
      position: position ?? this.position,
      properties: properties ?? this.properties,
      parentChain: parentChain ?? this.parentChain,
      uniqueInstanceId: uniqueInstanceId ?? this.uniqueInstanceId,
      siblingIndex: siblingIndex ?? this.siblingIndex,
      matchConfidence: matchConfidence ?? this.matchConfidence,
      columnNumber: columnNumber ?? this.columnNumber,
      preciseWidgetCode: preciseWidgetCode ?? this.preciseWidgetCode,
      layoutInfo: layoutInfo ?? this.layoutInfo,
      diagnosticProperties: diagnosticProperties ?? this.diagnosticProperties,
    );
  }

  @override
  String toString() => 'WidgetInfo($widgetType at $location)';
}

/// A note about a widget to send to AI
class WidgetNote {
  final WidgetInfo widget;
  final String userNote;
  final NoteAction action;
  final DateTime timestamp;

  WidgetNote({
    required this.widget,
    required this.userNote,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'widget': widget.toJson(),
    'userNote': userNote,
    'action': action.name,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Formatted text ready to paste to Claude or other AI
  String get formattedForClipboard {
    final buffer = StringBuffer();
    buffer.writeln('=== WIDGET INSPECTOR ===');
    buffer.writeln();

    // Most important: EXACT SOURCE LOCATION
    if (widget.lineNumber != null) {
      buffer.writeln('EXACT SOURCE LOCATION:');
      buffer.writeln('  ${widget.locationString}');
    } else {
      buffer.writeln('LIKELY SOURCE FILE:');
      buffer.writeln('  ${widget.sourceFile}');
    }
    buffer.writeln();

    // Widget identification
    buffer.writeln('WIDGET: ${widget.shortDescription}');
    buffer.writeln('ACTION: ${action.description}');
    if (!widget.isExactMatch) {
      buffer.writeln('MATCH CONFIDENCE: ${(widget.matchConfidence * 100).toInt()}%');
    }
    buffer.writeln();

    // User's request
    buffer.writeln('USER REQUEST:');
    buffer.writeln(userNote);
    buffer.writeln();

    // Precise widget code (if available)
    if (widget.hasPreciseCode) {
      buffer.writeln('--- Precise Widget Code ---');
      buffer.writeln('```dart');
      buffer.writeln(widget.preciseWidgetCode);
      buffer.writeln('```');
      buffer.writeln();
    }

    // Widget details
    buffer.writeln('--- Widget Details ---');
    buffer.writeln('Size: ${widget.size.width.toInt()} x ${widget.size.height.toInt()} px');
    buffer.writeln('Position: (${widget.position.dx.toInt()}, ${widget.position.dy.toInt()})');
    buffer.writeln('UI Panel: ${widget.location}');

    // Layout info
    if (widget.layoutInfo != null) {
      buffer.writeln();
      buffer.writeln('Layout Info:');
      buffer.writeln('  ${widget.layoutSummary}');
      if (widget.layoutInfo!.constraints != null) {
        buffer.writeln('  Constraints: ${widget.layoutInfo!.constraints}');
      }
      if (widget.layoutInfo!.padding != null) {
        buffer.writeln('  Padding: ${widget.layoutInfo!.padding}');
      }
    }

    if (widget.properties.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Properties:');
      widget.properties.forEach((key, value) {
        final valueStr = value.toString();
        final displayValue = valueStr.length > 100 ? '${valueStr.substring(0, 100)}...' : valueStr;
        buffer.writeln('  $key: $displayValue');
      });
    }

    if (widget.parentChain.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Widget Hierarchy (selected -> parent):');
      for (int i = 0; i < widget.parentChain.length && i < 8; i++) {
        buffer.writeln('  ${i == 0 ? ">" : " "} ${widget.parentChain[i]}');
      }
      if (widget.parentChain.length > 8) {
        buffer.writeln('  ... +${widget.parentChain.length - 8} more ancestors');
      }
    }

    return buffer.toString();
  }
}

/// Holds exact bounds information for a widget
class WidgetBounds {
  final Rect rect;
  final WidgetInfo info;

  WidgetBounds({
    required this.rect,
    required this.info,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WidgetBounds && other.rect == rect;
  }

  @override
  int get hashCode => rect.hashCode;
}

/// Action to take on the widget
enum NoteAction {
  discuss('Discuss this widget with AI'),
  modify('Modify this widget'),
  fix('Fix a bug in this widget'),
  enhance('Enhance this widget'),
  remove('Remove this widget'),
  relocate('Move this widget'),
  style('Change styling'),
  question('Ask a question');

  final String description;
  const NoteAction(this.description);
}

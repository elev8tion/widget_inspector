import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';

/// Service for controlling the widget inspector
///
/// Use this to programmatically enable/disable the inspector,
/// listen for widget selections, and handle notes.
class InspectorService {
  static final InspectorService _instance = InspectorService._internal();
  factory InspectorService() => _instance;
  InspectorService._internal();

  bool _isActive = false;
  final _activeController = StreamController<bool>.broadcast();
  final _widgetSelectedController = StreamController<WidgetInfo>.broadcast();
  final _noteController = StreamController<WidgetNote>.broadcast();

  /// Stream of inspector active state changes
  Stream<bool> get activeStream => _activeController.stream;

  /// Stream of widget selection events
  Stream<WidgetInfo> get widgetSelectedStream => _widgetSelectedController.stream;

  /// Stream of notes sent to AI
  Stream<WidgetNote> get noteStream => _noteController.stream;

  /// Whether the inspector is currently active
  bool get isActive => _isActive;

  final List<WidgetNote> _notes = [];

  /// All notes collected during this session
  List<WidgetNote> get notes => List.unmodifiable(_notes);

  /// Toggle the inspector on/off
  void toggle() {
    _isActive = !_isActive;
    _activeController.add(_isActive);
    debugPrint('🔍 Widget Inspector ${_isActive ? "ENABLED" : "DISABLED"}');
  }

  /// Enable the inspector
  void enable() {
    _isActive = true;
    _activeController.add(true);
    debugPrint('🔍 Widget Inspector ENABLED');
  }

  /// Disable the inspector
  void disable() {
    _isActive = false;
    _activeController.add(false);
    debugPrint('🔍 Widget Inspector DISABLED');
  }

  /// Called when a widget is selected
  void selectWidget(WidgetInfo info) {
    _widgetSelectedController.add(info);
    debugPrint('📍 Selected: ${info.widgetType} at ${info.location}');
  }

  /// Send a note about a widget to AI (copies to clipboard)
  Future<bool> sendNoteToAI(WidgetInfo widget, String note, {NoteAction action = NoteAction.discuss}) async {
    final widgetNote = WidgetNote(
      widget: widget,
      userNote: note,
      action: action,
      timestamp: DateTime.now(),
    );

    _notes.add(widgetNote);
    _noteController.add(widgetNote);

    // Copy to clipboard
    try {
      await Clipboard.setData(ClipboardData(text: widgetNote.formattedForClipboard));
      debugPrint('💬 Note copied to clipboard successfully');
      debugPrint('   Widget: ${widget.widgetType}');
      debugPrint('   Action: ${action.name}');
      debugPrint('   Note: $note');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to copy to clipboard: $e');
      return false;
    }
  }

  /// Format a note for AI consumption
  String formatNoteForAI(WidgetNote note) {
    final buffer = StringBuffer();

    buffer.writeln('=== Widget Inspection Note ===');
    buffer.writeln('User Request: ${note.action.description}');
    buffer.writeln('Timestamp: ${note.timestamp}');
    buffer.writeln();
    buffer.writeln('Widget Information:');
    buffer.writeln('  Type: ${note.widget.widgetType}');
    buffer.writeln('  Location: ${note.widget.location}');
    buffer.writeln('  Source File: ${note.widget.sourceFile}');
    if (note.widget.lineNumber != null) {
      buffer.writeln('  Line Number: ${note.widget.lineNumber}');
    }
    buffer.writeln('  Size: ${note.widget.size.width.toStringAsFixed(0)} × ${note.widget.size.height.toStringAsFixed(0)}');
    buffer.writeln('  Position: (${note.widget.position.dx.toStringAsFixed(0)}, ${note.widget.position.dy.toStringAsFixed(0)})');

    if (note.widget.properties.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Properties:');
      note.widget.properties.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    if (note.widget.parentChain.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Widget Hierarchy:');
      for (int i = 0; i < note.widget.parentChain.length; i++) {
        buffer.writeln('  ${'  ' * i}└─ ${note.widget.parentChain[i]}');
      }
    }

    buffer.writeln();
    buffer.writeln('User Note:');
    buffer.writeln(note.userNote);
    buffer.writeln();
    buffer.writeln('Suggested File to Edit: ${note.widget.sourceFile}');

    return buffer.toString();
  }

  /// Clear all collected notes
  void clearNotes() {
    _notes.clear();
  }

  /// Dispose of the service (call when app is closing)
  void dispose() {
    _activeController.close();
    _widgetSelectedController.close();
    _noteController.close();
  }
}

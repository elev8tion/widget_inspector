# Widget Inspector

A powerful Flutter widget inspector tool for debugging and visual inspection. Click on any widget to inspect its properties, hierarchy, and generate AI-ready modification requests.

## Features

- **Click-to-Inspect**: Click on any widget in your app to select and inspect it
- **Hover Highlighting**: Widgets are highlighted as you hover over them
- **Widget Hierarchy**: View the complete widget tree path
- **Property Extraction**: Automatically extracts text content, colors, and other properties
- **AI-Ready Notes**: Generate formatted notes that can be pasted directly to Claude or other AI assistants
- **Clipboard Integration**: Notes are automatically copied to clipboard
- **Customizable**: Plug in your own location and source file detectors

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  widget_inspector:
    path: /path/to/widget_inspector
```

Or if published to pub.dev:

```yaml
dependencies:
  widget_inspector: ^1.0.0
```

## Usage

### Basic Setup

Wrap your app with `InspectorOverlay`:

```dart
import 'package:widget_inspector/widget_inspector.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InspectorOverlay(
        child: MyHomePage(),
      ),
    );
  }
}
```

### Toggle the Inspector

Use `InspectorService` to control the inspector:

```dart
final inspector = InspectorService();

// Toggle on/off
inspector.toggle();

// Enable
inspector.enable();

// Disable
inspector.disable();

// Check if active
if (inspector.isActive) {
  // ...
}
```

### Add a Toggle Button

```dart
StreamBuilder<bool>(
  stream: InspectorService().activeStream,
  initialData: InspectorService().isActive,
  builder: (context, snapshot) {
    final isActive = snapshot.data ?? false;
    return IconButton(
      icon: Icon(isActive ? Icons.search_off : Icons.search),
      onPressed: () => InspectorService().toggle(),
    );
  },
)
```

### Keyboard Shortcuts

Add keyboard shortcuts in your app:

```dart
@override
void initState() {
  super.initState();
  HardwareKeyboard.instance.addHandler(_handleKeyPress);
}

bool _handleKeyPress(KeyEvent event) {
  if (event is KeyDownEvent) {
    if (event.logicalKey == LogicalKeyboardKey.f2) {
      InspectorService().toggle();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      InspectorService().disable();
      return true;
    }
  }
  return false;
}
```

### Listen for Events

```dart
// When a widget is selected
InspectorService().widgetSelectedStream.listen((widget) {
  print('Selected: ${widget.widgetType}');
  print('Location: ${widget.location}');
  print('Size: ${widget.size}');
});

// When a note is sent
InspectorService().noteStream.listen((note) {
  print('Note: ${note.userNote}');
  print('Action: ${note.action}');
});
```

### Custom Location Detection

Provide your own location detector for project-specific panels:

```dart
InspectorOverlay(
  locationDetector: (hierarchy, position, context) {
    if (hierarchy.join(' ').contains('Sidebar')) {
      return 'Sidebar Panel';
    }
    if (position.dx < 300) {
      return 'Left Panel';
    }
    return 'Main Content';
  },
  sourceFileDetector: (location) {
    if (location.contains('Sidebar')) {
      return 'lib/widgets/sidebar.dart';
    }
    return 'lib/main.dart';
  },
  child: MyApp(),
)
```

## API Reference

### InspectorOverlay

The main widget that wraps your app.

| Property | Type | Description |
|----------|------|-------------|
| `child` | `Widget` | The app to wrap |
| `onWidgetSelected` | `ValueChanged<WidgetInfo>?` | Called when a widget is selected |
| `onNoteSent` | `ValueChanged<WidgetNote>?` | Called when a note is sent |
| `locationDetector` | `Function?` | Custom location detection |
| `sourceFileDetector` | `Function?` | Custom source file detection |

### InspectorService

Singleton service to control the inspector.

| Method | Description |
|--------|-------------|
| `toggle()` | Toggle inspector on/off |
| `enable()` | Enable the inspector |
| `disable()` | Disable the inspector |
| `isActive` | Current active state |
| `activeStream` | Stream of active state changes |
| `widgetSelectedStream` | Stream of widget selections |
| `noteStream` | Stream of notes |
| `notes` | List of all notes |
| `clearNotes()` | Clear collected notes |

### WidgetInfo

Information about an inspected widget.

| Property | Type | Description |
|----------|------|-------------|
| `widgetType` | `String` | Widget class name |
| `location` | `String` | Panel/area location |
| `sourceFile` | `String` | Source file path |
| `size` | `Size` | Widget dimensions |
| `position` | `Offset` | Global position |
| `properties` | `Map<String, dynamic>` | Extracted properties |
| `parentChain` | `List<String>` | Widget hierarchy |

### NoteAction

Available actions for widget notes.

- `discuss` - Discuss this widget with AI
- `modify` - Modify this widget
- `fix` - Fix a bug in this widget
- `enhance` - Enhance this widget
- `remove` - Remove this widget
- `relocate` - Move this widget
- `style` - Change styling
- `question` - Ask a question

## Example

See the `example/` directory for a complete working example.

```bash
cd example
flutter run
```

## License

MIT License - feel free to use in any project!

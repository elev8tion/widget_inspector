# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Widget Inspector is a Flutter package for click-to-inspect widget debugging. It enables developers to select any widget at runtime, extract its properties and source location, and generate AI-ready modification requests.

## Commands

```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run tests
flutter test

# Run example app
cd example && flutter run
```

## Architecture

The package uses singleton services with stream-based state management. No external dependencies beyond Flutter SDK.

### Core Components

**InspectorService** (`lib/src/inspector_service.dart`) - Singleton controlling inspector state, events, and clipboard operations. Entry point for toggling and listening to widget selections.

**InspectorOverlay** (`lib/src/widget_selector.dart`) - Main wrapper widget that handles pointer events (hover/tap), hit testing, and visual feedback (highlighting, breadcrumbs). Wraps the entire app.

**EnhancedHitTestProcessor** (`lib/src/enhanced_hit_test_processor.dart`) - Singleton that scores widget candidates using specificity algorithm (area + center distance + user-facing bonus). Handles corner-aware parent selection.

**WidgetInstanceTracker** (`lib/src/widget_instance_tracker.dart`) - Singleton tracking sibling indices for duplicate widgets of the same type, generating unique IDs.

**SourceCodeCorrelator** (`lib/src/source_code_correlator.dart`) - Singleton that matches runtime widgets to source code using bracket-matching algorithm. Handles Dart syntax (strings, comments).

**Models** (`lib/src/models.dart`) - Data structures: `WidgetInfo`, `WidgetNote`, `WidgetLayoutInfo`, `WidgetBounds`, `NoteAction` enum.

**Inspector Widgets** (`lib/src/inspector_widgets.dart`) - UI components: `InspectorBanner`, `WidgetPathBreadcrumb`, `EnhancedNotePanel`.

### Data Flow

1. `InspectorOverlay` captures pointer events
2. `EnhancedHitTestProcessor` scores candidates and selects best match
3. `WidgetInstanceTracker` provides sibling index for duplicate identification
4. `SourceCodeCorrelator` extracts precise widget code from source
5. `InspectorService` broadcasts selection via streams and handles clipboard

### Widget Selection Algorithm

Specificity scoring in `EnhancedHitTestProcessor`:
- Area score: smaller widgets score higher
- Center score: clicks closer to widget center score higher
- User-facing bonus: known UI widgets (Text, Button, etc.) get +0.2
- Corner zones trigger parent widget selection

## Key Patterns

- All core services are singletons accessed via factory constructors
- State changes broadcast via `StreamController`
- Source location extraction uses multiple fallback strategies (DiagnosticsNode, debug info, toString patterns)
- Widget code extraction uses bracket-stack parsing with string/comment awareness

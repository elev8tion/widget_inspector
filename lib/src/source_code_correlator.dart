/// Source Code Correlator - Bridges runtime widgets to source code locations
///
/// Uses bracket matching algorithm (inspired by Flutter Widget Catcher extension)
/// to precisely extract widget code from source files.
class SourceCodeCorrelator {
  // Singleton pattern
  static final SourceCodeCorrelator _instance = SourceCodeCorrelator._internal();
  static SourceCodeCorrelator get instance => _instance;
  SourceCodeCorrelator._internal();

  /// Widget name regex pattern (matches WidgetName followed by parenthesis)
  static final RegExp _widgetPattern = RegExp(r'([A-Z][a-zA-Z0-9_]*)\s*\(');

  /// Find all widget occurrences in source code
  List<WidgetOccurrence> findWidgetOccurrences(String source, String widgetType) {
    final occurrences = <WidgetOccurrence>[];

    // Find all matches of the widget pattern
    final pattern = RegExp('$widgetType\\s*\\(');

    for (final match in pattern.allMatches(source)) {
      final boundary = findWidgetBoundary(source, match.start);
      if (boundary != null) {
        final lineNumber = _calculateLineNumber(source, match.start);
        final columnNumber = _calculateColumnNumber(source, match.start);

        occurrences.add(WidgetOccurrence(
          widgetType: widgetType,
          lineNumber: lineNumber,
          columnNumber: columnNumber,
          startOffset: match.start,
          endOffset: boundary.endOffset,
          boundary: boundary,
        ));
      }
    }

    return occurrences;
  }

  /// Find widget boundary using bracket stack matching
  ///
  /// This is the core algorithm adapted from Flutter Widget Catcher.
  /// It handles Dart-specific syntax: strings, comments, raw strings.
  WidgetBoundary? findWidgetBoundary(String source, int startOffset) {
    // Find the widget name pattern
    final match = _widgetPattern.matchAsPrefix(source, startOffset);
    if (match == null) return null;

    final widgetName = match.group(1)!;
    int openParenPos = match.end - 1;

    // Use bracket stack to find matching closing bracket
    final bracketStack = <String>['('];
    int i = openParenPos + 1;

    while (i < source.length && bracketStack.isNotEmpty) {
      final char = source[i];

      // Handle string literals (skip their contents)
      if (char == '"' || char == "'") {
        i = _skipStringLiteral(source, i);
        continue;
      }

      // Handle raw strings r"..." or r'...'
      if (char == 'r' && i + 1 < source.length) {
        final nextChar = source[i + 1];
        if (nextChar == '"' || nextChar == "'") {
          i = _skipStringLiteral(source, i + 1);
          continue;
        }
      }

      // Handle line comments //
      if (char == '/' && i + 1 < source.length && source[i + 1] == '/') {
        i = _skipLineComment(source, i);
        continue;
      }

      // Handle block comments /* */
      if (char == '/' && i + 1 < source.length && source[i + 1] == '*') {
        i = _skipBlockComment(source, i);
        continue;
      }

      // Handle brackets
      switch (char) {
        case '(':
          bracketStack.add('(');
          break;
        case ')':
          if (bracketStack.isNotEmpty && bracketStack.last == '(') {
            bracketStack.removeLast();
          }
          break;
        case '{':
          bracketStack.add('{');
          break;
        case '}':
          if (bracketStack.isNotEmpty && bracketStack.last == '{') {
            bracketStack.removeLast();
          }
          break;
        case '[':
          bracketStack.add('[');
          break;
        case ']':
          if (bracketStack.isNotEmpty && bracketStack.last == '[') {
            bracketStack.removeLast();
          }
          break;
      }

      i++;
    }

    // Extract the complete widget code
    final widgetCode = source.substring(startOffset, i);

    return WidgetBoundary(
      widgetName: widgetName,
      startOffset: startOffset,
      endOffset: i,
      sourceCode: widgetCode,
    );
  }

  /// Skip over a string literal (handles escape sequences)
  int _skipStringLiteral(String source, int pos) {
    final quote = source[pos];
    bool isTripleQuote = false;

    // Check for triple-quoted string
    if (pos + 2 < source.length &&
        source[pos + 1] == quote &&
        source[pos + 2] == quote) {
      isTripleQuote = true;
      pos += 3;
    } else {
      pos += 1;
    }

    while (pos < source.length) {
      final char = source[pos];

      // Handle escape sequences
      if (char == '\\' && pos + 1 < source.length) {
        pos += 2; // Skip escape and next character
        continue;
      }

      if (isTripleQuote) {
        // Check for closing triple quote
        if (pos + 2 < source.length &&
            source[pos] == quote &&
            source[pos + 1] == quote &&
            source[pos + 2] == quote) {
          return pos + 3;
        }
      } else {
        // Check for closing single quote
        if (char == quote) {
          return pos + 1;
        }
        // Single-quoted strings can't span lines
        if (char == '\n') {
          return pos;
        }
      }

      pos++;
    }

    return source.length;
  }

  /// Skip over a line comment
  int _skipLineComment(String source, int pos) {
    while (pos < source.length && source[pos] != '\n') {
      pos++;
    }
    return pos + 1; // Skip the newline too
  }

  /// Skip over a block comment
  int _skipBlockComment(String source, int pos) {
    pos += 2; // Skip /*
    while (pos + 1 < source.length) {
      if (source[pos] == '*' && source[pos + 1] == '/') {
        return pos + 2;
      }
      pos++;
    }
    return source.length;
  }

  /// Calculate line number from offset
  int _calculateLineNumber(String source, int offset) {
    int lineNumber = 1;
    for (int i = 0; i < offset && i < source.length; i++) {
      if (source[i] == '\n') {
        lineNumber++;
      }
    }
    return lineNumber;
  }

  /// Calculate column number from offset
  int _calculateColumnNumber(String source, int offset) {
    int lastNewline = -1;
    for (int i = 0; i < offset && i < source.length; i++) {
      if (source[i] == '\n') {
        lastNewline = i;
      }
    }
    return offset - lastNewline;
  }

  /// Extract parent chain from source code (looking backwards from widget position)
  List<String> extractParentChain(String source, WidgetBoundary boundary) {
    final parents = <String>[];
    int searchPos = boundary.startOffset - 1;

    // Look backwards for parent widgets
    while (searchPos >= 0 && parents.length < 10) {
      // Find the previous widget pattern
      final substring = source.substring(0, searchPos);
      final lastMatch = _widgetPattern.allMatches(substring).lastOrNull;

      if (lastMatch == null) break;

      parents.add(lastMatch.group(1)!);
      searchPos = lastMatch.start - 1;
    }

    return parents;
  }

  /// Match runtime widget to source occurrence using parent chain
  WidgetOccurrence? matchToSourceOccurrence(
    List<WidgetOccurrence> occurrences,
    List<String> runtimeParentChain,
    String source,
  ) {
    if (occurrences.isEmpty) return null;
    if (occurrences.length == 1) return occurrences.first;

    // Score each occurrence by how well its parent chain matches
    double bestScore = -1;
    WidgetOccurrence? bestMatch;

    for (final occurrence in occurrences) {
      final sourceParents = extractParentChain(source, occurrence.boundary);
      final score = _calculateChainMatchScore(runtimeParentChain, sourceParents);

      if (score > bestScore) {
        bestScore = score;
        bestMatch = occurrence;
      }
    }

    return bestMatch ?? occurrences.first;
  }

  /// Calculate how well two parent chains match
  double _calculateChainMatchScore(List<String> runtime, List<String> source) {
    if (runtime.isEmpty || source.isEmpty) return 0.0;

    int matches = 0;
    final minLength = runtime.length < source.length ? runtime.length : source.length;

    for (int i = 0; i < minLength; i++) {
      if (runtime[i] == source[i]) {
        matches++;
      }
    }

    return matches / minLength;
  }

  /// Extract widget properties from source code
  Map<String, String> extractPropertiesFromSource(String source, WidgetBoundary boundary) {
    final properties = <String, String>{};
    final widgetCode = boundary.sourceCode;

    // Find property patterns: propertyName: value
    final propertyPattern = RegExp(r'(\w+)\s*:\s*([^,\)]+)');

    for (final match in propertyPattern.allMatches(widgetCode)) {
      final name = match.group(1)!;
      final value = match.group(2)!.trim();

      // Skip 'child' and 'children' as they're nested widgets
      if (name != 'child' && name != 'children') {
        properties[name] = value;
      }
    }

    return properties;
  }

  /// Find the source location for a widget given its type and parent chain
  SourceLocation? findWidgetSourceLocation(
    String source,
    String widgetType,
    List<String> parentChain,
  ) {
    final occurrences = findWidgetOccurrences(source, widgetType);

    if (occurrences.isEmpty) return null;

    final bestMatch = matchToSourceOccurrence(occurrences, parentChain, source);

    if (bestMatch == null) return null;

    return SourceLocation(
      filePath: '', // To be filled by caller
      lineNumber: bestMatch.lineNumber,
      columnNumber: bestMatch.columnNumber,
      widgetCode: bestMatch.boundary.sourceCode,
      confidence: occurrences.length == 1 ? 1.0 : 0.8,
    );
  }
}

/// Represents a widget boundary in source code
class WidgetBoundary {
  final String widgetName;
  final int startOffset;
  final int endOffset;
  final String sourceCode;

  WidgetBoundary({
    required this.widgetName,
    required this.startOffset,
    required this.endOffset,
    required this.sourceCode,
  });

  int get length => endOffset - startOffset;

  @override
  String toString() {
    return 'WidgetBoundary($widgetName, $startOffset-$endOffset, ${sourceCode.length} chars)';
  }
}

/// Represents a widget occurrence in source code
class WidgetOccurrence {
  final String widgetType;
  final int lineNumber;
  final int columnNumber;
  final int startOffset;
  final int endOffset;
  final WidgetBoundary boundary;

  WidgetOccurrence({
    required this.widgetType,
    required this.lineNumber,
    required this.columnNumber,
    required this.startOffset,
    required this.endOffset,
    required this.boundary,
  });

  @override
  String toString() {
    return 'WidgetOccurrence($widgetType at $lineNumber:$columnNumber)';
  }
}

/// Represents a source code location with confidence score
class SourceLocation {
  final String filePath;
  final int lineNumber;
  final int columnNumber;
  final String widgetCode;
  final double confidence; // 0.0 - 1.0

  SourceLocation({
    required this.filePath,
    required this.lineNumber,
    required this.columnNumber,
    required this.widgetCode,
    required this.confidence,
  });

  bool get isExact => confidence > 0.95;
  bool get isApproximate => confidence > 0.5 && confidence <= 0.95;
  bool get isGuess => confidence <= 0.5;

  @override
  String toString() {
    return 'SourceLocation($filePath:$lineNumber:$columnNumber, '
           'confidence: ${(confidence * 100).toInt()}%)';
  }
}

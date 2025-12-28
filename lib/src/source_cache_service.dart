import 'source_code_correlator.dart';

/// Service for caching and searching source code files
/// Enables precise widget code extraction by maintaining a cache of source files
class SourceCacheService {
  static final SourceCacheService _instance = SourceCacheService._internal();
  static SourceCacheService get instance => _instance;
  SourceCacheService._internal();

  /// Cached source files: path -> content
  final Map<String, String> _sourceCache = {};

  /// Whether any source has been loaded
  bool get hasSource => _sourceCache.isNotEmpty;

  /// Number of cached files
  int get fileCount => _sourceCache.length;

  /// Add a source file to the cache
  void addSource(String filePath, String content) {
    _sourceCache[_normalizePath(filePath)] = content;
  }

  /// Add multiple source files at once
  void addSources(Map<String, String> sources) {
    for (final entry in sources.entries) {
      addSource(entry.key, entry.value);
    }
  }

  /// Remove a source file from the cache
  void removeSource(String filePath) {
    _sourceCache.remove(_normalizePath(filePath));
  }

  /// Clear all cached source files
  void clearCache() {
    _sourceCache.clear();
  }

  /// Get source content for a file path
  String? getSourceContent(String filePath) {
    final normalized = _normalizePath(filePath);

    // Try exact match
    if (_sourceCache.containsKey(normalized)) {
      return _sourceCache[normalized];
    }

    // Try with lib/ prefix
    if (!normalized.startsWith('lib/')) {
      final withLib = 'lib/$normalized';
      if (_sourceCache.containsKey(withLib)) {
        return _sourceCache[withLib];
      }
    }

    // Try partial match (filename only)
    for (final entry in _sourceCache.entries) {
      if (entry.key.endsWith(normalized) || normalized.endsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Get all cached source files
  Map<String, String> get allSources => Map.unmodifiable(_sourceCache);

  /// Get all cached file paths
  List<String> get cachedPaths => _sourceCache.keys.toList();

  /// Find widget in cached source using SourceCodeCorrelator
  WidgetSourceMatch? findWidget(
    String widgetType, {
    List<String>? parentChain,
  }) {
    final correlator = SourceCodeCorrelator.instance;

    for (final entry in _sourceCache.entries) {
      final path = entry.key;
      final content = entry.value;

      final occurrences = correlator.findWidgetOccurrences(content, widgetType);

      if (occurrences.isEmpty) continue;

      // If only one occurrence, use it
      if (occurrences.length == 1) {
        final occ = occurrences.first;
        return WidgetSourceMatch(
          filePath: path,
          lineNumber: occ.lineNumber,
          columnNumber: occ.columnNumber,
          preciseWidgetCode: occ.boundary.sourceCode,
          confidence: 1.0,
          matchType: MatchType.instantiation,
        );
      }

      // Multiple occurrences - use parent chain matching
      if (parentChain != null) {
        final bestMatch = correlator.matchToSourceOccurrence(
          occurrences,
          parentChain,
          content,
        );

        if (bestMatch != null) {
          return WidgetSourceMatch(
            filePath: path,
            lineNumber: bestMatch.lineNumber,
            columnNumber: bestMatch.columnNumber,
            preciseWidgetCode: bestMatch.boundary.sourceCode,
            confidence: 0.8,
            matchType: MatchType.instantiation,
          );
        }
      }

      // Return first occurrence as fallback
      final first = occurrences.first;
      return WidgetSourceMatch(
        filePath: path,
        lineNumber: first.lineNumber,
        columnNumber: first.columnNumber,
        preciseWidgetCode: first.boundary.sourceCode,
        confidence: 0.5,
        matchType: MatchType.instantiation,
      );
    }

    return null;
  }

  /// Search all cached files for a widget type
  List<WidgetSourceMatch> findAllOccurrences(String widgetType) {
    final results = <WidgetSourceMatch>[];
    final correlator = SourceCodeCorrelator.instance;

    for (final entry in _sourceCache.entries) {
      final path = entry.key;
      final content = entry.value;

      final occurrences = correlator.findWidgetOccurrences(content, widgetType);

      for (final occ in occurrences) {
        results.add(WidgetSourceMatch(
          filePath: path,
          lineNumber: occ.lineNumber,
          columnNumber: occ.columnNumber,
          preciseWidgetCode: occ.boundary.sourceCode,
          confidence: 0.9,
          matchType: MatchType.instantiation,
        ));
      }
    }

    return results;
  }

  /// Find best matching source location using context
  WidgetSourceMatch? findBestMatch(
    String widgetType, {
    List<String>? parentChain,
    String? uiLocation,
  }) {
    final locations = findAllOccurrences(widgetType);
    if (locations.isEmpty) return null;
    if (locations.length == 1) return locations.first;

    // Score each location based on context
    WidgetSourceMatch? best;
    double bestScore = -1;

    for (final loc in locations) {
      double score = loc.confidence;

      // Boost score if parent chain hints at file
      if (parentChain != null) {
        final chainStr = parentChain.join(' ').toLowerCase();
        final pathLower = loc.filePath.toLowerCase();

        if (chainStr.contains('filetree') && pathLower.contains('file_tree')) {
          score += 0.5;
        }
        if (chainStr.contains('editor') && pathLower.contains('editor')) {
          score += 0.5;
        }
        if (chainStr.contains('preview') && pathLower.contains('preview')) {
          score += 0.5;
        }
        if (chainStr.contains('terminal') && pathLower.contains('terminal')) {
          score += 0.5;
        }
        if (chainStr.contains('assistant') && pathLower.contains('assistant')) {
          score += 0.5;
        }
      }

      // Boost for UI location hints
      if (uiLocation != null) {
        final locLower = uiLocation.toLowerCase();
        final pathLower = loc.filePath.toLowerCase();

        if (locLower.contains('panel') && pathLower.contains('panel')) {
          score += 0.3;
        }
        if (locLower.contains('screen') && pathLower.contains('screen')) {
          score += 0.3;
        }
      }

      // Prefer class definitions over instantiations
      if (loc.matchType == MatchType.definition) {
        score += 0.3;
      }

      // Prefer files in lib/widgets/ or lib/screens/
      if (loc.filePath.contains('lib/widgets/') ||
          loc.filePath.contains('lib/screens/')) {
        score += 0.2;
      }

      if (score > bestScore) {
        bestScore = score;
        best = loc;
      }
    }

    return best ?? locations.first;
  }

  /// Search for class definitions
  List<WidgetSourceMatch> findClassDefinitions(String className) {
    final results = <WidgetSourceMatch>[];
    final classPattern = RegExp('class\\s+$className\\s+extends');

    for (final entry in _sourceCache.entries) {
      final path = entry.key;
      final content = entry.value;

      for (final match in classPattern.allMatches(content)) {
        final lineNumber = _getLineNumber(content, match.start);
        final column = _getColumn(content, match.start);
        final snippet = _extractSnippet(content, match.start);

        results.add(WidgetSourceMatch(
          filePath: path,
          lineNumber: lineNumber,
          columnNumber: column,
          preciseWidgetCode: snippet,
          confidence: 1.0,
          matchType: MatchType.definition,
        ));
      }
    }

    return results;
  }

  String _normalizePath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  int _getLineNumber(String content, int offset) {
    int line = 1;
    for (int i = 0; i < offset && i < content.length; i++) {
      if (content[i] == '\n') line++;
    }
    return line;
  }

  int _getColumn(String content, int offset) {
    int lastNewline = -1;
    for (int i = 0; i < offset && i < content.length; i++) {
      if (content[i] == '\n') lastNewline = i;
    }
    return offset - lastNewline;
  }

  String _extractSnippet(String content, int offset) {
    int start = offset;
    while (start > 0 && content[start - 1] != '\n') {
      start--;
    }

    int end = offset;
    int count = 0;
    while (end < content.length && content[end] != '\n' && count < 120) {
      end++;
      count++;
    }

    return content.substring(start, end).trim();
  }
}

/// Type of match found in source code
enum MatchType {
  /// Widget class definition (class Foo extends StatelessWidget)
  definition,

  /// Widget instantiation (Foo(...))
  instantiation,

  /// Const widget instantiation (const Foo(...))
  constInstantiation,
}

/// Represents a widget source match with precise code extraction
class WidgetSourceMatch {
  final String filePath;
  final int lineNumber;
  final int columnNumber;
  final String preciseWidgetCode;
  final double confidence;
  final MatchType matchType;

  WidgetSourceMatch({
    required this.filePath,
    required this.lineNumber,
    required this.columnNumber,
    required this.preciseWidgetCode,
    required this.confidence,
    required this.matchType,
  });

  /// Format as file:line:column string
  String get locationString => '$filePath:$lineNumber:$columnNumber';

  /// Get short path (last 2 segments)
  String get shortPath {
    final parts = filePath.split('/');
    if (parts.length > 2) {
      return parts.sublist(parts.length - 2).join('/');
    }
    return filePath;
  }

  /// Whether this is a high confidence match
  bool get isHighConfidence => confidence > 0.8;

  @override
  String toString() => 'WidgetSourceMatch($filePath:$lineNumber, ${preciseWidgetCode.length} chars, ${matchType.name})';
}

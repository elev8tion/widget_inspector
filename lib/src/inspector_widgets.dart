import 'package:flutter/material.dart';
import 'models.dart';

/// Inspector banner shown at the top when inspector is active
class InspectorBanner extends StatelessWidget {
  final VoidCallback onClose;
  final String? exitHint;

  const InspectorBanner({
    super.key,
    required this.onClose,
    this.exitHint = 'ESC to exit',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.purple.shade600],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Widget Inspector Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Click any widget to inspect',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (exitHint != null) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  exitHint!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget path breadcrumb navigation
class WidgetPathBreadcrumb extends StatelessWidget {
  final List<WidgetInfo> path;
  final ValueChanged<WidgetInfo> onSelect;

  const WidgetPathBreadcrumb({
    super.key,
    required this.path,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(Icons.account_tree, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              ...List.generate(path.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  );
                }

                final widgetIndex = index ~/ 2;
                final widget = path[widgetIndex];
                final isLast = widgetIndex == path.length - 1;

                return InkWell(
                  onTap: () => onSelect(widget),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLast ? Colors.blue.shade100 : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.widgetType,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                        color: isLast ? Colors.blue.shade900 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced note panel with rich features
class EnhancedNotePanel extends StatelessWidget {
  final WidgetInfo widget;
  final TextEditingController noteController;
  final NoteAction selectedAction;
  final ValueChanged<NoteAction> onActionChanged;
  final VoidCallback onSendNote;
  final VoidCallback onClose;

  const EnhancedNotePanel({
    super.key,
    required this.widget,
    required this.noteController,
    required this.selectedAction,
    required this.onActionChanged,
    required this.onSendNote,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade300, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.purple.shade700],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Widget Modification Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Tell Claude exactly what you want',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WidgetInfoCard(widget: widget),
                    const SizedBox(height: 16),

                    const Text(
                      'What do you want to do?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _ActionSelector(
                      selectedAction: selectedAction,
                      onChanged: onActionChanged,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Describe your request:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Example: "Change the background color to blue and increase the padding to 16px"',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),

                    const SizedBox(height: 16),

                    _QuickSuggestions(
                      widgetType: widget.widgetType,
                      onSuggestionTap: (suggestion) {
                        noteController.text = suggestion;
                      },
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onSendNote,
                        icon: const Icon(Icons.send, size: 20),
                        label: const Text(
                          'Send to Claude & Copy to Clipboard',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your request will be formatted and copied. Just paste it to Claude!',
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetInfoCard extends StatefulWidget {
  final WidgetInfo widget;

  const _WidgetInfoCard({required this.widget});

  @override
  State<_WidgetInfoCard> createState() => _WidgetInfoCardState();
}

class _WidgetInfoCardState extends State<_WidgetInfoCard> {
  bool _showPreciseCode = false;
  bool _showParentChain = false;
  bool _showProperties = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with widget type and size
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.widget.shortDescription,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              if (!widget.widget.isExactMatch) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(widget.widget.matchConfidence * 100).toInt()}%',
                    style: TextStyle(fontSize: 10, color: Colors.orange.shade800),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${widget.widget.size.width.toInt()} × ${widget.widget.size.height.toInt()}px',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Basic info
          _InfoRow(icon: Icons.location_on, label: 'Location', value: widget.widget.location),
          _InfoRow(icon: Icons.code, label: 'File', value: widget.widget.locationString),
          if (widget.widget.properties.containsKey('text'))
            _InfoRow(icon: Icons.text_fields, label: 'Text', value: widget.widget.properties['text'].toString()),

          // Layout info
          if (widget.widget.layoutInfo != null) ...[
            const SizedBox(height: 4),
            _InfoRow(icon: Icons.view_quilt, label: 'Layout', value: widget.widget.layoutSummary),
          ],

          const SizedBox(height: 8),

          // Expandable toggles
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (widget.widget.hasPreciseCode)
                _ExpandableChip(
                  label: 'Widget Code',
                  icon: Icons.code,
                  isExpanded: _showPreciseCode,
                  onTap: () => setState(() => _showPreciseCode = !_showPreciseCode),
                ),
              if (widget.widget.parentChain.isNotEmpty)
                _ExpandableChip(
                  label: 'Parent Chain (${widget.widget.parentChain.length})',
                  icon: Icons.account_tree,
                  isExpanded: _showParentChain,
                  onTap: () => setState(() => _showParentChain = !_showParentChain),
                ),
              if (widget.widget.properties.isNotEmpty)
                _ExpandableChip(
                  label: 'Properties (${widget.widget.properties.length})',
                  icon: Icons.settings,
                  isExpanded: _showProperties,
                  onTap: () => setState(() => _showProperties = !_showProperties),
                ),
            ],
          ),

          // Expandable sections
          if (_showPreciseCode && widget.widget.hasPreciseCode) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                widget.widget.preciseWidgetCode!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFFD4D4D4),
                  height: 1.4,
                ),
              ),
            ),
          ],

          if (_showParentChain && widget.widget.parentChain.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < widget.widget.parentChain.length; i++)
                    Padding(
                      padding: EdgeInsets.only(left: i * 12.0),
                      child: Row(
                        children: [
                          Icon(
                            i == 0 ? Icons.arrow_right : Icons.subdirectory_arrow_right,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.widget.parentChain[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: i == 0 ? Colors.blue.shade700 : Colors.grey.shade700,
                              fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],

          if (_showProperties && widget.widget.properties.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.widget.properties.entries.map((entry) {
                  final valueStr = entry.value.toString();
                  final displayValue = valueStr.length > 80 ? '${valueStr.substring(0, 80)}...' : valueStr;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key}: ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            displayValue,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandableChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ExpandableChip({
    required this.label,
    required this.icon,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isExpanded ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? Colors.blue.shade400 : Colors.grey.shade400,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isExpanded ? Colors.blue.shade700 : Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isExpanded ? Colors.blue.shade700 : Colors.grey.shade700,
                fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 14,
              color: isExpanded ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSelector extends StatelessWidget {
  final NoteAction selectedAction;
  final ValueChanged<NoteAction> onChanged;

  const _ActionSelector({required this.selectedAction, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: NoteAction.values.map((action) {
        final isSelected = action == selectedAction;
        return ChoiceChip(
          label: Text(
            action.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(action),
          selectedColor: Colors.blue.shade200,
          backgroundColor: Colors.grey.shade100,
        );
      }).toList(),
    );
  }
}

class _QuickSuggestions extends StatelessWidget {
  final String widgetType;
  final ValueChanged<String> onSuggestionTap;

  const _QuickSuggestions({required this.widgetType, required this.onSuggestionTap});

  List<String> _getSuggestions() {
    final suggestions = <String>[];

    if (widgetType.contains('Text') || widgetType.contains('Paragraph')) {
      suggestions.addAll([
        'Change the text color to blue',
        'Increase font size to 16px',
        'Make the text bold',
      ]);
    } else if (widgetType.contains('Button')) {
      suggestions.addAll([
        'Change button color to purple',
        'Add rounded corners',
        'Increase button padding',
      ]);
    } else if (widgetType.contains('Container') || widgetType.contains('Box')) {
      suggestions.addAll([
        'Add background color',
        'Add border radius',
        'Increase padding to 16px',
      ]);
    } else if (widgetType.contains('Icon')) {
      suggestions.addAll([
        'Change icon color',
        'Increase icon size',
        'Use a different icon',
      ]);
    } else if (widgetType.contains('Image')) {
      suggestions.addAll([
        'Add border radius',
        'Add a shadow',
        'Change image fit',
      ]);
    } else {
      suggestions.addAll([
        'Change the styling',
        'Adjust the layout',
        'Remove this widget',
      ]);
    }

    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getSuggestions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick suggestions:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: suggestions.map((suggestion) {
            return InkWell(
              onTap: () => onSuggestionTap(suggestion),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  suggestion,
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

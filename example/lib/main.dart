import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:widget_inspector/widget_inspector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Widget Inspector Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const InspectorDemo(),
    );
  }
}

class InspectorDemo extends StatefulWidget {
  const InspectorDemo({super.key});

  @override
  State<InspectorDemo> createState() => _InspectorDemoState();
}

class _InspectorDemoState extends State<InspectorDemo> {
  final _inspector = InspectorService();

  @override
  void initState() {
    super.initState();
    // Listen for keyboard shortcuts
    HardwareKeyboard.instance.addHandler(_handleKeyPress);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyPress);
    super.dispose();
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Toggle inspector with F2 or Escape
      if (event.logicalKey == LogicalKeyboardKey.f2) {
        _inspector.toggle();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape && _inspector.isActive) {
        _inspector.disable();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Wrap your entire app with InspectorOverlay
    return InspectorOverlay(
      onWidgetSelected: (widget) {
        debugPrint('Selected: ${widget.widgetType}');
      },
      onNoteSent: (note) {
        debugPrint('Note sent: ${note.userNote}');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Widget Inspector Demo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            // Toggle button for inspector
            StreamBuilder<bool>(
              stream: _inspector.activeStream,
              initialData: _inspector.isActive,
              builder: (context, snapshot) {
                final isActive = snapshot.data ?? false;
                return TextButton.icon(
                  onPressed: () => _inspector.toggle(),
                  icon: Icon(
                    isActive ? Icons.search_off : Icons.search,
                    color: isActive ? Colors.orange : Colors.white,
                  ),
                  label: Text(
                    isActive ? 'Exit Inspector' : 'Inspect UI',
                    style: TextStyle(
                      color: isActive ? Colors.orange : Colors.white,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'How to Use',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('1. Click "Inspect UI" button or press F2'),
                      const Text('2. Hover over widgets to highlight them'),
                      const Text('3. Click to select and inspect'),
                      const Text('4. Add a note and copy to clipboard'),
                      const Text('5. Paste to Claude for precise modifications'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sample widgets to inspect
              const Text(
                'Sample Widgets',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Row of buttons
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Primary Button'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outlined Button'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Text Button'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.star, size: 48, color: Colors.amber),
                            const SizedBox(height: 8),
                            const Text(
                              'Feature Card',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Click to inspect this card',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.favorite, size: 48, color: Colors.red),
                            const SizedBox(height: 8),
                            const Text(
                              'Another Card',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'With different styling',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Container with decoration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.gradient, size: 48, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Gradient Container',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Inspect this to see all properties',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Text field
              TextField(
                decoration: InputDecoration(
                  labelText: 'Sample Text Field',
                  hintText: 'Click to inspect this input',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),

              const SizedBox(height: 24),

              // List tiles
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: const Text('John Doe'),
                      subtitle: const Text('Click to inspect ListTile'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.email, color: Colors.white),
                      ),
                      title: const Text('Messages'),
                      subtitle: const Text('3 unread messages'),
                      trailing: const Badge(
                        label: Text('3'),
                        child: Icon(Icons.notifications),
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Chip(label: Text('Flutter')),
                  const Chip(label: Text('Dart')),
                  Chip(
                    avatar: const Icon(Icons.star, size: 18),
                    label: const Text('Featured'),
                    backgroundColor: Colors.amber.shade100,
                  ),
                  ActionChip(
                    label: const Text('Action Chip'),
                    onPressed: () {},
                  ),
                  FilterChip(
                    label: const Text('Filter'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                ],
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _inspector.toggle(),
          icon: const Icon(Icons.search),
          label: const Text('Toggle Inspector'),
        ),
      ),
    );
  }
}

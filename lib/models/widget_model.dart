class WidgetModel {
  final String id;
  final String type;
  double x, y, width, height;
  Map<String, dynamic> properties;
  String? boundTable;
  String? boundField;
  List<WidgetModel> children;
  Map<String, dynamic> state;

  WidgetModel({
    required this.id,
    required this.type,
    this.x = 20,
    this.y = 20,
    this.width = 300,
    this.height = 52,
    this.properties = const {},
    this.boundTable,
    this.boundField,
    this.children = const [],
    this.state = const {},
  });

  factory WidgetModel.fromMap(Map<String, dynamic> m) => WidgetModel(
    id: m['id'],
    type: m['type'],
    x: (m['x'] as num).toDouble(),
    y: (m['y'] as num).toDouble(),
    width: (m['width'] as num).toDouble(),
    height: (m['height'] as num).toDouble(),
    properties: Map<String, dynamic>.from(m['properties'] ?? {}),
    boundTable: m['boundTable'],
    boundField: m['boundField'],
    children:
        (m['children'] as List<dynamic>?)
            ?.map((c) => WidgetModel.fromMap(c as Map<String, dynamic>))
            .toList() ??
        [],
    state: Map<String, dynamic>.from(m['state'] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'properties': properties,
    'boundTable': boundTable,
    'boundField': boundField,
    'children': children.map((c) => c.toMap()).toList(),
    'state': state,
  };

  // ── FIX 1: Removed duplicate keys ('dropdown', 'list', 'grid') from the map
  // literal. Dart silently uses the last value for duplicate keys, which caused
  // the first definitions for those types to be ignored entirely.
  static Map<String, dynamic> defaultPropsFor(String type) =>
      {
        'button': {
          'label': 'Button',
          'color': '#00C896',
          'textColor': '#FFFFFF',
          'fontSize': 16.0,
          'action': 'none',
          'borderRadius': 12.0,
          'actionTable': '',   // table name for addRecord action
          'actionFields': '',  // comma-sep field names to collect
        },
        'text': {
          'content': 'Sample Text',
          'fontSize': 16.0,
          'color': '#000000',
          'bold': false,
          'align': 'left',
        },
        'input': {
          'hint': 'Enter text...',
          'label': 'Field',
          'type': 'text',
          'textColor': '#000000',
          'labelColor': '#000000',
        },
        'image': {'src': '', 'fit': 'cover', 'borderRadius': 8.0},
        'card': {
          'title': 'Card Title',
          'subtitle': 'Subtitle text',
          'titleColor': '#000000',
          'subtitleColor': '#666666',
        },
        'navbar': {
          'activeColor': '#00C896',
          'inactiveColor': '#999999',
          'selectedTabIndex': 0,
          'tabs': [
            {
              'icon': 'home',
              'label': 'Tab 1',
              'navigationEnabled': false,
              'targetScreen': '',
            },
            {
              'icon': 'search',
              'label': 'Tab 2',
              'navigationEnabled': false,
              'targetScreen': '',
            },
            {
              'icon': 'person',
              'label': 'Tab 3',
              'navigationEnabled': false,
              'targetScreen': '',
            },
          ],
        },
        'appbar': {
          'title': 'My App',
          'color': '#00C896',
          'textColor': '#FFFFFF',
        },
        // ── FIX 1a: Single canonical 'dropdown' entry (was duplicated)
        'dropdown': {
          'hint': 'Select...',
          'options': 'Option 1,Option 2,Option 3',
          'color': '#00C896',
          'textColor': '#000000',
        },
        'checkbox': {
          'label': 'Check me',
          'checked': false,
          'color': '#00C896',
          'textColor': '#000000',
        },
        'switch_w': {
          'label': 'Toggle',
          'value': false,
          'color': '#00C896',
          'textColor': '#000000',
        },
        'divider': {'color': '#2E4A5A', 'thickness': 1.0},
        'icon': {
          'name': 'star',
          'color': '#FFD700',
          'size': 40.0,
          'hasBackground': false,
          'backgroundColor': '#FFFFFF',
          'backgroundRadius': 8.0,
          'hasShadow': false,
          'shadowColor': '#000000',
          'shadowBlur': 4.0,
          'opacity': 1.0,
        },
        'form': {
          'fields': 'Name,Email,Phone',
          'submitLabel': 'Submit',
          'textColor': '#000000',
          'labelColor': '#000000',
        },
        'chart': {'type': 'bar', 'color': '#00C896'},
        // ── FIX 1b: Single canonical 'list' entry (was duplicated).
        // Use string for items so the _list() helper in WidgetRenderer parses it.
        'list': {
          'items': 'Item 1,Item 2,Item 3',
          'divider': true,
          'textColor': '#000000',
        },
        // ── FIX 1c: Single canonical 'grid' entry (was duplicated)
        'grid': {
          'columns': 2.0,
          'items': 'Item 1,Item 2,Item 3,Item 4,Item 5,Item 6',
          'crossAxisCount': 2.0,
          'mainAxisSpacing': 8.0,
          'crossAxisSpacing': 8.0,
          'childAspectRatio': 1.2,
          'itemCount': 6.0,
          'scrollEnabled': true,
          'imageUrls': '',
          'textColor': '#000000',
        },
        'checkbox_todo': {
          'items': 'Todo 1,Todo 2,Todo 3',
          'color': '#00C896',
          'textColor': '#000000',
        },
        'container': {
          'label': 'Container',
          'bgColor': '#E8E8E8',
          'borderColor': '#CCCCCC',
          'borderWidth': 1.0,
          'borderRadius': 8.0,
          'width': 200.0,
          'height': 100.0,
          'imageUrl': '',
          'padding': 0.0,
          'marginAll': 0.0,
          'color': '#E8E8E8',
          'textColor': '#000000',
        },
        'todo': {
          'title': 'My Tasks',
          'color': '#00C896',
          'emptyMessage': 'No tasks yet. Add one!',
          'textColor': '#000000',
        },
        'gesture_detector': {
          'label': 'Tap me',
          'bgColor': '#00C896',
          'textColor': '#FFFFFF',
          'borderColor': '#CCCCCC',
          'borderWidth': 1.0,
          'borderRadius': 8.0,
          'fontSize': 14.0,
          'navigationType': 'none',
          'targetScreen': '',
        },
        'row': {
          'mainAxisAlignment': 'start',
          'crossAxisAlignment': 'start',
          'mainAxisSize': 'max',
          'spacing': 4.0,
          'scrollEnabled': false,
        },
        'column': {
          'mainAxisAlignment': 'start',
          'crossAxisAlignment': 'start',
          'mainAxisSize': 'max',
          'spacing': 4.0,
          'scrollEnabled': false,
        },
        'circleavatar': {
          'imageUrl': '',
          'radius': 40.0,
          'backgroundColor': '#00C896',
          'text': 'AB',
          'textColor': '#FFFFFF',
          'fontSize': 18.0,
          'borderColor': '#FFFFFF',
          'borderWidth': 0.0,
          'padding': 0.0,
        },
        'listtile': {
          'title': 'List Item',
          'subtitle': 'Subtitle',
          'leadingType': 'none',
          'leadingImageUrl': '',
          'leadingIcon': 'home',
          'trailingType': 'none',
          'trailingIcon': 'arrow_forward',
          'backgroundColor': '#FFFFFF',
          'textColor': '#000000',
          'subtitleColor': '#666666',
          'padding': 12.0,
          'onTap': 'none',
        },
        'listview': {
          'items': 'Item 1,Item 2,Item 3,Item 4,Item 5',
          'scrollDirection': 'vertical',
          'itemCount': 5.0,
          'spacing': 0.0,
          'padding': 0.0,
          'shrinkWrap': false,
          'scrollEnabled': true,
          'backgroundColor': '#FFFFFF',
        },
        'singlechildscrollview': {
          'scrollDirection': 'vertical',
          'padding': 0.0,
          'scrollEnabled': true,
          'showScrollIndicator': true,
          'physics': 'always',
        },
        'iconbtn': {
          'icon': 'favorite',
          'color': '#00C896',
          'iconColor': '#FFFFFF',
          'action': 'none',
          'actionTable': '',
          'actionFields': '',
        },
        'fab': {
          'icon': 'add',
          'color': '#00C896',
          'action': 'none',
          'actionTable': '',
          'actionFields': '',
        },
      }[type] ??
      {};

  static double defaultHeightFor(String type) =>
      {
        'button': 52.0,
        'text': 40.0,
        'input': 56.0,
        'card': 120.0,
        'image': 180.0,
        'list': 160.0,
        'grid': 200.0,
        'navbar': 64.0,
        'appbar': 56.0,
        'chart': 160.0,
        'form': 200.0,
        'divider': 16.0,
        'dropdown': 56.0,
        'checkbox': 44.0,
        'checkbox_todo': 120.0,
        'switch_w': 44.0,
        'container': 100.0,
        'icon': 64.0,
        'todo': 300.0,
        'gesture_detector': 120.0,
        'row': 120.0,
        'column': 200.0,
        'circleavatar': 100.0,
        'listtile': 72.0,
        'listview': 240.0,
        'singlechildscrollview': 200.0,
        'iconbtn': 56.0,
        'fab': 64.0,
      }[type] ??
      60.0;

  double get safeWidth => (width <= 0) ? 300 : width;
  double get safeHeight => (height <= 0) ? defaultHeightFor(type) : height;
}

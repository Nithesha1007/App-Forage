import '../models/widget_model.dart';
import '../models/screen_model.dart';

/// Service to auto-detect backend field types and names from UI widgets
class AutoBackendDetector {
  /// Detect field type from widget type
  static String detectFieldType(WidgetModel widget) {
    switch (widget.type) {
      case 'input':
        final inputType = widget.properties['type']?.toString() ?? 'text';
        if (inputType == 'email') return 'email';
        if (inputType == 'phone') return 'phone';
        if (inputType == 'number') return 'int';
        return 'string';
      case 'textarea':
        return 'text';
      case 'checkbox':
        return 'boolean';
      case 'switch_w':
        return 'boolean';
      case 'dropdown':
        return 'string';
      case 'datepicker':
        return 'datetime';
      case 'timepicker':
        return 'time';
      default:
        return 'unknown';
    }
  }

  /// Extract field name from widget properties
  static String suggestFieldName(WidgetModel widget) {
    final props = widget.properties;

    // Try to get from label first
    String fieldNameRaw = props['label']?.toString() ?? '';

    // If no label, try hint
    if (fieldNameRaw.isEmpty) {
      fieldNameRaw = props['hint']?.toString() ?? '';
    }

    // If still empty, use widget id as fallback
    if (fieldNameRaw.isEmpty) {
      fieldNameRaw = 'field_${widget.id.substring(0, 8)}';
    }

    // Sanitize: lowercase, replace spaces with underscores, remove special chars
    return fieldNameRaw
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .replaceAll(
          RegExp(r'^_+|_+$'),
          '',
        ); // remove leading/trailing underscores
  }

  /// Analyze input widgets in a screen and suggest entity/table name
  static String suggestTableName(AppScreen screen) {
    final inputWidgets = _findAllInputWidgets(screen.widgets);

    if (inputWidgets.isEmpty) return 'Table';

    // Common field patterns for entity detection
    final allFieldNames = inputWidgets
        .map((w) => suggestFieldName(w).toLowerCase())
        .toList();

    // Pattern 1: Contains user-like fields
    if (_containsPattern(allFieldNames, ['name', 'email', 'phone'])) {
      return 'User';
    }
    if (_containsPattern(allFieldNames, ['first_name', 'last_name', 'email'])) {
      return 'User';
    }

    // Pattern 2: Contains student fields
    if (_containsPattern(allFieldNames, ['roll_number', 'class'])) {
      return 'Student';
    }
    if (_containsPattern(allFieldNames, ['student_id', 'name'])) {
      return 'Student';
    }

    // Pattern 3: Contains order fields
    if (_containsPattern(allFieldNames, ['order_id', 'total', 'status'])) {
      return 'Order';
    }
    if (_containsPattern(allFieldNames, ['customer', 'items', 'amount'])) {
      return 'Order';
    }

    // Pattern 4: Contains customer fields
    if (_containsPattern(allFieldNames, ['customer_name', 'address'])) {
      return 'Customer';
    }

    // Pattern 5: Contains employee fields
    if (_containsPattern(allFieldNames, [
      'employee_id',
      'department',
      'salary',
    ])) {
      return 'Employee';
    }

    // Pattern 6: Contains product fields
    if (_containsPattern(allFieldNames, ['product_name', 'price', 'stock'])) {
      return 'Product';
    }

    // Fallback: capitalize first significant word
    if (allFieldNames.isNotEmpty) {
      final firstField = allFieldNames.first.split('_').first;
      return firstField[0].toUpperCase() + firstField.substring(1);
    }

    return 'Table';
  }

  /// Find all input-type widgets (including nested)
  static List<WidgetModel> _findAllInputWidgets(List<WidgetModel> widgets) {
    final inputs = <WidgetModel>[];

    for (final widget in widgets) {
      // Check if widget is input-type
      if (_isInputType(widget.type)) {
        inputs.add(widget);
      }

      // Recursively check children
      if (widget.children.isNotEmpty) {
        inputs.addAll(_findAllInputWidgets(widget.children));
      }
    }

    return inputs;
  }

  /// Check if widget type is an input widget
  static bool _isInputType(String type) {
    return [
      'input',
      'textarea',
      'checkbox',
      'switch_w',
      'dropdown',
      'datepicker',
      'timepicker',
    ].contains(type);
  }

  /// Check if field names match a pattern
  static bool _containsPattern(List<String> fields, List<String> pattern) {
    for (final p in pattern) {
      if (!fields.any((f) => f.contains(p) || p.contains(f))) {
        return false;
      }
    }
    return true;
  }

  /// Generate suggested backend structure from screen widgets
  static SuggestedBackendStructure generateFromScreen(AppScreen screen) {
    final inputWidgets = _findAllInputWidgets(screen.widgets);
    final tableName = suggestTableName(screen);

    final fields = <String, String>{};
    for (final widget in inputWidgets) {
      final fieldName = suggestFieldName(widget);
      final fieldType = detectFieldType(widget);
      if (fieldName.isNotEmpty && fieldType != 'unknown') {
        fields[fieldName] = fieldType;
      }
    }

    // Add standard fields
    fields.putIfAbsent('id', () => 'string');
    fields.putIfAbsent('created_at', () => 'datetime');
    fields.putIfAbsent('updated_at', () => 'datetime');

    return SuggestedBackendStructure(
      tableName: tableName,
      fields: fields,
      inputWidgets: inputWidgets,
    );
  }

  /// Analyze all screens and suggest multiple tables
  static List<SuggestedBackendStructure> generateFromAllScreens(
    List<AppScreen> screens,
  ) {
    return screens
        .map((screen) => generateFromScreen(screen))
        .where((s) => s.fields.isNotEmpty)
        .toList();
  }
}

/// Class to hold suggested backend structure
class SuggestedBackendStructure {
  final String tableName;
  final Map<String, String> fields; // fieldName -> fieldType
  final List<WidgetModel> inputWidgets;

  SuggestedBackendStructure({
    required this.tableName,
    required this.fields,
    required this.inputWidgets,
  });

  /// Get field names as list (excluding system fields)
  List<String> getFieldNames({bool includeSystem = false}) {
    if (includeSystem) {
      return fields.keys.toList();
    }
    return fields.keys
        .where((f) => !['id', 'created_at', 'updated_at'].contains(f))
        .toList();
  }

  /// Convert to JSON sample
  Map<String, dynamic> toSampleJson() {
    final json = <String, dynamic>{};
    for (final entry in fields.entries) {
      json[entry.key] = _sampleValueForType(entry.value);
    }
    return json;
  }

  static dynamic _sampleValueForType(String type) {
    switch (type) {
      case 'string':
        return '';
      case 'email':
        return 'user@example.com';
      case 'phone':
        return '+1234567890';
      case 'int':
        return 0;
      case 'double':
        return 0.0;
      case 'boolean':
        return false;
      case 'datetime':
        return DateTime.now().toIso8601String();
      case 'date':
        return DateTime.now().toIso8601String().split('T').first;
      case 'time':
        return '00:00:00';
      case 'text':
        return '';
      default:
        return null;
    }
  }
}

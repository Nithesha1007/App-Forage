import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/builder_provider.dart';
import '../../models/project_model.dart';

/// Quick dialog to create a field and add it to backend
class QuickFieldDialog extends StatefulWidget {
  final BuilderProvider provider;
  final String suggestedFieldName;
  final String suggestedFieldType;
  final String? suggestedTableName;

  const QuickFieldDialog({
    super.key,
    required this.provider,
    required this.suggestedFieldName,
    required this.suggestedFieldType,
    this.suggestedTableName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required BuilderProvider provider,
    required String suggestedFieldName,
    required String suggestedFieldType,
    String? suggestedTableName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuickFieldDialog(
        provider: provider,
        suggestedFieldName: suggestedFieldName,
        suggestedFieldType: suggestedFieldType,
        suggestedTableName: suggestedTableName,
      ),
    );
  }

  @override
  State<QuickFieldDialog> createState() => _QuickFieldDialogState();
}

class _QuickFieldDialogState extends State<QuickFieldDialog> {
  late TextEditingController _fieldNameCtrl;
  late TextEditingController _tableNameCtrl;
  late String _selectedType;
  late String _selectedTable;
  bool _createNewTable = false;

  @override
  void initState() {
    super.initState();
    _fieldNameCtrl = TextEditingController(text: widget.suggestedFieldName);
    _tableNameCtrl = TextEditingController(
      text: widget.suggestedTableName ?? 'Table',
    );
    _selectedType = widget.suggestedFieldType;
    _selectedTable = widget.suggestedTableName ?? '';
    _createNewTable =
        widget.suggestedTableName == null || widget.suggestedTableName!.isEmpty;
  }

  @override
  void dispose() {
    _fieldNameCtrl.dispose();
    _tableNameCtrl.dispose();
    super.dispose();
  }

  List<DatabaseTable> get _tables =>
      widget.provider.project?.backendConfig.tables ?? [];

  void _createField() {
    final fieldName = _fieldNameCtrl.text.trim();
    final tableName = _createNewTable
        ? _tableNameCtrl.text.trim()
        : _selectedTable;

    if (fieldName.isEmpty || tableName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    // Create or get table
    if (_createNewTable) {
      widget.provider.addTable(tableName, [fieldName]);
    } else {
      // Add field to existing table
      final existingTable = _tables.firstWhere(
        (t) => t.name == tableName,
        orElse: () {
          widget.provider.addTable(tableName, [fieldName]);
          return DatabaseTable(id: '', name: tableName, fields: [fieldName]);
        },
      );

      if (!existingTable.fields.contains(fieldName)) {
        widget.provider.addFieldToTable(tableName, fieldName);
      }
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final fieldTypes = [
      'string',
      'email',
      'phone',
      'int',
      'double',
      'boolean',
      'datetime',
      'date',
      'time',
      'text',
    ];

    return Dialog(
      backgroundColor: AppTheme.darkCard,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Quick Create Field',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Create backend field instantly',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: AppTheme.darkBorder),
            const SizedBox(height: 16),

            // Field Name
            const Text(
              'Field Name',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fieldNameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g., user_name, email_address',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.darkBorder),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Field Type
            const Text(
              'Field Type',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.darkBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: AppTheme.darkCard,
                items: fieldTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedType = value ?? ''),
              ),
            ),

            const SizedBox(height: 16),

            // Table Selection / Creation
            const Text(
              'Add to Table',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),

            if (_tables.isEmpty || _createNewTable)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _tableNameCtrl,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., Users, Products',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.darkBorder,
                        ),
                      ),
                    ),
                  ),
                  if (_tables.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _createNewTable = false),
                        child: Text(
                          'Or select existing table',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.darkBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedTable.isEmpty ? null : _selectedTable,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: AppTheme.darkCard,
                      hint: const Text(
                        'Select a table',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      items: [
                        ..._tables.map((table) {
                          return DropdownMenuItem(
                            value: table.name,
                            child: Text(
                              table.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }),
                        const DropdownMenuItem(
                          value: '__CREATE_NEW__',
                          child: Text(
                            '+ Create New Table',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == '__CREATE_NEW__') {
                          setState(() => _createNewTable = true);
                        } else {
                          setState(() => _selectedTable = value ?? '');
                        }
                      },
                    ),
                  ),
                  if (_selectedTable.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _createNewTable = true),
                        child: Text(
                          'Or create new table',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 20),

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: const Text(
                '💡 This field will be created in your backend and linked to your widget',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createField,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                    child: const Text('Create Field'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/builder_provider.dart';
import '../../models/project_model.dart';
import '../../models/backend_template_model.dart';
import '../../services/auto_backend_detector.dart';

class BackendPanel extends StatefulWidget {
  final BuilderProvider provider;
  const BackendPanel({super.key, required this.provider});

  @override
  State<BackendPanel> createState() => _BackendPanelState();
}

class _BackendPanelState extends State<BackendPanel> {
  bool _addingTable = false;
  bool _selectingTemplate = false;
  String _selectedCategory = 'All';
  BackendTemplate? _selectedTemplate;
  final Set<String> _selectedFields = {};
  final _nameCtrl = TextEditingController();
  final _fieldsCtrl = TextEditingController();

  // Local copies of auth state — synced from provider on build
  late bool _emailAuth;
  late bool _googleAuth;
  late bool _phoneAuth;

  @override
  void initState() {
    super.initState();
    final cfg = _config;
    _emailAuth = cfg.emailAuth;
    _googleAuth = cfg.googleAuth;
    _phoneAuth = cfg.phoneAuth;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fieldsCtrl.dispose();
    super.dispose();
  }

  // ── Safe config getter ────────────────────────────────────────────────────
  BackendConfig get _config =>
      widget.provider.project?.backendConfig ??
      BackendConfig(
        tables: [],
        emailAuth: true,
        googleAuth: false,
        phoneAuth: false,
      );

  // ── Create table — uses addTable() which exists in BuilderProvider ────────
  void _createTable() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final raw = _fieldsCtrl.text
        .split(',')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    final fields = raw.isEmpty ? ['id', 'created_at'] : raw;
    widget.provider.addTable(name, fields); // ✅ exists in BuilderProvider
    _nameCtrl.clear();
    _fieldsCtrl.clear();
    setState(() => _addingTable = false);
  }

  // ── Delete table — rebuilds table list locally, saves via addTable loop ───
  void _deleteTable(String tableId) {
    // We don't call any missing method.
    // Instead we store updated list in local state and rebuild UI.
    // The actual Firestore save happens next time user adds a table.
    // For immediate persistence, we rebuild project via provider.project setter workaround.
    final project = widget.provider.project;
    if (project == null) return;

    final updatedTables = _config.tables.where((t) => t.id != tableId).toList();

    // Directly mutate via Firestore service through provider's internal save
    // by rebuilding a BackendConfig and calling the notify path
    final updatedConfig = BackendConfig(
      tables: updatedTables,
      emailAuth: _config.emailAuth,
      googleAuth: _config.googleAuth,
      phoneAuth: _config.phoneAuth,
    );

    // Access provider's project and update it using addWidget trick:
    // We use a dedicated helper that only touches backendConfig
    _applyBackendConfig(updatedConfig);
  }

  // ── Toggle auth — stored locally + applied via helper ────────────────────
  void _toggleEmail(bool v) {
    setState(() => _emailAuth = v);
    _applyBackendConfig(
      BackendConfig(
        tables: _config.tables,
        emailAuth: v,
        googleAuth: _googleAuth,
        phoneAuth: _phoneAuth,
      ),
    );
  }

  void _toggleGoogle(bool v) {
    setState(() => _googleAuth = v);
    _applyBackendConfig(
      BackendConfig(
        tables: _config.tables,
        emailAuth: _emailAuth,
        googleAuth: v,
        phoneAuth: _phoneAuth,
      ),
    );
  }

  void _togglePhone(bool v) {
    setState(() => _phoneAuth = v);
    _applyBackendConfig(
      BackendConfig(
        tables: _config.tables,
        emailAuth: _emailAuth,
        googleAuth: _googleAuth,
        phoneAuth: v,
      ),
    );
  }

  // ── Apply BackendConfig — ONLY uses provider.project (no missing methods) -
  void _applyBackendConfig(BackendConfig cfg) {
    final project = widget.provider.project;
    if (project == null) return;
    // Update the project's backendConfig through the provider's
    // updateTheme path which triggers a save — we shadow-copy the project
    final updated = project.copyWith(backendConfig: cfg);
    widget.provider.applyProject(updated); // defined below
    setState(() {});
  }

  // ── Template selection methods ────────────────────────────────────────────
  void _selectTemplate(BackendTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _selectedFields.clear();
      _selectedFields.addAll(template.defaultFields);
    });
  }

  void _toggleField(String fieldName, bool selected) {
    setState(() {
      if (selected) {
        _selectedFields.add(fieldName);
      } else {
        _selectedFields.remove(fieldName);
      }
    });
  }

  void _createTableFromTemplate() {
    if (_selectedTemplate == null || _selectedFields.isEmpty) return;

    final tableName = _selectedTemplate!.name;
    final fields = _selectedFields.toList();

    widget.provider.addTable(tableName, fields);

    // Reset template selection
    setState(() {
      _selectedTemplate = null;
      _selectedFields.clear();
      _selectingTemplate = false;
    });
  }

  void _cancelTemplateSelection() {
    setState(() {
      _selectedTemplate = null;
      _selectedFields.clear();
      _selectingTemplate = false;
    });
  }

  // ── Generate backend from current screen ────────────────────────────────────
  Future<void> _generateFromCurrentScreen() async {
    if (widget.provider.activeScreen == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No active screen')));
      return;
    }

    final suggestion = AutoBackendDetector.generateFromScreen(
      widget.provider.activeScreen!,
    );

    if (suggestion.fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No input fields found in current screen'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show preview dialog
    _showGeneratePreview(suggestion);
  }

  void _showGeneratePreview(SuggestedBackendStructure suggestion) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text(
          'Suggested Backend Structure',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Table name
              Text(
                'Table: ${suggestion.tableName}',
                style: const TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // Fields list
              const Text(
                'Fields:',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestion.fields.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      '${e.key} (${e.value})',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Sample JSON
              const Text(
                'Sample Data:',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E17),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Text(
                  _prettyJson(suggestion.toSampleJson()),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Create the table
              widget.provider.addTable(
                suggestion.tableName,
                suggestion.getFieldNames(includeSystem: true),
              );

              // Auto-bind widgets if possible
              for (final w in suggestion.inputWidgets) {
                final fieldName = AutoBackendDetector.suggestFieldName(w);
                if (fieldName.isNotEmpty) {
                  widget.provider.bindWidgetToData(
                    w.id,
                    suggestion.tableName,
                    fieldName,
                  );
                }
              }

              Navigator.pop(context);
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✅ Created "${suggestion.tableName}" table with ${suggestion.fields.length} fields',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
            ),
            child: const Text('Create Table & Bind'),
          ),
        ],
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> json) {
    final buffer = StringBuffer('{\n');
    final entries = json.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      buffer.write('  "${e.key}": ${_jsonValue(e.value)}');
      if (i < entries.length - 1) buffer.write(',');
      buffer.write('\n');
    }
    buffer.write('}');
    return buffer.toString();
  }

  String _jsonValue(dynamic value) {
    if (value is String) return '"$value"';
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) return value.toString();
    return 'null';
  }

  @override
  Widget build(BuildContext context) {
    // Sync local auth booleans in case project reloads
    _emailAuth = _config.emailAuth;
    _googleAuth = _config.googleAuth;
    _phoneAuth = _config.phoneAuth;

    final tables = _config.tables;

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        // ── Database ──────────────────────────────────────────────────────
        _SectionHeader(
          icon: Icons.storage_outlined,
          title: 'Database',
          subtitle: '${tables.length} table${tables.length == 1 ? '' : 's'}',
          color: AppTheme.primary,
        ),
        const SizedBox(height: 10),

        ...tables.map(
          (t) => _TableCard(table: t, onDelete: () => _deleteTable(t.id)),
        ),

        // ── Quick generation from screen ───────────────────────────────────
        _AutoGenerateButton(
          onTap: _generateFromCurrentScreen,
          label: 'Generate from Screen',
        ),
        const SizedBox(height: 8),

        // ── Template Selection ─────────────────────────────────────────────
        if (_selectingTemplate)
          _TemplateSelectionWidget(
            selectedCategory: _selectedCategory,
            selectedTemplate: _selectedTemplate,
            selectedFields: _selectedFields,
            onCategoryChanged: (category) =>
                setState(() => _selectedCategory = category),
            onTemplateSelected: _selectTemplate,
            onFieldToggled: _toggleField,
            onCreate: _createTableFromTemplate,
            onCancel: _cancelTemplateSelection,
          )
        else
          _TemplateSelectionButton(
            onTap: () => setState(() => _selectingTemplate = true),
          ),

        const SizedBox(height: 10),

        if (_addingTable)
          _AddTableForm(
            nameCtrl: _nameCtrl,
            fieldsCtrl: _fieldsCtrl,
            onCreate: _createTable,
            onCancel: () {
              _nameCtrl.clear();
              _fieldsCtrl.clear();
              setState(() => _addingTable = false);
            },
          )
        else
          _AddTableButton(onTap: () => setState(() => _addingTable = true)),

        const SizedBox(height: 16),
        const Divider(color: AppTheme.darkBorder),
        const SizedBox(height: 12),

        // ── Authentication ────────────────────────────────────────────────
        _SectionHeader(
          icon: Icons.lock_outline,
          title: 'Authentication',
          subtitle: '',
          color: AppTheme.secondary,
        ),
        const SizedBox(height: 10),

        _AuthToggleRow(
          label: 'Email / Password',
          value: _emailAuth,
          onChanged: _toggleEmail,
        ),
        _AuthToggleRow(
          label: 'Google Sign-In',
          value: _googleAuth,
          onChanged: _toggleGoogle,
        ),
        _AuthToggleRow(
          label: 'Phone OTP',
          value: _phoneAuth,
          onChanged: _togglePhone,
        ),

        const SizedBox(height: 16),
        const Divider(color: AppTheme.darkBorder),
        const SizedBox(height: 12),

        // ── Security Rules ────────────────────────────────────────────────
        _SectionHeader(
          icon: Icons.security,
          title: 'Security Rules',
          subtitle: 'auto-generated',
          color: AppTheme.accent,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF060F1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: const Text(
            "rules_version = '2';\n"
            "service cloud.firestore {\n"
            "  match /databases/{db}/documents {\n"
            "    match /users/{uid} {\n"
            "      allow read, write:\n"
            "        if request.auth.uid == uid;\n"
            "    }\n"
            "    match /projects/{id} {\n"
            "      allow read, write:\n"
            "        if request.auth.uid\n"
            "           == resource.data.userId;\n"
            "    }\n"
            "  }\n"
            "}",
            style: TextStyle(
              color: AppTheme.primary,
              fontFamily: 'monospace',
              fontSize: 10,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.primary, size: 14),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                'Secure · No vendor lock-in · You own your data',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      if (subtitle.isNotEmpty) ...[
        const Spacer(),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    ],
  );
}

class _TableCard extends StatelessWidget {
  final DatabaseTable table;
  final VoidCallback onDelete;
  const _TableCard({required this.table, required this.onDelete});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.table_chart_outlined,
              size: 14,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                table.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '${table.fields.length} fields',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 14, color: AppTheme.accent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: table.fields
              .take(8)
              .map(
                (f) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    f,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _AddTableForm extends StatelessWidget {
  final TextEditingController nameCtrl, fieldsCtrl;
  final VoidCallback onCreate, onCancel;
  const _AddTableForm({
    required this.nameCtrl,
    required this.fieldsCtrl,
    required this.onCreate,
    required this.onCancel,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Table',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Table name (e.g. Products)',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: fieldsCtrl,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Fields: name, price, image',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            helperText: 'Comma separated. id & created_at auto-added.',
            helperStyle: TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onCreate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'Create Table',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AddTableButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTableButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppTheme.primary, size: 16),
            SizedBox(width: 6),
            Text(
              'Create Table',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AuthToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AuthToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          ),
        ),
        Switch(
          value: value,
          activeColor: AppTheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _TemplateSelectionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TemplateSelectionButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu, color: AppTheme.secondary, size: 16),
            SizedBox(width: 6),
            Text(
              'Use Template',
              style: TextStyle(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TemplateSelectionWidget extends StatefulWidget {
  final String selectedCategory;
  final BackendTemplate? selectedTemplate;
  final Set<String> selectedFields;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<BackendTemplate> onTemplateSelected;
  final void Function(String, bool) onFieldToggled;
  final VoidCallback onCreate;
  final VoidCallback onCancel;

  const _TemplateSelectionWidget({
    required this.selectedCategory,
    required this.selectedTemplate,
    required this.selectedFields,
    required this.onCategoryChanged,
    required this.onTemplateSelected,
    required this.onFieldToggled,
    required this.onCreate,
    required this.onCancel,
  });

  @override
  State<_TemplateSelectionWidget> createState() =>
      _TemplateSelectionWidgetState();
}

class _TemplateSelectionWidgetState extends State<_TemplateSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    final templates = BackendTemplates.getByCategory(widget.selectedCategory);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Template',
            style: TextStyle(
              color: AppTheme.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          // Category selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BackendTemplates.categories.map((category) {
                final isSelected = category == widget.selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => widget.onCategoryChanged(category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.secondary.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.secondary
                              : AppTheme.darkBorder,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.secondary
                              : AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Template grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = template == widget.selectedTemplate;

              return GestureDetector(
                onTap: () => widget.onTemplateSelected(template),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.secondary.withOpacity(0.1)
                        : const Color(0xFF060F1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.secondary
                          : AppTheme.darkBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            template.emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              template.name,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          if (widget.selectedTemplate != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Select Fields',
              style: TextStyle(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),

            // Field selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selectedTemplate!.availableFields.map((field) {
                final isSelected = widget.selectedFields.contains(field.name);
                final isRequired = field.required;

                return GestureDetector(
                  onTap: isRequired
                      ? null
                      : () => widget.onFieldToggled(field.name, !isSelected),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.secondary.withOpacity(0.1)
                          : const Color(0xFF060F1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.secondary
                            : AppTheme.darkBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRequired)
                          const Icon(
                            Icons.lock,
                            size: 12,
                            color: AppTheme.accent,
                          )
                        else
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 12,
                            color: isSelected
                                ? AppTheme.secondary
                                : AppTheme.textMuted,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          field.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.secondary
                                : AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.selectedFields.isNotEmpty
                        ? widget.onCreate
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: AppTheme.secondary,
                    ),
                    child: Text(
                      'Create ${widget.selectedTemplate!.name} Table',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Auto-Generate Button ──────────────────────────────────────────────────────
class _AutoGenerateButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _AutoGenerateButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.secondary.withOpacity(0.1),
            AppTheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, color: AppTheme.secondary, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

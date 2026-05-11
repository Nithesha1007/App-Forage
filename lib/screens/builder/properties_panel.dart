import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/project_model.dart';
import '../../models/widget_model.dart';
import '../../providers/builder_provider.dart';
import 'child_management_panel.dart';

// ── FIX 15: PropertiesPanel now takes the BuilderProvider directly so it can
// call updateWidgetSize() for width/height changes in addition to the existing
// updateWidgetProperty() for all other fields.
class PropertiesPanel extends StatelessWidget {
  final WidgetModel widget;
  final BuilderProvider provider; // added
  final Function(String key, dynamic value) onPropertyChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onBindData;
  final VoidCallback onDeselect;

  const PropertiesPanel({
    super.key,
    required this.widget,
    required this.provider,
    required this.onPropertyChanged,
    required this.onDelete,
    required this.onDuplicate,
    required this.onBindData,
    required this.onDeselect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(left: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Properties',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.type,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDeselect,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.darkBorder, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data binding badge
                  if (widget.boundTable != null &&
                      widget.boundTable!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '🔗 ${widget.boundTable}.${widget.boundField}',
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── FIX 16: Width & Height size controls appear for every
                  // widget type, immediately above the widget-specific fields.
                  _SizeControls(widget: widget, provider: provider),
                  const SizedBox(height: 4),

                  // Dynamic widget-specific fields
                  ..._buildFields(),

                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.darkBorder),
                  const SizedBox(height: 12),

                  const Text(
                    'ACTIONS',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  // const SizedBox(height: 8),
                  // _ActionBtn(
                  //   Icons.link,
                  //   'Bind to Database',
                  //   AppTheme.secondary,
                  //   onBindData,
                  // ),
                  const SizedBox(height: 6),
                  _ActionBtn(
                    Icons.copy,
                    'Duplicate Widget',
                    AppTheme.textMuted,
                    onDuplicate,
                  ),
                  const SizedBox(height: 6),
                  _ActionBtn(
                    Icons.delete_outline,
                    'Delete Widget',
                    AppTheme.accent,
                    onDelete,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFields() {
    final fields = <Widget>[];

    void add(
      String label,
      String key, {
      String type = 'text',
      List<String>? options,
      double? min,
      double? max,
    }) {
      fields.add(
        _PropRow(
          label: label,
          value: widget.properties[key],
          type: type,
          options: options,
          min: min,
          max: max,
          onChanged: (v) => onPropertyChanged(key, v),
        ),
      );
      fields.add(const SizedBox(height: 12));
    }

    switch (widget.type) {
      case 'button':
        add('Label', 'label');
        add('Background', 'color', type: 'color');
        add('Text Color', 'textColor', type: 'color');
        add('Font Size', 'fontSize', type: 'slider', min: 10, max: 32);
        add('Border Radius', 'borderRadius', type: 'slider', min: 0, max: 32);
        add(
          'On Tap',
          'action',
          type: 'select',
          options: ['none', 'navigate', 'submit', 'open_url', 'addRecord'],
        );
        if (widget.properties['action'] == 'addRecord') {
          final tables = provider.project?.backendConfig.tables ?? [];
          if (tables.isEmpty) {
            fields.add(
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: const Text(
                  '⚠️ No tables yet. Create one in the Backend panel first.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ),
            );
            fields.add(const SizedBox(height: 12));
          } else {
            final tableNames = tables.map((t) => t.name).toList();
            add(
              'Target Table',
              'actionTable',
              type: 'select',
              options: tableNames,
            );
            final selectedName =
                widget.properties['actionTable']?.toString() ??
                tableNames.first;
            final DatabaseTable selectedTable = tables.firstWhere(
              (t) => t.name == selectedName,
              orElse: () => tables.first,
            );
            final fieldOptions = selectedTable.fields
                .where((f) => !['id', 'created_at', 'updated_at'].contains(f))
                .toList();
            if (fieldOptions.isNotEmpty) {
              final selectedFields =
                  (widget.properties['actionFields']?.toString() ?? '')
                      .split(',')
                      .map((f) => f.trim())
                      .where((f) => f.isNotEmpty)
                      .toSet();
              fields.add(
                _FieldChipSelector(
                  allFields: fieldOptions,
                  selectedFields: selectedFields,
                  onChanged: (updated) =>
                      onPropertyChanged('actionFields', updated.join(',')),
                ),
              );
              fields.add(const SizedBox(height: 12));
            }
          }
        }
        break;
      case 'text':
        add('Content', 'content');
        add('Color', 'color', type: 'color');
        add('Font Size', 'fontSize', type: 'slider', min: 10, max: 48);
        add('Bold', 'bold', type: 'select', options: ['false', 'true']);
        add(
          'Alignment',
          'align',
          type: 'select',
          options: ['left', 'center', 'right'],
        );
        break;
      case 'input':
        add('Placeholder', 'hint');
        add('Label', 'label');
        add(
          'Type',
          'type',
          type: 'select',
          options: ['text', 'email', 'password', 'number', 'phone'],
        );
        break;
      case 'image':
        add('Image URL', 'src');
        add('Border Radius', 'borderRadius', type: 'slider', min: 0, max: 32);
        add(
          'Fit',
          'fit',
          type: 'select',
          options: ['cover', 'contain', 'fill'],
        );
        break;
      case 'card':
        add('Title', 'title');
        add('Subtitle', 'subtitle');
        add('Elevation', 'elevation', type: 'slider', min: 0, max: 16);
        break;
      case 'appbar':
        add('Title', 'title');
        add('Background', 'color', type: 'color');
        add(
          'Show Back Button',
          'showBack',
          type: 'select',
          options: ['false', 'true'],
        );
        break;
      case 'navbar':
        // Custom UI for Bottom Nav tabs configuration
        fields.add(
          _BottomNavConfigPanel(
            widget: widget,
            provider: provider,
            onPropertyChanged: onPropertyChanged,
          ),
        );
        break;
      case 'icon':
        add(
          'Icon',
          'name',
          type: 'select',
          options: [
            'star',
            'heart',
            'home',
            'search',
            'settings',
            'user',
            'menu',
            'close',
            'add',
            'delete',
            'edit',
            'share',
            'like',
            'notifications',
            'email',
            'phone',
            'location',
            'calendar',
            'clock',
            'arrow_back',
          ],
        );
        add('Color', 'color', type: 'color');
        add('Size', 'size', type: 'slider', min: 16, max: 80);
        add('Opacity', 'opacity', type: 'slider', min: 0, max: 1);
        add(
          'Background',
          'hasBackground',
          type: 'select',
          options: ['false', 'true'],
        );
        add('Background Color', 'backgroundColor', type: 'color');
        add(
          'Background Radius',
          'backgroundRadius',
          type: 'slider',
          min: 0,
          max: 20,
        );
        add('Shadow', 'hasShadow', type: 'select', options: ['false', 'true']);
        add('Shadow Blur', 'shadowBlur', type: 'slider', min: 0, max: 20);
        break;
      case 'form':
        add('Fields (comma sep)', 'fields');
        add('Submit Label', 'submitLabel');
        add('Submit Color', 'color', type: 'color');
        break;
      case 'checkbox':
        add('Label', 'label');
        add('Color', 'color', type: 'color');
        add('Checked', 'checked', type: 'select', options: ['false', 'true']);
        break;
      case 'switch_w':
        add('Label', 'label');
        add('Active Color', 'color', type: 'color');
        add('Value', 'value', type: 'select', options: ['false', 'true']);
        break;
      case 'dropdown':
        add('Hint', 'hint');
        add('Options (comma sep)', 'options');
        add('Color', 'color', type: 'color');
        break;
      case 'list':
        add('Items (comma sep)', 'items');
        add(
          'Show Divider',
          'divider',
          type: 'select',
          options: ['true', 'false'],
        );
        break;
      case 'grid':
        add(
          'Columns (Cross Axis)',
          'crossAxisCount',
          type: 'slider',
          min: 1,
          max: 6,
        );
        add(
          'Main Axis Spacing',
          'mainAxisSpacing',
          type: 'slider',
          min: 0,
          max: 32,
        );
        add(
          'Cross Axis Spacing',
          'crossAxisSpacing',
          type: 'slider',
          min: 0,
          max: 32,
        );
        add(
          'Child Aspect Ratio',
          'childAspectRatio',
          type: 'slider',
          min: 0.5,
          max: 3.0,
        );
        add('Item Count', 'itemCount', type: 'slider', min: 1, max: 20);
        add('Items (comma sep)', 'items');
        add('Image URLs (comma sep)', 'imageUrls');
        add(
          'Scroll Enabled',
          'scrollEnabled',
          type: 'select',
          options: ['true', 'false'],
        );
        break;
      case 'chart':
        add(
          'Chart Type',
          'type',
          type: 'select',
          options: ['line', 'bar', 'pie', 'area'],
        );
        add('Color', 'color', type: 'color');
        break;
      case 'container':
        add('Background Color', 'bgColor', type: 'color');
        add('Border Color', 'borderColor', type: 'color');
        add('Border Width', 'borderWidth', type: 'slider', min: 0, max: 8);
        add('Border Radius', 'borderRadius', type: 'slider', min: 0, max: 32);
        add('Image URL', 'imageUrl');
        add('Padding', 'padding', type: 'slider', min: 0, max: 32);
        add('Margin', 'marginAll', type: 'slider', min: 0, max: 32);
        break;
      case 'divider':
        add('Color', 'color', type: 'color');
        add('Thickness', 'thickness', type: 'slider', min: 1, max: 8);
        break;
      case 'todo':
        add('Title', 'title');
        add('Accent Color', 'color', type: 'color');
        add('Empty Message', 'emptyMessage');
        break;
      case 'dialog':
        add('Title', 'title');
        add('Body', 'body');
        add('Buttons (comma sep)', 'buttons');
        break;
      case 'gesture_detector':
        add('Label', 'label');
        add('Background Color', 'bgColor', type: 'color');
        add('Border Color', 'borderColor', type: 'color');
        add('Border Width', 'borderWidth', type: 'slider', min: 0, max: 4);
        add('Border Radius', 'borderRadius', type: 'slider', min: 0, max: 32);
        add('Text Color', 'textColor', type: 'color');
        add('Font Size', 'fontSize', type: 'slider', min: 10, max: 32);
        add(
          'Navigation Type',
          'navigationType',
          type: 'select',
          options: ['none', 'switchScreen'],
        );
        // Build dynamic screen list for targetScreen dropdown (store screen ID)
        final availableScreens = provider.project?.screens ?? [];
        final screenOptions = availableScreens
            .map((s) => '${s.name}:${s.id}')
            .toList();
        if (screenOptions.isNotEmpty) {
          add(
            'Target Screen',
            'targetScreen',
            type: 'select',
            options: screenOptions,
          );
        }
        break;
      case 'row':
      case 'column':
        add(
          'Main Axis Alignment',
          'mainAxisAlignment',
          type: 'select',
          options: [
            'start',
            'center',
            'end',
            'spaceBetween',
            'spaceAround',
            'spaceEvenly',
          ],
        );
        add(
          'Cross Axis Alignment',
          'crossAxisAlignment',
          type: 'select',
          options: ['start', 'center', 'end', 'stretch'],
        );
        add(
          'Main Axis Size',
          'mainAxisSize',
          type: 'select',
          options: ['min', 'max'],
        );
        add('Spacing', 'spacing', type: 'slider', min: 0, max: 32);
        add(
          'Scroll Enabled',
          'scrollEnabled',
          type: 'select',
          options: ['false', 'true'],
        );
        // Add child management panel
        fields.add(const SizedBox(height: 16));
        fields.add(ChildManagementPanel(widget: widget, provider: provider));
        break;
      case 'circleavatar':
        add('Image URL', 'imageUrl');
        add('Radius', 'radius', type: 'slider', min: 20, max: 100);
        add('Background Color', 'backgroundColor', type: 'color');
        add('Text', 'text');
        add('Text Color', 'textColor', type: 'color');
        add('Font Size', 'fontSize', type: 'slider', min: 12, max: 32);
        add('Border Color', 'borderColor', type: 'color');
        add('Border Width', 'borderWidth', type: 'slider', min: 0, max: 4);
        break;
      case 'listtile':
        add('Title', 'title');
        add('Subtitle', 'subtitle');
        add(
          'Leading Type',
          'leadingType',
          type: 'select',
          options: ['none', 'icon', 'image', 'avatar'],
        );
        add(
          'Leading Icon',
          'leadingIcon',
          type: 'select',
          options: [
            'home',
            'search',
            'settings',
            'user',
            'delete',
            'edit',
            'star',
            'favorite',
            'share',
            'info',
          ],
        );
        add('Leading Image URL', 'leadingImageUrl');
        add(
          'Trailing Type',
          'trailingType',
          type: 'select',
          options: ['none', 'icon', 'switch', 'checkbox'],
        );
        add(
          'Trailing Icon',
          'trailingIcon',
          type: 'select',
          options: [
            'arrow_forward',
            'more_vert',
            'delete',
            'edit',
            'favorite',
            'share',
            'info',
          ],
        );
        add('Background Color', 'backgroundColor', type: 'color');
        add('Text Color', 'textColor', type: 'color');
        add('Subtitle Color', 'subtitleColor', type: 'color');
        add('Padding', 'padding', type: 'slider', min: 0, max: 24);
        break;
      case 'listview':
        // Source table binding — sets boundTable so the installed app streams
        // records from Firestore for that collection automatically.
        final lvTables = provider.project?.backendConfig.tables ?? [];
        fields.add(
          _SourceTableRow(
            currentTable: widget.boundTable ?? '',
            tables: lvTables,
            onChanged: (tableName) =>
                provider.bindWidgetToData(widget.id, tableName, ''),
            onClear: () => provider.bindWidgetToData(widget.id, '', ''),
          ),
        );
        fields.add(const SizedBox(height: 12));
        add('Items (comma sep)', 'items');
        add(
          'Scroll Direction',
          'scrollDirection',
          type: 'select',
          options: ['vertical', 'horizontal'],
        );
        add('Spacing', 'spacing', type: 'slider', min: 0, max: 16);
        add('Padding', 'padding', type: 'slider', min: 0, max: 24);
        add(
          'Scroll Enabled',
          'scrollEnabled',
          type: 'select',
          options: ['false', 'true'],
        );
        add('Background Color', 'backgroundColor', type: 'color');
        break;
      case 'singlechildscrollview':
        add(
          'Scroll Direction',
          'scrollDirection',
          type: 'select',
          options: ['vertical', 'horizontal'],
        );
        add('Padding', 'padding', type: 'slider', min: 0, max: 32);
        add(
          'Scroll Enabled',
          'scrollEnabled',
          type: 'select',
          options: ['false', 'true'],
        );
        // Add child management panel - only ONE child allowed
        fields.add(const SizedBox(height: 16));
        fields.add(ChildManagementPanel(widget: widget, provider: provider));
        break;
      case 'iconbtn':
        fields.add(
          _IconPickerRow(
            label: 'ICON',
            value: widget.properties['icon']?.toString() ?? 'favorite',
            onChanged: (v) => onPropertyChanged('icon', v),
          ),
        );
        fields.add(const SizedBox(height: 12));
        add('Background Color', 'color', type: 'color');
        add('Icon Color', 'iconColor', type: 'color');
        add(
          'On Tap',
          'action',
          type: 'select',
          options: ['none', 'navigate', 'submit', 'open_url', 'addRecord'],
        );
        if (widget.properties['action'] == 'addRecord') {
          final tables = provider.project?.backendConfig.tables ?? [];
          if (tables.isEmpty) {
            fields.add(
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: const Text(
                  '⚠️ No tables yet. Create one in the Backend panel first.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ),
            );
            fields.add(const SizedBox(height: 12));
          } else {
            final tableNames = tables.map((t) => t.name).toList();
            add(
              'Target Table',
              'actionTable',
              type: 'select',
              options: tableNames,
            );
            final selectedName =
                widget.properties['actionTable']?.toString() ??
                tableNames.first;
            final DatabaseTable selectedTable = tables.firstWhere(
              (t) => t.name == selectedName,
              orElse: () => tables.first,
            );
            final fieldOptions = selectedTable.fields
                .where((f) => !['id', 'created_at', 'updated_at'].contains(f))
                .toList();
            if (fieldOptions.isNotEmpty) {
              final selectedFields =
                  (widget.properties['actionFields']?.toString() ?? '')
                      .split(',')
                      .map((f) => f.trim())
                      .where((f) => f.isNotEmpty)
                      .toSet();
              fields.add(
                _FieldChipSelector(
                  allFields: fieldOptions,
                  selectedFields: selectedFields,
                  onChanged: (updated) =>
                      onPropertyChanged('actionFields', updated.join(',')),
                ),
              );
              fields.add(const SizedBox(height: 12));
            }
          }
        }
        break;

      case 'fab':
        fields.add(
          _IconPickerRow(
            label: 'ICON',
            value: widget.properties['icon']?.toString() ?? 'add',
            onChanged: (v) => onPropertyChanged('icon', v),
          ),
        );
        fields.add(const SizedBox(height: 12));
        add('Background Color', 'color', type: 'color');
        add(
          'On Tap',
          'action',
          type: 'select',
          options: ['none', 'navigate', 'submit', 'open_url', 'addRecord'],
        );
        if (widget.properties['action'] == 'addRecord') {
          final tables = provider.project?.backendConfig.tables ?? [];
          if (tables.isEmpty) {
            fields.add(
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: const Text(
                  '⚠️ No tables yet. Create one in the Backend panel first.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ),
            );
            fields.add(const SizedBox(height: 12));
          } else {
            final tableNames = tables.map((t) => t.name).toList();
            add(
              'Target Table',
              'actionTable',
              type: 'select',
              options: tableNames,
            );
            final selectedName =
                widget.properties['actionTable']?.toString() ??
                tableNames.first;
            final DatabaseTable selectedTable = tables.firstWhere(
              (t) => t.name == selectedName,
              orElse: () => tables.first,
            );
            final fieldOptions = selectedTable.fields
                .where((f) => !['id', 'created_at', 'updated_at'].contains(f))
                .toList();
            if (fieldOptions.isNotEmpty) {
              final selectedFields =
                  (widget.properties['actionFields']?.toString() ?? '')
                      .split(',')
                      .map((f) => f.trim())
                      .where((f) => f.isNotEmpty)
                      .toSet();
              fields.add(
                _FieldChipSelector(
                  allFields: fieldOptions,
                  selectedFields: selectedFields,
                  onChanged: (updated) =>
                      onPropertyChanged('actionFields', updated.join(',')),
                ),
              );
              fields.add(const SizedBox(height: 12));
            }
          }
        }
        break;

      default:
        add('Label', 'label');
        add('Color', 'color', type: 'color');
    }

    return fields;
  }

  Widget _ActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 16 — Width & Height size controls (always visible in panel)
// ══════════════════════════════════════════════════════════════════════════════
class _SizeControls extends StatefulWidget {
  final WidgetModel widget;
  final BuilderProvider provider;
  const _SizeControls({required this.widget, required this.provider});

  @override
  State<_SizeControls> createState() => _SizeControlsState();
}

class _SizeControlsState extends State<_SizeControls> {
  late TextEditingController _wCtrl;
  late TextEditingController _hCtrl;

  @override
  void initState() {
    super.initState();
    _wCtrl = TextEditingController(
      text: widget.widget.safeWidth.toInt().toString(),
    );
    _hCtrl = TextEditingController(
      text: widget.widget.safeHeight.toInt().toString(),
    );
  }

  @override
  void didUpdateWidget(_SizeControls old) {
    super.didUpdateWidget(old);
    // Refresh when a different widget is selected
    if (old.widget.id != widget.widget.id) {
      _wCtrl.text = widget.widget.safeWidth.toInt().toString();
      _hCtrl.text = widget.widget.safeHeight.toInt().toString();
    }
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  void _commit() {
    final w = double.tryParse(_wCtrl.text) ?? widget.widget.safeWidth;
    final h = double.tryParse(_hCtrl.text) ?? widget.widget.safeHeight;
    widget.provider.updateWidgetSize(widget.widget.id, w, h);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SIZE',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _SizeField(
                label: 'W',
                controller: _wCtrl,
                onSubmitted: _commit,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SizeField(
                label: 'H',
                controller: _hCtrl,
                onSubmitted: _commit,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: AppTheme.darkBorder, height: 1),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SizeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  const _SizeField({
    required this.label,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      onFieldSubmitted: (_) => onSubmitted(),
      onEditingComplete: onSubmitted,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
      decoration: InputDecoration(
        prefixText: '$label  ',
        prefixStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}

// ── Single property row ───────────────────────────────────────────────────────
class _PropRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final String type;
  final List<String>? options;
  final double? min, max;
  final Function(dynamic) onChanged;

  const _PropRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.type = 'text',
    this.options,
    this.min,
    this.max,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 5),
      _buildControl(context),
    ],
  );

  Widget _buildControl(BuildContext context) {
    switch (type) {
      case 'color':
        final hex = value is String ? value as String : '#00C896';
        Color c;
        try {
          c = Color(int.parse(hex.replaceAll('#', '0xFF')));
        } catch (_) {
          c = AppTheme.primary;
        }
        return Row(
          children: [
            GestureDetector(
              onTap: () => _showColorPicker(context, c),
              child: Container(
                width: 36,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: hex,
                onChanged: onChanged,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ],
        );

      case 'slider':
        final double sliderMin = min ?? 0;
        final double sliderMax = max ?? 100;
        final double v = (value is num ? (value as num).toDouble() : sliderMin)
            .clamp(sliderMin, sliderMax);
        return Row(
          children: [
            Expanded(
              child: Slider(
                value: v,
                min: sliderMin,
                max: sliderMax,
                activeColor: AppTheme.primary,
                inactiveColor: AppTheme.darkBorder,
                onChanged: (double newVal) => onChanged(newVal),
              ),
            ),
            SizedBox(
              width: 28,
              child: Text(
                v.toInt().toString(),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        );

      case 'select':
        final String v = value?.toString() ?? '';
        final List<String> allOpts = options ?? [];
        final bool isValid = allOpts.contains(v);
        final String safeVal = isValid
            ? v
            : (allOpts.isNotEmpty ? allOpts.first : v);

        // When the stored value is missing/invalid, the dropdown auto-corrects
        // to the first option visually — but never saves it. Schedule a write
        // so the persisted value matches what the user actually sees.
        if (!isValid && allOpts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => onChanged(safeVal),
          );
        }

        return DropdownButtonFormField<String>(
          value: safeVal.isEmpty ? null : safeVal,
          items: allOpts.map((o) {
            final displayText = o.contains(':') ? o.split(':').first.trim() : o;
            return DropdownMenuItem(
              value: o,
              child: Text(
                displayText,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          dropdownColor: AppTheme.darkCard,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        );

      default:
        return TextFormField(
          initialValue: value?.toString() ?? '',
          onChanged: onChanged,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        );
    }
  }

  void _showColorPicker(BuildContext context, Color current) {
    const palette = [
      '#00C896',
      '#6C63FF',
      '#FF6B6B',
      '#FF6B35',
      '#3498DB',
      '#E74C3C',
      '#F39C12',
      '#8E44AD',
      '#2ECC71',
      '#1ABC9C',
      '#34495E',
      '#2C3E50',
      '#FFFFFF',
      '#F5F5F5',
      '#333333',
      '#000000',
    ];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text(
          'Pick a Color',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        ),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: palette.map((hex) {
            final c = Color(int.parse(hex.replaceAll('#', '0xFF')));
            return GestureDetector(
              onTap: () {
                onChanged(hex);
                Navigator.pop(context);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: c == current ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Bottom Nav Configuration Panel
// Allows users to configure tabs dynamically with custom icons, labels, and navigation
// ══════════════════════════════════════════════════════════════════════════════
class _BottomNavConfigPanel extends StatefulWidget {
  final WidgetModel widget;
  final BuilderProvider provider;
  final Function(String key, dynamic value) onPropertyChanged;

  const _BottomNavConfigPanel({
    required this.widget,
    required this.provider,
    required this.onPropertyChanged,
  });

  @override
  State<_BottomNavConfigPanel> createState() => _BottomNavConfigPanelState();
}

class _BottomNavConfigPanelState extends State<_BottomNavConfigPanel> {
  late List<Map<String, dynamic>> _tabs;
  late String _activeColor;
  late String _inactiveColor;
  int _expandedTabIndex = -1;

  /// Get list of available screen IDs from the current project
  List<String> _getAvailableScreenIds() {
    final screens = widget.provider.project?.screens ?? [];
    return screens.map((s) => s.id).toList();
  }

  /// Get screen name for a given screen ID
  String _getScreenName(String screenId) {
    final screens = widget.provider.project?.screens ?? [];
    final screen = screens.firstWhere(
      (s) => s.id == screenId,
      orElse: () =>
          screens.isNotEmpty ? screens.first : throw Exception('No screens'),
    );
    return screen.name;
  }

  @override
  void initState() {
    super.initState();
    _initializeFromProps();
  }

  @override
  void didUpdateWidget(_BottomNavConfigPanel old) {
    super.didUpdateWidget(old);
    if (old.widget.properties != widget.widget.properties) {
      _initializeFromProps();
    }
  }

  void _initializeFromProps() {
    final props = widget.widget.properties;
    _activeColor = props['activeColor']?.toString() ?? '#00C896';
    _inactiveColor = props['inactiveColor']?.toString() ?? '#999999';

    final tabsList = props['tabs'];
    if (tabsList is List && tabsList.isNotEmpty) {
      _tabs = List<Map<String, dynamic>>.from(
        tabsList.map((t) => Map<String, dynamic>.from(t as Map)),
      );
    } else {
      _tabs = [
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
      ];
    }
  }

  void _updateTab(int index, String key, dynamic value) {
    final updated = List<Map<String, dynamic>>.from(_tabs);
    updated[index] = {...updated[index], key: value};
    setState(() => _tabs = updated);
    widget.onPropertyChanged('tabs', updated);
  }

  /// Add a new tab with default values
  void _addTab() {
    final newTabIndex = _tabs.length;
    final newTab = {
      'icon': 'apps',
      'label': 'Tab ${newTabIndex + 1}',
      'navigationEnabled': false,
      'targetScreen': '',
    };
    final updated = List<Map<String, dynamic>>.from(_tabs)..add(newTab);
    setState(() {
      _tabs = updated;
      _expandedTabIndex = newTabIndex; // Auto-expand the new tab
    });
    widget.onPropertyChanged('tabs', updated);
    debugPrint('✅ Added new tab: Tab ${newTabIndex + 1}');
  }

  /// Remove a tab at the specified index
  void _removeTab(int index) {
    if (_tabs.length <= 1) {
      // Prevent removing the last tab (minimum 1 tab required)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove the last tab'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }
    final updated = List<Map<String, dynamic>>.from(_tabs)..removeAt(index);
    setState(() {
      _tabs = updated;
      // Adjust selected tab if needed
      if (_expandedTabIndex >= _tabs.length) {
        _expandedTabIndex = _tabs.length - 1;
      }
    });
    widget.onPropertyChanged('tabs', updated);
    debugPrint('✅ Removed tab at index $index');
  }

  @override
  Widget build(BuildContext context) {
    const iconList = [
      'home',
      'search',
      'cart',
      'person',
      'profile',
      'settings',
      'favorite',
      'notifications',
      'mail',
      'email',
      'phone',
      'location',
      'calendar',
      'clock',
      'menu',
      'star',
      'heart',
      'apps',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colors section
        Text(
          'COLORS'.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () =>
                        _showColorPicker(context, _activeColor, (color) {
                          setState(() => _activeColor = color);
                          widget.onPropertyChanged('activeColor', color);
                        }),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: _parseColor(_activeColor),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INACTIVE',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () =>
                        _showColorPicker(context, _inactiveColor, (color) {
                          setState(() => _inactiveColor = color);
                          widget.onPropertyChanged('inactiveColor', color);
                        }),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: _parseColor(_inactiveColor),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: AppTheme.darkBorder),
        const SizedBox(height: 12),

        // Tabs configuration
        Text(
          'TABS CONFIGURATION'.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ..._tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isExpanded = _expandedTabIndex == index;

          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isExpanded ? AppTheme.darkBg : Colors.transparent,
                  border: Border.all(color: AppTheme.darkBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: InkWell(
                  onTap: () => setState(
                    () => _expandedTabIndex = isExpanded ? -1 : index,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TAB ${index + 1}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${tab['label']?.toString() ?? ''} • ${tab['icon']?.toString() ?? ''}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: AppTheme.textMuted,
                              size: 18,
                            ),
                            if (_tabs.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: GestureDetector(
                                  onTap: () => _removeTab(index),
                                  child: const Icon(
                                    Icons.close,
                                    color: Color(0xFFFF6B6B),
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isExpanded)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBg,
                    border: Border.all(color: AppTheme.darkBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon selector
                      const Text(
                        'ICON',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: tab['icon']?.toString() ?? 'home',
                        items: iconList.map((icon) {
                          return DropdownMenuItem(
                            value: icon,
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) _updateTab(index, 'icon', value);
                        },
                        dropdownColor: AppTheme.darkCard,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Label input
                      const Text(
                        'LABEL',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue:
                            tab['label']?.toString() ?? 'Tab ${index + 1}',
                        onChanged: (value) => _updateTab(index, 'label', value),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          hintText: 'Tab label',
                          hintStyle: TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Enable navigation toggle
                      const Text(
                        'ENABLE NAVIGATION',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Transform.scale(
                        scale: 0.8,
                        alignment: Alignment.centerLeft,
                        child: Switch(
                          value:
                              tab['navigationEnabled'] == true ||
                              tab['navigationEnabled'] == 'true',
                          onChanged: (value) =>
                              _updateTab(index, 'navigationEnabled', value),
                          activeColor: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Target screen (conditional on navigation enabled)
                      if (tab['navigationEnabled'] == true ||
                          tab['navigationEnabled'] == 'true') ...[
                        const Text(
                          'TARGET SCREEN',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // ── FIX 16: Dropdown for screen selection instead of text input
                        // Get list of available screens from current project
                        Builder(
                          builder: (context) {
                            final screenIds = _getAvailableScreenIds();
                            // Clean targetScreen: extract ID from "name:id" format or convert safely
                            String rawValue =
                                tab['targetScreen']?.toString() ?? '';
                            final currentTargetScreen = rawValue.contains(':')
                                ? rawValue.split(':').last.trim()
                                : rawValue;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (screenIds.isEmpty)
                                  const Text(
                                    'No screens available. Create screens first.',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 9,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                else
                                  SizedBox(
                                    width: double.maxFinite,
                                    child: DropdownButtonFormField<String>(
                                      value:
                                          currentTargetScreen.isNotEmpty &&
                                              screenIds.contains(
                                                currentTargetScreen,
                                              )
                                          ? currentTargetScreen
                                          : null,
                                      items: screenIds.map((screenId) {
                                        try {
                                          final screenName = _getScreenName(
                                            screenId,
                                          );
                                          return DropdownMenuItem(
                                            value: screenId,
                                            child: Text(
                                              screenName,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        } catch (_) {
                                          return DropdownMenuItem(
                                            value: screenId,
                                            child: Text(
                                              screenId,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }
                                      }).toList(),
                                      selectedItemBuilder: (context) {
                                        return screenIds.map((screenId) {
                                          try {
                                            final screenName = _getScreenName(
                                              screenId,
                                            );
                                            return Text(
                                              screenName,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          } catch (_) {
                                            return Text(
                                              screenId,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          }
                                        }).toList();
                                      },
                                      onChanged: (value) {
                                        if (value != null) {
                                          _updateTab(
                                            index,
                                            'targetScreen',
                                            value,
                                          );
                                          debugPrint(
                                            '✅ Selected screen: $value for tab ${index + 1}',
                                          );
                                        }
                                      },
                                      dropdownColor: AppTheme.darkCard,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 11,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        hintText: 'Select a screen',
                                        hintStyle: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
        const SizedBox(height: 12),
        // ── Add Tab Button
        SizedBox(
          width: double.maxFinite,
          child: OutlinedButton.icon(
            onPressed: _addTab,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Tab'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  void _showColorPicker(
    BuildContext context,
    String currentHex,
    Function(String) onColorSelected,
  ) {
    const palette = [
      '#00C896',
      '#6C63FF',
      '#FF6B6B',
      '#FF6B35',
      '#3498DB',
      '#E74C3C',
      '#F39C12',
      '#8E44AD',
      '#2ECC71',
      '#1ABC9C',
      '#34495E',
      '#2C3E50',
      '#FFFFFF',
      '#F5F5F5',
      '#333333',
      '#000000',
      '#999999',
      '#CCCCCC',
      '#16A085',
      '#27AE60',
      '#C0392B',
    ];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text(
          'Pick a Color',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: palette.map((hex) {
            final c = Color(int.parse(hex.replaceAll('#', '0xFF')));
            return GestureDetector(
              onTap: () {
                onColorSelected(hex);
                Navigator.pop(context);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: currentHex == hex
                        ? Colors.white
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ── Source table selector for listview ───────────────────────────────────────
class _SourceTableRow extends StatelessWidget {
  final String currentTable;
  final List<DatabaseTable> tables;
  final void Function(String tableName) onChanged;
  final VoidCallback onClear;

  const _SourceTableRow({
    required this.currentTable,
    required this.tables,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'SOURCE TABLE',
        style: TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 5),
      if (tables.isEmpty)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
          ),
          child: const Text(
            'No tables yet — create one in the Backend panel',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        )
      else
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: currentTable.isEmpty ? null : currentTable,
                hint: const Text(
                  'None (use static items)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 8,
                  ),
                ),
                items: tables.map((t) {
                  return DropdownMenuItem(value: t.name, child: Text(t.name));
                }).toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
            if (currentTable.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppTheme.accent),
                onPressed: onClear,
                tooltip: 'Remove binding',
              ),
          ],
        ),
      if (currentTable.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              const Icon(Icons.link, size: 12, color: AppTheme.secondary),
              const SizedBox(width: 4),
              SizedBox(
                width: 180,
                child: Text(
                  'Will show records from "$currentTable" in installed app',
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

// ── Field chip selector for addRecord button config ───────────────────────────
class _FieldChipSelector extends StatelessWidget {
  final List<String> allFields;
  final Set<String> selectedFields;
  final void Function(List<String>) onChanged;

  const _FieldChipSelector({
    required this.allFields,
    required this.selectedFields,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'FIELDS TO COLLECT',
        style: TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: allFields.map((f) {
          final isSelected = selectedFields.contains(f);
          return GestureDetector(
            onTap: () {
              final updated = Set<String>.from(selectedFields);
              if (isSelected) {
                updated.remove(f);
              } else {
                updated.add(f);
              }
              onChanged(updated.toList());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.darkBorder,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

// ── Icon picker: text input + quick-pick chips ────────────────────────────────
class _IconPickerRow extends StatefulWidget {
  final String label;
  final String value;
  final void Function(String) onChanged;

  const _IconPickerRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_IconPickerRow> createState() => _IconPickerRowState();
}

class _IconPickerRowState extends State<_IconPickerRow> {
  static const _icons = [
    ('favorite', Icons.favorite),
    ('add', Icons.add),
    ('home', Icons.home),
    ('search', Icons.search),
    ('settings', Icons.settings),
    ('person', Icons.person),
    ('edit', Icons.edit),
    ('delete', Icons.delete),
    ('share', Icons.share),
    ('notifications', Icons.notifications),
    ('email', Icons.email),
    ('phone', Icons.phone),
    ('location_on', Icons.location_on),
    ('calendar_today', Icons.calendar_today),
    ('check', Icons.check),
    ('close', Icons.close),
    ('arrow_back', Icons.arrow_back),
    ('arrow_forward', Icons.arrow_forward),
    ('send', Icons.send),
    ('download', Icons.download),
    ('upload', Icons.upload),
    ('camera_alt', Icons.camera_alt),
    ('lock', Icons.lock),
    ('star', Icons.star),
    ('info', Icons.info),
    ('refresh', Icons.refresh),
    ('thumb_up', Icons.thumb_up),
    ('menu', Icons.menu),
    ('more_vert', Icons.more_vert),
    ('check_circle', Icons.check_circle),
  ];

  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_IconPickerRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.value.toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: _ctrl,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          decoration: const InputDecoration(
            hintText: 'e.g. favorite, add, home…',
            hintStyle: TextStyle(fontSize: 11),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          onChanged: (v) => widget.onChanged(v.trim().toLowerCase()),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _icons.length,
            separatorBuilder: (_, _i) => const SizedBox(width: 4),
            itemBuilder: (context, i) {
              final (name, iconData) = _icons[i];
              final selected = current == name;
              return GestureDetector(
                onTap: () {
                  widget.onChanged(name);
                  _ctrl.text = name;
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withOpacity(0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.darkBorder,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    iconData,
                    size: 16,
                    color: selected ? AppTheme.primary : AppTheme.textMuted,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

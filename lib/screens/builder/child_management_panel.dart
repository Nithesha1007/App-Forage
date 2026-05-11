import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/widget_model.dart';
import '../../providers/builder_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Child Management Panel for Row, Column & SingleChildScrollView
// Allows adding/removing/configuring child widgets
// ══════════════════════════════════════════════════════════════════════════════
class ChildManagementPanel extends StatelessWidget {
  final WidgetModel widget;
  final BuilderProvider provider;

  const ChildManagementPanel({required this.widget, required this.provider});

  static const _availableChildTypes = [
    'text',
    'button',
    'input',
    'image',
    'icon',
    'container',
    'card',
    'divider',
  ];

  /// Check if this is a single-child container (vs multi-child like row/column)
  bool get _isSingleChild => widget.type == 'singlechildscrollview';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          _isSingleChild ? 'CHILD (Single)' : 'CHILDREN',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),

        // Add child button (disable if single-child and already has one)
        SizedBox(
          width: double.infinity,
          child: PopupMenuButton<String>(
            enabled: !_isSingleChild || widget.children.isEmpty,
            onSelected: (type) {
              provider.addChildWidget(widget.id, type);
            },
            itemBuilder: (context) => _availableChildTypes
                .map(
                  (type) => PopupMenuItem<String>(
                    value: type,
                    child: Text(
                      type[0].toUpperCase() + type.substring(1),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: (_isSingleChild && widget.children.isNotEmpty)
                    ? AppTheme.primary.withOpacity(0.05)
                    : AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_isSingleChild && widget.children.isNotEmpty)
                      ? AppTheme.primary.withOpacity(0.15)
                      : AppTheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    size: 16,
                    color: (_isSingleChild && widget.children.isNotEmpty)
                        ? AppTheme.textMuted
                        : AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isSingleChild ? 'Set Child' : 'Add Child',
                    style: TextStyle(
                      color: (_isSingleChild && widget.children.isNotEmpty)
                          ? AppTheme.textMuted
                          : AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Children list
        if (widget.children.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Text(
              _isSingleChild
                  ? 'Add a child to scroll.'
                  : 'No children yet. Add one!',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.children.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final child = widget.children[i];
              return _ChildItem(
                child: child,
                parentId: widget.id,
                provider: provider,
                index: i,
              );
            },
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Individual Child Widget Item in the list
// ══════════════════════════════════════════════════════════════════════════════
class _ChildItem extends StatefulWidget {
  final WidgetModel child;
  final String parentId;
  final BuilderProvider provider;
  final int index;

  const _ChildItem({
    required this.child,
    required this.parentId,
    required this.provider,
    required this.index,
  });

  @override
  State<_ChildItem> createState() => _ChildItemState();
}

class _ChildItemState extends State<_ChildItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.index + 1}. ${widget.child.type.toUpperCase()}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    onPressed: () {
                      widget.provider.removeChildWidget(
                        widget.parentId,
                        widget.child.id,
                      );
                    },
                    color: AppTheme.accent,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_expanded) ...[
            const Divider(color: AppTheme.darkBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Size controls
                  const Text(
                    'Size',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _SizeField(
                          label: 'W',
                          value: widget.child.width.toInt(),
                          onChanged: (v) {
                            widget.provider.updateChildSize(
                              widget.parentId,
                              widget.child.id,
                              v.toDouble(),
                              widget.child.height,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SizeField(
                          label: 'H',
                          value: widget.child.height.toInt(),
                          onChanged: (v) {
                            widget.provider.updateChildSize(
                              widget.parentId,
                              widget.child.id,
                              widget.child.width,
                              v.toDouble(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Size Field for Child Widgets
// ══════════════════════════════════════════════════════════════════════════════
class _SizeField extends StatefulWidget {
  final String label;
  final int value;
  final Function(int) onChanged;

  const _SizeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SizeField> createState() => _SizeFieldState();
}

class _SizeFieldState extends State<_SizeField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_SizeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final num = int.tryParse(v) ?? widget.value;
        widget.onChanged(num);
      },
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
      decoration: InputDecoration(
        prefix: Text(
          '${widget.label}:',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppTheme.darkBorder),
        ),
      ),
    );
  }
}

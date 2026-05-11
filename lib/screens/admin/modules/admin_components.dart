import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/admin_service.dart';
import '../admin_dashboard.dart';

class AdminComponents extends StatelessWidget {
  final AdminService service;
  const AdminComponents({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'UI Components',
            action: ElevatedButton.icon(
              onPressed: () => _showDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Component'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                textStyle: const TextStyle(fontSize: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.streamComponents(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                final comps = snap.data!;
                if (comps.isEmpty) {
                  return const Center(
                    child: Text(
                      'No components yet',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: comps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _CompRow(comp: comps[i], service: service),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, {Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final typeCtrl = TextEditingController(
      text: existing?['type']?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existing == null ? 'New Component' : 'Edit Component',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Field(ctrl: nameCtrl, hint: 'Component name (e.g. Button)'),
            const SizedBox(height: 10),
            _Field(ctrl: typeCtrl, hint: 'Type (e.g. basic, layout, form)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final data = {
                'name': nameCtrl.text.trim(),
                'type': typeCtrl.text.trim(),
              };
              if (existing != null) {
                service.updateComponent(existing['id'], data);
              } else {
                service.createComponent(data);
              }
              Navigator.pop(context);
            },
            child: Text(existing == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }
}

/// Simple text field widget for admin dialogs
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;

  const _Field({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted),
      filled: true,
      fillColor: AppTheme.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    ),
  );
}

class _CompRow extends StatelessWidget {
  final Map<String, dynamic> comp;
  final AdminService service;
  const _CompRow({required this.comp, required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.widgets_rounded,
              color: Colors.orangeAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comp['name']?.toString() ?? 'Unknown',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Type: ${comp['type']?.toString() ?? '—'}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showEditDialog(context),
                child: _iconBtn(Icons.edit_outlined, Colors.blueAccent),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => service.deleteComponent(comp['id']),
                child: _iconBtn(Icons.delete_outline, Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Icon(icon, color: color, size: 14),
  );

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(
      text: comp['name']?.toString() ?? '',
    );
    final typeCtrl = TextEditingController(
      text: comp['type']?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text(
          'Edit Component',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Field(ctrl: nameCtrl, hint: 'Component name'),
            const SizedBox(height: 10),
            _Field(ctrl: typeCtrl, hint: 'Type'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              service.updateComponent(comp['id'], {
                'name': nameCtrl.text.trim(),
                'type': typeCtrl.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

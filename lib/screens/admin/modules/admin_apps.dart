import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/admin_service.dart';
import '../admin_dashboard.dart';

class AdminApps extends StatefulWidget {
  final AdminService service;
  const AdminApps({super.key, required this.service});

  @override
  State<AdminApps> createState() => _AdminAppsState();
}

class _AdminAppsState extends State<AdminApps> {
  String _filter = 'all'; // all | pending | approved | rejected

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(title: 'App Management'),

          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  [
                    'all',
                    'draft',
                    'pending',
                    'approved',
                    'rejected',
                    'published',
                  ].map((f) {
                    final active = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.primary : AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? AppTheme.primary
                                : AppTheme.darkBorder,
                          ),
                        ),
                        child: Text(
                          f[0].toUpperCase() + f.substring(1),
                          style: TextStyle(
                            color: active ? Colors.white : AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.service.streamAllApps(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                var apps = snap.data ?? [];
                if (_filter != 'all') {
                  apps = apps
                      .where((a) => a['status']?.toString() == _filter)
                      .toList();
                }
                if (apps.isEmpty) {
                  return const Center(
                    child: Text(
                      'No apps found',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: apps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _AppRow(app: apps[i], service: widget.service),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  final Map<String, dynamic> app;
  final AdminService service;
  const _AppRow({required this.app, required this.service});

  @override
  Widget build(BuildContext context) {
    final id = app['id']?.toString() ?? '';
    final name = app['name']?.toString() ?? 'Unnamed';
    final userId = app['userId']?.toString() ?? '';
    final status = app['status']?.toString() ?? 'draft';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              color: Colors.blueAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Owner: ${userId.length > 12 ? userId.substring(0, 12) : userId}...',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status),
          const SizedBox(width: 8),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == 'pending') ...[
                _ActionBtn(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  tooltip: 'Approve',
                  onTap: () => service.approveApp(id),
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.cancel_outlined,
                  color: Colors.orangeAccent,
                  tooltip: 'Reject',
                  onTap: () => service.rejectApp(id),
                ),
                const SizedBox(width: 4),
              ],
              _ActionBtn(
                icon: Icons.delete_outline,
                color: Colors.redAccent,
                tooltip: 'Delete',
                onTap: () async {
                  final ok = await _confirm(context, name);
                  if (ok) service.deleteApp(id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String appName) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          title: const Text(
            'Delete App?',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: Text(
            'Delete "$appName" permanently?',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    ),
  );
}

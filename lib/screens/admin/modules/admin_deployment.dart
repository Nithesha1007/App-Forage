import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/admin_service.dart';
import '../admin_dashboard.dart';

class AdminDeployment extends StatelessWidget {
  final AdminService service;
  const AdminDeployment({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(title: 'Deployment Management'),

          // Summary cards
          Row(
            children: [
              Expanded(
                child: AdminStatCard(
                  label: 'Live Apps',
                  value: '—',
                  icon: Icons.rocket_launch_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Pending Deploy',
                  value: '—',
                  icon: Icons.pending_rounded,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Failed',
                  value: '—',
                  icon: Icons.error_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'Recent Deployments',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.streamDeployments(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                final deps = snap.data!;
                if (deps.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.rocket_launch_outlined,
                          color: AppTheme.textMuted,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No deployments yet',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Apps published by users appear here',
                          style: TextStyle(
                            color: AppTheme.textMuted.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: deps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _DeployRow(dep: deps[i], service: service),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DeployRow extends StatelessWidget {
  final Map<String, dynamic> dep;
  final AdminService service;
  const _DeployRow({required this.dep, required this.service});

  @override
  Widget build(BuildContext context) {
    final id = dep['id']?.toString() ?? '';
    final name = dep['appName']?.toString() ?? 'App';
    final status = dep['status']?.toString() ?? 'pending';
    final url = dep['url']?.toString() ?? '';

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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.green,
              size: 18,
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
                if (url.isNotEmpty)
                  Text(
                    url,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          StatusBadge(status),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            color: AppTheme.darkCard,
            icon: const Icon(
              Icons.more_vert,
              size: 18,
              color: AppTheme.textMuted,
            ),
            onSelected: (s) => service.updateDeploymentStatus(id, s),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'live',
                child: Text('Set Live', style: TextStyle(color: Colors.green)),
              ),
              const PopupMenuItem(
                value: 'suspended',
                child: Text('Suspend', style: TextStyle(color: Colors.orange)),
              ),
              const PopupMenuItem(
                value: 'offline',
                child: Text(
                  'Take Offline',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

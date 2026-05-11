import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/admin_service.dart';
import '../admin_dashboard.dart';

class AdminOverview extends StatelessWidget {
  final AdminService service;
  const AdminOverview({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        await service.getAnalytics();
      },
      child: SingleChildScrollView(
        // ✅ always scrollable so RefreshIndicator works
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats grid ───────────────────────────────────────────────
            const _SectionLabel('Live Statistics'),
            FutureBuilder<Map<String, dynamic>>(
              future: service.getAnalytics(),
              builder: (_, snap) {
                final d = snap.data ?? {};
                final loading = !snap.hasData;
                return _StatsGrid(d: d, loading: loading);
              },
            ),

            const SizedBox(height: 24),

            // ── Quick actions ────────────────────────────────────────────
            const _SectionLabel('Quick Actions'),
            _QuickActionsGrid(),

            const SizedBox(height: 24),

            // ── Recent activity ──────────────────────────────────────────
            const _SectionLabel('Recent Apps'),
            _RecentActivity(service: service),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Stats 2×3 grid ────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> d;
  final bool loading;
  const _StatsGrid({required this.d, required this.loading});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatData(
        'Total Users',
        loading ? '—' : '${d['totalUsers'] ?? 0}',
        Icons.people_rounded,
        AppTheme.primary,
        'All registered',
      ),
      _StatData(
        'Total Apps',
        loading ? '—' : '${d['totalApps'] ?? 0}',
        Icons.apps_rounded,
        Colors.blueAccent,
        'Created projects',
      ),
      _StatData(
        'Published',
        loading ? '—' : '${d['publishedApps'] ?? 0}',
        Icons.rocket_launch_rounded,
        Colors.green,
        'Live apps',
      ),
      _StatData(
        'Active (7d)',
        loading ? '—' : '${d['activeUsers'] ?? 0}',
        Icons.online_prediction_rounded,
        Colors.orangeAccent,
        'Last 7 days',
      ),
      _StatData(
        'Admins',
        loading ? '—' : '${d['adminCount'] ?? 0}',
        Icons.shield_rounded,
        Colors.purpleAccent,
        'With admin role',
      ),
      _StatData(
        'Platform',
        'Live',
        Icons.check_circle_rounded,
        Colors.green,
        'All systems normal',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        // ✅ Fixed aspect ratio — prevents overflow
        childAspectRatio: 1.75,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final s = items[i];
        return AdminStatCard(
          label: s.label,
          value: s.value,
          icon: s.icon,
          color: s.color,
          subtitle: s.subtitle,
        );
      },
    );
  }
}

class _StatData {
  final String label, value, subtitle;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.icon, this.color, this.subtitle);
}

// ── Quick actions ─────────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA(Icons.person_add_rounded, 'Add Admin', Colors.purpleAccent),
      _QA(Icons.layers_rounded, 'New Template', Colors.blueAccent),
      _QA(Icons.widgets_rounded, 'Add Component', Colors.orangeAccent),
      _QA(Icons.bar_chart_rounded, 'Analytics', Colors.green),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.2,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) {
        final a = actions[i];
        return _QuickActionTile(qa: a);
      },
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final Color color;
  const _QA(this.icon, this.label, this.color);
}

class _QuickActionTile extends StatelessWidget {
  final _QA qa;
  const _QuickActionTile({required this.qa});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: qa.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(qa.icon, color: qa.color, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              qa.label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 14,
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }
}

// ── Recent activity ───────────────────────────────────────────────────────────
class _RecentActivity extends StatelessWidget {
  final AdminService service;
  const _RecentActivity({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.streamAllApps(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }
        final apps = (snap.data ?? []).take(5).toList();
        if (apps.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: const Center(
              child: Text(
                'No apps yet',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          );
        }
        return Column(
          children: apps.map((a) {
            final name = a['name']?.toString() ?? 'Unnamed';
            final status = a['status']?.toString() ?? 'draft';
            final uid = a['userId']?.toString() ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'by ${uid.length > 10 ? uid.substring(0, 10) : uid}...',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: StatusBadge(status)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Small section label ───────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

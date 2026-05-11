// ════════════════════════════════════════════════════════════════════════════
// SAVE EACH CLASS IN ITS OWN FILE as shown in the header comment
// ════════════════════════════════════════════════════════════════════════════

// ── File: lib/screens/admin/modules/admin_analytics.dart ────────────────────
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/admin_service.dart';
import '../admin_dashboard.dart';

class AdminAnalytics extends StatelessWidget {
  final AdminService service;
  const AdminAnalytics({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(title: 'Analytics Dashboard'),
          FutureBuilder<Map<String, dynamic>>(
            future: service.getAnalytics(),
            builder: (_, snap) {
              final d = snap.data ?? {};
              final loading = !snap.hasData;
              return Column(
                children: [
                  LayoutBuilder(
                    builder: (_, c) {
                      final cols = c.maxWidth > 500 ? 3 : 2;
                      return GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          AdminStatCard(
                            label: 'Total Users',
                            value: loading ? '—' : '${d['totalUsers']}',
                            icon: Icons.people_rounded,
                            color: AppTheme.primary,
                          ),
                          AdminStatCard(
                            label: 'Total Apps',
                            value: loading ? '—' : '${d['totalApps']}',
                            icon: Icons.apps_rounded,
                            color: Colors.blueAccent,
                          ),
                          AdminStatCard(
                            label: 'Published',
                            value: loading ? '—' : '${d['publishedApps']}',
                            icon: Icons.rocket_launch_rounded,
                            color: Colors.green,
                          ),
                          AdminStatCard(
                            label: 'Active (7d)',
                            value: loading ? '—' : '${d['activeUsers']}',
                            icon: Icons.online_prediction_rounded,
                            color: Colors.orangeAccent,
                          ),
                          AdminStatCard(
                            label: 'Admins',
                            value: loading ? '—' : '${d['adminCount']}',
                            icon: Icons.shield_rounded,
                            color: Colors.purpleAccent,
                          ),
                          AdminStatCard(
                            label: 'Pending Review',
                            value: '—',
                            icon: Icons.pending_rounded,
                            color: Colors.amber,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Engagement bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Platform Health',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _HealthRow('Firebase Auth', 0.98, Colors.green),
                        _HealthRow('Firestore DB', 0.95, Colors.green),
                        _HealthRow('Storage', 0.90, Colors.blueAccent),
                        _HealthRow('AI Service', 0.85, Colors.orangeAccent),
                        _HealthRow('Hosting', 0.99, Colors.green),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _HealthRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
            ),
            const Spacer(),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppTheme.darkBorder,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    ),
  );
}

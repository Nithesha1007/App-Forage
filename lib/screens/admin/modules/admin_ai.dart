import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/admin_service.dart';
import '../admin_dashboard.dart';

class AdminAi extends StatefulWidget {
  final AdminService service;
  const AdminAi({super.key, required this.service});

  @override
  State<AdminAi> createState() => _AdminAiState();
}

class _AdminAiState extends State<AdminAi> {
  bool _aiEnabled = true;
  bool _logEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(title: 'AI Module Control'),

          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Assistant',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Powered by Google Gemini 1.5 Flash',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _aiEnabled,
                      onChanged: (v) => setState(() => _aiEnabled = v),
                      activeColor: AppTheme.primary,
                    ),
                  ],
                ),
                const Divider(color: AppTheme.darkBorder, height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Log AI conversations',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Switch(
                      value: _logEnabled,
                      onChanged: (v) => setState(() => _logEnabled = v),
                      activeColor: AppTheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stat row
          Row(
            children: [
              Expanded(
                child: AdminStatCard(
                  label: 'Total Queries',
                  value: '—',
                  icon: Icons.chat_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Today',
                  value: '—',
                  icon: Icons.today_rounded,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Errors',
                  value: '0',
                  icon: Icons.error_outline,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'Recent AI Logs',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.service.streamAiLogs(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                final logs = snap.data!;
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: AppTheme.textMuted,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No AI logs yet',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Conversations are logged here when enabled',
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
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final log = logs[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.smart_toy_rounded,
                            color: AppTheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log['query']?.toString() ?? '—',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'User: ${log['userId']?.toString().substring(0, 8) ?? '—'}...',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => widget.service.deleteAiLog(log['id']),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

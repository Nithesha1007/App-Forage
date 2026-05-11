import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/admin_service.dart';
import '../admin_dashboard.dart';

class AdminUsers extends StatefulWidget {
  final AdminService service;
  const AdminUsers({super.key, required this.service});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'All Users',
            action: SizedBox(
              width: 220,
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Search users…',
                  hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                  filled: true,
                  fillColor: AppTheme.darkSurface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.service.streamUsers(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                final users = (snap.data ?? [])
                    .where(
                      (u) =>
                          _search.isEmpty ||
                          (u['email']?.toString().toLowerCase().contains(
                                _search,
                              ) ??
                              false) ||
                          (u['name']?.toString().toLowerCase().contains(
                                _search,
                              ) ??
                              false),
                    )
                    .toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _UserRow(user: users[i], service: widget.service),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final AdminService service;
  const _UserRow({required this.user, required this.service});

  @override
  Widget build(BuildContext context) {
    final role = user['role']?.toString() ?? 'user';
    final email = user['email']?.toString() ?? '';
    final name = user['name']?.toString() ?? 'Unknown';
    final uid = user['id']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
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
                  email,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'UID: ${uid.length > 10 ? uid.substring(0, 10) : uid}...',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Role badge
          StatusBadge(role),
          const SizedBox(width: 8),

          // Role toggle
          PopupMenuButton<String>(
            color: AppTheme.darkCard,
            tooltip: 'Change role',
            icon: const Icon(
              Icons.more_vert,
              size: 18,
              color: AppTheme.textMuted,
            ),
            onSelected: (newRole) async {
              if (newRole == 'delete') {
                final ok = await _confirmDelete(context);
                if (ok && context.mounted) {
                  await service.deleteUser(uid);
                }
              } else {
                await service.setRole(uid, newRole);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'admin',
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 16,
                      color: Colors.purpleAccent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Make Admin',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'user',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Make User',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Delete User',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.darkCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete User?',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: const Text(
              'This will remove the user from Firestore. The Firebase Auth account remains.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
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
}

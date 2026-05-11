import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import 'modules/admin_overview.dart';
import 'modules/admin_users.dart';
import 'modules/admin_apps.dart';
import 'modules/admin_templates.dart';
import 'modules/admin_components.dart';
import 'modules/admin_analytics.dart';
import 'modules/admin_security.dart';
import 'modules/admin_deployment.dart';
import 'modules/admin_ai.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AdminDashboard — mobile-first with Drawer + BottomNav
// ══════════════════════════════════════════════════════════════════════════════
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final _service = AdminService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Bottom nav — 5 main tabs (others in drawer)
  static const _bottomItems = [
    _NavItem(Icons.dashboard_rounded, 'Overview', 'Overview'),
    _NavItem(Icons.people_rounded, 'Users', 'User Management'),
    _NavItem(Icons.apps_rounded, 'Apps', 'App Management'),
    _NavItem(Icons.bar_chart_rounded, 'Analytics', 'Analytics'),
    _NavItem(Icons.menu_rounded, 'More', 'More'),
  ];

  // All modules
  static const _allItems = [
    _NavItem(Icons.dashboard_rounded, 'Overview', 'Overview'),
    _NavItem(Icons.people_rounded, 'Users', 'User Management'),
    _NavItem(Icons.apps_rounded, 'Apps', 'App Management'),
    _NavItem(Icons.bar_chart_rounded, 'Analytics', 'Analytics'),
    _NavItem(Icons.widgets_rounded, 'Components', 'Component Management'),
    _NavItem(Icons.layers_rounded, 'Templates', 'Template Management'),
    _NavItem(Icons.security_rounded, 'Security', 'Security & Access'),
    _NavItem(Icons.rocket_launch_rounded, 'Deployment', 'Deployment'),
    _NavItem(Icons.smart_toy_rounded, 'AI Module', 'AI Module Control'),
  ];

  Widget _buildModule() {
    switch (_selectedIndex) {
      case 0:
        return AdminOverview(service: _service);
      case 1:
        return AdminUsers(service: _service);
      case 2:
        return AdminApps(service: _service);
      case 3:
        return AdminAnalytics(service: _service);
      case 4:
        return AdminComponents(service: _service);
      case 5:
        return AdminTemplates(service: _service);
      case 6:
        return AdminSecurity(service: _service);
      case 7:
        return AdminDeployment(service: _service);
      case 8:
        return AdminAi(service: _service);
      default:
        return AdminOverview(service: _service);
    }
  }

  String get _currentTitle => _selectedIndex < _allItems.length
      ? _allItems[_selectedIndex].fullTitle
      : 'Overview';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.darkBg,

      // ── Drawer (all modules) ─────────────────────────────────────────
      drawer: _AdminDrawer(
        allItems: _allItems,
        selectedIndex: _selectedIndex,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          Navigator.pop(context);
        },
      ),

      // ── Top AppBar ───────────────────────────────────────────────────
      appBar: _buildAppBar(context),

      // ── Body ─────────────────────────────────────────────────────────
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _buildModule(),
        ),
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        items: _bottomItems,
        selectedIndex: _selectedIndex < 4 ? _selectedIndex : 4,
        onTap: (i) {
          if (i == 4) {
            // "More" opens drawer
            _scaffoldKey.currentState?.openDrawer();
          } else {
            setState(() => _selectedIndex = i);
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AppBar(
      backgroundColor: AppTheme.darkCard,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentTitle,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          Text(
            'Admin Panel',
            style: TextStyle(
              color: AppTheme.primary.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        // Admin badge
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_rounded,
                size: 12,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                auth.user?.email?.split('@').first ?? 'Admin',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.darkBorder),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Drawer — all 9 modules + sign out
// ══════════════════════════════════════════════════════════════════════════════
class _AdminDrawer extends StatelessWidget {
  final List<_NavItem> allItems;
  final int selectedIndex;
  final Function(int) onTap;

  const _AdminDrawer({
    required this.allItems,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.darkCard,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.darkBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AppForge',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(color: AppTheme.primary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: allItems.length,
                itemBuilder: (_, i) {
                  final item = allItems[i];
                  final active = i == selectedIndex;
                  return ListTile(
                    onTap: () => onTap(i),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.primary.withOpacity(0.15)
                            : AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        size: 18,
                        color: active ? AppTheme.primary : AppTheme.textMuted,
                      ),
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: active ? AppTheme.primary : AppTheme.textPrimary,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    selected: active,
                    selectedTileColor: AppTheme.primary.withOpacity(0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                  );
                },
              ),
            ),

            // Sign out
            const Divider(color: AppTheme.darkBorder, height: 1),
            Consumer<AuthProvider>(
              builder: (ctx, auth, _) => ListTile(
                onTap: () async {
                  Navigator.pop(ctx);
                  await auth.signOut();
                  if (ctx.mounted) ctx.go('/login');
                },
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Bottom navigation bar
// ══════════════════════════════════════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final Function(int) onTap;

  const _BottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(top: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final active = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.primary.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: active ? AppTheme.primary : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: active ? AppTheme.primary : AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Nav item model ────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  final String fullTitle;
  const _NavItem(this.icon, this.label, this.fullTitle);
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared widgets used across ALL admin modules
// ══════════════════════════════════════════════════════════════════════════════

/// Stat card — fixed height, no overflow
class AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header
class AdminSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const AdminSectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    ),
  );
}

/// Status badge
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
      case 'published':
        return Colors.green;
      case 'rejected':
      case 'inactive':
      case 'deleted':
        return Colors.red;
      case 'pending':
      case 'draft':
        return Colors.orange;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _color.withOpacity(0.4)),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: _color,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

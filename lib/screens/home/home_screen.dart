import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/builder_provider.dart';
import '../../models/project_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/floating_ai_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ FIX 3 & 4: LOAD PROJECTS ONLY ONCE - Prevent multiple rebuild fetches
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.uid;
      final userEmail = auth.user?.email;

      if (userId != null) {
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );
        debugPrint('🏠 STEP 5 - DASHBOARD: Loading projects');
        debugPrint('   userId=$userId');
        debugPrint('   LOGIN EMAIL: $userEmail');
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );

        final builder = context.read<BuilderProvider>();

        // ✅ FIX 3 & 4: Check if already loaded to prevent multiple fetches
        if (!builder.projectsLoaded) {
          print('⏳ Starting project load (projectsLoaded=false)');
          // ✅ FIX 6 & 7 & 8: Explicitly load projects from Firebase (with local fallback)
          await builder.loadAllProjects(userId);
          print('✅ Calling markProjectsAsLoaded()');
          builder.markProjectsAsLoaded();
          print(
            '✅ Projects loaded and flag set, allProjects.length=${builder.allProjects.length}',
          );
        } else {
          print('⏩ Projects already loaded, skipping (projectsLoaded=true)');
        }

        debugPrint('   Count: ${builder.allProjects.length}');
        for (var proj in builder.allProjects) {
          debugPrint(
            '   📦 ${proj.name} (${proj.status}) - email=${proj.userEmail ?? "NOT SET"}',
          );
        }
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );
      } else {
        debugPrint('⚠️ STEP 5: User not authenticated');
      }
    } catch (e) {
      debugPrint('❌ STEP 5: Failed to load projects: $e');
      print('❌ STEP 5 ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final builder = context.watch<BuilderProvider>();
    final projects = builder.allProjects;

    print('[SCREEN-RENDER] HomeScreen.build() called');
    print('[SCREEN-RENDER]   - user: ${user?.email}');
    print('[SCREEN-RENDER]   - projects in provider: ${projects.length}');
    print('[SCREEN-RENDER]   - projectsLoaded flag: ${builder.projectsLoaded}');

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('⚡', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AppForge',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () => _showProfileMenu(context, auth),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const FloatingAiButton(),
      body: StreamBuilder<List<ProjectModel>>(
        stream: user != null
            ? FirestoreService().getUserProjects(user.uid)
            : const Stream.empty(),
        builder: (context, snapshot) {
          // Use cached local projects first, fall back to Firebase stream
          final displayProjects = projects.isNotEmpty
              ? projects
              : (snapshot.data ?? []);

          print('[STREAM-RENDER] StreamBuilder builder called');
          print(
            '[STREAM-RENDER]   - projects from provider: ${projects.length}',
          );
          print(
            '[STREAM-RENDER]   - snapshot.data: ${snapshot.data?.length ?? 0}',
          );
          print(
            '[STREAM-RENDER]   - snapshot.connectionState: ${snapshot.connectionState}',
          );
          print(
            '[STREAM-RENDER]   - displayProjects: ${displayProjects.length}',
          );

          return CustomScrollView(
            slivers: [
              // Welcome Banner
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${user?.displayName?.split(' ').first ?? 'Builder'}! 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${displayProjects.length} project${displayProjects.length != 1 ? 's' : ''} in your workspace',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => context.go('/templates'),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                'New App',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text('🚀', style: TextStyle(fontSize: 64)),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),
              ),

              // Stats Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _StatCard(
                        'Projects',
                        '${displayProjects.length}',
                        Icons.folder_outlined,
                        AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        'Published',
                        '${displayProjects.where((p) => p.status == 'published').length}',
                        Icons.rocket_launch_outlined,
                        AppTheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        'Drafts',
                        '${displayProjects.where((p) => p.status == 'draft').length}',
                        Icons.edit_outlined,
                        AppTheme.accent,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Projects',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/templates'),
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                        label: const Text(
                          'New',
                          style: TextStyle(color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Projects
              if (snapshot.connectionState == ConnectionState.waiting &&
                  displayProjects.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  ),
                )
              else if (displayProjects.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyState(
                    onCreateTap: () => context.go('/templates'),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) =>
                        _ProjectCard(
                              project: displayProjects[i],
                              userId: user!.uid,
                              onOpen: () => context.go(
                                '/builder/${displayProjects[i].id}',
                              ),
                            )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: i * 60))
                            .slideX(begin: 0.15),
                    childCount: displayProjects.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  void _showProfileMenu(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primary,
              child: Text(
                (auth.user?.displayName ?? auth.user?.email ?? 'U')[0]
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              auth.user?.displayName ?? 'Builder',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              auth.user?.email ?? '',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.accent),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppTheme.accent),
              ),
              onTap: () async {
                Navigator.pop(context);
                await auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final String userId;
  final VoidCallback onOpen;
  const _ProjectCard({
    required this.project,
    required this.userId,
    required this.onOpen,
  });

  String get _emoji {
    switch (project.templateId) {
      case 'ecommerce':
        return '🛒';
      case 'school':
        return '🏫';
      case 'food':
        return '🍔';
      case 'crm':
        return '💼';
      case 'fitness':
        return '💪';
      case 'blog':
        return '📰';
      default:
        return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    try {
      color = Color(
        int.parse(project.theme.primaryColor.replaceAll('#', '0xFF')),
      );
    } catch (_) {
      color = AppTheme.primary;
    }

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(_emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (project.status == 'published'
                                      ? AppTheme.primary
                                      : AppTheme.textMuted)
                                  .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          project.status == 'published'
                              ? '🟢 Published'
                              : '✏️ Draft',
                          style: TextStyle(
                            color: project.status == 'published'
                                ? AppTheme.primary
                                : AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${project.screens.length} screens',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: AppTheme.darkCard,
              icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
              onSelected: (v) async {
                if (v == 'open') onOpen();
                if (v == 'delete')
                  await FirestoreService().deleteProject(project.id, userId);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'open',
                  child: Text(
                    'Open Builder',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.accent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛸', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'No projects yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first app with a template\nor start from scratch!',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add),
            label: const Text('Create Your First App'),
          ),
        ],
      ).animate().fadeIn().scale(),
    ),
  );
}

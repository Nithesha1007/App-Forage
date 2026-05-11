import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/builder_provider.dart';
import 'models/project_model.dart';
import 'models/screen_model.dart';
import 'models/widget_model.dart';
import 'widgets/floating_ai_button.dart';
import 'screens/builder/canvas_area.dart';
import 'screens/builder/widget_panel.dart';
import 'screens/builder/properties_panel.dart';
import 'screens/builder/backend_panel.dart';
import 'screens/builder/bind_data_panel.dart';

// ── Tool panel enum ───────────────────────────────────────────────────────────
enum _Panel { widgets, screens, theme, backend }

class BuilderScreen extends StatefulWidget {
  final String projectId;
  const BuilderScreen({super.key, required this.projectId});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  _Panel _activePanel = _Panel.widgets;
  String _deviceMode = 'Mobile';

  // ✅ FIX 4: IMPORTANT - Cancel/back operations MUST:
  // 1. Never delete the project from storage
  // 2. Never clear the builder state
  // 3. Never reset the project to an earlier version
  // 4. Just navigate back or close dialogs
  // 5. Always save before navigating away

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BuilderProvider>().loadProject(widget.projectId);
    });
  }

  void _selectPanel(_Panel panel) {
    setState(() => _activePanel = panel);
  }

  /// ✅ FIX 3 & 4: Save project before exiting builder
  /// This ensures that all changes are persisted before navigation
  Future<void> _handleBack(BuildContext ctx, BuilderProvider provider) async {
    if (provider.project != null) {
      debugPrint('🔄 SAVE BEFORE EXIT: ${provider.project!.name}');
      // ✅ FIX 3: Force save immediately
      await provider.saveCurrentProject();
      debugPrint('✅ SAVED BEFORE BACK: ${provider.project!.name}');
    }
    // ✅ Only after save completes → allow navigation
    if (ctx.mounted) ctx.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BuilderProvider>(
      builder: (context, provider, _) {
        // ── Loading state ─────────────────────────────────────────────
        if (provider.project == null) {
          return Scaffold(
            backgroundColor: AppTheme.darkBg,
            body: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading project…',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          );
        }

        final project = provider.project!;
        final selected = provider.selectedWidget;

        return SafeArea(
          child: Scaffold(
            backgroundColor: AppTheme.darkBg,

            // ── AppBar ────────────────────────────────────────────────────
            appBar: _BuilderAppBar(
              projectName: project.name,
              deviceMode: _deviceMode,
              canUndo: provider.canUndo,
              isSaving: provider.isSaving,
              onDeviceChange: (m) => setState(() => _deviceMode = m),
              onUndo: provider.canUndo ? provider.undo : null,
              onPreview: () => context.go('/preview/${widget.projectId}'),
              onPublish: () => context.go('/publish/${widget.projectId}'),
              onBack: () => _handleBack(context, provider),
            ),

            // ── Body: 3-column layout ───────────────────────────────────────────────
            body: SafeArea(
              child: Row(
                children: [
                  // LEFT: Tool panel selector + content (300px)
                  _LeftSidebar(
                    activePanel: _activePanel,
                    onSelectPanel: _selectPanel,
                    provider: provider,
                  ),

                  // CENTER: Canvas area (expanded)
                  Expanded(
                    child: Column(
                      children: [
                        _ScreenStrip(provider: provider),
                        Expanded(
                          child: _CanvasCenter(
                            provider: provider,
                            deviceMode: _deviceMode,
                            activeScreen: provider.activeScreen,
                            onWidgetTap: (w) {
                              provider.selectWidget(w);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // RIGHT: Properties panel (320px, shown when widget selected)
                  if (selected != null)
                    Container(
                      width: 320,
                      decoration: const BoxDecoration(
                        color: AppTheme.darkCard,
                        border: Border(
                          left: BorderSide(color: AppTheme.darkBorder),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppTheme.darkBorder),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Properties',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 17),
                                  onPressed: () {
                                    provider.selectWidget(null);
                                    setState(() {});
                                  },
                                  color: AppTheme.textMuted,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: PropertiesPanel(
                              widget: selected,
                              provider: provider,
                              onPropertyChanged: (key, val) => provider
                                  .updateWidgetProperty(selected.id, key, val),
                              onDelete: () {
                                provider.removeWidget(selected.id);
                                provider.selectWidget(null);
                                setState(() {});
                              },
                              onDuplicate: () =>
                                  provider.duplicateWidget(selected.id),
                              onBindData: () => BindDataPanel.show(
                                context,
                                provider: provider,
                                widget: selected,
                              ),
                              onDeselect: () {
                                provider.selectWidget(null);
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Floating AI button
            floatingActionButton: const FloatingAiButton(),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AppBar
// ══════════════════════════════════════════════════════════════════════════════
class _BuilderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String projectName, deviceMode;
  final bool canUndo, isSaving;
  final VoidCallback onPreview, onPublish, onBack;
  final VoidCallback? onUndo;
  final Function(String) onDeviceChange;

  const _BuilderAppBar({
    required this.projectName,
    required this.deviceMode,
    required this.canUndo,
    required this.isSaving,
    required this.onDeviceChange,
    required this.onUndo,
    required this.onPreview,
    required this.onPublish,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(bottom: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 17),
            onPressed: onBack,
            color: AppTheme.textMuted,
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    projectName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSaving) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.undo, size: 18),
            onPressed: onUndo,
            color: canUndo ? AppTheme.textMuted : AppTheme.darkBorder,
          ),

          TextButton.icon(
            onPressed: onPreview,
            icon: const Icon(
              Icons.visibility_outlined,
              size: 16,
              color: AppTheme.primary,
            ),
            label: const Text(
              'Preview',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
          ),
          TextButton.icon(
            onPressed: onPublish,
            icon: const Icon(
              Icons.rocket_launch,
              size: 16,
              color: AppTheme.primary,
            ),
            label: const Text(
              'Publish',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Screen strip
// ══════════════════════════════════════════════════════════════════════════════
class _ScreenStrip extends StatelessWidget {
  final BuilderProvider provider;
  const _ScreenStrip({required this.provider});

  @override
  Widget build(BuildContext context) {
    final screens = provider.project?.screens ?? [];
    // ✅ currentScreenId — correct getter
    final currentId = provider.currentScreenId;

    return Container(
      height: 36,
      color: AppTheme.darkCard,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              itemCount: screens.length,
              itemBuilder: (_, i) {
                final s = screens[i];
                final active = s.id == currentId;
                return GestureDetector(
                  // ✅ setCurrentScreen(String id)
                  onTap: () => provider.setCurrentScreen(s.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.primary.withOpacity(0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: active ? AppTheme.primary : AppTheme.darkBorder,
                      ),
                    ),
                    child: Text(
                      s.name,
                      style: TextStyle(
                        color: active ? AppTheme.primary : AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 15),
            color: AppTheme.textMuted,
            padding: const EdgeInsets.all(6),
            onPressed: () => _addScreenDialog(context, provider),
          ),
        ],
      ),
    );
  }

  void _addScreenDialog(BuildContext context, BuilderProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'New Screen',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Profile',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.darkSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final n = ctrl.text.trim();
              if (n.isNotEmpty) provider.addScreen(n);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Canvas center
// ══════════════════════════════════════════════════════════════════════════════
class _CanvasCenter extends StatelessWidget {
  final BuilderProvider provider;
  final String deviceMode;
  // ✅ AppScreen is in project_model.dart — no separate screen_model import
  final AppScreen? activeScreen;
  final Function(WidgetModel?) onWidgetTap;

  const _CanvasCenter({
    required this.provider,
    required this.deviceMode,
    required this.activeScreen,
    required this.onWidgetTap,
  });

  Color get _primaryColor {
    final hex = provider.project?.theme.primaryColor ?? '#00C896';
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  Color get _phoneBackgroundColor {
    final theme = provider.project?.theme ?? const ProjectTheme();
    if (theme.isDarkMode) {
      try {
        return Color(int.parse(theme.surfaceColorHex.replaceAll('#', '0xFF')));
      } catch (_) {
        return Color(0xFF2A2A2A);
      }
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkBg,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Phone frame
              Container(
                width: 320,
                height: 620,
                decoration: BoxDecoration(
                  color: _phoneBackgroundColor,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: AppTheme.darkBorder, width: 8),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.25),
                      blurRadius: 48,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    children: [
                      // Status bar
                      Container(
                        height: 36,
                        color: _primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              activeScreen?.name ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(
                                  Icons.signal_cellular_4_bar,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.battery_full,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Canvas area
                      Expanded(
                        child: CanvasArea(
                          screen: activeScreen,
                          provider: provider,
                          onWidgetSelected: onWidgetTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // App info pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Text(
                  '📱 ${provider.project?.name ?? ''} · ${provider.project?.screens.length ?? 0} screen${(provider.project?.screens.length ?? 0) != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Left sidebar with tool buttons
// ══════════════════════════════════════════════════════════════════════════════
class _LeftSidebar extends StatelessWidget {
  final _Panel activePanel;
  final Function(_Panel) onSelectPanel;
  final BuilderProvider provider;

  const _LeftSidebar({
    required this.activePanel,
    required this.onSelectPanel,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(right: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: Column(
        children: [
          // Tool selector buttons (vertical)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.darkBorder)),
            ),
            child: Column(
              children: [
                _toolButton(
                  icon: Icons.widgets_outlined,
                  label: 'Widgets',
                  panel: _Panel.widgets,
                ),
                _toolButton(
                  icon: Icons.phone_android_outlined,
                  label: 'Screens',
                  panel: _Panel.screens,
                ),
                _toolButton(
                  icon: Icons.palette_outlined,
                  label: 'Theme',
                  panel: _Panel.theme,
                ),
                _toolButton(
                  icon: Icons.storage_outlined,
                  label: 'Backend',
                  panel: _Panel.backend,
                ),
              ],
            ),
          ),
          // Tool content
          Expanded(child: _toolContent(context)),
        ],
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String label,
    required _Panel panel,
  }) {
    final isActive = activePanel == panel;
    return GestureDetector(
      onTap: () => onSelectPanel(panel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.darkBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppTheme.primary : AppTheme.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolContent(BuildContext context) {
    switch (activePanel) {
      case _Panel.widgets:
        return WidgetPanel(onAdd: (type) => provider.addWidget(type, 40, 80));
      case _Panel.screens:
        return _ScreensDrawerContent(provider: provider);
      case _Panel.theme:
        return _ThemeDrawerContent(provider: provider);
      case _Panel.backend:
        return BackendPanel(provider: provider);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Screens list inside drawer
// ══════════════════════════════════════════════════════════════════════════════
class _ScreensDrawerContent extends StatelessWidget {
  final BuilderProvider provider;
  const _ScreensDrawerContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final screens = provider.project?.screens ?? [];
    // ✅ activeScreenIndex
    final activeIndex = provider.activeScreenIndex;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...screens.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final active = i == activeIndex;
          return GestureDetector(
            onTap: () {
              // ✅ setActiveScreen(int)
              provider.setActiveScreen(i);
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_android,
                    size: 15,
                    color: active ? AppTheme.primary : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.name,
                      style: TextStyle(
                        color: active ? AppTheme.primary : AppTheme.textPrimary,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${s.widgets.length}w',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _addDialog(context, provider),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 15, color: AppTheme.primary),
                SizedBox(width: 6),
                Text(
                  'Add Screen',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addDialog(BuildContext context, BuilderProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'New Screen',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Screen name',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.darkSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final n = ctrl.text.trim();
              if (n.isNotEmpty) provider.addScreen(n);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Theme editor — ProjectTheme has NO copyWith, construct manually
// Fields: primaryColor, secondaryColor, backgroundColor,
//         fontFamily, borderRadius, isDarkMode
// ══════════════════════════════════════════════════════════════════════════════
class _ThemeDrawerContent extends StatelessWidget {
  final BuilderProvider provider;
  const _ThemeDrawerContent({required this.provider});

  static const _fonts = ['Poppins', 'Roboto', 'Inter', 'Lato', 'Montserrat'];

  // ✅ No copyWith on ProjectTheme — build new instance manually
  void _setPrimary(ProjectTheme t, String hex) => provider.updateTheme(
    ProjectTheme(
      primaryColor: hex,
      secondaryColor: t.secondaryColor,
      backgroundColor: t.backgroundColor,
      fontFamily: t.fontFamily,
      borderRadius: t.borderRadius,
      isDarkMode: t.isDarkMode,
    ),
  );

  void _setSecondary(ProjectTheme t, String hex) => provider.updateTheme(
    ProjectTheme(
      primaryColor: t.primaryColor,
      secondaryColor: hex,
      backgroundColor: t.backgroundColor,
      fontFamily: t.fontFamily,
      borderRadius: t.borderRadius,
      isDarkMode: t.isDarkMode,
    ),
  );

  void _setFont(ProjectTheme t, String font) => provider.updateTheme(
    ProjectTheme(
      primaryColor: t.primaryColor,
      secondaryColor: t.secondaryColor,
      backgroundColor: t.backgroundColor,
      fontFamily: font,
      borderRadius: t.borderRadius,
      isDarkMode: t.isDarkMode,
    ),
  );

  void _setDarkMode(ProjectTheme t, bool dark) => provider.updateTheme(
    ProjectTheme(
      primaryColor: t.primaryColor,
      secondaryColor: t.secondaryColor,
      backgroundColor: t.backgroundColor,
      fontFamily: t.fontFamily,
      borderRadius: t.borderRadius,
      isDarkMode: dark,
    ),
  );

  void _setColorPreset(ProjectTheme t, String presetName) {
    final preset = ProjectTheme.colorPresets[presetName];
    if (preset != null) {
      provider.updateTheme(
        ProjectTheme(
          primaryColor: preset['primary'] ?? t.primaryColor,
          secondaryColor: preset['secondary'] ?? t.secondaryColor,
          backgroundColor: t.backgroundColor,
          fontFamily: t.fontFamily,
          borderRadius: t.borderRadius,
          isDarkMode: t.isDarkMode,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = provider.project?.theme ?? const ProjectTheme();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      children: [
        // ─────────────────────────────────────────────────────────────────
        // STYLE PRESETS
        // ─────────────────────────────────────────────────────────────────
        const Text(
          'STYLE PRESETS',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ProjectTheme.colorPresets.entries.map((entry) {
            final presetName = entry.key;
            final colors = entry.value;
            final primaryHex = colors['primary'] ?? '#000000';
            final primaryColor = Color(
              int.parse(primaryHex.replaceAll('#', '0xFF')),
            );
            final isSelected = theme.primaryColor == primaryHex;

            return GestureDetector(
              onTap: () => _setColorPreset(theme, presetName),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 68,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 2,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? primaryColor : AppTheme.darkBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      presetName,
                      style: TextStyle(
                        color: isSelected ? primaryColor : AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        // ─────────────────────────────────────────────────────────────────
        // PRIMARY COLOR
        // ─────────────────────────────────────────────────────────────────
        const Text(
          'PRIMARY COLOR',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ProjectTheme.colorPresets.values
              .map((colors) => colors['primary']!)
              .toSet()
              .toList()
              .map((hex) {
                final color = Color(int.parse(hex.replaceAll('#', '0xFF')));
                final selected = theme.primaryColor == hex;
                return GestureDetector(
                  onTap: () => _setPrimary(theme, hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              })
              .toList(),
        ),

        const SizedBox(height: 24),
        // ─────────────────────────────────────────────────────────────────
        // SECONDARY COLOR
        // ─────────────────────────────────────────────────────────────────
        const Text(
          'SECONDARY COLOR',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ProjectTheme.colorPresets.values
              .map((colors) => colors['secondary']!)
              .toSet()
              .toList()
              .map((hex) {
                final color = Color(int.parse(hex.replaceAll('#', '0xFF')));
                final selected = theme.secondaryColor == hex;
                return GestureDetector(
                  onTap: () => _setSecondary(theme, hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              })
              .toList(),
        ),

        const SizedBox(height: 24),
        // ─────────────────────────────────────────────────────────────────
        // FONT FAMILY
        // ─────────────────────────────────────────────────────────────────
        const Text(
          'FONT FAMILY',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _fonts.map((f) {
            final selected = theme.fontFamily == f;
            return GestureDetector(
              onTap: () => _setFont(theme, f),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                          fontFamily: f,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        // ─────────────────────────────────────────────────────────────────
        // APP MODE (DARK / LIGHT)
        // ─────────────────────────────────────────────────────────────────
        const Text(
          'APP MODE',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _modeChip(theme, 'Dark', Icons.dark_mode, true),
            const SizedBox(width: 12),
            _modeChip(theme, 'Light', Icons.light_mode, false),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _modeChip(ProjectTheme theme, String label, IconData icon, bool dark) {
    final selected = theme.isDarkMode == dark;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setDarkMode(theme, dark),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withOpacity(0.1)
                : AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.darkBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppTheme.primary : AppTheme.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

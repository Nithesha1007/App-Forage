import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/builder_provider.dart';
import '../../models/project_model.dart';
import '../../models/screen_model.dart'; // ✅ AppScreen lives here
import '../../models/widget_model.dart';
import '../../widgets/floating_ai_button.dart';
import 'canvas_area.dart';
import 'widget_panel.dart';
import 'properties_panel.dart';
import 'backend_panel.dart';
import 'bind_data_panel.dart';

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
  bool _isPreviewMode = false;
  bool _previewHorizontal = true; // true = horizontal, false = vertical
  bool _isLoaded =
      false; // ✅ FIX 4: Guard to prevent render before load complete

  @override
  void initState() {
    super.initState();
    // ✅ FIX 1: Load ONLY ONCE in initState
    _loadProjectAsync();
  }

  /// ✅ FIX 4: Async load with proper await
  Future<void> _loadProjectAsync() async {
    try {
      await context.read<BuilderProvider>().loadProject(widget.projectId);
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    } catch (e) {
      debugPrint('❌ Failed to load project: $e');
      if (mounted) {
        setState(() => _isLoaded = true); // Show error state
      }
    }
  }

  /// ✅ FIX 5: Switch project with auto-save
  @override
  void didUpdateWidget(BuilderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If project ID changed, save current and load new
    if (oldWidget.projectId != widget.projectId) {
      _isLoaded = false;
      _loadProjectAsync();
    }
  }

  void _selectPanel(_Panel panel) {
    setState(() => _activePanel = panel);
  }

  void _togglePreviewMode() {
    setState(() => _isPreviewMode = !_isPreviewMode);
  }

  void _setPreviewOrientation(bool horizontal) {
    setState(() => _previewHorizontal = horizontal);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Auto-save before leaving
        final provider = context.read<BuilderProvider>();
        await provider.saveCurrentProject();
        return true;
      },
      child: Consumer<BuilderProvider>(
        builder: (context, provider, _) {
          // ✅ FIX 4: Wait for initial load before rendering UI
          if (!_isLoaded || provider.project == null) {
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
                lastSavedTime: provider.lastSavedTime,
                isPreviewMode: _isPreviewMode,
                previewHorizontal: _previewHorizontal,
                onDeviceChange: (m) => setState(() => _deviceMode = m),
                onUndo: provider.canUndo ? provider.undo : null,
                onTogglePreview: _togglePreviewMode,
                onSetPreviewOrientation: _setPreviewOrientation,
                onPreview: () async {
                  await provider.saveCurrentProject();
                  if (mounted) context.go('/preview/${widget.projectId}');
                },
                onPublish: () async {
                  await provider.saveCurrentProject();
                  if (mounted) context.go('/publish/${widget.projectId}');
                },
                onBack: () async {
                  await provider.saveCurrentProject();
                  if (mounted) context.go('/home');
                },
              ),

              // ── Body: Preview Mode or Normal Builder ───────────────────────
              body: _isPreviewMode
                  ? _PreviewMode(
                      provider: provider,
                      horizontal: _previewHorizontal,
                      onOrientationChange: _setPreviewOrientation,
                    )
                  : _NormalBuilderView(
                      provider: provider,
                      activePanel: _activePanel,
                      onSelectPanel: _selectPanel,
                      deviceMode: _deviceMode,
                      selected: selected,
                    ),

              // Floating AI button
              floatingActionButton: const FloatingAiButton(),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Normal Builder View (4-column layout with canvas and panels)
// ══════════════════════════════════════════════════════════════════════════════
class _NormalBuilderView extends StatelessWidget {
  final BuilderProvider provider;
  final _Panel activePanel;
  final Function(_Panel) onSelectPanel;
  final String deviceMode;
  final WidgetModel? selected;

  const _NormalBuilderView({
    required this.provider,
    required this.activePanel,
    required this.onSelectPanel,
    required this.deviceMode,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          // FAR LEFT: Vertical tab buttons (narrow)
          _LeftSidebar(
            activePanel: activePanel,
            onSelectPanel: onSelectPanel,
            provider: provider,
          ),

          // LEFT-CENTER: Tab content panel (~300px)
          _LeftPanelContent(activePanel: activePanel, provider: provider),

          // CENTER-RIGHT: Canvas area (expanded)
          Expanded(
            child: Column(
              children: [
                _ScreenStrip(provider: provider),
                Expanded(
                  child: _CanvasCenter(
                    provider: provider,
                    deviceMode: deviceMode,
                    activeScreen: provider.activeScreen,
                    onWidgetTap: (w) {
                      provider.selectWidget(w);
                    },
                  ),
                ),
              ],
            ),
          ),

          // FAR RIGHT: Properties panel (320px, shown when widget selected)
          if (selected != null)
            Container(
              width: 320,
              decoration: const BoxDecoration(
                color: AppTheme.darkCard,
                border: Border(left: BorderSide(color: AppTheme.darkBorder)),
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
                      widget: selected!,
                      provider: provider,
                      onPropertyChanged: (key, val) =>
                          provider.updateWidgetProperty(selected!.id, key, val),
                      onDelete: () {
                        provider.removeWidget(selected!.id);
                        provider.selectWidget(null);
                      },
                      onDuplicate: () => provider.duplicateWidget(selected!.id),
                      onBindData: () => BindDataPanel.show(
                        context,
                        provider: provider,
                        widget: selected!,
                      ),
                      onDeselect: () {
                        provider.selectWidget(null);
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Preview Mode (horizontal or vertical scroll through all screens)
// ══════════════════════════════════════════════════════════════════════════════
class _PreviewMode extends StatelessWidget {
  final BuilderProvider provider;
  final bool horizontal;
  final Function(bool) onOrientationChange;

  const _PreviewMode({
    required this.provider,
    required this.horizontal,
    required this.onOrientationChange,
  });

  List<Widget> _intersperse(List<Widget> items, Widget separator) {
    if (items.isEmpty) return [];
    return [
      for (int i = 0; i < items.length; i++) ...[
        items[i],
        if (i < items.length - 1) separator,
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = provider.project?.screens ?? [];
    if (screens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No screens to preview',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Orientation Toggle Bar ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.darkCard,
            border: Border(bottom: BorderSide(color: AppTheme.darkBorder)),
          ),
          child: Row(
            children: [
              const Text(
                'Preview Orientation:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => onOrientationChange(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: horizontal
                        ? AppTheme.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: horizontal
                          ? AppTheme.primary
                          : AppTheme.darkBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: horizontal
                            ? AppTheme.primary
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Horizontal',
                        style: TextStyle(
                          color: horizontal
                              ? AppTheme.primary
                              : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: horizontal
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onOrientationChange(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: !horizontal
                        ? AppTheme.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: !horizontal
                          ? AppTheme.primary
                          : AppTheme.darkBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 14,
                        color: !horizontal
                            ? AppTheme.primary
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Vertical',
                        style: TextStyle(
                          color: !horizontal
                              ? AppTheme.primary
                              : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: !horizontal
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${screens.length} screen${screens.length != 1 ? 's' : ''}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),

        // ── Scrollable Screens ──────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
            padding: const EdgeInsets.all(24),
            child: horizontal
                ? Row(
                    children: _intersperse(
                      screens
                          .map(
                            (screen) => _PreviewScreenFrame(
                              screen: screen,
                              provider: provider,
                            ),
                          )
                          .toList(),
                      const SizedBox(width: 24),
                    ),
                  )
                : Column(
                    children: _intersperse(
                      screens
                          .map(
                            (screen) => _PreviewScreenFrame(
                              screen: screen,
                              provider: provider,
                            ),
                          )
                          .toList(),
                      const SizedBox(height: 24),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Preview Screen Frame (renders a single screen in preview)
// ══════════════════════════════════════════════════════════════════════════════
class _PreviewScreenFrame extends StatelessWidget {
  final AppScreen screen;
  final BuilderProvider provider;

  const _PreviewScreenFrame({required this.screen, required this.provider});

  Color get _primaryColor {
    final hex = provider.project?.theme.primaryColor ?? '#00C896';
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 620,
      decoration: BoxDecoration(
        color: Colors.white,
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
                  Expanded(
                    child: Text(
                      screen.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: false,
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
                      Icon(Icons.battery_full, color: Colors.white, size: 14),
                    ],
                  ),
                ],
              ),
            ),
            // Canvas area with rendered widgets
            Expanded(
              child: Container(
                color: Colors.white,
                child: _PreviewCanvas(screen: screen, provider: provider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Preview Canvas (renders the screen's widgets without selection/edit)
// ══════════════════════════════════════════════════════════════════════════════
class _PreviewCanvas extends StatelessWidget {
  final AppScreen screen;
  final BuilderProvider provider;

  const _PreviewCanvas({required this.screen, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Container(color: Colors.white),
        // Widgets rendered without selection/interactivity
        ...screen.widgets.map((widget) {
          return Positioned(
            left: widget.x,
            top: widget.y,
            width: widget.width,
            height: widget.height,
            child: _PreviewWidgetRenderer(widget: widget, provider: provider),
          );
        }).toList(),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Preview Widget Renderer (renders a widget in preview mode)
// ══════════════════════════════════════════════════════════════════════════════
class _PreviewWidgetRenderer extends StatelessWidget {
  final WidgetModel widget;
  final BuilderProvider provider;

  const _PreviewWidgetRenderer({required this.widget, required this.provider});

  @override
  Widget build(BuildContext context) {
    final props = widget.properties;
    final primaryColor = _getPrimaryColor();

    switch (widget.type) {
      case 'Button':
        return _PreviewButton(
          text: props['label'] ?? 'Button',
          backgroundColor: primaryColor,
          width: widget.width,
          height: widget.height,
        );
      case 'Text':
        return _PreviewText(
          text: props['content'] ?? 'Text',
          fontSize: (props['fontSize'] as num?)?.toDouble() ?? 16,
          width: widget.width,
          height: widget.height,
        );
      case 'Image':
        return _PreviewImage(
          url: props['imageUrl'] ?? '',
          width: widget.width,
          height: widget.height,
        );
      case 'TextInput':
        return _PreviewTextInput(
          placeholder: props['placeholder'] ?? 'Enter text',
          width: widget.width,
          height: widget.height,
        );
      case 'Container':
        return _PreviewContainer(
          backgroundColor: Color(
            int.parse(
              (props['backgroundColor'] as String? ?? '#FFFFFF').replaceAll(
                '#',
                '0xFF',
              ),
            ),
          ),
          width: widget.width,
          height: widget.height,
          borderRadius: (props['borderRadius'] as num?)?.toDouble() ?? 0,
        );
      case 'Card':
        return _PreviewCard(width: widget.width, height: widget.height);
      case 'ListView':
        return _PreviewListView(
          itemCount: (props['itemCount'] as num?)?.toInt() ?? 3,
          width: widget.width,
          height: widget.height,
        );
      default:
        return _PreviewUnknown(
          type: widget.type,
          width: widget.width,
          height: widget.height,
        );
    }
  }

  Color _getPrimaryColor() {
    final hex = provider.project?.theme.primaryColor ?? '#00C896';
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Preview Widget Components
// ──────────────────────────────────────────────────────────────────────────────
class _PreviewButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final double width;
  final double height;

  const _PreviewButton({
    required this.text,
    required this.backgroundColor,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PreviewText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double width;
  final double height;

  const _PreviewText({
    required this.text,
    required this.fontSize,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black87,
          fontSize: fontSize.clamp(8, 48),
          fontWeight: FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 3,
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const _PreviewImage({
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.image, color: Colors.grey[600]),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }
}

class _PreviewTextInput extends StatelessWidget {
  final String placeholder;
  final double width;
  final double height;

  const _PreviewTextInput({
    required this.placeholder,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Center(
        child: Text(
          placeholder,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _PreviewContainer extends StatelessWidget {
  final Color backgroundColor;
  final double width;
  final double height;
  final double borderRadius;

  const _PreviewContainer({
    required this.backgroundColor,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final double width;
  final double height;

  const _PreviewCard({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _PreviewListView extends StatelessWidget {
  final int itemCount;
  final double width;
  final double height;

  const _PreviewListView({
    required this.itemCount,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Text(
            'Item ${i + 1}',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

class _PreviewUnknown extends StatelessWidget {
  final String type;
  final double width;
  final double height;

  const _PreviewUnknown({
    required this.type,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          type,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ),
    );
  }
}

class _BuilderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String projectName;
  final String deviceMode;
  final bool canUndo;
  final bool isSaving;
  final DateTime? lastSavedTime;
  final bool isPreviewMode;
  final bool previewHorizontal;
  final VoidCallback onPreview;
  final VoidCallback onPublish;
  final VoidCallback onBack;
  final VoidCallback onTogglePreview;
  final Function(bool) onSetPreviewOrientation;
  final VoidCallback? onUndo;
  final Function(String) onDeviceChange;

  const _BuilderAppBar({
    required this.projectName,
    required this.deviceMode,
    required this.canUndo,
    required this.isSaving,
    required this.lastSavedTime,
    required this.isPreviewMode,
    required this.previewHorizontal,
    required this.onPreview,
    required this.onPublish,
    required this.onBack,
    required this.onTogglePreview,
    required this.onSetPreviewOrientation,
    required this.onUndo,
    required this.onDeviceChange,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    // Use local variables for explicit comparisons
    final isSavingValue = isSaving;
    final canUndoValue = canUndo;
    final isPreviewModeValue = isPreviewMode;
    final previewHorizontalValue = previewHorizontal;

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
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                if (isSavingValue == true) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Saving',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else if (lastSavedTime != null) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Saved',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.undo, size: 18),
            onPressed: onUndo,
            color: canUndoValue == true
                ? AppTheme.textMuted
                : AppTheme.darkBorder,
          ),

          // ── Preview Mode Exit + Orientation Controls ────────────────
          if (isPreviewModeValue == true) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => onSetPreviewOrientation(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: previewHorizontalValue == true
                          ? AppTheme.primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: previewHorizontalValue == true
                            ? AppTheme.primary
                            : AppTheme.darkBorder,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: previewHorizontalValue == true
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => onSetPreviewOrientation(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: previewHorizontalValue == false
                          ? AppTheme.primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: previewHorizontalValue == false
                            ? AppTheme.primary
                            : AppTheme.darkBorder,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_downward,
                      size: 14,
                      color: previewHorizontalValue == false
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onTogglePreview,
              color: AppTheme.textMuted,
              tooltip: 'Exit Preview Mode',
            ),
            const SizedBox(width: 6),
          ],

          // ── Navigation Buttons (hidden in preview mode) ──────────────
          if (isPreviewModeValue == false) ...[
            TextButton.icon(
              onPressed: onPreview,
              icon: const Icon(
                Icons.visibility,
                size: 16,
                color: AppTheme.primary,
              ),
              label: const Text(
                'Preview',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ),
          ],
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
                  color: Colors.white,
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
                      // Canvas area — properly constrained to prevent overflow
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: CanvasArea(
                            screen: activeScreen,
                            provider: provider,
                            onWidgetSelected: onWidgetTap,
                          ),
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
// Left sidebar with tool buttons (narrow - icons + labels only)
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
      width: 80,
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(right: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _toolButton(
              icon: Icons.widgets_outlined,
              label: 'Widgets',
              panel: _Panel.widgets,
            ),
            const SizedBox(height: 18),
            _toolButton(
              icon: Icons.phone_android_outlined,
              label: 'Screens',
              panel: _Panel.screens,
            ),
            const SizedBox(height: 18),
            _toolButton(
              icon: Icons.palette_outlined,
              label: 'Theme',
              panel: _Panel.theme,
            ),
            const SizedBox(height: 18),
            _toolButton(
              icon: Icons.storage_outlined,
              label: 'Backend',
              panel: _Panel.backend,
            ),
            const Spacer(),
          ],
        ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? AppTheme.primary : AppTheme.textMuted,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppTheme.primary : AppTheme.textMuted,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Left panel content (shows selected tab: Widgets, Screens, Theme, Backend)
// ══════════════════════════════════════════════════════════════════════════════
class _LeftPanelContent extends StatelessWidget {
  final _Panel activePanel;
  final BuilderProvider provider;

  const _LeftPanelContent({required this.activePanel, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: AppTheme.darkBg,
        border: Border(right: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: _toolContent(context),
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
// Screen item with inline edit capability
// ══════════════════════════════════════════════════════════════════════════════
class _ScreenItem extends StatefulWidget {
  final int index;
  final AppScreen screen;
  final bool active;
  final VoidCallback onSelect;
  final Function(String) onRename;

  const _ScreenItem({
    required this.index,
    required this.screen,
    required this.active,
    required this.onSelect,
    required this.onRename,
  });

  @override
  State<_ScreenItem> createState() => _ScreenItemState();
}

class _ScreenItemState extends State<_ScreenItem> {
  late TextEditingController _editController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.screen.name);
  }

  @override
  void didUpdateWidget(covariant _ScreenItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screen.name != widget.screen.name) {
      _editController.text = widget.screen.name;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _enableEdit() {
    setState(() {
      _isEditing = true;
      _editController.text = widget.screen.name;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _editController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _editController.text.length,
        );
      }
    });
  }

  void _submitEdit() {
    final newName = _editController.text.trim();
    if (newName.isNotEmpty && newName != widget.screen.name) {
      widget.onRename(newName);
    }
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  void _cancelEdit() {
    setState(() => _isEditing = false);
    _editController.text = widget.screen.name;
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary),
        ),
        child: Row(
          children: [
            Icon(Icons.phone_android, size: 15, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _editController,
                autofocus: true,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Screen name',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                ),
                onSubmitted: (_) => _submitEdit(),
                onEditingComplete: _submitEdit,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _submitEdit,
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _cancelEdit,
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: widget.active
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.active ? AppTheme.primary : AppTheme.darkBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.phone_android,
              size: 15,
              color: widget.active ? AppTheme.primary : AppTheme.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.screen.name,
                style: TextStyle(
                  color: widget.active
                      ? AppTheme.primary
                      : AppTheme.textPrimary,
                  fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '${widget.screen.widgets.length}w',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _enableEdit,
              child: const Icon(
                Icons.edit,
                size: 14,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
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
          return _ScreenItem(
            index: i,
            screen: s,
            active: active,
            onSelect: () => provider.setActiveScreen(i),
            onRename: (newName) => provider.renameScreen(i, newName),
          );
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _addDialog(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.darkBorder),
            ),
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

  static const _colors = [
    // Row 1 Reds
    '#DC143C',
    '#FF6B6B',
    '#FF6347',
    '#FF69B4',
    '#C41E3A',
    '#FF2400',
    '#FA8072',
    '#8B0000',
    // Row 2 Oranges
    '#FF8C00',
    '#FFBF00',
    '#FFDAB9',
    '#FBCEB1',
    '#CC5500',
    '#FF4500',
    '#B87333',
    '#FFD700',
    // Row 3 Yellows
    '#FFD700',
    '#FFF44F',
    '#E4D00A',
    '#FFFACD',
    '#FFFFF0',
    '#F7E7CE',
    '#F5DEB3',
    '#C2B280',
    // Row 4 Greens
    '#50C878',
    '#98FF98',
    '#32CD32',
    '#228B22',
    '#808000',
    '#8FBC8F',
    '#008080',
    '#00A86B',
    // Row 5 Blues
    '#4169E1',
    '#87CEEB',
    '#000080',
    '#0047AB',
    '#4682B4',
    '#B0E0E6',
    '#CCCCFF',
    '#4B0082',
    // Row 6 Purples
    '#EE82EE',
    '#E6E6FA',
    '#8B008B',
    '#DDA0DD',
    '#FF00FF',
    '#FF77FF',
    '#6F2DA8',
    '#BF94E4',
    // Row 7 Neutrals
    '#FFFFFF',
    '#C0C0C0',
    '#808080',
    '#36454F',
    '#708090',
    '#000000',
    '#F5F5DC',
    '#483C32',
    // Row 8 Futuristic
    '#39FF14',
    '#0BFFFF',
    '#FF1493',
    '#FFFF00',
    '#BF00FF',
    '#00FF41',
    '#00B4FF',
    '#FF0000',
  ];
  static const _fonts = [
    'Poppins',
    'Roboto',
    'Inter',
    'Lato',
    'Montserrat',
    'Nunito',
    'Raleway',
    'Oswald',
    'Playfair Display',
    'Ubuntu',
    'Merriweather',
    'Open Sans',
    'Orbitron',
    'Audiowide',
  ];

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

  Widget _styleCard(ProjectTheme theme, String label, IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary, size: 32),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = provider.project?.theme ?? const ProjectTheme();

    return Container(
      color: const Color(0xFF1A1A2E),
      child: SingleChildScrollView(
        child: ListView(
          padding: const EdgeInsets.all(14),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFF00FF41).withOpacity(0.8),
                    width: 3,
                  ),
                ),
              ),
              child: const Text(
                'PRIMARY COLOR',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((hex) {
                final color = Color(int.parse(hex.replaceAll('#', '0xFF')));
                final selected = theme.primaryColor == hex;
                return GestureDetector(
                  onTap: () => _setPrimary(theme, hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFF0BFFFF).withOpacity(0.8),
                    width: 3,
                  ),
                ),
              ),
              child: const Text(
                'FONT FAMILY',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ..._fonts.map((f) {
              final selected = theme.fontFamily == f;
              return GestureDetector(
                onTap: () => _setFont(theme, f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withOpacity(0.1)
                        : AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.darkBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                            fontFamily: f != 'Poppins' ? f : null,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFFFF1493).withOpacity(0.8),
                    width: 3,
                  ),
                ),
              ),
              child: const Text(
                'APP STYLE',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                _styleCard(theme, 'Dark', Icons.dark_mode),
                _styleCard(theme, 'Light', Icons.light_mode),
                _styleCard(theme, 'Neon', Icons.flash_on),
                _styleCard(theme, 'Glassmorphism', Icons.blur_on),
                _styleCard(theme, 'Cyberpunk', Icons.terminal),
                _styleCard(theme, 'Minimal', Icons.crop_square),
                _styleCard(theme, 'Retro', Icons.gamepad),
                _styleCard(theme, 'Aurora', Icons.wb_twighlight),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

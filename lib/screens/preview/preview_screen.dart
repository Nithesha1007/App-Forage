import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/project_model.dart';
import '../../models/screen_model.dart';
import '../../services/firestore_service.dart';
import '../builder/canvas_area.dart';
import '../../widgets/floating_ai_button.dart';

class PreviewScreen extends StatefulWidget {
  final String projectId;
  const PreviewScreen({super.key, required this.projectId});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  ProjectModel? _project;
  bool _loading = true;
  bool _isHorizontal = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await FirestoreService().getProject(widget.projectId);
    setState(() {
      _project = p;
      _loading = false;
    });
  }

  List<Widget> _intersperse(List<Widget> items, Widget separator) {
    if (items.isEmpty) return [];
    return [
      for (int i = 0; i < items.length; i++) ...[
        items[i],
        if (i < items.length - 1) separator,
      ],
    ];
  }

  Color get _primaryColor {
    try {
      return Color(
        int.parse(
          (_project?.theme.primaryColor ?? '#00C896').replaceAll('#', '0xFF'),
        ),
      );
    } catch (_) {
      return AppTheme.primary;
    }
  }

  /// Build the ordered list of preview frames:
  /// [Screen 0 (home), Search Screen, Screen 1, Screen 2, …]
  List<Widget> _buildFrames(List<AppScreen> screens) {
    final frames = <Widget>[];

    if (screens.isNotEmpty) {
      frames.add(
        _PreviewScreenFrame(
          screen: screens.first,
          primaryColor: _primaryColor,
        ),
      );
    }

    // Search screen is always the second frame
    if (_project != null) {
      frames.add(
        _SearchScreenFrame(
          project: _project!,
          primaryColor: _primaryColor,
        ),
      );
    }

    for (int i = 1; i < screens.length; i++) {
      frames.add(
        _PreviewScreenFrame(
          screen: screens[i],
          primaryColor: _primaryColor,
        ),
      );
    }

    return frames;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final screens = _project?.screens ?? [];
    final frames = _buildFrames(screens);
    final totalFrames = frames.length;

    return Scaffold(
      backgroundColor: const Color(0xFF060F1A),
      floatingActionButton: const FloatingAiButton(),
      appBar: AppBar(
        backgroundColor: AppTheme.darkCard,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/builder/${widget.projectId}'),
        ),
        title: Text('Preview — ${_project?.name ?? ''}'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/publish/${widget.projectId}'),
            icon: const Icon(
              Icons.rocket_launch,
              size: 16,
              color: AppTheme.primary,
            ),
            label: const Text(
              'Publish',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: screens.isEmpty && _project == null
          ? Center(
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
            )
          : Column(
              children: [
                // ── Orientation Toggle Bar ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.darkCard,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.darkBorder),
                    ),
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
                      _OrientationChip(
                        label: 'Horizontal',
                        icon: Icons.arrow_forward,
                        active: _isHorizontal,
                        onTap: () => setState(() => _isHorizontal = true),
                      ),
                      const SizedBox(width: 8),
                      _OrientationChip(
                        label: 'Vertical',
                        icon: Icons.arrow_downward,
                        active: !_isHorizontal,
                        onTap: () => setState(() => _isHorizontal = false),
                      ),
                      const Spacer(),
                      Text(
                        '$totalFrames screen${totalFrames != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Screens ──────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection:
                        _isHorizontal ? Axis.horizontal : Axis.vertical,
                    padding: const EdgeInsets.all(24),
                    child: _isHorizontal
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _intersperse(
                              frames,
                              const SizedBox(width: 24),
                            ),
                          )
                        : Column(
                            children: _intersperse(
                              frames,
                              const SizedBox(height: 24),
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Orientation toggle chip ───────────────────────────────────────────────────
class _OrientationChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _OrientationChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? AppTheme.primary : AppTheme.darkBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: active ? AppTheme.primary : AppTheme.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? AppTheme.primary : AppTheme.textMuted,
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Preview Screen Frame — static layout preview with SafeArea simulation
// ══════════════════════════════════════════════════════════════════════════════
class _PreviewScreenFrame extends StatelessWidget {
  final AppScreen screen;
  final Color primaryColor;

  const _PreviewScreenFrame({
    required this.screen,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return _PhoneShell(
      primaryColor: primaryColor,
      statusLabel: screen.name,
      child: screen.widgets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone_android,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Empty screen',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              // Top safe-area gap below status bar
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: screen.widgets
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: WidgetRenderer(widgetModel: w),
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Search Screen Frame — always second in preview, interactive search
// ══════════════════════════════════════════════════════════════════════════════
class _SearchScreenFrame extends StatefulWidget {
  final ProjectModel project;
  final Color primaryColor;

  const _SearchScreenFrame({
    required this.project,
    required this.primaryColor,
  });

  @override
  State<_SearchScreenFrame> createState() => _SearchScreenFrameState();
}

class _SearchScreenFrameState extends State<_SearchScreenFrame> {
  String _query = '';
  DatabaseTable? _expanded;

  List<DatabaseTable> get _tables => widget.project.backendConfig.tables;

  List<DatabaseTable> get _filtered {
    if (_query.trim().isEmpty) return [];
    final q = _query.trim().toLowerCase();
    return _tables
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              t.fields.any((f) => f.toLowerCase().contains(q)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor;
    final results = _filtered;

    return _PhoneShell(
      primaryColor: primary,
      statusLabel: 'Search',
      child: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────
          Container(
            height: 52,
            color: primary,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(Icons.search, color: Colors.white.withValues(alpha: 0.85), size: 22),
              ],
            ),
          ),

          // ── Search Field ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() {
                _query = v;
                _expanded = null;
              }),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: 'Search anything…',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, size: 18, color: primary),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() {
                          _query = '';
                          _expanded = null;
                        }),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // ── Results ──────────────────────────────────────────────
          Expanded(
            child: _query.trim().isEmpty
                ? _EmptySearchHint(primaryColor: primary, hasTables: _tables.isNotEmpty)
                : results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 40,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No results for "$_query"',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        itemCount: results.length,
                        itemBuilder: (ctx, i) {
                          final table = results[i];
                          final isOpen = _expanded?.id == table.id;
                          return _SearchResultCard(
                            table: table,
                            primaryColor: primary,
                            isExpanded: isOpen,
                            query: _query,
                            onTap: () => setState(
                              () => _expanded = isOpen ? null : table,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Search result card with expandable field keys ─────────────────────────────
class _SearchResultCard extends StatelessWidget {
  final DatabaseTable table;
  final Color primaryColor;
  final bool isExpanded;
  final String query;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.table,
    required this.primaryColor,
    required this.isExpanded,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? primaryColor.withValues(alpha: 0.5)
                : Colors.grey.shade200,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.table_chart_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          '${table.fields.length} field${table.fields.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),

            // Expandable field keys
            if (isExpanded) ...[
              Divider(height: 1, color: Colors.grey.shade100),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIELDS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: table.fields.map((f) {
                        final match = f.toLowerCase().contains(
                          query.toLowerCase(),
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: match
                                ? primaryColor.withValues(alpha: 0.15)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: match
                                  ? primaryColor.withValues(alpha: 0.4)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.key_rounded,
                                size: 10,
                                color: match
                                    ? primaryColor
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                f,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: match
                                      ? primaryColor
                                      : Colors.grey.shade600,
                                  fontWeight: match
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty search state hint ───────────────────────────────────────────────────
class _EmptySearchHint extends StatelessWidget {
  final Color primaryColor;
  final bool hasTables;

  const _EmptySearchHint({required this.primaryColor, required this.hasTables});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search, size: 36, color: primaryColor.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),
          Text(
            hasTables ? 'Search your data' : 'No backend tables yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasTables
                ? 'Type to search tables and fields'
                : 'Add tables in the Backend panel\nto enable search',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared phone shell — wraps any content in the phone mockup frame with
// a simulated status bar (top safe area) and home indicator (bottom safe area).
// ══════════════════════════════════════════════════════════════════════════════
class _PhoneShell extends StatelessWidget {
  final Color primaryColor;
  final String statusLabel;
  final Widget child;

  const _PhoneShell({
    required this.primaryColor,
    required this.statusLabel,
    required this.child,
  });

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
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 48,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // ── Simulated status bar (top safe area) ─────────────
            Container(
              height: 36,
              color: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
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

            // ── Screen content (safe area insets applied) ─────────
            Expanded(child: child),

            // ── Simulated home indicator (bottom safe area) ───────
            Container(
              height: 20,
              color: Colors.white,
              alignment: Alignment.center,
              child: Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

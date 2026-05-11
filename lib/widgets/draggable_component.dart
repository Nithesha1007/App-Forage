import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/widget_model.dart';

/// A widget that wraps any canvas widget to make it:
///   • Selectable (tap → highlight + show properties panel)
///   • Draggable (long-press drag → reposition on canvas)
///   • Deletable (shows a trash icon when selected)
class DraggableComponent extends StatefulWidget {
  final WidgetModel model;
  final bool isSelected;
  final Widget child;
  final VoidCallback onTap;
  final Function(double dx, double dy) onMove;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const DraggableComponent({
    super.key,
    required this.model,
    required this.isSelected,
    required this.child,
    required this.onTap,
    required this.onMove,
    required this.onDelete,
    required this.onDuplicate,
  });
  @override
  State<DraggableComponent> createState() => _DraggableComponentState();
}

class _DraggableComponentState extends State<DraggableComponent> {
  Offset _dragStart = Offset.zero;
  Offset _posStart = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: (details) {
        widget.onTap(); // auto-select on drag
        _dragStart = details.globalPosition;
        _posStart = Offset(widget.model.x, widget.model.y);
      },
      onPanUpdate: (details) {
        final delta = details.globalPosition - _dragStart;
        widget.onMove(
          (_posStart.dx + delta.dx).clamp(0, 320),
          (_posStart.dy + delta.dy).clamp(0, 640),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Main widget ────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: widget.isSelected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : const BoxDecoration(),
            child: widget.child,
          ),

          // ── Selection handles (only when selected) ─────────────────────
          if (widget.isSelected) ...[
            // Top-left: drag handle indicator
            Positioned(
              top: -6,
              left: -6,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Top-right: drag handle
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Bottom-left: drag handle
            Positioned(
              bottom: -6,
              left: -6,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Bottom-right: drag handle
            Positioned(
              bottom: -6,
              right: -6,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Floating toolbar
            Positioned(
              top: -40,
              right: 0,
              child: _FloatingToolbar(
                onDelete: widget.onDelete,
                onDuplicate: widget.onDuplicate,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Floating mini toolbar ─────────────────────────────────────────────────────
class _FloatingToolbar extends StatelessWidget {
  final VoidCallback onDelete, onDuplicate;
  const _FloatingToolbar({required this.onDelete, required this.onDuplicate});

  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolBtn(
          icon: Icons.copy_outlined,
          color: AppTheme.textMuted,
          onTap: onDuplicate,
          tooltip: 'Duplicate',
        ),
        Container(
          width: 1,
          height: 16,
          color: AppTheme.darkBorder,
          margin: const EdgeInsets.symmetric(horizontal: 2),
        ),
        _ToolBtn(
          icon: Icons.delete_outline,
          color: AppTheme.accent,
          onTap: onDelete,
          tooltip: 'Delete',
        ),
      ],
    ),
  );
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _ToolBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(icon, color: color, size: 16),
      ),
    ),
  );
}

/// A lightweight drag-and-drop target that sits on the canvas.
/// Accepts a widget type string dropped from [WidgetPanel].
class CanvasDragTarget extends StatelessWidget {
  final Function(String widgetType, Offset localPosition) onAccept;
  final Widget child;

  const CanvasDragTarget({
    super.key,
    required this.onAccept,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final local = box.globalToLocal(details.offset);
          onAccept(details.data, local);
        }
      },
      builder: (_, candidateData, __) {
        final isDraggingOver = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: isDraggingOver
              ? BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: AppTheme.primary.withOpacity(0.05),
                )
              : null,
          child: child,
        );
      },
    );
  }
}

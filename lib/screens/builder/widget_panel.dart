import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

const _categories = {
  'Basic': [
    {'type': 'text', 'label': 'Text', 'icon': '📝', 'color': 0xFF6C63FF},
    {
      'type': 'richtext',
      'label': 'Rich Text',
      'icon': '✍',
      'color': 0xFF9B59B6,
    },
    {'type': 'button', 'label': 'Button', 'icon': '⬛', 'color': 0xFF00C896},
    {'type': 'iconbtn', 'label': 'Icon Btn', 'icon': '🔘', 'color': 0xFF3498DB},
    {'type': 'fab', 'label': 'FAB', 'icon': '⊕', 'color': 0xFFE74C3C},
    {'type': 'image', 'label': 'Image', 'icon': '🖼', 'color': 0xFF3498DB},
    {'type': 'icon', 'label': 'Icon', 'icon': '⭐', 'color': 0xFFF39C12},
    {'type': 'divider', 'label': 'Divider', 'icon': '—', 'color': 0xFF95A5A6},
    {'type': 'badge', 'label': 'Badge', 'icon': '🔴', 'color': 0xFFE74C3C},
    {'type': 'chip', 'label': 'Chip', 'icon': '🏷', 'color': 0xFF16A085},
    {
      'type': 'circleavatar',
      'label': 'Circle Avatar',
      'icon': '⭕',
      'color': 0xFF9B59B6,
    },
    {
      'type': 'container',
      'label': 'Container',
      'icon': '📦',
      'color': 0xFF34495E,
    },
  ],
  'Forms': [
    {'type': 'input', 'label': 'Text Field', 'icon': '📋', 'color': 0xFFE74C3C},
    {
      'type': 'multiline',
      'label': 'Multi-line',
      'icon': '📄',
      'color': 0xFFC0392B,
    },
    {'type': 'dropdown', 'label': 'Dropdown', 'icon': '▼', 'color': 0xFF9B59B6},
    {
      'type': 'multiselect',
      'label': 'Multi-Select',
      'icon': '☑',
      'color': 0xFF1ABC9C,
    },
    {
      'type': 'autocomplete',
      'label': 'Autocomplete',
      'icon': '💬',
      'color': 0xFF2980B9,
    },
    {'type': 'checkbox', 'label': 'Checkbox', 'icon': '☑', 'color': 0xFF1ABC9C},
    {'type': 'radio', 'label': 'Radio', 'icon': '⭕', 'color': 0xFF3498DB},
    {'type': 'switch_w', 'label': 'Switch', 'icon': '🔄', 'color': 0xFF2ECC71},
    {
      'type': 'switch_listtile',
      'label': 'Switch ListTile',
      'icon': '🔄',
      'color': 0xFF2ECC71,
    },
    {
      'type': 'checkbox_listtile',
      'label': 'Checkbox ListTile',
      'icon': '☑',
      'color': 0xFF1ABC9C,
    },
    {'type': 'slider', 'label': 'Slider', 'icon': '⊲', 'color': 0xFFF1C40F},
    {
      'type': 'rangeslider',
      'label': 'Range Slider',
      'icon': '⊲⊳',
      'color': 0xFFE67E22,
    },
    {'type': 'form', 'label': 'Form', 'icon': '📄', 'color': 0xFF16A085},
  ],
  'Layout': [
    {'type': 'card', 'label': 'Card', 'icon': '🃏', 'color': 0xFF6C63FF},
    {'type': 'padding', 'label': 'Padding', 'icon': '⬛', 'color': 0xFF8E44AD},
    {'type': 'row', 'label': 'Row', 'icon': '↔', 'color': 0xFFE67E22},
    {'type': 'column', 'label': 'Column', 'icon': '↨', 'color': 0xFFC0392B},
    {'type': 'list', 'label': 'List', 'icon': '📋', 'color': 0xFF00C896},
    {'type': 'grid', 'label': 'Grid', 'icon': '⊞', 'color': 0xFFFF6B35},
    {
      'type': 'navbar',
      'label': 'Bottom Nav',
      'icon': '🧭',
      'color': 0xFF2C3E50,
    },
    {'type': 'appbar', 'label': 'App Bar', 'icon': '📊', 'color': 0xFF16A085},
    {'type': 'tabs', 'label': 'Tabs', 'icon': '📑', 'color': 0xFF8E44AD},
    {'type': 'stepper', 'label': 'Stepper', 'icon': '1️⃣', 'color': 0xFF27AE60},
    {
      'type': 'listview',
      'label': 'ListView',
      'icon': '📑',
      'color': 0xFF1ABC9C,
    },
    {
      'type': 'listtile',
      'label': 'ListTile',
      'icon': '📄',
      'color': 0xFF3498DB,
    },
    {
      'type': 'singlechildscrollview',
      'label': 'Scroll View',
      'icon': '↕',
      'color': 0xFF1E90FF,
    },
  ],
  'Input Controls': [
    {'type': 'rating', 'label': 'Rating', 'icon': '⭐', 'color': 0xFFFDB913},
    {
      'type': 'datepick',
      'label': 'Date Picker',
      'icon': '📅',
      'color': 0xFF2980B9,
    },
    {
      'type': 'timepick',
      'label': 'Time Picker',
      'icon': '🕒',
      'color': 0xFF8E44AD,
    },
    {
      'type': 'progress',
      'label': 'Progress',
      'icon': '📊',
      'color': 0xFF27AE60,
    },
    {'type': 'pincode', 'label': 'OTP/PIN', 'icon': '🔐', 'color': 0xFFE74C3C},
    {
      'type': 'signature',
      'label': 'Signature',
      'icon': '✍',
      'color': 0xFF34495E,
    },
  ],
  'Media': [
    {'type': 'chart', 'label': 'Chart', 'icon': '📈', 'color': 0xFF2980B9},
    {'type': 'map', 'label': 'Map', 'icon': '🗺', 'color': 0xFF27AE60},
    {'type': 'video', 'label': 'Video', 'icon': '🎬', 'color': 0xFFC0392B},
    {
      'type': 'carousel',
      'label': 'Carousel',
      'icon': '🎠',
      'color': 0xFF8E44AD,
    },
    {'type': 'lottie', 'label': 'Animation', 'icon': '✨', 'color': 0xFF9B59B6},
    {'type': 'camera', 'label': 'Camera', 'icon': '📷', 'color': 0xFF3498DB},
    {
      'type': 'gallery',
      'label': 'Image Gallery',
      'icon': '🖼',
      'color': 0xFF2980B9,
    },
    {'type': 'qrcode', 'label': 'QR Code', 'icon': '📲', 'color': 0xFF34495E},
    {'type': 'webview', 'label': 'Web View', 'icon': '🌐', 'color': 0xFF1ABC9C},
  ],
  'Feedback': [
    {
      'type': 'snackbar',
      'label': 'Snackbar',
      'icon': '💬',
      'color': 0xFF16A085,
    },
    {'type': 'tooltip', 'label': 'Tooltip', 'icon': '💡', 'color': 0xFFF39C12},
    {'type': 'dialog', 'label': 'Dialog', 'icon': '📦', 'color': 0xFF2980B9},
    {'type': 'alert', 'label': 'Alert', 'icon': '⚠', 'color': 0xFFE74C3C},
    {
      'type': 'bottomsheet',
      'label': 'Bottom Sheet',
      'icon': '📂',
      'color': 0xFF8E44AD,
    },
    {'type': 'loader', 'label': 'Loader', 'icon': '⌛', 'color': 0xFF27AE60},
    {'type': 'skeleton', 'label': 'Skeleton', 'icon': '░', 'color': 0xFF95A5A6},
  ],
  'Social & Auth': [
    {
      'type': 'googlelogin',
      'label': 'Google Login',
      'icon': '🔐',
      'color': 0xFFDB4437,
    },
    {
      'type': 'fblogin',
      'label': 'Facebook Login',
      'icon': '🔐',
      'color': 0xFF4267B2,
    },
    {
      'type': 'sharebutton',
      'label': 'Share Button',
      'icon': '↗',
      'color': 0xFF1ABC9C,
    },
    {
      'type': 'likebutton',
      'label': 'Like Button',
      'icon': '❤',
      'color': 0xFFE74C3C,
    },
    {
      'type': 'followbtn',
      'label': 'Follow Button',
      'icon': '➕',
      'color': 0xFF3498DB,
    },
    {'type': 'comment', 'label': 'Comment', 'icon': '💬', 'color': 0xFF16A085},
  ],
  'Navigation': [
    {
      'type': 'breadcrumb',
      'label': 'Breadcrumb',
      'icon': '▶',
      'color': 0xFF2980B9,
    },
    {
      'type': 'pagination',
      'label': 'Pagination',
      'icon': '«»',
      'color': 0xFF34495E,
    },
    {'type': 'menu', 'label': 'Menu', 'icon': '☰', 'color': 0xFF16A085},
    {'type': 'drawer', 'label': 'Drawer', 'icon': '📂', 'color': 0xFF8E44AD},
    {
      'type': 'navdrawer',
      'label': 'Nav Drawer',
      'icon': '🎯',
      'color': 0xFF9B59B6,
    },
  ],
  'Composite': [
    {'type': 'todo', 'label': 'Todo Widget', 'icon': '✓', 'color': 0xFF00C896},
  ],
  'Advanced': [
    {
      'type': 'gesture_detector',
      'label': 'GestureDetector',
      'icon': '👆',
      'color': 0xFF2980B9,
    },
  ],
  'Icons': [
    {
      'type': 'icon_home',
      'label': 'Home Icon',
      'icon': '🏠',
      'color': 0xFF3498DB,
    },
    {
      'type': 'icon_search',
      'label': 'Search Icon',
      'icon': '🔍',
      'color': 0xFF1ABC9C,
    },
    {
      'type': 'icon_settings',
      'label': 'Settings Icon',
      'icon': '⚙️',
      'color': 0xFF95A5A6,
    },
    {
      'type': 'icon_user',
      'label': 'User Icon',
      'icon': '👤',
      'color': 0xFF9B59B6,
    },
    {
      'type': 'icon_favorite',
      'label': 'Favorite Icon',
      'icon': '❤️',
      'color': 0xFFE74C3C,
    },
    {
      'type': 'icon_star',
      'label': 'Star Icon',
      'icon': '⭐',
      'color': 0xFFF39C12,
    },
    {
      'type': 'icon_notification',
      'label': 'Notification Icon',
      'icon': '🔔',
      'color': 0xFFE67E22,
    },
    {
      'type': 'icon_menu',
      'label': 'Menu Icon',
      'icon': '☰',
      'color': 0xFF2C3E50,
    },
    {
      'type': 'icon_camera',
      'label': 'Camera Icon',
      'icon': '📷',
      'color': 0xFF3498DB,
    },
    {
      'type': 'icon_chat',
      'label': 'Chat Icon',
      'icon': '💬',
      'color': 0xFF27AE60,
    },
    {
      'type': 'icon_lock',
      'label': 'Lock Icon',
      'icon': '🔒',
      'color': 0xFFC0392B,
    },
    {
      'type': 'icon_location',
      'label': 'Location Icon',
      'icon': '📍',
      'color': 0xFFE74C3C,
    },
    {
      'type': 'icon_shopping_cart',
      'label': 'Shopping Cart Icon',
      'icon': '🛒',
      'color': 0xFF16A085,
    },
    {
      'type': 'icon_phone',
      'label': 'Phone Icon',
      'icon': '☎️',
      'color': 0xFF2980B9,
    },
    {
      'type': 'icon_email',
      'label': 'Email Icon',
      'icon': '✉️',
      'color': 0xFF8E44AD,
    },
  ],
};

class WidgetPanel extends StatefulWidget {
  final Function(String type) onAdd;
  const WidgetPanel({super.key, required this.onAdd});

  @override
  State<WidgetPanel> createState() => _WidgetPanelState();
}

class _WidgetPanelState extends State<WidgetPanel> {
  String _activeCategory = 'Basic';
  String _search = '';

  List<Map> get _items {
    if (_search.isNotEmpty) {
      return _categories.values
          .expand((v) => v)
          .where(
            (w) => (w['label'] as String).toLowerCase().contains(
              _search.toLowerCase(),
            ),
          )
          .toList()
          .cast<Map>();
    }
    return (_categories[_activeCategory] ?? []).cast<Map>();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search widgets...',
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppTheme.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
          ),
        ),

        // Spacing between search and tabs
        if (_search.isEmpty) const SizedBox(height: 10),

        // Category tabs (hidden when searching)
        if (_search.isEmpty)
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: _categories.keys.map((cat) {
                final active = cat == _activeCategory;
                return GestureDetector(
                  onTap: () => setState(() => _activeCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: active
                            ? AppTheme.primary.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: active ? AppTheme.primary : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: false,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // Spacing between tabs and grid
        if (_search.isEmpty) const SizedBox(height: 10),

        // Widget grid
        Expanded(
          child: SingleChildScrollView(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final w = _items[i];
                final color = Color(w['color'] as int);
                final widgetType = w['type'] as String;

                // For these specific widgets, pass full Map data instead of just type string
                final shouldPassMap =
                    {
                      'listtile',
                      'switch_listtile',
                      'checkbox_listtile',
                      'gesture_detector',
                      'listview',
                    }.contains(widgetType) ||
                    widgetType.startsWith('icon_');

                return Draggable<Object>(
                  data: shouldPassMap ? w : widgetType,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _Tile(w, color, () {}, isSidebar: false),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.4,
                    child: _Tile(w, color, () {}, isSidebar: true),
                  ),
                  child: _Tile(
                    w,
                    color,
                    () => widget.onAdd(w['type'] as String),
                    isSidebar: false,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  final Map w;
  final Color color;
  final VoidCallback onTap;
  final bool isSidebar;
  const _Tile(this.w, this.color, this.onTap, {this.isSidebar = false});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: widget.isSidebar
            ? null // no box for sidebar
            : BoxDecoration(
                color: _hovered
                    ? widget.color.withOpacity(0.1)
                    : AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hovered ? widget.color : AppTheme.darkBorder,
                ),
              ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.w['icon'] as String,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              widget.w['label'] as String,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

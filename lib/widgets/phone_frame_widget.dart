import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/project_model.dart';

enum PhoneSize { mobile, tablet }

class PhoneFrameWidget extends StatelessWidget {
  final Widget child;
  final ProjectTheme theme;
  final String screenName;
  final PhoneSize size;
  final bool showStatusBar;
  final bool showHomeIndicator;

  const PhoneFrameWidget({
    super.key,
    required this.child,
    required this.theme,
    required this.screenName,
    this.size = PhoneSize.mobile,
    this.showStatusBar = true,
    this.showHomeIndicator = true,
  });

  // ── Dimensions ─────────────────────────────────────────────────────────
  double get _frameWidth => size == PhoneSize.mobile ? 340 : 500;
  double get _frameHeight => size == PhoneSize.mobile ? 680 : 720;
  double get _radius => size == PhoneSize.mobile ? 36 : 20;
  double get _borderWidth => 7;

  Color get _primaryColor {
    try {
      return Color(int.parse(theme.primaryColor.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _frameWidth,
      height: _frameHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: const Color(0xFF2E2E4E), width: _borderWidth),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 16),
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - _borderWidth),
        child: Column(
          children: [
            // ── Notch / Camera ─────────────────────────────────────────────
            _Notch(size: size),

            // ── Status bar ─────────────────────────────────────────────────
            if (showStatusBar)
              _StatusBar(primaryColor: _primaryColor, screenName: screenName),

            // ── App content ────────────────────────────────────────────────
            Expanded(
              child: Container(
                color: theme.isDarkMode
                    ? const Color(0xFF121212)
                    : Colors.white,
                child: child,
              ),
            ),

            // ── Home indicator bar ─────────────────────────────────────────
            if (showHomeIndicator)
              _HomeIndicator(
                primaryColor: _primaryColor,
                isDark: theme.isDarkMode,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Notch / camera pill ────────────────────────────────────────────────────────
class _Notch extends StatelessWidget {
  final PhoneSize size;
  const _Notch({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: size == PhoneSize.mobile ? 28 : 16,
    color: const Color(0xFF0D0D1E),
    child: Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (size == PhoneSize.mobile) ...[
            Container(
              width: 90,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A2E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3A3A5E),
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Container(
              width: 40,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    ),
  );
}

// ── Status bar ────────────────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  final Color primaryColor;
  final String screenName;
  const _StatusBar({required this.primaryColor, required this.screenName});

  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    color: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        // App name
        Expanded(
          child: Text(
            screenName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Status icons
        const Row(
          children: [
            Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Icon(Icons.wifi, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Icon(Icons.battery_full, color: Colors.white, size: 14),
          ],
        ),
      ],
    ),
  );
}

// ── Home indicator ────────────────────────────────────────────────────────────
class _HomeIndicator extends StatelessWidget {
  final Color primaryColor;
  final bool isDark;
  const _HomeIndicator({required this.primaryColor, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    color: isDark ? const Color(0xFF121212) : Colors.white,
    child: Center(
      child: Container(
        width: 100,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? Colors.white24 : Colors.black26,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}

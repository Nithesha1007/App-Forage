import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/admin_service.dart';
import '../admin_dashboard.dart';

class AdminSecurity extends StatefulWidget {
  final AdminService service;
  const AdminSecurity({super.key, required this.service});

  @override
  State<AdminSecurity> createState() => _AdminSecurityState();
}

class _AdminSecurityState extends State<AdminSecurity> {
  bool _emailAuth = true;
  bool _googleAuth = true;
  bool _phoneAuth = false;
  bool _twoFactor = false;
  bool _forceHttps = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(title: 'Security & Access Control'),

          // Auth methods
          _Section(
            title: 'Authentication Methods',
            icon: Icons.lock_outline,
            color: Colors.blueAccent,
            children: [
              _Toggle(
                'Email / Password',
                _emailAuth,
                (v) => setState(() => _emailAuth = v),
              ),
              _Toggle(
                'Google Sign-In',
                _googleAuth,
                (v) => setState(() => _googleAuth = v),
              ),
              _Toggle(
                'Phone OTP',
                _phoneAuth,
                (v) => setState(() => _phoneAuth = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Security settings
          _Section(
            title: 'Security Settings',
            icon: Icons.security_rounded,
            color: Colors.purpleAccent,
            children: [
              _Toggle(
                'Two-Factor Authentication',
                _twoFactor,
                (v) => setState(() => _twoFactor = v),
              ),
              _Toggle(
                'Force HTTPS',
                _forceHttps,
                (v) => setState(() => _forceHttps = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Firestore rules
          _Section(
            title: 'Firestore Security Rules',
            icon: Icons.shield_rounded,
            color: Colors.green,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF060F1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: const Text(
                  "rules_version = '2';\n"
                  "service cloud.firestore {\n"
                  "  match /databases/{db}/documents {\n"
                  "    match /users/{uid} {\n"
                  "      allow read, write:\n"
                  "        if request.auth.uid == uid;\n"
                  "    }\n"
                  "    match /projects/{id} {\n"
                  "      allow read, write:\n"
                  "        if request.auth.uid ==\n"
                  "           resource.data.userId;\n"
                  "    }\n"
                  "    match /admin/{doc} {\n"
                  "      allow read, write:\n"
                  "        if get(/databases/{database}/documents/"
                  "users/{request.auth.uid}).data.role == 'admin';\n"
                  "    }\n"
                  "  }\n"
                  "}",
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'Admin routes protected by role-based rules',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Access levels
          _Section(
            title: 'Access Levels',
            icon: Icons.verified_user_rounded,
            color: Colors.orangeAccent,
            children: [
              _AccessRow(
                'Admin',
                'Full access to all modules',
                Colors.purpleAccent,
              ),
              _AccessRow(
                'User',
                'App builder + own projects only',
                AppTheme.primary,
              ),
              _AccessRow('Guest', 'Read-only template preview', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.darkBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(color: AppTheme.darkBorder, height: 1),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onChanged;
  const _Toggle(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
        ),
      ],
    ),
  );
}

class _AccessRow extends StatelessWidget {
  final String label, desc;
  final Color color;
  const _AccessRow(this.label, this.desc, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

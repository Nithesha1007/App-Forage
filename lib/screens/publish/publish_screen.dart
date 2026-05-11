import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../models/project_model.dart';
import '../../services/firestore_service.dart';
import '../../services/build_service.dart';
import '../../widgets/floating_ai_button.dart';

class PublishScreen extends StatefulWidget {
  final String projectId;
  const PublishScreen({super.key, required this.projectId});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  ProjectModel? _project;
  bool _loading = true;
  String _platform = 'android';
  int _step = 0; // 0=config  1=building  2=done
  double _progress = 0;
  String? _downloadUrl;
  String _buildError = '';
  List<String> _buildLogs = [];
  double _downloadProgress = 0;
  bool _isDownloading = false;

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

  /// Show build confirmation dialog before starting build
  void _showBuildDialog() {
    if (_project == null) {
      _showError('Project not loaded');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                '🚀 Build & Publish',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re about to build your app for Android',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // App Details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'App Name:',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _project?.name ?? 'Unknown',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Platform:',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '📱 Android APK',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Screens:',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_project?.screens.length ?? 0} screens',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Build will take 2-5 minutes to complete',
                        style: TextStyle(color: AppTheme.primary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _startBuild();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF4F6FFF),
                      ),
                      icon: const Text('⚙️', style: TextStyle(fontSize: 16)),
                      label: const Text(
                        'Build APK',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startBuild() async {
    if (_project == null) {
      _showError('Project not loaded');
      return;
    }

    if (_platform != 'android') {
      _showError(
        'Only Android APK is currently supported for automated builds',
      );
      return;
    }

    setState(() {
      _step = 1;
      _progress = 0;
      _buildError = '';
      _buildLogs = ['📋 Initializing build process...'];
    });

    // Step 1: Check backend connection BEFORE attempting any build
    _buildLogs.add('⏳ Checking backend connection...');
    _updateLogs();

    try {
      final connectionError = await BuildService.checkBackendConnection(
        onStatusUpdate: (status) {
          _buildLogs.add(status);
          _updateLogs();
        },
      );

      if (connectionError != null) {
        // Backend not running - show error and exit immediately
        // Do NOT retry on backend errors
        _buildLogs.add('');
        _buildLogs.add(
          '═══════════════════════════════════════════════════════',
        );
        _buildLogs.add('❌ BACKEND NOT RUNNING');
        _buildLogs.add(
          '═══════════════════════════════════════════════════════',
        );
        _buildLogs.add('');
        _buildLogs.add(connectionError);
        _buildLogs.add('');
        _updateLogs();

        _showBuildError(connectionError);
        return;
      }

      // Backend is running - proceed with build
      _buildLogs.add('✅ Backend is ready');
      _updateLogs();

      // Retry loop only for actual build failures, not connection errors
      const maxBuildRetries = 3;

      for (
        int buildAttempt = 1;
        buildAttempt <= maxBuildRetries;
        buildAttempt++
      ) {
        try {
          if (buildAttempt > 1) {
            _buildLogs.add(
              '🔄 Retry attempt $buildAttempt/$maxBuildRetries...',
            );
            _updateLogs();
          }

          // Step 2: Submit build request to backend
          _buildLogs.add('📤 Submitting build request...');
          _updateLogs();

          final buildId = await BuildService.startApkBuild(
            _project!,
            onStatusUpdate: (status) {
              _buildLogs.add(status);
              _updateLogs();
            },
          );

          if (!mounted) return;

          _buildLogs.add('✅ Build queued (ID: $buildId)');
          _buildLogs.add('⏳ Waiting for build to complete...');
          _updateLogs();

          // Step 3: Poll for build status
          final downloadUrl = await BuildService.pollBuildStatus(
            buildId,
            _updateProgress,
            (log) {
              _buildLogs.add(log);
              _updateLogs();
            },
          );

          if (!mounted) return;

          _buildLogs.add('✅ Build completed successfully!');
          _buildLogs.add('📥 APK is ready for download');
          _updateLogs();

          // Step 4: Build complete - store download URL for manual download
          setState(() {
            _downloadUrl = downloadUrl;
            _buildLogs.add('✅ Click "Download APK" button to download');
          });
          _updateLogs();

          // Transition to success view after a brief delay
          Future.delayed(const Duration(seconds: 2)).then((_) {
            if (mounted) {
              setState(() {
                _step = 2;
              });
            }
          });

          return; // Build successful, exit retry loop
        } catch (e) {
          if (!mounted) return;

          final errorMsg = e.toString();
          _buildLogs.add('❌ Error: $errorMsg');

          if (buildAttempt < maxBuildRetries) {
            _buildLogs.add(
              '🔄 Retrying build (attempt $buildAttempt/$maxBuildRetries)',
            );
            _buildLogs.add('⏳ Waiting before retry...');
            _updateLogs();

            // Wait before retrying (with backoff)
            await Future.delayed(Duration(seconds: 3 * buildAttempt));
          } else {
            _buildLogs.add('❌ Build failed after $maxBuildRetries attempts');
            _showBuildError(
              'Build failed after $maxBuildRetries attempts:\n\n$errorMsg',
            );
            return;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showBuildError('Backend connection failed: ${e.toString()}');
      return;
    }
  }

  void _updateProgress(double progress) {
    if (!mounted) return;
    setState(() => _progress = progress);
  }

  void _updateLogs() {
    if (mounted) setState(() {});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showBuildError(String error) {
    setState(() {
      _buildError = error;
      _buildLogs.add('❌ Build failed: $error');
      _step = 1; // Stay on building step to show error
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      floatingActionButton: const FloatingAiButton(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/builder/${widget.projectId}'),
        ),
        title: const Text('Publish App'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _step == 0
              ? _ConfigStep()
              : _step == 1
              ? _BuildingStep()
              : _DoneStep(),
        ),
      ),
    );
  }

  // ── Step 1: Config ──────────────────────────────────────────────────────────
  Widget _ConfigStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 Launch Your App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _project?.name ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _Chip('✅ No vendor lock-in'),
                _Chip('✅ Full source code'),
              ],
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: -0.1),

      const SizedBox(height: 24),
      const Text(
        'Choose Platform',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),

      // Platform grid
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _PlatformTile('android', '📱', 'Android APK', 'Any Android device'),
          _PlatformTile('ios', '🍎', 'iOS App', 'App Store (Mac needed)'),
          _PlatformTile('web', '🌐', 'Web App', 'Firebase Hosting'),
          _PlatformTile('source', '📦', 'Flutter Source', 'Full Dart code'),
        ],
      ).animate().fadeIn(delay: 100.ms),

      const SizedBox(height: 24),
      const Text(
        "What's Included",
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),

      ...[
        ['✅ Full source code export', 'You own 100% of the code'],
        ['✅ Firebase configuration', 'Auth + Firestore pre-configured'],
        [
          '✅ All screens & widgets',
          '${_project?.screens.length ?? 0} screens included',
        ],
        ['✅ No vendor lock-in', 'Deploy anywhere you like'],
        ['✅ Auto-scalable backend', 'Firebase scales to millions of users'],
      ].map(
        (row) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row[0],
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                row[1],
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showBuildDialog,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Text('🚀', style: TextStyle(fontSize: 20)),
          label: const Text(
            'Publish App',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ).animate().fadeIn(delay: 200.ms),
    ],
  );

  Widget _PlatformTile(String id, String icon, String title, String sub) {
    final active = _platform == id;
    return GestureDetector(
      onTap: () => setState(() => _platform = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary.withOpacity(0.1) : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppTheme.primary : AppTheme.darkBorder,
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: active ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _Chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ── Step 2: Building ────────────────────────────────────────────────────────
  Widget _BuildingStep() => Column(
    children: [
      const SizedBox(height: 40),
      const Text(
        '⚙️',
        style: TextStyle(fontSize: 72),
      ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2000.ms),
      const SizedBox(height: 24),
      const Text(
        'Building APK...',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Compiling Flutter code for Android release',
        style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
      ),
      const SizedBox(height: 32),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _progress,
          backgroundColor: AppTheme.darkCard,
          color: AppTheme.primary,
          minHeight: 8,
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          '${(_progress * 100).toInt()}%',
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      const SizedBox(height: 20),

      // Build logs
      Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          reverse: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildLogs
                .map(
                  (log) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: log.contains('❌')
                            ? Colors.red
                            : log.contains('✅')
                            ? AppTheme.primary
                            : AppTheme.textMuted,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),

      // Show error if any
      if (_buildError.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ Build Error',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _buildError,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ],
  );

  // ── Step 3: Done ────────────────────────────────────────────────────────────
  Widget _DoneStep() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Text(
          '🎉',
          style: TextStyle(fontSize: 80),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        const Text(
          'APK Built Successfully!',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your app is ready to download and share',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 32),

        // Download URL Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DOWNLOAD LINK',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                _downloadUrl ?? 'No URL',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '📥 Link valid for 30 days',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Info box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '✅ Installation Instructions',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1. Download the APK file\n'
                '2. Enable "Unknown Sources" on your Android device\n'
                '3. Open the APK file to install\n'
                '4. Grant permissions when prompted',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _shareApk(),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share Link'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _downloadApk(),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download APK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/builder/${widget.projectId}'),
            child: const Text('Back to Builder'),
          ),
        ),
      ],
    );
  }

  Future<void> _shareApk() async {
    if (_downloadUrl == null || _downloadUrl!.isEmpty) {
      _showError('No download URL available');
      return;
    }

    try {
      await Share.share(
        'Download my Flutter app: $_downloadUrl',
        subject: '${_project?.name} - Android App',
      );
    } catch (e) {
      _showError('Failed to share: $e');
    }
  }

  Future<void> _downloadApk() async {
    if (_downloadUrl == null || _downloadUrl!.isEmpty) {
      _showError('No download URL available');
      return;
    }

    try {
      // Use BuildService to download APK in web browser
      BuildService.downloadApkWeb(_downloadUrl!);
      _showError('✅ APK download started in your browser!');
    } catch (e) {
      _showError('Failed to download APK: $e');
    }
  }
}

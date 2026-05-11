class AppConstants {
  AppConstants._();
  
  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'AppForge';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Build apps without code';

  // ── Firestore Collections ─────────────────────────────────────────────────
  static const String colUsers = 'users';
  static const String colProjects = 'projects';
  static const String colUserApps = 'user_apps';

  // ── Storage Paths ─────────────────────────────────────────────────────────
  static const String storageUsers = 'users';
  static const String storageApps = 'apps';

  // ── Route Names ───────────────────────────────────────────────────────────
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeHome = '/home';
  static const String routeTemplates = '/templates';
  static const String routeBuilder = '/builder';
  static const String routePreview = '/preview';
  static const String routePublish = '/publish';

  // ── Limits ────────────────────────────────────────────────────────────────
  static const int maxProjects = 10;
  static const int maxScreens = 20;
  static const int maxWidgets = 100;
  static const int maxUndoHistory = 20;
  static const int maxTables = 15;

  // ── Canvas ────────────────────────────────────────────────────────────────
  static const double canvasWidth = 360;
  static const double canvasHeight = 680;
  static const double gridSize = 20;
  static const double phoneFramePad = 8;

  // ── Animation Durations ───────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // ── Default Widget Sizes ──────────────────────────────────────────────────
  static const double defaultWidgetWidth = 320;
  static const double defaultWidgetHeight = 48;

  // ── Hive Box Names ────────────────────────────────────────────────────────
  static const String hiveBoxProjects = 'projects_cache';
  static const String hiveBoxSettings = 'settings';

  // ── Shared Pref Keys ──────────────────────────────────────────────────────
  static const String prefThemeMode = 'theme_mode';
  static const String prefOnboarded = 'onboarded';
  static const String prefLastProject = 'last_project';

  // ── Template IDs ─────────────────────────────────────────────────────────
  static const String templateEcommerce = 'ecommerce';
  static const String templateSchool = 'school';
  static const String templateFood = 'food';
  static const String templateCrm = 'crm';
  static const String templateFitness = 'fitness';
  static const String templateBlog = 'blog';
  static const String templateBlank = 'blank';

  // ── Widget Types ──────────────────────────────────────────────────────────
  static const List<String> widgetTypes = [
    'text',
    'button',
    'image',
    'icon',
    'divider',
    'input',
    'dropdown',
    'checkbox',
    'switch_w',
    'form',
    'card',
    'list',
    'grid',
    'navbar',
    'appbar',
    'tabs',
    'chart',
    'map',
    'video',
    'carousel',
  ];

  // ── Publish Platforms ─────────────────────────────────────────────────────
  static const List<String> platforms = ['android', 'ios', 'web', 'source'];

  // ── AI Chat Quick Replies ─────────────────────────────────────────────────
  static const List<String> aiQuickReplies = [
    'How do I add a widget?',
    'How do I set up the database?',
    'How do I bind data to UI?',
    'How do I publish my app?',
    'How do I use templates?',
  ];
}

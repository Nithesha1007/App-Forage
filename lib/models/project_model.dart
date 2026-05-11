import 'package:cloud_firestore/cloud_firestore.dart';
import 'screen_model.dart';

class ProjectModel {
  final String id, name, userId, templateId, templateName;
  final String? userEmail; // ✅ FIX 1: Email for permanent user-based storage
  final List<AppScreen> screens;
  final ProjectTheme theme;
  final BackendConfig backendConfig;
  final DateTime createdAt, updatedAt;
  final String status;
  final String? publishedUrl;

  ProjectModel({
    required this.id,
    required this.name,
    required this.userId,
    required this.templateId,
    required this.templateName,
    required this.screens,
    required this.theme,
    required this.backendConfig,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'draft',
    this.publishedUrl,
    this.userEmail,
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      name: d['name'] ?? '',
      userId: d['userId'] ?? '',
      templateId: d['templateId'] ?? 'blank',
      templateName: d['templateName'] ?? '',
      screens: (d['screens'] as List? ?? [])
          .map((s) => AppScreen.fromMap(s))
          .toList(),
      theme: ProjectTheme.fromMap(d['theme'] ?? {}),
      backendConfig: BackendConfig.fromMap(d['backendConfig'] ?? {}),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: d['status'] ?? 'draft',
      publishedUrl: d['publishedUrl'],
      userEmail: d['userEmail'], // ✅ FIX 1: Load email from Firestore
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'userId': userId,
    'userEmail': userEmail, // ✅ FIX 1: Save email to Firestore
    'templateId': templateId,
    'templateName': templateName,
    'screens': screens.map((s) => s.toMap()).toList(),
    'theme': theme.toMap(),
    'backendConfig': backendConfig.toMap(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'status': status,
    'publishedUrl': publishedUrl,
  };

  /// Convert to JSON-serializable format for local storage
  /// Uses ISO strings for timestamps instead of Firestore Timestamp objects
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'userId': userId,
    'userEmail': userEmail, // ✅ FIX 1: Save email to local storage
    'templateId': templateId,
    'templateName': templateName,
    'screens': screens.map((s) => s.toMap()).toList(),
    'theme': theme.toMap(),
    'backendConfig': backendConfig.toMap(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'status': status,
    'publishedUrl': publishedUrl,
  };

  ProjectModel copyWith({
    String? name,
    List<AppScreen>? screens,
    ProjectTheme? theme,
    BackendConfig? backendConfig,
    String? status,
  }) => ProjectModel(
    id: id,
    userId: userId,
    userEmail: userEmail, // ✅ FIX 1: Preserve email in copyWith
    templateId: templateId,
    templateName: templateName,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    name: name ?? this.name,
    screens: screens ?? this.screens,
    theme: theme ?? this.theme,
    backendConfig: backendConfig ?? this.backendConfig,
    status: status ?? this.status,
  );
}

class ProjectTheme {
  final String primaryColor, secondaryColor, backgroundColor, fontFamily;
  final double borderRadius;
  final bool isDarkMode;

  // App Style presets
  static const Map<String, Map<String, String>> colorPresets = {
    'Blue': {'primary': '#4A90E2', 'secondary': '#357ABD', 'accent': '#2A5AA0'},
    'Purple': {
      'primary': '#7B61FF',
      'secondary': '#6B51D5',
      'accent': '#5B41C5',
    },
    'Orange': {
      'primary': '#FF8C42',
      'secondary': '#E67E31',
      'accent': '#CC6A20',
    },
    'Teal': {'primary': '#2EC4B6', 'secondary': '#1FA39A', 'accent': '#158280'},
    'Dark': {'primary': '#1E1E2F', 'secondary': '#16213E', 'accent': '#0F3460'},
    'Green': {
      'primary': '#00C896',
      'secondary': '#009973',
      'accent': '#007A5E',
    },
  };

  const ProjectTheme({
    this.primaryColor = '#00C896',
    this.secondaryColor = '#6C63FF',
    this.backgroundColor = '#FFFFFF',
    this.fontFamily = 'Poppins',
    this.borderRadius = 12.0,
    this.isDarkMode = false,
  });

  factory ProjectTheme.fromMap(Map<String, dynamic> m) => ProjectTheme(
    primaryColor: m['primaryColor'] ?? '#00C896',
    secondaryColor: m['secondaryColor'] ?? '#6C63FF',
    backgroundColor: m['backgroundColor'] ?? '#FFFFFF',
    fontFamily: m['fontFamily'] ?? 'Poppins',
    borderRadius: (m['borderRadius'] as num?)?.toDouble() ?? 12.0,
    isDarkMode: m['isDarkMode'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'primaryColor': primaryColor,
    'secondaryColor': secondaryColor,
    'backgroundColor': backgroundColor,
    'fontFamily': fontFamily,
    'borderRadius': borderRadius,
    'isDarkMode': isDarkMode,
  };

  // Get dark mode text color
  String get textColorHex => isDarkMode ? '#F0F0F0' : '#1A1A1A';
  String get textMutedHex => isDarkMode ? '#A0A0A0' : '#666666';
  String get surfaceColorHex => isDarkMode ? '#2A2A2A' : '#FFFFFF';
  String get surfaceDarkHex => isDarkMode ? '#1F1F1F' : '#F5F5F5';
}

class BackendConfig {
  final List<DatabaseTable> tables;
  final bool emailAuth, googleAuth, phoneAuth;
  const BackendConfig({
    this.tables = const [],
    this.emailAuth = true,
    this.googleAuth = false,
    this.phoneAuth = false,
  });
  factory BackendConfig.fromMap(Map<String, dynamic> m) => BackendConfig(
    tables: (m['tables'] as List? ?? [])
        .map((t) => DatabaseTable.fromMap(t))
        .toList(),
    emailAuth: m['emailAuth'] ?? true,
    googleAuth: m['googleAuth'] ?? false,
    phoneAuth: m['phoneAuth'] ?? false,
  );
  Map<String, dynamic> toMap() => {
    'tables': tables.map((t) => t.toMap()).toList(),
    'emailAuth': emailAuth,
    'googleAuth': googleAuth,
    'phoneAuth': phoneAuth,
  };
}

class DatabaseTable {
  final String id, name;
  final List<String> fields;
  const DatabaseTable({
    required this.id,
    required this.name,
    required this.fields,
  });
  factory DatabaseTable.fromMap(Map<String, dynamic> m) => DatabaseTable(
    id: m['id'],
    name: m['name'],
    fields: List<String>.from(m['fields'] ?? []),
  );
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'fields': fields};
}

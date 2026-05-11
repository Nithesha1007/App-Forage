import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_model.dart';
import '../models/screen_model.dart';
import '../models/widget_model.dart';
import '../services/firestore_service.dart';
import '../services/project_persistence_service.dart';
import '../services/auto_backend_detector.dart';

class BuilderProvider extends ChangeNotifier {
  // ── Service instances ─────────────────────────────────────────────────
  final _fs = FirestoreService();
  final _persistence = ProjectPersistenceService();
  final _uuid = const Uuid();

  // ── Private fields (declare all fields BEFORE getters) ─────────────────
  ProjectModel? _project;
  int _activeScreen = 0;
  WidgetModel? _selectedWidget;
  bool _isLoading = false;
  bool _isSaving = false;
  DateTime? _lastSavedTime;
  final List<ProjectModel> _history = [];
  List<ProjectModel> _allProjects = [];
  String? _currentActiveProjectId;
  bool _projectsLoaded = false; // ✅ FIX 3: Prevent multiple reloads

  // ── Public getters (declare AFTER all fields) ───────────────────────────
  bool get canUndo => _history.isNotEmpty;
  ProjectModel? get project => _project;
  int get activeScreenIndex => _activeScreen;
  AppScreen? get activeScreen => _project?.screens.isNotEmpty == true
      ? _project!.screens[_activeScreen]
      : null;
  String? get currentScreenId => activeScreen?.id;
  WidgetModel? get selectedWidget => _selectedWidget;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  DateTime? get lastSavedTime => _lastSavedTime;
  List<ProjectModel> get allProjects => _allProjects;
  String? get currentActiveProjectId => _currentActiveProjectId;
  List<WidgetModel> get currentWidgets => activeScreen?.widgets ?? [];
  bool get projectsLoaded =>
      _projectsLoaded; // ✅ FIX 3: Getter for single-load flag

  // ✅ FIX 3: Setter for single-load flag
  void markProjectsAsLoaded() {
    _projectsLoaded = true;
  }

  Future<void> loadProject(String id) async {
    try {
      _isLoading = true;
      debugPrint('📥 LOADING PROJECT: id=$id');
      notifyListeners();

      // ✅ FIX: Get userId from current Firebase user
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔐 STEP 6 & 7 - EMAIL VERIFICATION');
      debugPrint('   LOGIN EMAIL:     $userEmail');
      debugPrint('   Current User ID: $userId');
      debugPrint('═══════════════════════════════════════════════════════════');

      // ✅ FIX: Try persistence service first (local + Firebase fallback)
      ProjectModel? loaded =
          await _persistence.loadProject(id, userId) ??
          await _fs.getProject(id);

      // ✅ PREVENT EMPTY OVERWRITE: Only set if project loaded successfully
      if (loaded != null) {
        debugPrint('✅ PROJECT LOADED: ${loaded.name} (${loaded.status})');

        // ✅ STEP 6 & 7 - VERIFY EMAIL CONSISTENCY
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );
        debugPrint('🔐 STEP 6 & 7 - EMAIL MATCH CHECK');
        debugPrint('   LOGIN EMAIL:      $userEmail');
        debugPrint('   PROJECT EMAIL:    ${loaded.userEmail ?? "NOT SET"}');
        debugPrint(
          '   Email Match:      ${userEmail == loaded.userEmail ? "✅ YES" : "❌ NO"}',
        );
        debugPrint('   LOGIN USER ID:    $userId');
        debugPrint('   PROJECT USER ID:  ${loaded.userId}');
        debugPrint(
          '   UserId Match:     ${userId == loaded.userId ? "✅ YES" : "❌ NO"}',
        );
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );

        _project = loaded;
        _currentActiveProjectId = loaded.id;
        _activeScreen = 0;

        // ✅ WARN if mismatch
        if (loaded.userId != userId) {
          debugPrint(
            '⚠️ WARNING: userId mismatch! Project may not sync correctly',
          );
        }
        if (loaded.userEmail != userEmail) {
          debugPrint(
            '⚠️ WARNING: email mismatch! Expected $userEmail, got ${loaded.userEmail}',
          );
        }
      } else {
        debugPrint('⚠️ Project failed to load: $id');
        _project = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading project: $e');
      _isLoading = false;
      _project = null;
      notifyListeners();
    }
  }

  /// Load all projects for current user (from Firebase with local fallback)
  /// This method:
  /// 1. First tries to load from Firebase (source of truth)
  /// 2. Falls back to local Hive cache if offline
  /// 3. Caches Firebase results in Hive for offline access
  Future<void> loadAllProjects(String userId) async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📦 STEP 3-4: BUILDER LOADING ALL PROJECTS');
      debugPrint('   userId: $userId');
      debugPrint('   LOGIN EMAIL: $userEmail');
      debugPrint('   BEFORE FETCH: ${_allProjects.length} projects in memory');
      debugPrint('═══════════════════════════════════════════════════════════');

      // ✅ Verify current user matches requested user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.uid != userId) {
        debugPrint(
          '⚠️ WARNING: Requested userId $userId != current user ${currentUser?.uid}',
        );
      }

      List<ProjectModel> projects = [];

      // Try to fetch from Firebase first (source of truth)
      try {
        debugPrint('   Fetching from Firebase...');
        // Use the stream to get the first batch of projects
        final projectStream = _fs.getUserProjects(userId).first;
        projects = await projectStream;
        debugPrint('✅ STEP 3: Firebase returned ${projects.length} projects');
        print(
          '[DEBUG-LOAD] Before setState: current count = ${_allProjects.length}',
        );
        print('[DEBUG-LOAD] Firebase fetched: ${projects.length}');

        for (var proj in projects) {
          debugPrint(
            '   📦 ${proj.name} (email=${proj.userEmail ?? "NOT SET"}, userId=${proj.userId})',
          );
        }

        // ✅ FIX 6: SAVE PROJECTS LOCALLY AFTER FETCH
        if (projects.isNotEmpty) {
          for (var project in projects) {
            await _persistence.saveProjectImmediately(project);
          }
          debugPrint('   ✅ Saved ${projects.length} projects to Hive');
        }
      } catch (e) {
        // If Firebase fails, fall back to local cache
        debugPrint('⚠️ STEP 3: Firebase fetch failed: $e');
        debugPrint('   Falling back to local cache...');
        projects = await _persistence.getCachedUserProjects(userId);
        debugPrint('✅ STEP 3: Loaded ${projects.length} projects from cache');

        for (var proj in projects) {
          debugPrint(
            '   📦 ${proj.name} (email=${proj.userEmail ?? "NOT SET"}, userId=${proj.userId})',
          );
        }
      }

      // ✅ FIX 2: PREVENT EMPTY API OVERWRITE - Only update if response is not empty
      if (projects.isNotEmpty) {
        print('[DEBUG-LOAD] Setting _allProjects to ${projects.length} items');
        _allProjects = projects;
        print(
          '[DEBUG-LOAD] After assignment: _allProjects.length = ${_allProjects.length}',
        );
        debugPrint('   ✅ Updated _allProjects with ${projects.length} items');
      } else {
        debugPrint(
          '   ⚠️ Skipping empty response. Keeping ${_allProjects.length} cached projects',
        );
        print('[DEBUG-LOAD] Empty response, keeping ${_allProjects.length}');
      }

      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint(
        '✅ STEP 3-4 COMPLETE: UI PROJECT COUNT: ${_allProjects.length}',
      );
      print(
        '[DEBUG-LOAD] Before notifyListeners: count = ${_allProjects.length}',
      );
      for (var proj in _allProjects) {
        debugPrint('   ✔ ${proj.name} (${proj.status})');
      }
      debugPrint('═══════════════════════════════════════════════════════════');
      notifyListeners();
      print(
        '[DEBUG-LOAD] AFTER notifyListeners: count = ${_allProjects.length}',
      );
    } catch (e) {
      // ✅ FIX 1: PRESERVE EXISTING PROJECTS ON ERROR - Don't clear them
      debugPrint('❌ STEP 3-4: Error loading all projects: $e');
      debugPrint(
        '   ⚠️ PRESERVING ${_allProjects.length} existing projects in memory',
      );
      print(
        '[DEBUG-LOAD] ERROR in loadAllProjects: $e, preserving ${_allProjects.length} projects',
      );
      // DO NOT set _allProjects = []; - Keep existing cached projects
      notifyListeners();
      print(
        '[DEBUG-LOAD] After error notifyListeners: count = ${_allProjects.length}',
      );
    }
  }

  void setActiveScreen(int i) {
    _activeScreen = i;
    _selectedWidget = null;
    notifyListeners();
  }

  void setCurrentScreen(String id) {
    if (_project == null) return;
    final index = _project!.screens.indexWhere((s) => s.id == id);
    if (index != -1) {
      _activeScreen = index;
      _selectedWidget = null;
      notifyListeners();
    }
  }

  void addScreen(String name) {
    if (_project == null) return;
    _saveHistory();
    final s = AppScreen(id: _uuid.v4(), name: name);
    _project = _project!.copyWith(screens: [..._project!.screens, s]);
    _activeScreen = _project!.screens.length - 1;
    notifyListeners();
    _autosave();
  }

  void removeScreen(int i) {
    if (_project == null || _project!.screens.length <= 1) return;
    _saveHistory();
    final screens = [..._project!.screens]..removeAt(i);
    _project = _project!.copyWith(screens: screens);
    if (_activeScreen >= screens.length) _activeScreen = screens.length - 1;
    notifyListeners();
    _autosave();
  }

  void renameScreen(int i, String newName) {
    if (_project == null || newName.trim().isEmpty) return;
    _saveHistory();
    final screens = _project!.screens
        .asMap()
        .map(
          (idx, s) => MapEntry(
            idx,
            idx == i
                ? AppScreen(id: s.id, name: newName.trim(), widgets: s.widgets)
                : s,
          ),
        )
        .values
        .toList();
    _project = _project!.copyWith(screens: screens);
    notifyListeners();
    _autosave();
  }

  void addWidget(String type, double x, double y) {
    if (_project == null || activeScreen == null) return;
    _saveHistory();
    final w = WidgetModel(
      id: _uuid.v4(),
      type: type,
      x: x.clamp(0, 320),
      y: y.clamp(0, 680),
      width: 300,
      height: WidgetModel.defaultHeightFor(type),
      // ── FIX 2: Use Map.from() to ensure the properties map is always
      // a mutable copy. Without this, widgets sharing the same default props
      // reference could corrupt each other's state when one is mutated.
      properties: Map<String, dynamic>.from(WidgetModel.defaultPropsFor(type)),
    );
    _updateScreenWidgets([...activeScreen!.widgets, w]);
    _selectedWidget = w;
    notifyListeners();
    _autosave();
  }

  void selectWidget(WidgetModel? w) {
    _selectedWidget = w;
    notifyListeners();
  }

  void moveWidget(String id, double x, double y) {
    _updateWidget(id, (w) {
      w.x = x.clamp(0, 320);
      w.y = y.clamp(0, 680);
    });
    // ── FIX 3: Keep _selectedWidget reference in sync after a move so the
    // Properties panel reflects the correct position immediately.
    if (_selectedWidget?.id == id) {
      _selectedWidget!.x = x.clamp(0, 320);
      _selectedWidget!.y = y.clamp(0, 680);
    }
    notifyListeners();
    _autosave();
  }

  void updateWidgetProperty(String id, String key, dynamic value) {
    _updateWidget(id, (w) => w.properties[key] = value);
    // ── FIX 4: Mirror the change into _selectedWidget so the canvas widget
    // (which reads from provider.selectedWidget) re-renders immediately.
    // Previously only the list copy was updated; the selected reference was stale.
    if (_selectedWidget?.id == id) {
      _selectedWidget!.properties[key] = value;
    }
    notifyListeners();
    _autosave();
  }

  // ── FIX 5: New method — update width/height of a widget and propagate
  // to _selectedWidget so the canvas resizes the widget in real time.
  void updateWidgetSize(String id, double width, double height) {
    _updateWidget(id, (w) {
      w.width = width.clamp(60, 320);
      w.height = height.clamp(20, 600);
    });
    if (_selectedWidget?.id == id) {
      _selectedWidget!.width = width.clamp(60, 320);
      _selectedWidget!.height = height.clamp(20, 600);
    }
    notifyListeners();
    _autosave();
  }

  void removeWidget(String id) {
    if (activeScreen == null) return;
    _saveHistory();
    _updateScreenWidgets(
      activeScreen!.widgets.where((w) => w.id != id).toList(),
    );
    if (_selectedWidget?.id == id) _selectedWidget = null;
    notifyListeners();
    _autosave();
  }

  void duplicateWidget(String id) {
    if (activeScreen == null) return;
    final orig = activeScreen!.widgets.firstWhere((w) => w.id == id);
    final copy = WidgetModel(
      id: _uuid.v4(),
      type: orig.type,
      x: orig.x + 16,
      y: orig.y + 16,
      width: orig.width,
      height: orig.height,
      // ── FIX 6: Deep-copy properties so the duplicate is fully independent.
      properties: Map<String, dynamic>.from(orig.properties),
    );
    _updateScreenWidgets([...activeScreen!.widgets, copy]);
    _selectedWidget = copy;
    notifyListeners();
    _autosave();
  }

  void bindWidgetToData(String id, String table, String field) {
    _updateWidget(id, (w) {
      w.boundTable = table;
      w.boundField = field;
    });
    notifyListeners();
    _autosave();
  }

  // ── NEW: Add a child widget to a Row/Column
  void addChildWidget(String parentId, String childType) {
    _updateWidget(parentId, (parent) {
      if (parent.type == 'row' || parent.type == 'column') {
        final childWidget = WidgetModel(
          id: _uuid.v4(),
          type: childType,
          x: 0,
          y: 0,
          width: 100,
          height: WidgetModel.defaultHeightFor(childType),
          properties: Map<String, dynamic>.from(
            WidgetModel.defaultPropsFor(childType),
          ),
        );
        parent.children = [...parent.children, childWidget];
      } else if (parent.type == 'singlechildscrollview') {
        // ── SingleChildScrollView: Only allow ONE child
        // If a child already exists, replace it (or show warning)
        final childWidget = WidgetModel(
          id: _uuid.v4(),
          type: childType,
          x: 0,
          y: 0,
          width: 100,
          height: WidgetModel.defaultHeightFor(childType),
          properties: Map<String, dynamic>.from(
            WidgetModel.defaultPropsFor(childType),
          ),
        );
        parent.children = [childWidget];
      }
    });
    if (_selectedWidget?.id == parentId) {
      _selectedWidget = activeScreen?.widgets.firstWhere(
        (w) => w.id == parentId,
        orElse: () => _selectedWidget!,
      );
    }
    notifyListeners();
    _autosave();
  }

  // ── NEW: Remove a child widget from Row/Column
  void removeChildWidget(String parentId, String childId) {
    _updateWidget(parentId, (parent) {
      parent.children = parent.children.where((c) => c.id != childId).toList();
    });
    notifyListeners();
    _autosave();
  }

  // ── NEW: Update a child widget's properties
  void updateChildProperty(
    String parentId,
    String childId,
    String key,
    dynamic value,
  ) {
    _updateWidget(parentId, (parent) {
      for (final child in parent.children) {
        if (child.id == childId) {
          child.properties[key] = value;
          break;
        }
      }
    });
    notifyListeners();
    _autosave();
  }

  // ── NEW: Update child widget size
  void updateChildSize(
    String parentId,
    String childId,
    double width,
    double height,
  ) {
    _updateWidget(parentId, (parent) {
      for (final child in parent.children) {
        if (child.id == childId) {
          child.width = width.clamp(40, 320);
          child.height = height.clamp(20, 600);
          break;
        }
      }
    });
    notifyListeners();
    _autosave();
  }

  void updateTheme(ProjectTheme theme) {
    _project = _project?.copyWith(theme: theme);
    notifyListeners();
    _autosave();
  }

  void addTable(String name, List<String> fields) {
    if (_project == null) return;
    final t = DatabaseTable(id: _uuid.v4(), name: name, fields: fields);
    final cfg = _project!.backendConfig;
    _project = _project!.copyWith(
      backendConfig: BackendConfig(
        tables: [...cfg.tables, t],
        emailAuth: cfg.emailAuth,
        googleAuth: cfg.googleAuth,
      ),
    );
    notifyListeners();
    _autosave();
  }

  /// Add a single field to an existing table
  void addFieldToTable(String tableName, String fieldName) {
    if (_project == null) return;
    final cfg = _project!.backendConfig;
    final tables = cfg.tables.map((table) {
      if (table.name == tableName && !table.fields.contains(fieldName)) {
        return DatabaseTable(
          id: table.id,
          name: table.name,
          fields: [...table.fields, fieldName],
        );
      }
      return table;
    }).toList();

    _project = _project!.copyWith(
      backendConfig: BackendConfig(
        tables: tables,
        emailAuth: cfg.emailAuth,
        googleAuth: cfg.googleAuth,
      ),
    );
    notifyListeners();
    _autosave();
  }

  /// Generate backend structure from all input widgets in current screen
  Future<void> generateBackendFromScreen() async {
    if (_project == null || activeScreen == null) return;

    final suggestion = AutoBackendDetector.generateFromScreen(activeScreen!);

    if (suggestion.fields.isEmpty) {
      debugPrint('No input widgets found in screen');
      return;
    }

    // Create the table with all suggested fields
    addTable(
      suggestion.tableName,
      suggestion.getFieldNames(includeSystem: true),
    );

    // Auto-bind widgets to their fields if possible
    for (final widget in suggestion.inputWidgets) {
      final fieldName = AutoBackendDetector.suggestFieldName(widget);
      if (fieldName.isNotEmpty) {
        bindWidgetToData(widget.id, suggestion.tableName, fieldName);
      }
    }
  }

  /// Generate backend from all screens at once
  Future<List<String>> generateBackendFromAllScreens() async {
    if (_project == null) return [];

    final suggestions = AutoBackendDetector.generateFromAllScreens(
      _project!.screens,
    );
    final createdTables = <String>[];

    for (final suggestion in suggestions) {
      // Check if table already exists
      final exists = _project!.backendConfig.tables.any(
        (t) => t.name == suggestion.tableName,
      );

      if (!exists) {
        addTable(
          suggestion.tableName,
          suggestion.getFieldNames(includeSystem: true),
        );
        createdTables.add(suggestion.tableName);
      }
    }

    return createdTables;
  }

  void undo() {
    if (_history.isNotEmpty) {
      _project = _history.removeLast();
      _selectedWidget = null;
      notifyListeners();
    }
  }

  void _updateWidget(String id, void Function(WidgetModel) fn) {
    if (activeScreen == null) return;
    for (final w in activeScreen!.widgets) {
      if (w.id == id) fn(w);
    }
    _updateScreenWidgets(activeScreen!.widgets);
  }

  void _updateScreenWidgets(List<WidgetModel> widgets) {
    if (_project == null) return;
    final screens = _project!.screens
        .asMap()
        .map(
          (i, s) => MapEntry(
            i,
            i == _activeScreen
                ? AppScreen(id: s.id, name: s.name, widgets: widgets)
                : s,
          ),
        )
        .values
        .toList();
    _project = _project!.copyWith(screens: screens);
  }

  void _saveHistory() {
    if (_project != null) {
      _history.add(_project!);
      if (_history.length > 20) _history.removeAt(0);
    }
  }

  /// Debounced auto-save on every change
  /// Fires after 400ms of inactivity to avoid excessive writes
  void _autosave() {
    // ✅ PREVENT EMPTY OVERWRITE: Only save if project exists and has data
    if (_project == null || _project!.id.isEmpty) {
      return;
    }

    _isSaving = true;
    notifyListeners();

    // ✅ Verify userId before save
    final currentUser = FirebaseAuth.instance.currentUser?.uid ?? '';
    debugPrint('💾 AUTO-SAVE QUEUED: ${_project!.name}');
    debugPrint('   Project id:   ${_project!.id}');
    debugPrint('   Project uid:  ${_project!.userId}');
    debugPrint('   Current user: $currentUser');

    if (_project!.userId.isEmpty) {
      debugPrint('⚠️ WARNING: Project has no userId - may not save correctly!');
    }

    _persistence.debouncedSaveProject(_project!);

    // Reset saving state after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isSaving) {
        _isSaving = false;
        _lastSavedTime = DateTime.now();
        debugPrint('✅ AUTO-SAVE COMMITTED: ${_project!.name}');
        notifyListeners();
      }
    });
  }

  /// Immediately save current project without debounce
  /// Use before switching projects or on critical operations
  Future<void> saveCurrentProject() async {
    // ✅ PREVENT EMPTY OVERWRITE: Only save if project exists and has data
    if (_project == null || _project!.id.isEmpty) {
      debugPrint('⚠️ Skipping save: Project is empty or null');
      return;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser?.uid ?? '';
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('💾 FORCE SAVE: project=${_project!.name} (${_project!.id})');
      debugPrint('   Project userId:  ${_project!.userId}');
      debugPrint('   Current user:    $currentUser');

      if (_project!.userId != currentUser) {
        debugPrint('⚠️ WARNING: userId mismatch during save!');
      }

      await _persistence.saveProjectImmediately(_project!);
      debugPrint('✅ FORCE SAVE SUCCESS: ${_project!.name}');
      debugPrint('═══════════════════════════════════════════════════════════');
      _lastSavedTime = DateTime.now();
    } catch (e) {
      debugPrint('❌ Save failed: $e');
    }

    _isSaving = false;
    notifyListeners();
  }

  /// Switch to another project with auto-save of current
  Future<void> switchProject(String newProjectId) async {
    debugPrint('🔄 SWITCH PROJECT: from=${_project?.id} to=$newProjectId');

    // Save current project before switching
    if (_project != null) {
      debugPrint('💾 Saving current project before switch...');
      await saveCurrentProject();
    }

    // Load new project
    debugPrint('📥 Loading new project: $newProjectId');
    await loadProject(newProjectId);
    _currentActiveProjectId = newProjectId;
    debugPrint('✅ PROJECT SWITCHED: ${_project?.name}');
    notifyListeners();
  }

  /// Cleanup on provider disposal
  @override
  void dispose() {
    _persistence.cancelPendingSaves();
    super.dispose();
  }

  /// Clear in-memory data on logout (but don't delete from storage)
  void clearOnLogout() {
    debugPrint('🛑 CLEARING IN-MEMORY BUILDER DATA ON LOGOUT');
    _project = null;
    _allProjects = [];
    _currentActiveProjectId = null;
    _activeScreen = 0;
    _selectedWidget = null;
    _history.clear();
    _projectsLoaded = false; // ✅ Allow reload on next login
    _persistence.cancelPendingSaves();
    notifyListeners();
  }

  void applyProject(ProjectModel updated) {
    _project = updated;
    notifyListeners();
    _autosave();
  }
}

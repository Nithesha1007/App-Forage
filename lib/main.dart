import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/builder_provider.dart';
import 'providers/chat_provider.dart';
import 'services/project_persistence_service.dart';
import 'config/network_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load .env FIRST
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    // .env file not found or failed to load - continue with defaults
    print('Warning: .env file not found, using defaults');
  }

  // ✅ Firebase init
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized — safe to ignore
  }

  // ✅ Hive init
  await Hive.initFlutter();
  await Hive.openBox('appforge_cache');

  // ✅ Initialize ProjectPersistenceService for auto-save and offline cache
  debugPrint('🔧 INITIALIZING PERSISTENCE SERVICE...');
  final persistenceService = ProjectPersistenceService();
  await persistenceService.init();
  debugPrint('✅ PERSISTENCE SERVICE INITIALIZED');

  // ✅ Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // ✅ Initialize NetworkConfig - detects system IP for backend connection
  await NetworkConfig.getBackendBaseUrl();

  debugPrint('🚀 APP STARTING...');
  runApp(const AppForgeApp());
}

class AppForgeApp extends StatelessWidget {
  const AppForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BuilderProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp.router(
        title: 'AppForge Builder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: AppRouter.router,
      ),
    );
  }
}

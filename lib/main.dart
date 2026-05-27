import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/notification_service.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://othxceezbpfiauaevibt.supabase.co',
    anonKey: 'sb_publishable_ki8a43mdYzPTaypjvfBNFw_caZ1fTyv',
  );

  // Initialize notification service
  final notifService = NotificationService();
  await notifService.initialize();
  await notifService.requestPermission();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start notification watcher after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNotificationWatcher();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  Future<void> _handleAppResumed() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session != null) {
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final expiresDateTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
        final difference = expiresDateTime.difference(DateTime.now());
        // If expired or expiring in less than 5 minutes, proactively refresh session
        if (difference.inMinutes < 5) {
          try {
            debugPrint("Proactively refreshing Supabase session on app resume...");
            await client.auth.refreshSession();
            debugPrint("Supabase session refreshed successfully on app resume.");
          } catch (e) {
            debugPrint("Failed to refresh Supabase session on resume: $e");
          }
        }
      }
    }
  }

  void _startNotificationWatcher() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final watcher = ref.read(notificationWatcherProvider);
      watcher.startWatching();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'NLIT',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}


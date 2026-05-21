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

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Start notification watcher after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNotificationWatcher();
    });
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

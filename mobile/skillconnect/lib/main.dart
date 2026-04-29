import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/realtime_service.dart';
import 'services/theme_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/pro_home_screen.dart';
import 'screens/profile/professional_profile_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/home/service_hub_screen.dart';
import 'screens/home/category_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/contacts/my_contacts_screen.dart';
import 'screens/bookings/bookings_list_screen.dart';
import 'screens/messages/threads_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/search/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  final themeService = ThemeService();
  await Future.wait([authService.init(), themeService.init()]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: themeService),
      ],
      child: const SkillConnectApp(),
    ),
  );
}

class SkillConnectApp extends StatelessWidget {
  const SkillConnectApp({super.key});

  static const _primary   = Color(0xFF6366F1);
  static const _secondary = Color(0xFF06B6D4);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border  = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final inputFill = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    final textTheme = TextTheme(
      displayLarge:  TextStyle(fontSize: 57, fontWeight: FontWeight.w900, letterSpacing: -2, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      headlineMedium:TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      titleLarge:    TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569)),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: brightness,
        primary: _primary,
        secondary: _secondary,
        surface: surface,
        surfaceContainerHighest: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      ),
      textTheme: textTheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontWeight: FontWeight.w400),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _primary.withAlpha(25),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? _primary : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? _primary : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            size: 24,
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeService>().mode;
    return MaterialApp(
      title: 'SkillConnect',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      home: Consumer<AuthService>(
        builder: (_, auth, __) {
          final dest = auth.isLoggedIn ? const MainShell() : const WelcomeScreen();
          return SplashScreen(nextScreen: dest);
        },
      ),
      routes: {
        '/login': (_) => const WelcomeScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainShell(),
        '/contacts': (_) => const MyContactsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/professional') {
          final id = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => ProfessionalProfileScreen(professionalId: id));
        }
        if (settings.name == '/search') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(builder: (_) => SearchScreen(
            categoryId: args?['categoryId'],
            categoryName: args?['categoryName'],
          ));
        }
        if (settings.name == '/category') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(builder: (_) => CategoryDetailScreen(
            categoryId: args['categoryId'] as int,
            categoryName: args['categoryName']?.toString() ?? '',
            categoryDescription: args['description']?.toString(),
            isRoot: args['isRoot'] == true,
          ));
        }
        return null;
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _unread = 0;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;
  StreamSubscription<ConnectionStatus>? _connSub;
  ConnectionStatus _connStatus = ConnectionStatus.disconnected;

  List<Widget> _buildScreens(bool isPro) => isPro
      ? const [
          ProHomeScreen(),       // Home: pro dashboard overview
          BookingsListScreen(),  // Bookings: all pro bookings
          ThreadsScreen(),       // Chats
          DashboardScreen(),     // Profile / settings
        ]
      : const [
          HomeScreen(),          // Home: discover pros
          ServiceHubScreen(),    // Services: browse categories
          BookingsListScreen(),  // Bookings
          ThreadsScreen(),       // Chats
          DashboardScreen(),     // Profile
        ];

  List<NavigationDestination> _destinations(bool isPro) => isPro
      ? const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ]
      : const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'Services'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ];

  @override
  void initState() {
    super.initState();
    _refreshUnread();
    _realtimeSub = RealtimeService.instance.stream.listen((_) { if (mounted) _refreshUnread(); });
    _connStatus = RealtimeService.instance.status;
    _connSub = RealtimeService.instance.statusStream.listen((s) {
      if (mounted) setState(() => _connStatus = s);
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnread() async {
    try {
      final n = await NotificationsService.unreadCount();
      if (mounted) setState(() => _unread = n);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isPro = auth.isProfessional;
    final screens = _buildScreens(isPro);
    // Reset index if it goes out of range when role changes
    final safeIndex = _index.clamp(0, screens.length - 1);

    return Scaffold(
      body: Stack(children: [
        Column(children: [
          // Connection status banner
          if (_connStatus != ConnectionStatus.connected)
            Material(
              color: _connStatus == ConnectionStatus.connecting
                  ? Colors.orange.shade700
                  : Colors.red.shade700,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white,
                      value: _connStatus == ConnectionStatus.disconnected ? 0 : null,
                    )),
                    const SizedBox(width: 8),
                    Text(
                      _connStatus == ConnectionStatus.connecting ? 'Connecting...' : 'No connection',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ),
            ),
          Expanded(child: IndexedStack(index: safeIndex, children: screens)),
        ]),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                _refreshUnread();
              },
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(clipBehavior: Clip.none, children: [
                  const Icon(Icons.notifications_outlined, size: 22),
                  if (_unread > 0)
                    Positioned(
                      right: -4, top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 18),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                        child: Text(_unread > 99 ? '99+' : '$_unread',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) => setState(() => _index = i),
          animationDuration: const Duration(milliseconds: 400),
          destinations: _destinations(isPro),
        ),
      ),
    );
  }
}

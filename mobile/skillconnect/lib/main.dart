import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/realtime_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
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
  await authService.init();
  runApp(
    ChangeNotifierProvider.value(value: authService, child: const SkillConnectApp()),
  );
}

class SkillConnectApp extends StatelessWidget {
  const SkillConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF06B6D4),
          surface: Colors.white,
          surfaceContainerHighest: const Color(0xFFF8FAFC),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.grey.shade100)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFF6366F1).withAlpha(30),
          backgroundColor: Colors.white,
          elevation: 3,
          shadowColor: Colors.black26,
          labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ),
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

  // Screens differ by role — built lazily after first auth check
  List<Widget>? _screens;

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
    RealtimeService.instance.stream.listen((_) { if (mounted) _refreshUnread(); });
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
        IndexedStack(index: safeIndex, children: screens),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: Material(
            color: Colors.white,
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        animationDuration: const Duration(milliseconds: 400),
        destinations: _destinations(isPro),
      ),
    );
  }
}

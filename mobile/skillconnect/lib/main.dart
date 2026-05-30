import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/realtime_service.dart';
import 'services/theme_service.dart';
import 'services/smart_location_service.dart';
import 'services/analytics_service.dart';
import 'services/performance_monitor.dart';
import 'services/offline/offline_services.dart';
import 'services/app_locale_service.dart';
import 'theme/design_tokens.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/pro_home_screen.dart';
import 'screens/home/agent_home_screen.dart';
import 'screens/home/admin_home_screen.dart';
import 'screens/profile/professional_profile_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/home/service_hub_screen.dart';
import 'screens/home/category_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_intro_screen.dart';
import 'screens/contacts/my_contacts_screen.dart';
import 'screens/bookings/bookings_list_screen.dart';
import 'screens/delivery/delivery_screen.dart';
import 'screens/rides/my_ride_screen.dart';
import 'screens/food/food_screen.dart';
import 'screens/groceries/groceries_screen.dart';
import 'screens/shopping/shopping_screen.dart';
import 'screens/jobs/job_screen.dart';
import 'screens/messages/threads_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/search/instant_quote_screen.dart';
import 'screens/emergency/emergency_booking_screen.dart';
import 'screens/payments/payment_screen.dart';
import 'screens/tracking/live_tracking_screen.dart';
import 'screens/disputes/dispute_screen.dart';
import 'screens/warranty/warranty_screen.dart';
import 'screens/notifications/notification_preferences_screen.dart';
import 'screens/schedule/schedule_management_screen.dart';
import 'screens/earnings/earnings_screen.dart';
import 'screens/scan/scan_screen.dart';
import 'widgets/connectivity_banner.dart';
import 'widgets/app_components.dart';
import 'theme/design_tokens.dart';

void main() async {
  // Track cold start time
  PerformanceMonitor.instance.markAppStart();

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline services
  await LocalCacheService.init();
  await ConnectivityService.instance.init();
  await OfflineQueueService.init();

  // Initialize analytics
  await AnalyticsService.instance.init();

  // Initialize smart location (non-blocking)
  SmartLocationService.instance.init();

  final authService = AuthService();
  final themeService = ThemeService();
  await Future.wait([authService.init(), themeService.init(), AppLocaleService.init()]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: ConnectivityService.instance),
        ChangeNotifierProvider.value(value: SmartLocationService.instance),
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
    return ValueListenableBuilder<Locale?>(
      valueListenable: AppLocaleService.notifier,
      builder: (_, locale, __) => MaterialApp(
        title: 'SkillConnect',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: themeMode,
        locale: locale,
        // i18n: Regional language support (Telugu-first)
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer<AuthService>(
          builder: (_, auth, __) {
            if (auth.isLoggedIn) {
              return SplashScreen(nextScreen: const _OnboardingGate());
            }
            return const SplashScreen(nextScreen: WelcomeScreen());
          },
        ),
        routes: {
        '/login': (_) => const WelcomeScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const _OnboardingGate(),
        '/contacts': (_) => const MyContactsScreen(),
        '/instant-quote': (_) => const InstantQuoteScreen(),
        '/emergency': (_) => const EmergencyBookingScreen(),
        '/warranty': (_) => const WarrantyScreen(),
        '/notification-preferences': (_) => const NotificationPreferencesScreen(),
        '/schedule': (_) => const ScheduleManagementScreen(),
        '/earnings': (_) => const EarningsScreen(),
        '/scan': (_) => const ScanScreen(),
        '/delivery': (_) => const DeliveryScreen(),
        '/my-ride': (_) => const MyRideScreen(),
        '/food': (_) => const FoodScreen(),
        '/groceries': (_) => const GroceriesScreen(),
        '/shopping': (_) => const ShoppingScreen(),
        '/jobs': (_) => const JobScreen(),
        '/services': (_) => const ServiceHubScreen(),
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
          if (settings.name == '/payment') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(builder: (_) => PaymentScreen(
              bookingId: args['bookingId'] as String,
              amount: (args['amount'] as num).toDouble(),
              professionalName: args['professionalName'] as String? ?? 'Professional',
            ));
          }
          if (settings.name == '/tracking') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(builder: (_) => LiveTrackingScreen(
              bookingId: args['bookingId'] as String,
              professionalName: args['professionalName'] as String? ?? 'Professional',
            ));
          }
          if (settings.name == '/dispute') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(builder: (_) => DisputeScreen(
              bookingId: args['bookingId'] as String,
              bookingTitle: args['bookingTitle'] as String? ?? 'Booking',
            ));
          }
          return null;
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

/// Gate that shows onboarding intro for first-time users, then shows MainShell.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  bool _showOnboarding = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_complete') ?? false;
    if (mounted) {
      setState(() {
        _showOnboarding = !done;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: () {
        if (mounted) setState(() => _showOnboarding = false);
      });
    }
    return const MainShell();
  }
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _unread = 0;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;
  StreamSubscription<ConnectionStatus>? _connSub;
  ConnectionStatus _connStatus = ConnectionStatus.disconnected;

  List<Widget> _buildScreens(bool isPro, bool isAgent, bool isAdmin) {
    if (isAdmin) {
      return const [
        AdminHomeScreen(),     // Dashboard
        BookingsListScreen(),  // Users (reuse bookings as placeholder)
        ThreadsScreen(),       // Reports (reuse chats as placeholder)
        DashboardScreen(),     // Settings / Profile
      ];
    }
    if (isAgent) {
      return const [
        AgentHomeScreen(),     // Overview
        BookingsListScreen(),  // Referrals (reuse bookings as placeholder)
        ThreadsScreen(),       // Chats
        DashboardScreen(),     // Profile
      ];
    }
    if (isPro) {
      return const [
        ProHomeScreen(),       // Home: pro dashboard overview
        BookingsListScreen(),  // Bookings: all pro bookings
        ThreadsScreen(),       // Chats
        DashboardScreen(),     // Profile / settings
      ];
    }
    // Consumer: Home · Requests · [FAB=Services] · Scan · Chat
    return const [
      HomeScreen(),          // Home: discover
      BookingsListScreen(),  // Requests
      ScanScreen(),          // Scan (FAB placeholder slot — never shown as indexed)
      ThreadsScreen(),       // Chat
      DashboardScreen(),     // Profile
    ];
  }

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
    final isAgent = auth.isAgent;
    final isAdmin = auth.isAdmin;
    final screens = _buildScreens(isPro, isAgent, isAdmin);
    final isConsumer = !isPro && !isAgent && !isAdmin;

    // For consumer: 4 nav slots (0=Home,1=Requests,2=Scan,3=Chat,4=Profile)
    // but we treat FAB as index 2 (Services) and shift:
    // bar slot 0→screens[0], 1→screens[1], FAB→ServiceHub, 2→screens[2](Scan), 3→screens[3](Chat)
    // We keep _index in range 0–3 (not counting FAB)
    // Effective screen index: _index < 2 ? _index : _index + 1 (skip Scan placeholder at 2)
    int effectiveIndex = isConsumer
        ? (_index < 2 ? _index : _index + 1)
        : _index;
    final safeIndex = effectiveIndex.clamp(0, screens.length - 1);

    return Scaffold(
      body: Stack(children: [
        Column(children: [
          const ConnectivityBanner(),
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
      // ── Consumer: custom BottomAppBar + center FAB ──────────────
      floatingActionButton: isConsumer
          ? FloatingActionButton(
              backgroundColor: AppColors.superOrange,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: const CircleBorder(),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ServiceHubScreen()),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.apps_rounded, size: 22),
                  Text('Services', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                ],
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: isConsumer
          ? _ConsumerBottomBar(
              currentIndex: _index,
              unread: _unread,
              onTap: (i) {
                HapticFeedback.selectionClick();
                if (i == 2) {
                  // Scan tab
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
                } else {
                  setState(() => _index = i);
                }
              },
            )
          : _LegacyBottomNav(
              isPro: isPro,
              isAgent: isAgent,
              isAdmin: isAdmin,
              selectedIndex: _index.clamp(0, screens.length - 1),
              unread: _unread,
              onTap: (i) {
                HapticFeedback.selectionClick();
                setState(() => _index = i);
              },
            ),
    );
  }
}

// ── Consumer Bottom Bar (Grab/Gojek-style with center FAB notch) ─────────────

class _ConsumerBottomBar extends StatelessWidget {
  final int currentIndex;
  final int unread;
  final ValueChanged<int> onTap;

  const _ConsumerBottomBar({
    required this.currentIndex,
    required this.unread,
    required this.onTap,
  });

  // Visible slots: 0=Home, 1=Requests, [FAB], 2=Scan, 3=Chat
  // currentIndex maps: 0→Home, 1→Requests, 2→Scan, 3→Chat, 4→Profile (not in bottom bar)
  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Requests'),
    _NavItem(Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_rounded, 'Scan'),
    _NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.cardDark : Colors.white;
    final activeColor = AppColors.superBlue;
    final inactiveColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return BottomAppBar(
      color: bgColor,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            // Left two items
            ...[0, 1].map((i) => Expanded(
              child: _NavButton(
                item: _items[i],
                selected: currentIndex == i,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => onTap(i),
              ),
            )),
            // Center spacer for FAB
            const Expanded(child: SizedBox()),
            // Right two items
            ...[2, 3].map((i) => Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _NavButton(
                    item: _items[i],
                    selected: currentIndex == i,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    onTap: () => onTap(i),
                    badge: i == 3 && unread > 0 ? unread : null,
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final int? badge;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                color: selected ? activeColor : inactiveColor,
                size: 24,
              ),
              if (badge != null)
                Positioned(
                  right: -6, top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    child: Text('$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Legacy Bottom Nav (pro / agent / admin) ───────────────────────────────────

class _LegacyBottomNav extends StatelessWidget {
  final bool isPro;
  final bool isAgent;
  final bool isAdmin;
  final int selectedIndex;
  final int unread;
  final ValueChanged<int> onTap;

  const _LegacyBottomNav({
    required this.isPro,
    required this.isAgent,
    required this.isAdmin,
    required this.selectedIndex,
    required this.unread,
    required this.onTap,
  });

  List<NavigationDestination> _destinations() {
    if (isAdmin) {
      return const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: 'Users'),
        NavigationDestination(icon: Icon(Icons.assessment_outlined), selectedIcon: Icon(Icons.assessment), label: 'Reports'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
      ];
    }
    if (isAgent) {
      return const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
        NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: 'Referrals'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chats'),
        NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ];
    }
    // Pro
    return [
      const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
      const NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Requests'),
      NavigationDestination(
        icon: unread > 0
            ? AppBadge(count: unread, child: const Icon(Icons.chat_bubble_outline))
            : const Icon(Icons.chat_bubble_outline),
        selectedIcon: const Icon(Icons.chat_bubble),
        label: 'Chats',
      ),
      const NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        animationDuration: const Duration(milliseconds: 400),
        destinations: _destinations(),
      ),
    );
  }
}

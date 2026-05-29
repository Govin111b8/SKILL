import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_service.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/home/category_detail_screen.dart';
import '../screens/profile/professional_profile_screen.dart';
import '../screens/contacts/my_contacts_screen.dart';
import '../screens/bookings/bookings_list_screen.dart';
import '../screens/bookings/booking_detail_screen.dart';
import '../screens/messages/threads_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/notifications/notification_preferences_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/search/instant_quote_screen.dart';
import '../screens/emergency/emergency_booking_screen.dart';
import '../screens/payments/payment_screen.dart';
import '../screens/payments/wallet_screen.dart';
import '../screens/tracking/live_tracking_screen.dart';
import '../screens/disputes/dispute_screen.dart';
import '../screens/warranty/warranty_screen.dart';
import '../screens/schedule/schedule_management_screen.dart';
import '../screens/earnings/earnings_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/kyc/kyc_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/referrals/referrals_screen.dart';
import '../screens/subscriptions/subscriptions_screen.dart';
import '../screens/marketplace/marketplace_screen.dart';
import '../screens/collections/collections_screen.dart';
import '../screens/community/community_feed_screen.dart';
import '../screens/family/family_account_screen.dart';
import '../screens/analytics/provider_analytics_screen.dart';
import '../screens/social/followers_screen.dart';
import '../screens/social/stories_screen.dart';
import '../screens/loyalty/loyalty_screen.dart';
import '../screens/onboarding/professional_onboarding_screen.dart';
import '../screens/agent/agent_onboarding_screen.dart';
import '../screens/agent/agent_wallet_screen.dart';
import '../screens/agent/agent_leaderboard_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_kyc_screen.dart';
import '../screens/admin/admin_disputes_screen.dart';
import '../screens/admin/admin_complaints_screen.dart';
import '../screens/admin/admin_featured_slots_screen.dart';
import '../screens/search/map_search_screen.dart';
// New screens
import '../screens/trust/neighbourhood_trust_screen.dart';
import '../screens/quotes/quote_bid_management_screen.dart';
import '../screens/amc/amc_visits_screen.dart';
import '../screens/society/society_screen.dart';

/// Application router using go_router.
///
/// Features:
/// - Deep link support (https://skillconnect.in/booking/:id, etc.)
/// - Custom URI scheme: skillconnect://
/// - Auth redirect: unauthenticated users → /login
/// - Role-based route access (admin routes require admin role)
class AppRouter {
  static GoRouter buildRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: false,
      redirect: (context, state) {
        final isLoggedIn = authService.isLoggedIn;
        final isAuthRoute = state.matchedLocation.startsWith('/login') ||
            state.matchedLocation.startsWith('/register') ||
            state.matchedLocation == '/splash';

        if (!isLoggedIn && !isAuthRoute) return '/login';
        if (isLoggedIn && isAuthRoute && state.matchedLocation != '/splash') {
          return '/home';
        }
        return null;
      },
      refreshListenable: authService,
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const _SplashRedirect()),
        GoRoute(path: '/login', builder: (_, __) => const WelcomeScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (_, __) => const MainShellPlaceholder()),
        GoRoute(
          path: '/booking/:id',
          builder: (context, state) => BookingDetailScreen(
            bookingId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/professional/:id',
          builder: (context, state) => ProfessionalProfileScreen(
            professionalId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => SearchScreen(
            categoryId: state.uri.queryParameters['category_id'] != null
                ? int.tryParse(state.uri.queryParameters['category_id']!)
                : null,
            categoryName: state.uri.queryParameters['category'],
          ),
        ),
        GoRoute(path: '/map', builder: (_, __) => const MapSearchScreen()),
        GoRoute(
          path: '/category/:id',
          builder: (context, state) => CategoryDetailScreen(
            categoryId: int.parse(state.pathParameters['id']!),
            categoryName: state.uri.queryParameters['name'] ?? '',
            categoryDescription: state.uri.queryParameters['description'],
            isRoot: state.uri.queryParameters['root'] == 'true',
          ),
        ),
        GoRoute(
          path: '/payment',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return PaymentScreen(
              bookingId: extra['bookingId'] as String,
              amount: (extra['amount'] as num).toDouble(),
              professionalName: extra['professionalName'] as String? ?? 'Professional',
            );
          },
        ),
        GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
        GoRoute(
          path: '/tracking/:bookingId',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return LiveTrackingScreen(
              bookingId: state.pathParameters['bookingId']!,
              professionalName: extra['professionalName'] as String? ?? 'Professional',
            );
          },
        ),
        GoRoute(
          path: '/dispute/:bookingId',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return DisputeScreen(
              bookingId: state.pathParameters['bookingId']!,
              bookingTitle: extra['bookingTitle'] as String? ?? 'Booking',
            );
          },
        ),
        GoRoute(path: '/contacts', builder: (_, __) => const MyContactsScreen()),
        GoRoute(path: '/instant-quote', builder: (_, __) => const InstantQuoteScreen()),
        GoRoute(path: '/emergency', builder: (_, __) => const EmergencyBookingScreen()),
        GoRoute(path: '/warranty', builder: (_, __) => const WarrantyScreen()),
        GoRoute(path: '/notification-preferences', builder: (_, __) => const NotificationPreferencesScreen()),
        GoRoute(path: '/schedule', builder: (_, __) => const ScheduleManagementScreen()),
        GoRoute(path: '/earnings', builder: (_, __) => const EarningsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/kyc', builder: (_, __) => const KycScreen()),
        GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/bookings', builder: (_, __) => const BookingsListScreen()),
        GoRoute(path: '/messages', builder: (_, __) => const ThreadsScreen()),
        GoRoute(
          path: '/chat/:threadId',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return ChatScreen(
              threadId: state.pathParameters['threadId']!,
              otherName: extra['otherUserName'] as String? ?? 'User',
              otherUserId: extra['otherUserId'] as String? ?? '',
            );
          },
        ),
        GoRoute(path: '/referrals', builder: (_, __) => const ReferralsScreen()),
        GoRoute(path: '/subscriptions', builder: (_, __) => const SubscriptionsScreen()),
        GoRoute(path: '/marketplace', builder: (_, __) => const MarketplaceScreen()),
        GoRoute(path: '/collections', builder: (_, __) => const CollectionsScreen()),
        GoRoute(path: '/community', builder: (_, __) => const CommunityFeedScreen()),
        GoRoute(path: '/followers', builder: (_, __) => const FollowersScreen()),
        GoRoute(path: '/stories', builder: (_, state) => StoriesScreen(professionalId: state.uri.queryParameters['professionalId'] ?? '', storyId: state.uri.queryParameters['storyId'])),
        GoRoute(path: '/loyalty', builder: (_, __) => const LoyaltyScreen()),
        GoRoute(path: '/family', builder: (_, __) => const FamilyAccountScreen()),
        GoRoute(path: '/analytics', builder: (_, __) => const ProviderAnalyticsScreen()),
        GoRoute(path: '/onboarding/professional', builder: (_, __) => const ProfessionalOnboardingScreen()),
        GoRoute(path: '/onboarding/agent', builder: (_, __) => const AgentOnboardingScreen()),
        GoRoute(path: '/agent/wallet', builder: (_, __) => const AgentWalletScreen()),
        GoRoute(path: '/agent/leaderboard', builder: (_, __) => const AgentLeaderboardScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
        GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
        GoRoute(path: '/admin/kyc', builder: (_, __) => const AdminKYCScreen()),
        GoRoute(path: '/admin/disputes', builder: (_, __) => const AdminDisputesScreen()),
        GoRoute(path: '/admin/complaints', builder: (_, __) => const AdminComplaintsScreen()),
        GoRoute(path: '/admin/featured-slots', builder: (_, __) => const AdminFeaturedSlotsScreen()),
        // New screens
        GoRoute(path: '/trust/neighbourhood', builder: (_, __) => const NeighbourhoodTrustScreen()),
        GoRoute(path: '/quotes/bids', builder: (_, __) => const QuoteBidManagementScreen()),
        GoRoute(path: '/amc/visits', builder: (_, __) => const AmcVisitsScreen()),
        GoRoute(path: '/society', builder: (_, __) => const SocietyScreen()),
      ],
    );
  }
}

class MainShellPlaceholder extends StatefulWidget {
  const MainShellPlaceholder({super.key});

  @override
  State<MainShellPlaceholder> createState() => _MainShellPlaceholderState();
}

class _MainShellPlaceholderState extends State<MainShellPlaceholder> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Import screens dynamically based on index
    final screens = [
      const _HomeTab(),
      const _SearchTab(),
      const _BookingsTab(),
      const _MessagesTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Wrapper tabs to load the appropriate content screens
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    // We import the home_screen.dart module here to avoid circular dependencies
    // The HomeScreen already handles role-based content display
    return const HomeScreen();
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) => const SearchScreen();
}

class _BookingsTab extends StatelessWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context) => const BookingsListScreen();
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) => const ThreadsScreen();
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) => const DashboardScreen();
}

class _SplashRedirect extends StatelessWidget {
  const _SplashRedirect();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

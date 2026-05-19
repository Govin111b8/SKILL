import { Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Footer from './components/Footer';
import BottomNav from './components/BottomNav';
import ProtectedRoute from './components/ProtectedRoute';
import Home from './pages/Home';
import Login from './pages/Login';
import Register from './pages/Register';
import CustomerLogin from './pages/CustomerLogin';
import ProfessionalLogin from './pages/ProfessionalLogin';
import AgentLogin from './pages/AgentLogin';
import AdminLogin from './pages/AdminLogin';
import CustomerRegister from './pages/CustomerRegister';
import ProfessionalRegister from './pages/ProfessionalRegister';
import AgentRegister from './pages/AgentRegister';
import SearchResults from './pages/SearchResults';
import ProfessionalProfile from './pages/ProfessionalProfile';
import Categories from './pages/Categories';
import CategoryDetail from './pages/CategoryDetail';
import Dashboard from './pages/Dashboard';
import Settings from './pages/Settings';
import Bookings from './pages/Bookings';
import BookingDetail from './pages/BookingDetail';
import CreateBooking from './pages/CreateBooking';
import Messages from './pages/Messages';
import Chat from './pages/Chat';
import Notifications from './pages/Notifications';
import Payment from './pages/Payment';
import Favorites from './pages/Favorites';
import Earnings from './pages/Earnings';
import Schedule from './pages/Schedule';
import Emergency from './pages/Emergency';
import Referrals from './pages/Referrals';
import Disputes from './pages/Disputes';
import Warranties from './pages/Warranties';
import Analytics from './pages/Analytics';
import AdminDashboard from './pages/admin/AdminDashboard';
import AdminUsers from './pages/admin/AdminUsers';
import AdminKYC from './pages/admin/AdminKYC';
import AdminDisputes from './pages/admin/AdminDisputes';
import AdminCategoryRequests from './pages/admin/AdminCategoryRequests';
import AdminFeaturedSlots from './pages/admin/AdminFeaturedSlots';
import AdminAppeals from './pages/admin/AdminAppeals';
import AdminComplaints from './pages/admin/AdminComplaints';
import AdminAuditLog from './pages/admin/AdminAuditLog';
import Storefront from './pages/Storefront';
import StorefrontSetup from './pages/StorefrontSetup';
import AgentDashboard from './pages/AgentDashboard';
import AgentOnboard from './pages/AgentOnboard';
import AgentWallet from './pages/AgentWallet';
import AgentLeaderboard from './pages/AgentLeaderboard';
import TermsOfService from './pages/TermsOfService';
import PrivacyPolicy from './pages/PrivacyPolicy';
import RefundPolicy from './pages/RefundPolicy';
import CookiePolicy from './pages/CookiePolicy';
import ProfessionalTerms from './pages/ProfessionalTerms';
import ContentModerationPolicy from './pages/ContentModerationPolicy';
import ProfessionalOnboarding from './pages/ProfessionalOnboarding';
import Collections from './pages/Collections';
import CommunityFeed from './pages/CommunityFeed';
import ReelsFeed from './pages/ReelsFeed';
import Subscriptions from './pages/Subscriptions';
import FamilyAccount from './pages/FamilyAccount';
import Marketplace from './pages/Marketplace';
import NotFound from './pages/NotFound';
import Toast from './components/Toast';
import AnnouncementBar from './components/AnnouncementBar';
import CookieConsent from './components/CookieConsent';
import AppInstallBanner from './components/AppInstallBanner';
import ErrorBoundary from './components/ErrorBoundary';
import './App.css';

function App() {
  return (
    <div className="app">
      <AnnouncementBar />
      <Navbar />
      <main className="app-main">
        <ErrorBoundary>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          <Route path="/login/customer" element={<CustomerLogin />} />
          <Route path="/login/professional" element={<ProfessionalLogin />} />
          <Route path="/login/agent" element={<AgentLogin />} />
          <Route path="/login/admin" element={<AdminLogin />} />
          <Route path="/register" element={<Register />} />
          <Route path="/register/customer" element={<CustomerRegister />} />
          <Route path="/register/professional" element={<ProfessionalRegister />} />
          <Route path="/register/agent" element={<AgentRegister />} />
          <Route path="/search" element={<SearchResults />} />
          <Route path="/professionals/:id" element={<ProfessionalProfile />} />
          <Route path="/professionals/:id/storefront" element={<Storefront />} />
          <Route
            path="/dashboard/storefront"
            element={
              <ProtectedRoute>
                <StorefrontSetup />
              </ProtectedRoute>
            }
          />
          <Route
            path="/onboarding/professional"
            element={
              <ProtectedRoute allowedRoles={['professional']}>
                <ProfessionalOnboarding />
              </ProtectedRoute>
            }
          />
          <Route path="/categories" element={<Categories />} />
          <Route path="/categories/:slug" element={<CategoryDetail />} />
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/settings"
            element={
              <ProtectedRoute>
                <Settings />
              </ProtectedRoute>
            }
          />
          <Route
            path="/bookings"
            element={
              <ProtectedRoute>
                <Bookings />
              </ProtectedRoute>
            }
          />
          <Route
            path="/bookings/create"
            element={
              <ProtectedRoute>
                <CreateBooking />
              </ProtectedRoute>
            }
          />
          <Route
            path="/bookings/:id/pay"
            element={
              <ProtectedRoute>
                <Payment />
              </ProtectedRoute>
            }
          />
          <Route
            path="/bookings/:id"
            element={
              <ProtectedRoute>
                <BookingDetail />
              </ProtectedRoute>
            }
          />
          <Route
            path="/messages"
            element={
              <ProtectedRoute>
                <Messages />
              </ProtectedRoute>
            }
          />
          <Route
            path="/messages/:threadId"
            element={
              <ProtectedRoute>
                <Chat />
              </ProtectedRoute>
            }
          />
          <Route
            path="/notifications"
            element={
              <ProtectedRoute>
                <Notifications />
              </ProtectedRoute>
            }
          />
          <Route
            path="/favorites"
            element={
              <ProtectedRoute>
                <Favorites />
              </ProtectedRoute>
            }
          />
          <Route
            path="/earnings"
            element={
              <ProtectedRoute>
                <Earnings />
              </ProtectedRoute>
            }
          />
          <Route
            path="/schedule"
            element={
              <ProtectedRoute>
                <Schedule />
              </ProtectedRoute>
            }
          />
          <Route
            path="/emergency"
            element={
              <ProtectedRoute>
                <Emergency />
              </ProtectedRoute>
            }
          />
          <Route
            path="/referrals"
            element={
              <ProtectedRoute>
                <Referrals />
              </ProtectedRoute>
            }
          />
          <Route
            path="/disputes"
            element={
              <ProtectedRoute>
                <Disputes />
              </ProtectedRoute>
            }
          />
          <Route
            path="/warranties"
            element={
              <ProtectedRoute>
                <Warranties />
              </ProtectedRoute>
            }
          />
          <Route
            path="/analytics"
            element={
              <ProtectedRoute>
                <Analytics />
              </ProtectedRoute>
            }
          />
          {/* Admin Routes */}
          <Route
            path="/admin"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AdminDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/users"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AdminUsers />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/kyc"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AdminKYC />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/disputes"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AdminDisputes />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/complaints"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AdminComplaints />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/category-requests"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AdminCategoryRequests />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/categories"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AdminCategoryRequests />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/featured-slots"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AdminFeaturedSlots />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/appeals"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AdminAppeals />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/audit-log"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AdminAuditLog />
              </ProtectedRoute>
            }
          />
          {/* Legal Pages */}
          <Route path="/terms" element={<TermsOfService />} />
          <Route path="/privacy" element={<PrivacyPolicy />} />
          <Route path="/refund-policy" element={<RefundPolicy />} />
          <Route path="/cookie-policy" element={<CookiePolicy />} />
          <Route path="/professional-terms" element={<ProfessionalTerms />} />
          <Route path="/content-moderation" element={<ContentModerationPolicy />} />
          {/* Social & Discovery */}
          <Route
            path="/collections"
            element={
              <ProtectedRoute>
                <Collections />
              </ProtectedRoute>
            }
          />
          <Route path="/community" element={<CommunityFeed />} />
          <Route path="/reels" element={<ReelsFeed />} />
          <Route path="/subscriptions" element={<Subscriptions />} />
          <Route path="/marketplace" element={<Marketplace />} />
          <Route
            path="/family"
            element={
              <ProtectedRoute>
                <FamilyAccount />
              </ProtectedRoute>
            }
          />
          {/* Agent Routes */}
          <Route
            path="/agent/dashboard"
            element={
              <ProtectedRoute>
                <AgentDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/agent/onboard/:type"
            element={
              <ProtectedRoute>
                <AgentOnboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/agent/wallet"
            element={
              <ProtectedRoute>
                <AgentWallet />
              </ProtectedRoute>
            }
          />
          <Route
            path="/agent/leaderboard"
            element={
              <ProtectedRoute>
                <AgentLeaderboard />
              </ProtectedRoute>
            }
          />
          <Route path="*" element={<NotFound />} />
        </Routes>
        </ErrorBoundary>
      </main>
      <Footer />
      <BottomNav />
      <Toast />
      <CookieConsent />
      <AppInstallBanner />
    </div>
  );
}

export default App;

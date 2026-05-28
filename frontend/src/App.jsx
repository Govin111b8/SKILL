import { Routes, Route } from 'react-router-dom';
import { lazy, Suspense } from 'react';
import Navbar from './components/Navbar';
import Footer from './components/Footer';
import BottomNav from './components/BottomNav';
import ProtectedRoute from './components/ProtectedRoute';
import Home from './pages/Home';
import Login from './pages/Login';
import Toast from './components/Toast';
import AnnouncementBar from './components/AnnouncementBar';
import CookieConsent from './components/CookieConsent';
import AppInstallBanner from './components/AppInstallBanner';
import ErrorBoundary from './components/ErrorBoundary';
import LoadingSpinner from './components/LoadingSpinner';
import './App.css';

// Code-split pages with React.lazy
const Register = lazy(() => import('./pages/Register'));
const CustomerLogin = lazy(() => import('./pages/CustomerLogin'));
const ProfessionalLogin = lazy(() => import('./pages/ProfessionalLogin'));
const AgentLogin = lazy(() => import('./pages/AgentLogin'));
const AdminLogin = lazy(() => import('./pages/AdminLogin'));
const CustomerRegister = lazy(() => import('./pages/CustomerRegister'));
const ProfessionalRegister = lazy(() => import('./pages/ProfessionalRegister'));
const AgentRegister = lazy(() => import('./pages/AgentRegister'));
const SearchResults = lazy(() => import('./pages/SearchResults'));
const ProfessionalProfile = lazy(() => import('./pages/ProfessionalProfile'));
const Categories = lazy(() => import('./pages/Categories'));
const CategoryDetail = lazy(() => import('./pages/CategoryDetail'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));
const Bookings = lazy(() => import('./pages/Bookings'));
const BookingDetail = lazy(() => import('./pages/BookingDetail'));
const CreateBooking = lazy(() => import('./pages/CreateBooking'));
const Messages = lazy(() => import('./pages/Messages'));
const Chat = lazy(() => import('./pages/Chat'));
const Notifications = lazy(() => import('./pages/Notifications'));
const Payment = lazy(() => import('./pages/Payment'));
const Favorites = lazy(() => import('./pages/Favorites'));
const Earnings = lazy(() => import('./pages/Earnings'));
const Schedule = lazy(() => import('./pages/Schedule'));
const Emergency = lazy(() => import('./pages/Emergency'));
const Referrals = lazy(() => import('./pages/Referrals'));
const Disputes = lazy(() => import('./pages/Disputes'));
const Warranties = lazy(() => import('./pages/Warranties'));
const Analytics = lazy(() => import('./pages/Analytics'));
const AdminDashboard = lazy(() => import('./pages/admin/AdminDashboard'));
const AdminUsers = lazy(() => import('./pages/admin/AdminUsers'));
const AdminKYC = lazy(() => import('./pages/admin/AdminKYC'));
const AdminDisputes = lazy(() => import('./pages/admin/AdminDisputes'));
const AdminCategoryRequests = lazy(() => import('./pages/admin/AdminCategoryRequests'));
const AdminFeaturedSlots = lazy(() => import('./pages/admin/AdminFeaturedSlots'));
const AdminAppeals = lazy(() => import('./pages/admin/AdminAppeals'));
const AdminComplaints = lazy(() => import('./pages/admin/AdminComplaints'));
const AdminAuditLog = lazy(() => import('./pages/admin/AdminAuditLog'));
const AdminCountries = lazy(() => import('./pages/admin/AdminCountries'));
const Storefront = lazy(() => import('./pages/Storefront'));
const StorefrontSetup = lazy(() => import('./pages/StorefrontSetup'));
const AgentDashboard = lazy(() => import('./pages/AgentDashboard'));
const AgentOnboard = lazy(() => import('./pages/AgentOnboard'));
const AgentWallet = lazy(() => import('./pages/AgentWallet'));
const AgentLeaderboard = lazy(() => import('./pages/AgentLeaderboard'));
const TermsOfService = lazy(() => import('./pages/TermsOfService'));
const PrivacyPolicy = lazy(() => import('./pages/PrivacyPolicy'));
const RefundPolicy = lazy(() => import('./pages/RefundPolicy'));
const CookiePolicy = lazy(() => import('./pages/CookiePolicy'));
const ProfessionalTerms = lazy(() => import('./pages/ProfessionalTerms'));
const ContentModerationPolicy = lazy(() => import('./pages/ContentModerationPolicy'));
const ProfessionalOnboarding = lazy(() => import('./pages/ProfessionalOnboarding'));
const Collections = lazy(() => import('./pages/Collections'));
const CommunityFeed = lazy(() => import('./pages/CommunityFeed'));
const ReelsFeed = lazy(() => import('./pages/ReelsFeed'));
const Subscriptions = lazy(() => import('./pages/Subscriptions'));
const FamilyAccount = lazy(() => import('./pages/FamilyAccount'));
const Marketplace = lazy(() => import('./pages/Marketplace'));
const QuoteRequest = lazy(() => import('./pages/QuoteRequest'));
const HomeProfile = lazy(() => import('./pages/HomeProfile'));
const JobTracker = lazy(() => import('./pages/JobTracker'));
const NotFound = lazy(() => import('./pages/NotFound'));

function App() {
  return (
    <div className="app">
      <AnnouncementBar />
      <Navbar />
      <main className="app-main">
        <ErrorBoundary>
        <Suspense fallback={<div className="page-loading"><LoadingSpinner /></div>}>
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
          <Route
            path="/admin/countries"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AdminCountries />
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
          <Route path="/quotes" element={<QuoteRequest />} />
          <Route
            path="/home-profiles"
            element={
              <ProtectedRoute>
                <HomeProfile />
              </ProtectedRoute>
            }
          />
          <Route
            path="/track/:bookingId"
            element={
              <ProtectedRoute>
                <JobTracker />
              </ProtectedRoute>
            }
          />
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
        </Suspense>
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

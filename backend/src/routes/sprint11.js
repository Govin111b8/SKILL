const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const recurring = require('../controllers/recurringBookingController');
const coupon = require('../controllers/couponController');
const sprint11 = require('../controllers/sprint11Controller');

// =====================================================
// RECURRING BOOKINGS
// =====================================================
router.get('/recurring-bookings', authenticate, recurring.listRecurring);
router.post('/recurring-bookings', authenticate, recurring.createRecurring);
router.put('/recurring-bookings/:id', authenticate, recurring.updateRecurring);
router.delete('/recurring-bookings/:id', authenticate, recurring.cancelRecurring);

// Booking rescheduling
router.post('/bookings/:id/reschedule', authenticate, recurring.reschedule);
router.get('/bookings/:id/reschedule-history', authenticate, recurring.getRescheduleHistory);

// =====================================================
// COUPONS
// =====================================================
router.get('/coupons', authenticate, coupon.listCoupons);
router.post('/coupons/validate', authenticate, coupon.validateCoupon);
router.post('/coupons/apply', authenticate, coupon.applyCoupon);
router.post('/coupons', authenticate, coupon.createCoupon); // Admin only

// =====================================================
// SAVED SEARCHES
// =====================================================
router.get('/saved-searches', authenticate, sprint11.listSavedSearches);
router.post('/saved-searches', authenticate, sprint11.saveSearch);
router.put('/saved-searches/:id', authenticate, sprint11.updateSavedSearch);
router.delete('/saved-searches/:id', authenticate, sprint11.deleteSavedSearch);

// =====================================================
// PROFESSIONAL COMPARISON
// =====================================================
router.get('/compare', authenticate, sprint11.compareProfessionals);

// =====================================================
// PAYMENT HISTORY
// =====================================================
router.get('/payment-history', authenticate, sprint11.getPaymentHistory);

// =====================================================
// PROMOTIONAL BANNERS
// =====================================================
router.get('/banners', sprint11.getActiveBanners);
router.post('/banners', authenticate, sprint11.createBanner); // Admin only

// =====================================================
// QUICK REPLIES (Chat Templates)
// =====================================================
router.get('/quick-replies', authenticate, sprint11.getQuickReplies);
router.post('/quick-replies', authenticate, sprint11.createQuickReply);
router.delete('/quick-replies/:id', authenticate, sprint11.deleteQuickReply);

// =====================================================
// PROFESSIONAL GOALS
// =====================================================
router.get('/goals', authenticate, sprint11.getGoals);
router.post('/goals', authenticate, sprint11.createGoal);
router.put('/goals/:id', authenticate, sprint11.updateGoal);

// =====================================================
// USER ADDRESSES
// =====================================================
router.get('/addresses', authenticate, sprint11.getAddresses);
router.post('/addresses', authenticate, sprint11.createAddress);
router.put('/addresses/:id', authenticate, sprint11.updateAddress);
router.delete('/addresses/:id', authenticate, sprint11.deleteAddress);

module.exports = router;

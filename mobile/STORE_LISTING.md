# SkillConnect — App Store Listing Assets

## Google Play Store

### App Details
- **App Name**: SkillConnect — Hire Local Experts
- **Short Description** (80 chars): Book trusted local professionals for home & office services
- **Category**: Lifestyle / Home Services
- **Content Rating**: Everyone

### Full Description (4000 chars)
SkillConnect connects you with verified, trusted local professionals for all your service needs.

**🔧 Services Available**
- Home Repair & Plumbing
- Electrical Work
- Carpentry & Furniture
- Cleaning & Deep Cleaning
- Painting & Waterproofing
- AC Repair & Appliances
- Beauty & Wellness
- Tutoring & Education
- And 50+ more categories

**✅ Why SkillConnect?**
- All professionals are KYC verified with government ID + skill tests
- Trust Level badges (Bronze → Platinum) based on ratings and reliability
- Live GPS tracking during service visits
- Escrow payments — money released only on job completion
- Warranty tracker for long-term service guarantees
- Voice search in Telugu & Hindi
- Works offline — book even with poor connectivity

**💳 Easy Payments**
- UPI (GPay, PhonePe, Paytm) — instant and free
- Razorpay (Cards, Net Banking, Wallets)
- Cash on Service option

**🌐 Languages**
Available in English, हिंदी (Hindi), and తెలుగు (Telugu)

**📱 For Professionals**
- Create your digital storefront
- Manage bookings with calendar view
- Instant quote requests
- Earnings dashboard with analytics
- Subscription services management

---

## Apple App Store

### App Details
- **App Name**: SkillConnect
- **Subtitle**: Hire Local Experts Near You
- **Category**: Lifestyle
- **Secondary Category**: Business

### Keywords
home services, plumber, electrician, carpenter, cleaning, professionals, local, booking, repair, maintenance

### Privacy Nutrition Labels
Data linked to user identity:
- Contact info (name, email, phone)
- Location (for nearby professional discovery)
- Usage data (bookings, search history)

Data NOT collected:
- Financial information (payments via Razorpay/UPI — not stored by app)
- Health data
- Browsing history

---

## CI/CD Required Secrets

Set these in GitHub repository Settings → Secrets → Actions:

| Secret | Description |
|--------|-------------|
| `KEYSTORE_BASE64` | Base64-encoded Android upload keystore (.jks) |
| `STORE_PASSWORD` | Keystore store password |
| `KEY_ALIAS` | Keystore key alias |
| `KEY_PASSWORD` | Keystore key password |
| `GOOGLE_SERVICES_JSON` | Base64-encoded google-services.json |
| `GOOGLE_SERVICE_INFO_PLIST` | Base64-encoded GoogleService-Info.plist |
| `APP_STORE_CONNECT_API_KEY` | JSON key for App Store Connect API |
| `PLAY_STORE_SERVICE_ACCOUNT` | JSON key for Google Play API |
| `API_BASE_URL` | Production API URL: https://api.skillconnect.in/api |
| `RAZORPAY_KEY` | Razorpay API key (rzp_live_...) |

### Generate Android Keystore
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -alias skillconnect \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=SkillConnect, OU=Mobile, O=SkillConnect Technologies, L=Hyderabad, S=Telangana, C=IN"
```

### Encode keystore for secret
```bash
base64 -i upload-keystore.jks | pbcopy  # macOS
base64 upload-keystore.jks | xclip      # Linux
```

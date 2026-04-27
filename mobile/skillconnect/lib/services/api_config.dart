class ApiConfig {
  // Web: relative path — same server serves app + API, no CORS needed
  // Android emulator: needs full URL
  static const String baseUrl = '/api';
  static const String androidBaseUrl = 'http://10.0.2.2:3000/api';
}

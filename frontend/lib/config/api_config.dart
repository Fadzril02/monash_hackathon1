/// API Configuration for RytGuard Backend
///
/// Configure the baseUrl based on your testing platform:
/// - Android Emulator: Use 'http://10.0.2.2:3001'
/// - iOS Simulator: Use 'http://localhost:3001' or 'http://127.0.0.1:3001'
/// - Physical Device: Use your computer's IP, e.g., 'http://192.168.1.100:3001'
class ApiConfig {
  // Change this based on your platform
  static const String _androidEmulatorUrl = 'http://10.0.2.2:3001';
  static const String _iosSimulatorUrl = 'http://localhost:3001';
  static const String _webUrl = 'http://localhost:3001'; // For Chrome/Web
  static const String _physicalDeviceUrl = 'http://192.168.1.100:3001'; // Update with your IP

  /// Current base URL - Change this based on your testing platform
  static const String baseUrl = _webUrl; // Changed to Web for Chrome testing

  /// Default test user ID
  static const String defaultUserExternalId = 'john_doe_001';

  /// API Endpoints
  static const String healthEndpoint = '/health';
  static const String chatEndpoint = '/api/chat';
  static const String reloadEndpoint = '/api/reload';
  static const String withdrawEndpoint = '/api/withdraw';
  static const String checkWithdrawalEndpoint = '/api/check-withdrawal';
  static const String subscriptionsEndpoint = '/api/subscriptions';
  static const String addSubscriptionEndpoint = '/api/add-subscription';
  static const String cancelSubscriptionEndpoint = '/api/cancel-subscription';
  static const String promotionsEndpoint = '/api/promotions';
  static const String queryEndpoint = '/api/query';

  /// Headers
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };
}

import 'package:firebase_messaging/firebase_messaging.dart';

class FCMTokenService {
  // Singleton instance
  static final FCMTokenService _instance = FCMTokenService._internal();
  factory FCMTokenService() => _instance;
  FCMTokenService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Method to get current FCM token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Method to handle token refresh
  void initTokenRefresh() {
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      // Here you would typically send the new token to your backend
      _sendTokenToServer(newToken);
    });
  }

  // Method to send token to your backend server
  Future<void> _sendTokenToServer(String token) async {
    try {
      // Replace with your actual API endpoint
      // Example using http package:
      // await http.post(
      //   Uri.parse('https://your-backend.com/register-token'),
      //   body: {
      //     'token': token,
      //     'userId': currentUserId, // Add user identification
      //   }
      // );
      print('Token sent to server: $token');
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }

  // Method to subscribe to a specific topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Method to unsubscribe from a specific topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}

// Example usage in your app initialization
void setupFCM() {
  final fcmTokenService = FCMTokenService();

  // Get initial token
  fcmTokenService.getToken().then((token) {
    if (token != null) {
      print('Initial FCM Token: $token');
      // Send initial token to your server
      // fcmTokenService._sendTokenToServer(token);
    }
  });

  // Start listening for token refreshes
  fcmTokenService.initTokenRefresh();

  // Optional: Subscribe to topics
  fcmTokenService.subscribeToTopic('all_users');
}

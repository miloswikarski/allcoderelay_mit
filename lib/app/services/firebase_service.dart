//DISABLED
/*
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FirebaseService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'fcm_token';

  Future<String?> getToken() async {
    try {
      // First try to get token from secure storage
      String? token = await _storage.read(key: _tokenKey);
      
      // If no token in storage, request new one
      if (token == null) {
        // Request notification permission
        NotificationSettings settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          // Get the token
          token = await _messaging.getToken();
          
          // Store the token
          if (token != null) {
            await _storage.write(key: _tokenKey, value: token);
          }
        }
      }

      return token;
    } catch (e) {
      // Handle any errors that occur during token retrieval
      return null;
    }
  }

  Future<void> initialize() async {
    // Configure FCM handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Request permission and get initial token
    await getToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      await _storage.write(key: _tokenKey, value: newToken);
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Handle foreground message
    print('Received foreground message: ${message.messageId}');
    // TODO: Implement foreground message handling
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background/terminated message
    print('Received background message: ${message.messageId}');
    // TODO: Implement background message handling
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // This static handler is required for background messages when the app is terminated
    print('Handling background message: ${message.messageId}');
    // TODO: Implement terminated state message handling
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _messaging.deleteToken();
  }
}

*/

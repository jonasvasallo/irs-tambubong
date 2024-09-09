import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<String?> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    await _firebaseMessaging.subscribeToTopic("incident-alert");

    final fcmToken = await _firebaseMessaging.getToken();

    print('Token: ${fcmToken}');
    return fcmToken;
  }
}
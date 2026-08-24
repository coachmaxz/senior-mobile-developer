import 'dart:async';

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_background_service/flutter_background_service.dart';

import '/firebase_options.dart';
import '/services/share_local_storage.dart';

import '/screens/home_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFirebaseMessaging();
  if (notification != null) {
    print('Nnotification: ${notification.toMap()}');
    print('Title: ${notification.title}');
    print('Body: ${notification.body}');
    print('Data: ${message.data}');
  }
  print('Handling a background message ${message.messageId}');
}

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  String? fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
  print('Firebase Cloud Messaging Token: $fcmToken');
  await ShareLocalStorage().setStringData('fcmToken', fcmToken);

  runApp(const MyApp());

}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    print("Background execution running actively!");
  });
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

class MyApp extends StatelessWidget {

  const MyApp({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }

}

class MainPage extends StatelessWidget {

  const MainPage({
    super.key, 
  });

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }

}
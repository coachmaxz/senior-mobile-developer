import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';

import 'package:firebase_core/firebase_core.dart';

// import 'package:geolocator/geolocator.dart';
// import 'package:geolocator_android/geolocator_android.dart';

import 'package:flutter_background_service/flutter_background_service.dart';

import 'screens/home_screen.dart';

const notificationId = 888;
const notificationChannelId = 'my_foreground';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeBackgroundService();
  runApp(const MyApp());
}

Future<void> initializeBackgroundService() async {
  // final service = FlutterBackgroundService();
  // const AndroidNotificationChannel channel = AndroidNotificationChannel(
  //   notificationChannelId,d
  //   'MY FOREGROUND SERVICE',
  //   description: 'This channel is used for important notifications.',
  //   importance: Importance.low, 
  // );
  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  // await service.configure(
  //   androidConfiguration: AndroidConfiguration(
  //     onStart: onStart, 
  //     autoStart: true,
  //     isForegroundMode: true,
  //     notificationChannelId: notificationChannelId,
  //     initialNotificationTitle: 'Background Service running',
  //     initialNotificationContent: 'Initializing...',
  //     foregroundServiceNotificationId: notificationId,
  //   ),
  //   iosConfiguration: IosConfiguration(
  //     autoStart: true,
  //     onForeground: onStart,
  //     onBackground: onIosBackground,
  //   ),
  // );
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
      title: 'Mobile Developer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
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
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeBackgroundService();
  runApp(const MyApp());
}

Future<void> initializeBackgroundService() async {
  // final service = FlutterBackgroundService();
  // await service.configure(
  //   androidConfiguration: AndroidConfiguration(
  //     onStart: onStart, 
  //     autoStart: true,
  //     isForegroundMode: true,
  //     notificationChannelId: 'my_foreground',
  //     initialNotificationTitle: 'Background Service running',
  //     initialNotificationContent: 'Initializing...',
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
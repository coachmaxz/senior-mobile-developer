import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:battery_plus/battery_plus.dart';

import '/core/config/app_config.dart';
import '/models/location_model.dart';

import '/services/reastful_api.dart';

class LocationService {

  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  LocationService._internal();

  final locationController = StreamController<LocationModel>.broadcast();
  Stream<LocationModel> get locationStream => locationController.stream;
  StreamSubscription<Position>? positionSub;

  final battery = Battery();

  Position? lastPosition;
  int lastWriteMs = 0;

  void dispose() {
    positionSub?.cancel();
    locationController.close();
  }

  Future<bool> requestPermissions() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return false;
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<void> onPosition(Position position, String? uuid) async {

    if (position.accuracy > AppConfig.maxAccuracyMeters) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastMs = now - lastWriteMs;

    double distanceMoved = 0;

    if (lastPosition != null) {
      distanceMoved = Geolocator.distanceBetween(
        lastPosition!.latitude,
        lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
    }

    final shouldWrite = lastPosition == null || distanceMoved >= AppConfig.distanceFilterMeters || timeSinceLastMs >= AppConfig.locationIntervalSeconds * 1000;
    if (!shouldWrite) return;

    int batteryLevel = 100;
    try {
      batteryLevel = await battery.batteryLevel;
    } catch (_) {}

    final speedKmh = (position.speed * 3.6).clamp(0, 300).toDouble();
    final loc = LocationModel(
      lat: position.latitude,
      lng: position.longitude,
      speed: speedKmh,
      heading: position.heading,
      accuracy: position.accuracy,
      altitude: position.altitude,
      battery: batteryLevel,
      isMoving: speedKmh >= AppConfig.movingSpeedThresholdKmh,
      timestamp: now,
    );

    lastPosition = position;
    lastWriteMs = now;

    locationController.add(loc);

    await Future.wait([
      postStartTracking(uuid, loc),
      writeRealtimeLocation(uuid, loc),
      // writeCurrentLocation(uuid, loc),
      // updatePresence(uuid),
    ]);

  }

  Future<void> startTracking({ required String uuid }) async {

    print('Start Tracking');

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {

      // locationSettings = AndroidSettings(
      //   accuracy: LocationAccuracy.high,
      //   distanceFilter: 5,
      //   foregroundNotificationConfig: const ForegroundNotificationConfig(
      //     notificationTitle: "Location Tracking Active",
      //     notificationText: "Tracking route details in background.",
      //     enableWifiLock: true,
      //   ),
      // );
      
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

    } else if (defaultTargetPlatform == TargetPlatform.iOS) {

      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );

    } else {

      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
      
    }

    positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      await onPosition(position, uuid);
      print('Background Location: ${position.latitude}, ${position.longitude}');
    });

  }

  Future<void> stopTracking({ required String uuid }) async {

    await positionSub?.cancel();

    positionSub = null;
    lastPosition = null;

    await FirebaseDatabase.instance.ref('members/$uuid/status').set('offline');
    await FirebaseDatabase.instance.ref('members/$uuid/lastChanged').set(ServerValue.timestamp);

  }

  Future<void> writeRealtimeLocation(String? uuid, LocationModel loc) async {
    print('POST: Realtime Location');
    Map<String, dynamic> res = await RESTfulAPI().post('/tracking/${uuid.toString()}', loc.toLocationJson(), {});
    if ((res['status'] == 200 || res['status'] == 201) && res['data']['message'] == 'CREATED') {
      print('POST: Realtime Location (CREATED)');
    }
    // await FirebaseDatabase.instance
    //   .ref('members/$uuid/realtimeLocation/${DateTime.now().millisecondsSinceEpoch}')
    //   .set(loc.toLocationJson());
  }

  Future<void> writeCurrentLocation(String? uuid, LocationModel loc) async {
    print('PUT: Current Location');
    Map<String, dynamic> res = await RESTfulAPI().put('/tracking/currentLocation/${uuid.toString()}', loc.toLocationJson(), {});
    if ((res['status'] == 200) && res['data']['message'] == 'UPDATED') {
      print('PUT: Current Location (UPDATED)');
    }
    // await FirebaseDatabase.instance
    //   .ref('members/$uuid/currentLocation')
    //   .set(loc.toLocationJson());
  }

  Future<void> updatePresence(String? uuid) async {
    print('PUT: Update Presence');
    Map<String, dynamic> res = await RESTfulAPI().put('/tracking/presence/${uuid.toString()}', {}, {});
    if ((res['status'] == 200) && res['data']['message'] == 'UPDATED') {
      print('PUT: Update Presence (UPDATED)');
    }
    // await FirebaseDatabase.instance.ref('members/$uuid/status').set('online');
    // await FirebaseDatabase.instance.ref('members/$uuid/lastChanged').set(ServerValue.timestamp);
  }

  Future<void> postStartTracking(String? uuid, LocationModel loc) async {
    print('POST: Start Tracking');
    Map<String, dynamic> res = await RESTfulAPI().post('/tracking/start/${uuid.toString()}', loc.toLocationJson(), {});
    if ((res['status'] == 200 || res['status'] == 201) && res['data']['message'] == 'CREATED') {
      print('POST: Start Tracking (CREATED)');
    }
  }

  Future<void> postStopTracking(String? uuid, LocationModel loc) async {
    print('POST: Stop Tracking');
    Map<String, dynamic> res = await RESTfulAPI().post('/tracking/stop/${uuid.toString()}', loc.toLocationJson(), {});
    if ((res['status'] == 200 || res['status'] == 201) && res['data']['message'] == 'CREATED') {
      print('POST: Stop Tracking (UPDATE)');
    }
  }

}
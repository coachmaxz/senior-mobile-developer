import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:firebase_database/firebase_database.dart';

import 'package:battery_plus/battery_plus.dart';

import '/core/config/app_config.dart';
import '/models/location_model.dart';

import '/services/reastful_api.dart';
import '/services/share_local_storage.dart';

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

  static String? trackingId = '';
  static const String trackingIdKey = 'trackingId';

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

  Future<String> getTrackingId() async {
    
    String? trackingIdNew;
    String? cachedId = await ShareLocalStorage().getStringData(trackingIdKey) ?? '';

    if (cachedId.isNotEmpty) {
      trackingIdNew = cachedId;
    } else {
      trackingIdNew = const Uuid().v4();
      trackingIdNew = '${DateTime.now().millisecondsSinceEpoch}-$trackingIdNew';
      await ShareLocalStorage().setStringData(trackingIdKey, trackingIdNew);
    }
    
    return trackingIdNew;
  
  }

  Future<void> onPosition(Position position, String? uuid, String? trackingIdNew) async {

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
      uuid: uuid.toString(),
      trackingId: trackingIdNew.toString(),
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
      postStartTracking(uuid, trackingIdNew, loc),
      writeRealtimeLocation(uuid, trackingIdNew, loc),
    ]);

  }

  Future<void> startTracking({ required String uuid }) async {

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

    String? trackingIdNew = await getTrackingId();

    positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      await onPosition(position, uuid, trackingIdNew);
    });

  }

  Future<void> stopTracking({ required String uuid }) async {

    String? trackingIdNew = await getTrackingId();

    await positionSub?.cancel();
    await ShareLocalStorage().removeStringData(trackingIdKey);

    positionSub = null;
    lastPosition = null;

    await Future.wait([
      putStopTracking(uuid, trackingIdNew),
    ]);

  }

  Future<void> writeRealtimeLocation(String? uuid, String? trackingIdNew, LocationModel loc) async {
    Map<String, dynamic> res = await RESTfulAPI().post('/tracking/${uuid.toString()}', {
      "uuid": uuid,
      "trackingId": trackingIdNew,
      "location": loc.toLocationJson(),
    }, {});
    if ((res['status'] == 200 || res['status'] == 201) && res['data']['message'] == 'CREATED') {
      // print('POST: Realtime Location (CREATED)');
    }
    // await FirebaseDatabase.instance
    //   .ref('members/$uuid/realtimeLocation/${DateTime.now().millisecondsSinceEpoch}')
    //   .set(loc.toLocationJson());
  }

  Future<void> writeCurrentLocation(String? uuid, String? trackingIdNew, LocationModel loc) async {
    Map<String, dynamic> res = await RESTfulAPI().put('/tracking/currentLocation/${uuid.toString()}', {
      "uuid": uuid,
      "trackingId": trackingIdNew,
      "location": loc.toLocationJson(),
    }, {});
    if (res['status'] == 200 && res['data']['message'] == 'UPDATED') {
      // print('POST: Realtime Location (CREATED)');
    }
    // await FirebaseDatabase.instance
    //   .ref('members/$uuid/realtimeLocation/${DateTime.now().millisecondsSinceEpoch}')
    //   .set(loc.toLocationJson());
  }

  Future<void> postStartTracking(String? uuid, String? trackingIdNew, LocationModel loc) async {
    Map<String, dynamic> res = await RESTfulAPI().post('/tracking/start/${uuid.toString()}', {
      "uuid": uuid,
      "trackingId": trackingIdNew,
      "location": loc.toLocationJson(),
    }, {});
    if ((res['status'] == 200 || res['status'] == 201) && res['data']['message'] == 'CREATED') {
      // print('POST: Start Tracking (CREATED)');
    }
    // await FirebaseDatabase.instance.ref('members/$uuid/status').set('riding');
    // await FirebaseDatabase.instance.ref('members/$uuid/lastChanged').set(ServerValue.timestamp);
  }

  Future<void> putStopTracking(String? uuid, String? trackingIdNew) async {
    Map<String, dynamic> res = await RESTfulAPI().put('/tracking/stop/${uuid.toString()}', {
      "uuid": uuid,
      "trackingId": trackingIdNew,
    }, {});
    if ((res['status'] == 200) && res['data']['message'] == 'UPDATED') {
      // print('PUT: Stop Tracking (UPDATED)');
    }
    // await FirebaseDatabase.instance.ref('members/$uuid/status').set('offline');
    // await FirebaseDatabase.instance.ref('members/$uuid/lastChanged').set(ServerValue.timestamp);
  }

}
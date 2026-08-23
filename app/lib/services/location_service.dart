import 'dart:async';
// import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:battery_plus/battery_plus.dart';

import '../../../core/config/app_config.dart';
import '../../models/location_model.dart';

class LocationService {

  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  LocationService._internal();

  final battery = Battery();

  final locationController = StreamController<LocationModel>.broadcast();
  Stream<LocationModel> get locationStream => locationController.stream;

  StreamSubscription<Position>? positionSub;

  // bool _isTracking = false;
  // bool get isTracking => _isTracking;
  
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

  Future<void> onPosition(
    Position position,
    String userId,
  ) async {

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
      writeCurrentLocation(userId, loc),
    ]);

  }

  Future<void> startTracking({ required String userId }) async {

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    positionSub = Geolocator.getPositionStream(locationSettings: settings).listen((position) async {
      await onPosition(position, userId);
    });

  }

  Future<void> writeCurrentLocation(String userId, LocationModel loc) async {
    await FirebaseDatabase.instance.ref('members/$userId/currentLocation').set(loc.toCurrentLocationJson());
  }

}
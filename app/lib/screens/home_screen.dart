import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';

import 'package:uuid/uuid.dart';

import '/services/reastful_api.dart';
import '/services/location_service.dart';
import '/services/share_local_storage.dart';

import '/models/location_model.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({
    super.key, 
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();

}

class HomeScreenState extends State<HomeScreen> {
  
  final locService = LocationService();

  LocationModel? myLocation;

  bool isTracking = false;
  bool permDenied = false;

  static String? uuid = 'uuid';
  static const String deviceIdKey = 'deviceId';

  @override
  void initState() {
    super.initState();
    getDeviceId();
    putFcmToken();
    locService.locationStream.listen((LocationModel loc) {
      print('Stream Location: ${loc.lat}, ${loc.lng}');
      setState(() => myLocation = loc);
    });
    getFetchLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final myLoc = myLocation;
    final speedKmh = myLoc?.speed.round() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Tracking'),
        actions: <Widget> [
          IconButton(
            icon: Icon(
              isTracking ? Icons.stop_circle : Icons.play_circle_filled,
              color: isTracking ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              size: 28,
            ),
            onPressed: toggleRide,
          ),
        ],
      ),
      body: Stack(
        children: <Widget> [
          Container(
            color: const Color(0xFF0D1B2A),
            child: CustomPaint(
              painter: MapGridPainter(),
              child: SizedBox.expand(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget> [
                      const Text(
                        '🗺️', 
                        style: TextStyle(
                          fontSize: 64,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isTracking ? 'กำลังส่ง GPS Realtime...' : 'กด START เพื่อเริ่มแชร์ตำแหน่ง',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8), 
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30, 
                          vertical: 10,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              isTracking ? Icons.stop_circle : Icons.play_circle_filled, 
                              color: Color(0xFFFFFFFF), 
                              size: 20,
                            ),
                            label: Text(
                              isTracking ? 'STOP RIDE' : 'START RIDE',
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF), 
                                fontSize: 18,
                              ),
                            ),
                            onPressed: toggleRide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isTracking ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (myLoc != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          'Lat: ${myLoc.lat}, Lng: ${myLoc.lng}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8), 
                            fontSize: 12, 
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      if (myLoc != null) 
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget> [
                            Text(
                              '$speedKmh',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w900, 
                                color: speedKmh > 120 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                                fontVariations: const [FontVariation('wght', 900)],
                              ),
                            ),
                            Text(
                              ' KM/H', 
                              style: const TextStyle(
                                color: Color(0xFF94A3B8), 
                                fontSize: 12, 
                                letterSpacing: 1
                              ),
                            ),
                          ],
                        ),
                      if (myLoc != null) 
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget> [
                            Text(
                              'BATTERY: ', 
                              style: const TextStyle(
                                color: Color(0xFF94A3B8), 
                                fontSize: 12, 
                                letterSpacing: 1
                              ),
                            ),
                            Text(
                              '${myLoc.battery}%',
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.w900, 
                                color: myLoc.battery < 20 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                                fontVariations: const <FontVariation> [
                                  FontVariation('wght', 800),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  
  }

  Future<String> getDeviceId() async {
    
    String? cachedId = await ShareLocalStorage().getStringData(deviceIdKey) ?? '';
    String? deviceId;

    if (cachedId.isNotEmpty) {
      deviceId = cachedId;
    } else {
      deviceId = const Uuid().v4();
      await ShareLocalStorage().setStringData(deviceIdKey, deviceId);
    }

    setState(() => uuid = deviceId);
    return deviceId;
  
  }

  Future<void> toggleRide() async {

    print('Toggle Ride');

    String? uuid = await getDeviceId();
    if (!mounted) return;

    if (!isTracking) {

      print('Tracking: START');

      final granted = await locService.requestPermissions();
      if (!granted) { setState(() => permDenied = true); return; }

      await locService.startTracking(uuid: uuid.toString());
      setState(() => isTracking = true);

    } else {

      print('Tracking: STOP');

      await locService.stopTracking(uuid: uuid.toString());

      setState(() => isTracking = false);
      setState(() => myLocation = null);

      getFetchLocation();

    }

  }

  Future<void> getFetchLocation() async {

    String? uuid = await getDeviceId();
    if (!mounted) return;

    print('GET: Fetch Location');
    Map<String, dynamic> res = await RESTfulAPI().get('/tracking/realtimeLocation/${uuid.toString()}', {});
    if ((res['status'] == 200) && res['data']['message'] == 'OK') {
      print('GET: Fetch Location (OK)');
      print(res['data']['data']);
    }

    // FirebaseDatabase.instance.ref('members/$uuid/realtimeLocation').onValue.listen((event) {
    //   final locations = <LocationModel>[];
    //   if (event.snapshot.exists) {
    //     final data = event.snapshot.value as Map<dynamic, dynamic>;
    //     data.forEach((key, value) {
    //       final location = LocationModel.fromJson(key.toString(), value as Map);
    //       locations.add(location);
    //     });
    //     locations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    //   }
    // });

  }

  Future<void> putFcmToken() async {
    String? fcmToken = await ShareLocalStorage().getStringData('fcmToken') ?? '';
    print('PUT: Save FCM Token');
    Map<String, dynamic> res = await RESTfulAPI().put('/tracking/fcmToken/${uuid.toString()}', {
      'fcmToken': fcmToken,
    }, {});
    if ((res['status'] == 200) && res['data']['message'] == 'UPDATED') {
      print('PUT: Save FCM Token (UPDATED)');
    }
    // await FirebaseDatabase.instance.ref('members/$uuid/fcmToken').set(fcmToken);
  }

}

class MapGridPainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF59E0B).withOpacity(0.04)..strokeWidth = 1;
    const gridSize = 40.0;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;

}
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// import '../../core/config/app_config.dart';

import '../../services/location_service.dart';
import '../../models/location_model.dart';

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
  bool permDenied = false;

  @override
  void initState() {
    super.initState();
    locService.locationStream.listen((loc) {
      if (mounted) setState(() => myLocation = loc);
    });
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
    final uid = 'demo-0001';

    Future<void> toggleRide() async {
      final granted = await locService.requestPermissions();
      if (!granted) {
        setState(() => permDenied = true);
        return;
      }
      await locService.startTracking(userId: uid);
      await FirebaseDatabase.instance.ref('members/$uid/status').set('riding');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Map'),
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
                      Text(
                        'กด START เพื่อเริ่มแชร์ตำแหน่ง',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8), 
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20,),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.play_circle_filled, 
                            color: Color(0xFFFFFFFF), 
                            size: 20,
                          ),
                          label: Text(
                            'START',
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF), 
                              fontSize: 18,
                            ),
                          ),
                          onPressed: toggleRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      if (myLoc != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${myLoc.lat.toStringAsFixed(5)}, ${myLoc.lng.toStringAsFixed(5)}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      )
    );
  
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
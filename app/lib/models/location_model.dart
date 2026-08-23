class LocationModel {

  final double lat;
  final double lng;

  final double speed;
  
  final double heading;
  final double accuracy;
  final double altitude;

  final int battery;

  final bool isMoving;
  final int timestamp;

  const LocationModel({
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.accuracy,
    required this.altitude,
    required this.battery,
    required this.isMoving,
    required this.timestamp,
  });

  Map<String, dynamic> toCurrentLocationJson() => {
    'lat': lat,
    'lng': lng,
    'speed': speed,
    'heading': heading,
    'accuracy': accuracy,
    'altitude': altitude,
    'battery': battery,
    'isMoving': isMoving,
    'timestamp': timestamp,
    'updatedAt': DateTime.now().millisecondsSinceEpoch,
  };

  Map<String, dynamic> toHistoryJson() => {
    'lat': lat,
    'lng': lng,
    'speed': speed,
    'heading': heading,
    'accuracy': accuracy,
    'timestamp': timestamp,
  };

}
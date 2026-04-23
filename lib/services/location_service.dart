import 'package:geolocator/geolocator.dart';

class LocationService {
  // Request permission and return current position.
  // Returns null if permission is denied.
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Returns a continuous stream of position updates.
  // distanceFilter: only emit when player moves at least 2 meters.
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    );
  }

  // Returns true if the player is within radiusMeters of the target.
  bool isWithinProximity(
    double playerLat,
    double playerLng,
    double targetLat,
    double targetLng,
    double radiusMeters,
  ) {
    final distance = Geolocator.distanceBetween(
      playerLat,
      playerLng,
      targetLat,
      targetLng,
    );
    return distance <= radiusMeters;
  }

  // Returns the distance in meters between two coordinates.
  double distanceBetween(
    double playerLat,
    double playerLng,
    double targetLat,
    double targetLng,
  ) {
    return Geolocator.distanceBetween(
      playerLat,
      playerLng,
      targetLat,
      targetLng,
    );
  }
}
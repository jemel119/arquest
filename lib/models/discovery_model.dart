import 'package:cloud_firestore/cloud_firestore.dart';

class DiscoveryModel {
  final String id;
  final String userId;
  final String questId;
  final String clueId;
  final String? assetId;
  final String photoUrl;
  final GeoPoint captureLocation;
  final DateTime timestamp;

  DiscoveryModel({
    required this.id,
    required this.userId,
    required this.questId,
    required this.clueId,
    this.assetId,
    required this.photoUrl,
    required this.captureLocation,
    required this.timestamp,
  });

  factory DiscoveryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return DiscoveryModel(
      id: id,
      userId: data['userId'] ?? '',
      questId: data['questId'] ?? '',
      clueId: data['clueId'] ?? '',
      assetId: data['assetId'],
      photoUrl: data['photoUrl'] ?? '',
      captureLocation: data['captureLocation'] as GeoPoint,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'questId': questId,
        'clueId': clueId,
        'assetId': assetId,
        'photoUrl': photoUrl,
        'captureLocation': captureLocation,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
import 'package:cloud_firestore/cloud_firestore.dart';

class ClueModel {
  final String id;
  final String questId;
  final int orderIndex;
  final String hintText;
  final GeoPoint targetLocation;
  final double proximityRadius;
  final String? arAssetUrl;
  final String? assetId;

  ClueModel({
    required this.id,
    required this.questId,
    required this.orderIndex,
    required this.hintText,
    required this.targetLocation,
    this.proximityRadius = 15.0,
    this.arAssetUrl,
    this.assetId,
  });

  factory ClueModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ClueModel(
      id: id,
      questId: data['questId'] ?? '',
      orderIndex: data['orderIndex'] ?? 0,
      hintText: data['hintText'] ?? '',
      targetLocation: data['targetLocation'] as GeoPoint,
      proximityRadius: (data['proximityRadius'] ?? 15.0).toDouble(),
      arAssetUrl: data['arAssetUrl'],
      assetId: data['assetId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'questId': questId,
        'orderIndex': orderIndex,
        'hintText': hintText,
        'targetLocation': targetLocation,
        'proximityRadius': proximityRadius,
        'arAssetUrl': arAssetUrl,
        'assetId': assetId,
      };
}
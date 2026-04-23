import 'package:cloud_firestore/cloud_firestore.dart';

class QuestModel {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String difficultyLevel;
  final int totalClues;
  final int pointValue;
  final bool isPublished;
  final DateTime createdAt;
  final GeoPoint centerLocation;
  final double radiusMeters;
  final List<String> tags;

  QuestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.difficultyLevel,
    required this.totalClues,
    required this.pointValue,
    required this.isPublished,
    required this.createdAt,
    required this.centerLocation,
    required this.radiusMeters,
    required this.tags,
  });

  factory QuestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return QuestModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      difficultyLevel: data['difficultyLevel'] ?? 'medium',
      totalClues: data['totalClues'] ?? 0,
      pointValue: data['pointValue'] ?? 0,
      isPublished: data['isPublished'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      centerLocation: data['centerLocation'] as GeoPoint,
      radiusMeters: (data['radiusMeters'] ?? 100).toDouble(),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'creatorId': creatorId,
        'difficultyLevel': difficultyLevel,
        'totalClues': totalClues,
        'pointValue': pointValue,
        'isPublished': isPublished,
        'createdAt': Timestamp.fromDate(createdAt),
        'centerLocation': centerLocation,
        'radiusMeters': radiusMeters,
        'tags': tags,
      };
}
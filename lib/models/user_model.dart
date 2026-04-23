import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final int totalScore;
  final int questsCompleted;
  final String fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.totalScore = 0,
    this.questsCompleted = 0,
    this.fcmToken = '',
    required this.createdAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoURL: data['photoURL'],
      totalScore: data['totalScore'] ?? 0,
      questsCompleted: data['questsCompleted'] ?? 0,
      fcmToken: data['fcmToken'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'photoURL': photoURL,
        'totalScore': totalScore,
        'questsCompleted': questsCompleted,
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
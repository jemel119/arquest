import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quest_model.dart';
import '../models/clue_model.dart';
import '../models/discovery_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── USERS ──────────────────────────────────────────────────────────────────

  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<void> incrementScore(String uid, int points) async {
    await _db.collection('users').doc(uid).update({
      'totalScore': FieldValue.increment(points),
      'questsCompleted': FieldValue.increment(1),
    });
  }

  // ── QUESTS ─────────────────────────────────────────────────────────────────

  Future<String> createQuest(QuestModel quest) async {
    final ref = await _db.collection('quests').add(quest.toMap());
    return ref.id;
  }

  Stream<List<QuestModel>> getPublishedQuests() {
    return _db
        .collection('quests')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => QuestModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<QuestModel?> getQuestById(String questId) async {
    final doc = await _db.collection('quests').doc(questId).get();
    if (!doc.exists) return null;
    return QuestModel.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> publishQuest(String questId) async {
    await _db
        .collection('quests')
        .doc(questId)
        .update({'isPublished': true});
  }

  // ── CLUES ──────────────────────────────────────────────────────────────────

  Future<void> addClue(String questId, ClueModel clue) async {
    await _db
        .collection('quests')
        .doc(questId)
        .collection('clues')
        .doc(clue.id)
        .set(clue.toMap());
  }

  Stream<List<ClueModel>> getCluesOrdered(String questId) {
    return _db
        .collection('quests')
        .doc(questId)
        .collection('clues')
        .orderBy('orderIndex')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClueModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ── DISCOVERIES ────────────────────────────────────────────────────────────

  Future<void> saveDiscovery(DiscoveryModel discovery) async {
    await _db.collection('discoveries').add(discovery.toMap());
  }

  Stream<List<DiscoveryModel>> getUserDiscoveries(String uid) {
    return _db
        .collection('discoveries')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DiscoveryModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ── LEADERBOARD ────────────────────────────────────────────────────────────

  Future<void> updateLeaderboard(
      String uid, String displayName, int totalScore) async {
    await _db.collection('leaderboard').doc(uid).set({
      'uid': uid,
      'displayName': displayName,
      'totalScore': totalScore,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> getLeaderboard() {
    return _db
        .collection('leaderboard')
        .orderBy('totalScore', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
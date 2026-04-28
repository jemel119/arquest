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
        .snapshots()
        .map((snap) {
          final quests = snap.docs
              .map((d) => QuestModel.fromFirestore(d.data(), d.id))
              .toList();
          quests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return quests;
        });
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

  // ── COMPLETED QUESTS ───────────────────────────────────────────────────────

  // Mark a quest as completed by the current user
  Future<void> markQuestCompleted(String uid, String questId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('completedQuests')
        .doc(questId)
        .set({
      'questId': questId,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Returns a stream of quest IDs the user has completed
  Stream<List<String>> getCompletedQuestIds(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('completedQuests')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
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

  // Fetches clues without orderBy to avoid composite index requirement.
  // Sorting is done in Dart after fetching — safe since clue counts are small.
  Stream<List<ClueModel>> getCluesOrdered(String questId) {
    return _db
        .collection('quests')
        .doc(questId)
        .collection('clues')
        .snapshots()
        .map((snap) {
          final clues = snap.docs
              .map((d) => ClueModel.fromFirestore(d.data(), d.id))
              .toList();
          clues.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          return clues;
        });
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

  // ── PAGINATION ─────────────────────────────────────────────────────────────

  DocumentSnapshot? _lastDocument;

  Future<List<QuestModel>> getQuestPage() async {
    Query query = _db
        .collection('quests')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snap = await query.get();
    if (snap.docs.isNotEmpty) _lastDocument = snap.docs.last;
    return snap.docs
        .map((d) =>
            QuestModel.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  void resetPagination() {
    _lastDocument = null;
  }
}
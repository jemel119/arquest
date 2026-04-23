import 'package:flutter/material.dart';
import '../models/quest_model.dart';
import '../models/clue_model.dart';
import '../services/firestore_service.dart';

class QuestProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<QuestModel> _quests = [];
  List<ClueModel> _currentClues = [];
  QuestModel? _activeQuest;
  bool _isLoading = false;
  String? _error;

  List<QuestModel> get quests => _quests;
  List<ClueModel> get currentClues => _currentClues;
  QuestModel? get activeQuest => _activeQuest;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Start listening to published quests stream
  void listenToQuests() {
    _firestoreService.getPublishedQuests().listen(
      (quests) {
        _quests = quests;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  // Load clues for a specific quest
  void listenToClues(String questId) {
    _firestoreService.getCluesOrdered(questId).listen(
      (clues) {
        _currentClues = clues;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  // Create a new quest and return its Firestore ID
  Future<String?> createQuest(QuestModel quest) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _firestoreService.createQuest(quest);
      _error = null;
      return id;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a clue to an existing quest
  Future<void> addClue(String questId, ClueModel clue) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.addClue(questId, clue);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setActiveQuest(QuestModel quest) {
    _activeQuest = quest;
    notifyListeners();
  }

  void clearActiveQuest() {
    _activeQuest = null;
    _currentClues = [];
    notifyListeners();
  }
}
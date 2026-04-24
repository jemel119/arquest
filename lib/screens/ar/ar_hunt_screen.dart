import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/quest_model.dart';
import '../../models/clue_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/difficulty_service.dart';
import '../ar/ar_photo_screen.dart';

class ARHuntScreen extends StatefulWidget {
  final QuestModel quest;
  final List<ClueModel> clues;

  const ARHuntScreen({
    super.key,
    required this.quest,
    required this.clues,
  });

  @override
  State<ARHuntScreen> createState() => _ARHuntScreenState();
}

class _ARHuntScreenState extends State<ARHuntScreen> {
  final _locationService = LocationService();
  final _firestoreService = FirestoreService();
  final _difficultyService = DifficultyService();

  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  int _currentClueIndex = 0;
  bool _clueFound = false;
  int _missedAttempts = 0;
  int _score = 0;
  late DateTime _questStartTime;
  late DateTime _clueStartTime;

  @override
  void initState() {
    super.initState();
    _questStartTime = DateTime.now();
    _clueStartTime = DateTime.now();
    _startLocationStream();
  }

  @override
  void dispose() {
    // Always cancel the stream to prevent memory leaks
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLocationStream() {
    _positionStream = _locationService.getPositionStream().listen(
      (Position position) {
        setState(() => _currentPosition = position);
        _checkProximity(position);
      },
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS error: ${e.toString()}')),
        );
      },
    );
  }

  void _checkProximity(Position position) {
    if (_clueFound || widget.clues.isEmpty) return;
    final clue = widget.clues[_currentClueIndex];

    final isClose = _locationService.isWithinProximity(
      position.latitude,
      position.longitude,
      clue.targetLocation.latitude,
      clue.targetLocation.longitude,
      clue.proximityRadius,
    );

    if (isClose) {
      setState(() => _clueFound = true);
      _onClueDiscovered(clue);
    }
  }

  void _onClueDiscovered(ClueModel clue) {
    final cluePoints =
        (widget.quest.pointValue / widget.clues.length).round();
    setState(() => _score += cluePoints);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Clue Found!'),
        content: Text(
          'You found clue ${_currentClueIndex + 1} of ${widget.clues.length}!\n'
          '+$cluePoints points',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ARPhotoScreen(
                    quest: widget.quest,
                    clue: clue,
                    onPhotoSubmitted: _onPhotoSubmitted,
                  ),
                ),
              );
            },
            child: const Text('Take Discovery Photo'),
          ),
        ],
      ),
    );
  }

  void _onPhotoSubmitted() {
    if (_currentClueIndex + 1 >= widget.clues.length) {
      _onQuestComplete();
    } else {
      setState(() {
        _currentClueIndex++;
        _clueFound = false;
        // Reset clue timer for the next clue
        _clueStartTime = DateTime.now();
      });
    }
  }

  void _onQuestComplete() {
    _positionStream?.cancel();

    // Use the last clue's completion time for the difficulty recommendation.
    // This reflects the player's most recent skill level more accurately
    // than total quest time, which includes all previous clues.
    final lastClueTime =
        DateTime.now().difference(_clueStartTime).inSeconds;

    final recommendation = _difficultyService.recommendNextDifficulty(
      recentCompletionTimeSeconds: lastClueTime,
      missedAttempts: _missedAttempts,
      currentDifficulty: widget.quest.difficultyLevel,
    );

    final reason = _difficultyService.getRecommendationReason(
      recentCompletionTimeSeconds: lastClueTime,
      missedAttempts: _missedAttempts,
    );

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final displayName =
        FirebaseAuth.instance.currentUser!.displayName ?? 'Player';
    _firestoreService.incrementScore(uid, _score);
    _firestoreService.updateLeaderboard(uid, displayName, _score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Quest Complete!'),
        content: Text(
          'Final Score: $_score pts\n'
          'Total Time: ${DateTime.now().difference(_questStartTime).inMinutes} min\n\n'
          '$reason\n'
          'Recommended next: $recommendation difficulty',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to quest list
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _skipClue() {
    setState(() {
      _missedAttempts++;
      if (_currentClueIndex + 1 < widget.clues.length) {
        _currentClueIndex++;
        _clueFound = false;
        // Reset clue timer on skip so skipped clues don't
        // inflate the time measurement for the next clue
        _clueStartTime = DateTime.now();
      } else {
        _onQuestComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clues.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('AR Hunt')),
        body: const Center(child: Text('No clues found for this quest.')),
      );
    }

    final currentClue = widget.clues[_currentClueIndex];
    final distanceToClue = _currentPosition != null
        ? _locationService.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            currentClue.targetLocation.latitude,
            currentClue.targetLocation.longitude,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quest.title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '$_score pts',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Progress ────────────────────────────────────────
            LinearProgressIndicator(
              value: _currentClueIndex / widget.clues.length,
            ),
            const SizedBox(height: 8),
            Text(
              'Clue ${_currentClueIndex + 1} of ${widget.clues.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // ── Current Clue ────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.search, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'Current Hint',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentClue.hintText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── GPS Distance ─────────────────────────────────────
            Card(
              color: _clueFound ? Colors.green[50] : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _clueFound
                          ? Icons.check_circle
                          : Icons.location_searching,
                      color: _clueFound ? Colors.green : null,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    if (_currentPosition == null)
                      const Text('Acquiring GPS...')
                    else if (_clueFound)
                      const Text(
                        'Clue found!',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      )
                    else
                      Text(
                        distanceToClue != null
                            ? '${distanceToClue.toStringAsFixed(0)}m away'
                            : 'Calculating distance...',
                        style: const TextStyle(fontSize: 18),
                      ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── Skip Button ──────────────────────────────────────
            OutlinedButton(
              onPressed: _skipClue,
              child: const Text('Skip this clue (-1 attempt)'),
            ),
          ],
        ),
      ),
    );
  }
}
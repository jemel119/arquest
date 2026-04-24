import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/quest_model.dart';
import '../../models/clue_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';

class QuestCreateScreen extends StatefulWidget {
  const QuestCreateScreen({super.key});

  @override
  State<QuestCreateScreen> createState() => _QuestCreateScreenState();
}

class _QuestCreateScreenState extends State<QuestCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hintController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();

  String _difficultyLevel = 'medium';
  int _pointValue = 100;
  String? _questId;
  final List<ClueModel> _clues = [];
  bool _isSavingQuest = false;
  bool _isAddingClue = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  // Step 1: Save the quest document first, get back the Firestore ID
  Future<void> _saveQuest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingQuest = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // We need a center location for the quest — use current GPS
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('GPS permission required to create a quest.')),
        );
        return;
      }

      final quest = QuestModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        creatorId: uid,
        difficultyLevel: _difficultyLevel,
        totalClues: 0,
        pointValue: _pointValue,
        isPublished: false,
        createdAt: DateTime.now(),
        centerLocation:
            GeoPoint(position.latitude, position.longitude),
        radiusMeters: 500,
        tags: [],
      );

      final id = await _firestoreService.createQuest(quest);
      setState(() => _questId = id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quest saved! Now add your clues.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save quest: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSavingQuest = false);
    }
  }

  // Step 2: Capture GPS and add a clue to the quest subcollection
  Future<void> _addClue() async {
    if (_questId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save the quest first before adding clues.')),
      );
      return;
    }
    if (_hintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a hint for this clue.')),
      );
      return;
    }

    setState(() => _isAddingClue = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('GPS permission required to place a clue.')),
        );
        return;
      }

      final clue = ClueModel(
        id: const Uuid().v4(),
        questId: _questId!,
        orderIndex: _clues.length,
        hintText: _hintController.text.trim(),
        targetLocation:
            GeoPoint(position.latitude, position.longitude),
        proximityRadius: 15.0,
      );

      await _firestoreService.addClue(_questId!, clue);
      setState(() => _clues.add(clue));
      _hintController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Clue ${_clues.length} added at your current location.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add clue: ${e.toString()}')),
      );
    } finally {
      setState(() => _isAddingClue = false);
    }
  }

  // Step 3: Publish the quest so other players can see it
  Future<void> _publishQuest() async {
    if (_questId == null) return;
    if (_clues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one clue before publishing.')),
      );
      return;
    }

    try {
      await _firestoreService.publishQuest(_questId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quest published!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quest'),
        actions: [
          if (_questId != null && _clues.isNotEmpty)
            TextButton(
              onPressed: _publishQuest,
              child: const Text('Publish',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Quest Details Form ──────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Quest Title'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: (val) =>
                        val == null || val.isEmpty
                            ? 'Enter a description'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _difficultyLevel,
                    decoration:
                        const InputDecoration(labelText: 'Difficulty'),
                    items: ['easy', 'medium', 'hard']
                        .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d[0].toUpperCase() + d.substring(1))))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _difficultyLevel = val!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _pointValue.toString(),
                    decoration:
                        const InputDecoration(labelText: 'Point Value'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) =>
                        _pointValue = int.tryParse(val) ?? 100,
                  ),
                  const SizedBox(height: 16),
                  _isSavingQuest
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _questId == null ? _saveQuest : null,
                          child: Text(_questId == null
                              ? 'Save Quest'
                              : 'Quest Saved ✓'),
                        ),
                ],
              ),
            ),

            const Divider(height: 32),

            // ── Add Clues Section ───────────────────────────────
            Text(
              'Clues (${_clues.length} added)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Walk to each clue location, enter the hint, then tap Add Clue. '
              'Your current GPS position will be saved as the clue location.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hintController,
              decoration: const InputDecoration(
                labelText: 'Clue Hint',
                hintText: 'e.g. Look near the old oak tree',
              ),
            ),
            const SizedBox(height: 8),
            _isAddingClue
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _addClue,
                    icon: const Icon(Icons.add_location),
                    label: const Text('Add Clue at Current Location'),
                  ),

            // ── Clue List ───────────────────────────────────────
            if (_clues.isNotEmpty) ...[
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _clues.length,
                itemBuilder: (ctx, i) {
                  final clue = _clues[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(clue.hintText),
                    subtitle: Text(
                      'Lat: ${clue.targetLocation.latitude.toStringAsFixed(5)}, '
                      'Lng: ${clue.targetLocation.longitude.toStringAsFixed(5)}',
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
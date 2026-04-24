import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quest_model.dart';
import '../../providers/quest_provider.dart';
import '../../widgets/clue_tile.dart';
import '../../widgets/difficulty_badge.dart';
import '../ar/ar_hunt_screen.dart';

class QuestDetailScreen extends StatefulWidget {
  final QuestModel quest;

  const QuestDetailScreen({super.key, required this.quest});

  @override
  State<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends State<QuestDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load clues for this quest
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestProvider>().listenToClues(widget.quest.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final questProvider = context.watch<QuestProvider>();
    final clues = questProvider.currentClues;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quest.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Quest Header ─────────────────────────────────────
            Row(
              children: [
                DifficultyBadge(difficulty: widget.quest.difficultyLevel),
                const SizedBox(width: 8),
                Text(
                  '${widget.quest.pointValue} pts',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '${widget.quest.totalClues} clues',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Description ──────────────────────────────────────
            Text(
              widget.quest.description,
              style: const TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 16),

            // ── Tags ─────────────────────────────────────────────
            if (widget.quest.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                children: widget.quest.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),

            const Divider(height: 32),

            // ── Clues Preview ────────────────────────────────────
            Text(
              'Clues',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'You will be guided to each location during the hunt.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),

            if (questProvider.isLoading && clues.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (clues.isEmpty)
              const Text('No clues available yet.',
                  style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clues.length,
                itemBuilder: (ctx, i) => ClueTile(
                  clue: clues[i],
                  index: i,
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),

      // ── Start Quest Button ─────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: clues.isEmpty
              ? null
              : () {
                  context.read<QuestProvider>().setActiveQuest(widget.quest);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ARHuntScreen(
                        quest: widget.quest,
                        clues: clues,
                      ),
                    ),
                  ).then((_) {
                    // Clear active quest when returning
                    context.read<QuestProvider>().clearActiveQuest();
                  });
                },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Quest'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
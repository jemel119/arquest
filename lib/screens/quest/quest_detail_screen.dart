import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quest_model.dart';
import '../../providers/quest_provider.dart';
import '../../widgets/clue_tile.dart';
import '../../widgets/difficulty_badge.dart';
import '../ar/ar_hunt_screen.dart';

class QuestDetailScreen extends StatefulWidget {
  final QuestModel quest;
  final bool isCompleted;

  const QuestDetailScreen({
    super.key,
    required this.quest,
    this.isCompleted = false,
  });

  @override
  State<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends State<QuestDetailScreen> {
  @override
  void initState() {
    super.initState();
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
            // ── Completed Banner ─────────────────────────────────
            if (widget.isCompleted)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'You have already completed this quest.',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

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

            // ── Clues ────────────────────────────────────────────
            Text(
              'Clues',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              widget.isCompleted
                  ? 'All clues found!'
                  : 'You will be guided to each location during the hunt.',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                  isFound: widget.isCompleted,
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),

      // ── Bottom Button ─────────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.isCompleted
            ? ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Quests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            : ElevatedButton.icon(
                onPressed: clues.isEmpty
                    ? null
                    : () {
                        context
                            .read<QuestProvider>()
                            .setActiveQuest(widget.quest);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ARHuntScreen(
                              quest: widget.quest,
                              clues: clues,
                            ),
                          ),
                        ).then((_) {
                          context
                              .read<QuestProvider>()
                              .clearActiveQuest();
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
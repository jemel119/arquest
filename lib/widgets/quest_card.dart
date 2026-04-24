import 'package:flutter/material.dart';
import '../models/quest_model.dart';
import 'difficulty_badge.dart';

class QuestCard extends StatelessWidget {
  final QuestModel quest;
  final VoidCallback onTap;

  const QuestCard({
    super.key,
    required this.quest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title Row ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quest.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  DifficultyBadge(difficulty: quest.difficultyLevel),
                ],
              ),

              const SizedBox(height: 8),

              // ── Description ────────────────────────────────────
              Text(
                quest.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 12),

              // ── Footer ─────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${quest.totalClues} clues',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  const Icon(Icons.star, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${quest.pointValue} pts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),

              // ── Tags ───────────────────────────────────────────
              if (quest.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: quest.tags
                      .take(3)
                      .map((tag) => Chip(
                            label: Text(tag,
                                style: const TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
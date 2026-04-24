import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quest_provider.dart';
import '../../widgets/quest_card.dart';
import 'quest_detail_screen.dart';

class QuestListScreen extends StatefulWidget {
  const QuestListScreen({super.key});

  @override
  State<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends State<QuestListScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening to published quests from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestProvider>().listenToQuests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final questProvider = context.watch<QuestProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ARQuest'),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          if (questProvider.isLoading && questProvider.quests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (questProvider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Error: ${questProvider.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<QuestProvider>().listenToQuests(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (questProvider.quests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No quests yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap + to create the first one!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<QuestProvider>().listenToQuests(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: questProvider.quests.length,
              itemBuilder: (ctx, i) {
                final quest = questProvider.quests[i];
                return QuestCard(
                  quest: quest,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestDetailScreen(quest: quest),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
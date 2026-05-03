import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/quest_provider.dart';
import '../../widgets/quest_card.dart';
import '../../services/firestore_service.dart';
import 'quest_detail_screen.dart';

class QuestListScreen extends StatefulWidget {
  const QuestListScreen({super.key});

  @override
  State<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends State<QuestListScreen> {
  final _firestoreService = FirestoreService();
  List<String> _completedQuestIds = [];
  bool _completedLoaded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestProvider>().listenToQuests();
    });
    _listenToCompletedQuests();
  }

  void _listenToCompletedQuests() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _completedLoaded = true);
      return;
    }
    _firestoreService.getCompletedQuestIds(uid).listen(
      (ids) {
        if (mounted) {
          setState(() {
            _completedQuestIds = ids;
            _completedLoaded = true;
          });
        }
      },
      onError: (_) {
        // If stream errors unblock taps so app never freezes
        if (mounted) setState(() => _completedLoaded = true);
      },
    );
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
                final isCompleted =
                    _completedQuestIds.contains(quest.id);

                return Stack(
                  children: [
                    QuestCard(
                      quest: quest,
                      isCompleted: isCompleted,
                      onTap: !_completedLoaded
                          ? () {}
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuestDetailScreen(
                                    quest: quest,
                                    isCompleted: isCompleted,
                                  ),
                                ),
                              ),
                    ),
                    if (isCompleted)
                      Positioned(
                        top: 12,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Completed',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
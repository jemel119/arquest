import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading leaderboard: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No scores yet. Complete a quest to appear here!'),
            );
          }

          final entries = snapshot.data!;
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (ctx, i) {
              final entry = entries[i];
              final isTopThree = i < 3;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _medalColor(i),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: isTopThree ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  entry['displayName'] ?? 'Player',
                  style: TextStyle(
                    fontWeight:
                        isTopThree ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Text(
                  '${entry['totalScore'] ?? 0} pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _medalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;      // Gold
      case 1:
        return Colors.grey;       // Silver
      case 2:
        return Colors.brown;      // Bronze
      default:
        return Colors.blueGrey;
    }
  }
}
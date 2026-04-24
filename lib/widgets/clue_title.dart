import 'package:flutter/material.dart';
import '../models/clue_model.dart';

class ClueTile extends StatelessWidget {
  final ClueModel clue;
  final int index;
  final bool isFound;

  const ClueTile({
    super.key,
    required this.clue,
    required this.index,
    this.isFound = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isFound ? Colors.green : Colors.grey[300],
        child: isFound
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                '${index + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black),
              ),
      ),
      title: Text(
        isFound ? clue.hintText : 'Clue ${index + 1}',
        style: TextStyle(
          color: isFound ? Colors.grey : null,
          decoration: isFound ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: isFound
          ? const Text('Found!',
              style: TextStyle(color: Colors.green, fontSize: 12))
          : Text(
              '${clue.proximityRadius.toInt()}m proximity radius',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
      trailing: isFound
          ? const Icon(Icons.emoji_events, color: Colors.orange)
          : const Icon(Icons.lock_outline, color: Colors.grey),
    );
  }
}
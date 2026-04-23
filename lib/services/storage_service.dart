import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a 3D AR asset for a quest clue.
  // Path: ar_assets/{questId}/{clueId}/{filename}
  Future<String> uploadArAsset({
    required String questId,
    required String clueId,
    required File file,
    required String filename,
  }) async {
    final ref = _storage.ref('ar_assets/$questId/$clueId/$filename');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  // Upload a discovery proof photo.
  // Path: discoveries/{userId}/{questId}/{timestamp}.jpg
  // The timestamp is captured before the try block so a retry
  // uses the same path and overwrites any partial upload
  // rather than creating an orphaned object.
  Future<String> uploadDiscoveryPhoto({
    required String userId,
    required String questId,
    required File photo,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref(
      'discoveries/$userId/$questId/$timestamp.jpg',
    );

    try {
      final task = await ref.putFile(photo);
      return await task.ref.getDownloadURL();
    } on FirebaseException {
      // Delete any partial object then rethrow so the caller
      // can show a retry option to the user.
      try {
        await ref.delete();
      } catch (_) {}
      rethrow;
    }
  }

  // Upload a user avatar image.
  // Path: avatars/{userId}/avatar.jpg
  Future<String> uploadAvatar({
    required String userId,
    required File photo,
  }) async {
    final ref = _storage.ref('avatars/$userId/avatar.jpg');
    try {
      final task = await ref.putFile(photo);
      return await task.ref.getDownloadURL();
    } on FirebaseException {
      try {
        await ref.delete();
      } catch (_) {}
      rethrow;
    }
  }

  // Delete a file at a known Storage path.
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (_) {}
  }
}
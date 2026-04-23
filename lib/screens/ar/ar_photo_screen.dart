import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/quest_model.dart';
import '../../models/clue_model.dart';
import '../../models/discovery_model.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import 'package:uuid/uuid.dart';

class ARPhotoScreen extends StatefulWidget {
  final QuestModel quest;
  final ClueModel clue;
  final VoidCallback onPhotoSubmitted;

  const ARPhotoScreen({
    super.key,
    required this.quest,
    required this.clue,
    required this.onPhotoSubmitted,
  });

  @override
  State<ARPhotoScreen> createState() => _ARPhotoScreenState();
}

class _ARPhotoScreenState extends State<ARPhotoScreen> {
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();

  File? _selectedPhoto;
  bool _isUploading = false;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75, // compress to reduce upload size
    );
    if (xfile == null) return;
    setState(() => _selectedPhoto = File(xfile.path));
  }

  Future<void> _submitPhoto() async {
    if (_selectedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Take a photo first.')),
      );
      return;
    }

    // Get GPS position at the moment of submission
    final position = await _locationService.getCurrentPosition();
    if (position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('GPS required for discovery proof. Please enable location.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Upload photo to Firebase Storage
      final photoUrl = await _storageService.uploadDiscoveryPhoto(
        userId: uid,
        questId: widget.quest.id,
        photo: _selectedPhoto!,
      );

      // 2. Write proof metadata to Firestore discoveries collection
      final discovery = DiscoveryModel(
        id: const Uuid().v4(),
        userId: uid,
        questId: widget.quest.id,
        clueId: widget.clue.id,
        assetId: widget.clue.assetId,
        photoUrl: photoUrl,
        captureLocation: GeoPoint(position.latitude, position.longitude),
        timestamp: DateTime.now(),
      );
      await _firestoreService.saveDiscovery(discovery);

      if (!mounted) return;

      // 3. Notify parent screen to advance to the next clue
      widget.onPhotoSubmitted();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed. Please retry. ${e.toString()}'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _submitPhoto,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discovery Photo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Clue Info ────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, size: 36, color: Colors.orange),
                    const SizedBox(height: 8),
                    const Text(
                      'You found it!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.clue.hintText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Photo Preview ────────────────────────────────────
            Expanded(
              child: _selectedPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedPhoto!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No photo taken yet',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // ── Buttons ──────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(
                  _selectedPhoto == null ? 'Take Photo' : 'Retake Photo'),
            ),
            const SizedBox(height: 8),
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _selectedPhoto != null ? _submitPhoto : null,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Submit Discovery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../models/quest_model.dart';
import '../../models/clue_model.dart';
import '../../models/discovery_model.dart';
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
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();

  XFile? _selectedPhoto;
  bool _isUploading = false;

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      imageQuality: 75,
    );
    if (xfile == null) return;
    setState(() => _selectedPhoto = xfile);
  }

  Future<void> _submitPhoto() async {
    if (_selectedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a photo first.')),
      );
      return;
    }

    final position = await _locationService.getCurrentPosition();
    if (position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS required for discovery proof.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Use bytes instead of File — works on both web and Android
      final bytes = await _selectedPhoto!.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance.ref(
        'discoveries/$uid/${widget.quest.id}/$timestamp.jpg',
      );

      await ref.putData(bytes);
      final photoUrl = await ref.getDownloadURL();

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
            // ── Clue Info ─────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events,
                        size: 36, color: Colors.orange),
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

            // ── Photo Preview ─────────────────────────────────────
            Expanded(
              child: _selectedPhoto != null
                  ? FutureBuilder<Uint8List>(
                      future: _selectedPhoto!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        return const Center(
                            child: CircularProgressIndicator());
                      },
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
                            Text('No photo selected yet',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // ── Camera / Gallery Buttons ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Submit Button ─────────────────────────────────────
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed:
                        _selectedPhoto != null ? _submitPhoto : null,
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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();

  String _gender = 'Woman';
  File? _photoFile;
  bool _isSaving = false;
  bool _photoMissing = false;
  String? _errorText;

  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _photoFile = File(picked.path);
        _photoMissing = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final formValid = _formKey.currentState!.validate();
    final hasPhoto = _photoFile != null;
    if (!hasPhoto) setState(() => _photoMissing = true);
    if (!formValid || !hasPhoto) return;

    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final photoUrl = await _storageService.uploadProfilePhoto(uid, _photoFile!);

      final user = AppUser(
        uid: uid,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        bio: _bioController.text.trim(),
        photoUrl: photoUrl,
      );
      await _firestoreService.saveProfile(user);
      // Navigation is handled by the auth/profile listener in main.dart.
    } catch (e) {
      setState(() => _errorText = 'Could not save your profile. Try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(_photoMissing ? 3 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: _photoMissing
                                ? Border.all(color: AppColors.nope, width: 2)
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.surface,
                            backgroundImage: _photoFile != null
                                ? FileImage(_photoFile!)
                                : null,
                            child: _photoFile == null
                                ? const Icon(Icons.camera_alt_outlined,
                                    size: 36, color: Colors.grey)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _photoMissing
                        ? 'Add a profile photo to continue'
                        : 'Add a profile photo — people should know who they\'re matching with',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _photoMissing ? AppColors.nope : Colors.grey,
                      fontSize: 13,
                      fontWeight: _photoMissing ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'First name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Age'),
                  validator: (value) {
                    final age = int.tryParse(value?.trim() ?? '');
                    if (age == null || age < 18 || age > 100) {
                      return 'Enter a valid age (18+)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'Woman', child: Text('Woman')),
                    DropdownMenuItem(value: 'Man', child: Text('Man')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _gender = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    hintText: 'A little about you (optional)',
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Start Swiping'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser myProfile;

  const ProfileScreen({super.key, required this.myProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;
  late String _gender;
  File? _newPhotoFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.myProfile.name);
    _ageController = TextEditingController(text: widget.myProfile.age.toString());
    _bioController = TextEditingController(text: widget.myProfile.bio);
    _gender = widget.myProfile.gender.isNotEmpty ? widget.myProfile.gender : 'Woman';
  }

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
      setState(() => _newPhotoFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      String photoUrl = widget.myProfile.photoUrl;
      if (_newPhotoFile != null) {
        photoUrl = await _storageService.uploadProfilePhoto(
          widget.myProfile.uid,
          _newPhotoFile!,
        );
      }
      final age = int.tryParse(_ageController.text.trim()) ?? widget.myProfile.age;
      final updated = AppUser(
        uid: widget.myProfile.uid,
        name: _nameController.text.trim(),
        age: age,
        gender: _gender,
        bio: _bioController.text.trim(),
        photoUrl: photoUrl,
      );
      await _firestoreService.saveProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.surface,
                        backgroundImage: _newPhotoFile != null
                            ? FileImage(_newPhotoFile!)
                            : (widget.myProfile.photoUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    widget.myProfile.photoUrl,
                                  ) as ImageProvider
                                : null),
                        child: _newPhotoFile == null &&
                                widget.myProfile.photoUrl.isEmpty
                            ? const Icon(Icons.person,
                                size: 48, color: Colors.grey)
                            : null,
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
                          child: const Icon(Icons.edit,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'First name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Age'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _gender,
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
              TextField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(hintText: 'About you'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

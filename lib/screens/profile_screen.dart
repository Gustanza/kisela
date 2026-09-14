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
    _ageController = TextEditingController(
      text: widget.myProfile.age.toString(),
    );
    _bioController = TextEditingController(text: widget.myProfile.bio);
    _gender = widget.myProfile.gender.isNotEmpty
        ? widget.myProfile.gender
        : 'Woman';
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
      final age =
          int.tryParse(_ageController.text.trim()) ?? widget.myProfile.age;
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated')));
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
      backgroundColor: AppColors.surface,
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhotoPreview(),
              const SizedBox(height: 28),
              _buildFormCard(),
              const SizedBox(height: 24),
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

  Widget _buildPhotoPreview() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 360,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _newPhotoFile != null
                  ? Image.file(_newPhotoFile!, fit: BoxFit.cover)
                  : (widget.myProfile.photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.myProfile.photoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => _emptyPhoto(),
                          )
                        : _emptyPhoto()),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _nameController,
                      _ageController,
                    ]),
                    builder: (context, _) {
                      final name = _nameController.text.trim().isEmpty
                          ? 'Your name'
                          : _nameController.text.trim();
                      final age = _ageController.text.trim();
                      return Text(
                        age.isEmpty ? name : '$name, $age',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Material(
                  shape: const CircleBorder(),
                  color: Colors.black45,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _pickPhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyPhoto() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.person, size: 84, color: Colors.white),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Basic Info'),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'First name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Woman', child: Text('Woman')),
                    DropdownMenuItem(value: 'Man', child: Text('Man')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _gender = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionLabel('About'),
          const SizedBox(height: 12),
          TextField(
            controller: _bioController,
            maxLines: 3,
            maxLength: 150,
            decoration: const InputDecoration(
              labelText: 'About you',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey[500],
        letterSpacing: 0.8,
      ),
    );
  }
}

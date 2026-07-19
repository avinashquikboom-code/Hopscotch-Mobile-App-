import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/api/auth_api.dart';
import 'package:hopscotch/widgets/toast_notification.dart';
import 'package:hopscotch/repositories/profile_repository.dart';
import 'package:hopscotch/constants/app_urls.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;
  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    
    // Read the current profile state to populate text fields immediately
    final profile = ref.read(profileNotifierProvider);
    _firstNameController = TextEditingController(text: profile?['firstName']?.toString() ?? '');
    _lastNameController = TextEditingController(text: profile?['lastName']?.toString() ?? '');
    _emailController = TextEditingController(text: profile?['email']?.toString() ?? '');
    _phoneController = TextEditingController(text: profile?['phone']?.toString() ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image from gallery');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image from camera');
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ToastNotification.show(
      context,
      message: message,
      isError: true,
    );
  }

  void _showSuccess(String message) {
    ToastNotification.show(
      context,
      message: message,
      isError: false,
    );
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final apiService = ApiService();
      final authApi = AuthApi(apiService);
      
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      
      final response = await authApi.updateProfile(
        firstName: firstName,
        lastName: lastName.isEmpty ? null : lastName,
        phone: _phoneController.text.trim(),
        avatar: _profileImage,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh the profile notifier immediately so other screens update their UI
        await ref.read(profileNotifierProvider.notifier).refreshProfile();
        
        _showSuccess('Profile updated successfully');
        if (mounted) {
          context.pop();
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _showError('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final userProfile = ref.watch(profileNotifierProvider);

    // Safely listen for profile data updates to populate fields without interrupting the build phase
    ref.listen<Map<String, dynamic>?>(profileNotifierProvider, (previous, next) {
      if (next != null) {
        if (_firstNameController.text.isEmpty && next['firstName'] != null) {
          _firstNameController.text = next['firstName'].toString();
        }
        if (_lastNameController.text.isEmpty && next['lastName'] != null) {
          _lastNameController.text = next['lastName'].toString();
        }
        if (_emailController.text.isEmpty && next['email'] != null) {
          _emailController.text = next['email'].toString();
        }
        if (_phoneController.text.isEmpty && next['phone'] != null) {
          _phoneController.text = next['phone'].toString();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EDIT PROFILE',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: responsive.iconSize(24)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Selection
              GestureDetector(
                onTap: _showImagePickerBottomSheet,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: responsive.iconSize(54),
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.08,
                      ),
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!) as ImageProvider
                          : () {
                              final rawUrl = userProfile?['avatarUrl']?.toString();
                              final resolvedUrl = (rawUrl != null && rawUrl.isNotEmpty)
                                  ? AppUrls.resolveUrl(rawUrl)
                                  : null;
                              return resolvedUrl != null ? NetworkImage(resolvedUrl) : null;
                            }(),
                      onBackgroundImageError: (_profileImage != null ||
                              (userProfile?['avatarUrl'] != null &&
                                  userProfile!['avatarUrl'].toString().isNotEmpty))
                          ? (exception, stackTrace) {}
                          : null,
                      child: (_profileImage == null &&
                              (userProfile?['avatarUrl'] == null ||
                                  userProfile!['avatarUrl'].toString().isEmpty))
                          ? Text(
                              (() {
                                final firstName = userProfile?['firstName']?.toString() ?? '';
                                final name = userProfile?['name']?.toString() ?? 'U';
                                return (firstName.isNotEmpty ? firstName : name)
                                    .substring(0, 1)
                                    .toUpperCase();
                              })(),
                              style: TextStyle(
                                fontSize: responsive.fontSize32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(responsive.spacing(6)),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: responsive.iconSize(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

              // Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          size: responsive.iconSize(20),
                        ),
                        labelStyle: TextStyle(fontSize: responsive.fontSize14),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'First name is required'
                          : null,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          size: responsive.iconSize(20),
                        ),
                        labelStyle: TextStyle(fontSize: responsive.fontSize14),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Last name is required'
                          : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceL)),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(fontSize: responsive.fontSize14),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: responsive.iconSize(20),
                  ),
                  labelStyle: TextStyle(fontSize: responsive.fontSize14),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Email is required'
                    : null,
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceL)),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: responsive.fontSize14),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    size: responsive.iconSize(20),
                  ),
                  labelStyle: TextStyle(fontSize: responsive.fontSize14),
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: responsive.spacing(56),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSaveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.textDisabledColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                  ),
                  child: _isSaving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: responsive.spacing(AppTheme.spaceS)),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                fontSize: responsive.fontSize14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'SAVE PROFILE CHANGES',
                          style: TextStyle(
                            fontSize: responsive.fontSize14,
                            fontWeight: FontWeight.w600,
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
}

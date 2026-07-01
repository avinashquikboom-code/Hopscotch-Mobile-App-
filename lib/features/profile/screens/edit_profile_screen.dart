import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_text.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../core/widgets/custom_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _zipController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _zipController = TextEditingController(text: user?.zipCode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = ref.read(authNotifierProvider);
      if (currentUser != null) {
        final updated = currentUser.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          zipCode: _zipController.text.trim(),
        );

        await ref.read(authNotifierProvider.notifier).updateProfile(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Aura Couture profile successfully updated! ✨',
                style: TextStyle(fontSize: context.responsive.fontSize14),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: $e',
              style: TextStyle(fontSize: context.responsive.fontSize14),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
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
    final user = ref.watch(authNotifierProvider);
    final responsive = context.responsive;

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
            } else {
              context.go('/profile');
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
              Stack(
                children: [
                  CircleAvatar(
                    radius: responsive.iconSize(54),
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.08,
                    ),
                    backgroundImage:
                        user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                        ? Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'U',
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
              SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

              // Fields
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(fontSize: responsive.fontSize14),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    size: responsive.iconSize(20),
                  ),
                  labelStyle: TextStyle(fontSize: responsive.fontSize14),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceL)),
              TextFormField(
                controller: _emailController,
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
              SizedBox(height: responsive.spacing(AppTheme.spaceL)),
              TextFormField(
                controller: _addressController,
                style: TextStyle(fontSize: responsive.fontSize14),
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  prefixIcon: Icon(
                    Icons.home_outlined,
                    size: responsive.iconSize(20),
                  ),
                  labelStyle: TextStyle(fontSize: responsive.fontSize14),
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceL)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(
                          Icons.location_city_outlined,
                          size: responsive.iconSize(20),
                        ),
                        labelStyle: TextStyle(fontSize: responsive.fontSize14),
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(AppTheme.spaceL)),
                  Expanded(
                    child: TextFormField(
                      controller: _zipController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'ZIP Code',
                        prefixIcon: Icon(
                          Icons.pin_drop_outlined,
                          size: responsive.iconSize(20),
                        ),
                        labelStyle: TextStyle(fontSize: responsive.fontSize14),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: responsive.spacing(56),
                child: CustomButton(
                  text: 'SAVE PROFILE CHANGES',
                  onPressed: _handleSaveProfile,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

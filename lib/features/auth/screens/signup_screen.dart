import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/toast_notification.dart';
import '../../../core/utils/responsive_text.dart';
import '../../../core/utils/dev_logger.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/api/api_service.dart';
import '../../../l10n/app_localizations.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      _showError('Failed to capture image from camera');
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: AppTheme.errorColor),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
    if (name.isEmpty) {
      _showError('Please enter your name');
      return;
    }
    
    if (email.isEmpty) {
      _showError('Please enter email');
      return;
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Please enter a valid email');
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('Please enter phone number');
      return;
    }

    if (phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter password');
      return;
    }
    
    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    
    if (confirmPassword.isEmpty) {
      _showError('Please confirm password');
      return;
    }
    
    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final authApi = AuthApi(apiService);
      
      final response = await authApi.register(
        firstName: name,
        lastName: '',
        email: email,
        password: password,
        phone: phone,
        profileImage: _profileImage,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          _showSuccess('Account created successfully');
          context.pop();
        }
      } else if (response.statusCode == 409) {
        _showError('Email already registered. Please login');
      } else if (response.statusCode == 400) {
        final errorMessage = response.data['message'] ?? 'Invalid input data';
        _showError(errorMessage);
      } else if (response.statusCode == 429) {
        _showError('Too many attempts. Please try again later');
      } else {
        final errorMessage = response.data['message'] ?? 'Signup failed';
        _showError(errorMessage);
      }
    } on DioException catch (e) {
      DevLogger.logError(e.toString(), context: 'Signup DioError');
      if (e.type == DioExceptionType.connectionTimeout) {
        _showError('Connection timeout. Please check your internet');
      } else if (e.type == DioExceptionType.connectionError) {
        _showError('No internet connection');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        _showError('Server not responding. Please try again');
      } else if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 409) {
          _showError('Email already registered. Please login');
        } else if (statusCode == 400) {
          final errorMessage = e.response?.data['message'] ?? 'Invalid input data';
          _showError(errorMessage);
        } else if (statusCode == 500) {
          _showError('Server error. Please try again later');
        } else {
          final errorMessage = e.response?.data['message'] ?? 'Signup failed';
          _showError(errorMessage);
        }
      } else {
        _showError('An unexpected error occurred');
      }
    } catch (e) {
      DevLogger.logError(e.toString(), context: 'Signup General');
      _showError('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ToastNotification.show(
        context,
        message: message,
        isError: true,
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ToastNotification.show(
        context,
        message: message,
        isError: false,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(AppTheme.spaceXL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
              // Header
              Icon(
                Icons.person_add_rounded,
                size: responsive.iconSize(56),
                color: AppTheme.primaryColor,
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceL)),
              Text(
                'Create Account',
                style: responsive.headline4.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceS)),
              Text(
                'Fill in your details to get started',
                style: responsive.bodyMedium.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // Profile Image
                Center(
                  child: AnimatedScale(
                    scale: _profileImage != null ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _showImagePickerBottomSheet,
                      child: Container(
                        width: responsive.spacing(90),
                        height: responsive.spacing(90),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                              AppTheme.primaryColor.withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: _profileImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _profileImage!,
                                  fit: BoxFit.cover,
                                  width: responsive.spacing(90),
                                  height: responsive.spacing(90),
                                ),
                              )
                            : Icon(
                                Icons.add_a_photo_rounded,
                                size: responsive.iconSize(32),
                                color: AppTheme.primaryColor,
                              ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                // Name
                TextField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    hintStyle: TextStyle(
                      color: AppTheme.textDisabledColor,
                      fontSize: responsive.fontSize14,
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: AppTheme.primaryColor,
                      size: responsive.iconSize(20),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(AppTheme.spaceL),
                      vertical: responsive.spacing(AppTheme.spaceM),
                    ),
                  ),
                ),
                                SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: TextStyle(
                      color: AppTheme.textDisabledColor,
                      fontSize: responsive.fontSize14,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppTheme.primaryColor,
                      size: responsive.iconSize(20),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(AppTheme.spaceL),
                      vertical: responsive.spacing(AppTheme.spaceM),
                    ),
                  ),
                ),
                                SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                // Phone
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Phone Number (e.g., 9876543210)',
                    hintStyle: TextStyle(
                      color: AppTheme.textDisabledColor,
                      fontSize: responsive.fontSize14,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppTheme.primaryColor,
                      size: responsive.iconSize(20),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: BorderSide(
                        color: AppTheme.borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: BorderSide(
                        color: AppTheme.borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(AppTheme.spaceL),
                      vertical: responsive.spacing(AppTheme.spaceM),
                    ),
                  ),
                ),
                                SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(
                      color: AppTheme.textDisabledColor,
                      fontSize: responsive.fontSize14,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: AppTheme.primaryColor,
                      size: responsive.iconSize(20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.textSecondaryColor,
                        size: responsive.iconSize(20),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(AppTheme.spaceL),
                      vertical: responsive.spacing(AppTheme.spaceM),
                    ),
                  ),
                ),
                                SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                // Confirm Password
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: TextStyle(
                      color: AppTheme.textDisabledColor,
                      fontSize: responsive.fontSize14,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: AppTheme.primaryColor,
                      size: responsive.iconSize(20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.textSecondaryColor,
                        size: responsive.iconSize(20),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(AppTheme.spaceL),
                      vertical: responsive.spacing(AppTheme.spaceM),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: responsive.spacing(48),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.textDisabledColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: responsive.spacing(AppTheme.spaceS)),
                              Text(
                                'Creating Account...',
                                style: TextStyle(
                                  fontSize: responsive.fontSize14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: responsive.fontSize14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                // Navigation to Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: responsive.bodyMedium.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Sign In',
                        style: responsive.label.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}

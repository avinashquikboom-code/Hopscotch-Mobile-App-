import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/widgets/custom_button.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/utils/dev_logger.dart';
import 'package:hopscotch/utils/error_handler.dart';
import 'package:hopscotch/api/auth_api.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/widgets/toast_notification.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
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
    _firstNameController.dispose();
    _lastNameController.dispose();
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

  Future<void> _signup() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
    if (firstName.isEmpty) {
      _showError('Please enter your first name');
      return;
    }
    
    if (lastName.isEmpty) {
      _showError('Please enter your last name');
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

    if (phone.isEmpty) {
      _showError('Please enter phone number');
      return;
    }
    
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone)) {
      _showError('Please enter a valid phone number (10+ digits)');
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
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
        profileImage: _profileImage,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ToastNotification.show(
            context,
            message: 'Account created successfully',
            isError: false,
          );
          context.pop();
        }
      } else {
        throw Exception('Signup failed');
      }
    } catch (e) {
      DevLogger.logError(e.toString(), context: 'Signup');
      if (mounted) {
        final errorMessage = ErrorHandler.getErrorMessage(e);
        _showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(AppTheme.spaceXL),
              vertical: responsive.spacing(AppTheme.spaceL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 // Profile Photo Picker
                 Center(
                   child: GestureDetector(
                     onTap: _showImagePickerBottomSheet,
                     child: Stack(
                       children: [
                         Container(
                           padding: EdgeInsets.all(responsive.spacing(4)),
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             border: Border.all(
                               color: AppTheme.primaryColor,
                               width: 2,
                             ),
                           ),
                           child: CircleAvatar(
                             radius: responsive.iconSize(54),
                             backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                             backgroundImage: _profileImage != null
                                 ? FileImage(_profileImage!)
                                 : null,
                             child: _profileImage == null
                                 ? Icon(
                                     Icons.person_add_alt_1_rounded,
                                     size: responsive.iconSize(44),
                                     color: AppTheme.primaryColor,
                                   )
                                 : null,
                           ),
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
                               Icons.camera_alt_rounded,
                               color: Colors.white,
                               size: responsive.iconSize(16),
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
                 SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                 // Greeting
                 Center(
                   child: Text(
                     'Create Account',
                     style: responsive.headline4.copyWith(
                       color: colorScheme.onSurface,
                     ),
                   ),
                 ),
                 SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                 Center(
                   child: Text(
                     'Sign up to get started',
                     style: responsive.bodyMedium.copyWith(
                       color: colorScheme.onSurface.withValues(alpha: 0.6),
                     ),
                     textAlign: TextAlign.center,
                   ),
                 ),
                 SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                 // First Name & Last Name
                 Row(
                   children: [
                     Expanded(
                       child: TextField(
                         controller: _firstNameController,
                         keyboardType: TextInputType.name,
                         style: TextStyle(
                           color: colorScheme.onSurface,
                           fontSize: responsive.fontSize14,
                         ),
                         decoration: InputDecoration(
                           hintText: 'First name',
                           hintStyle: TextStyle(
                             color: colorScheme.onSurface.withValues(alpha: 0.4),
                             fontSize: responsive.fontSize14,
                           ),
                           labelText: 'First Name',
                           labelStyle: TextStyle(
                             color: colorScheme.primary,
                             fontSize: responsive.fontSize14,
                           ),
                           prefixIcon: Icon(
                             Icons.person_outline_rounded,
                             color: colorScheme.primary,
                             size: responsive.iconSize(20),
                           ),
                           filled: true,
                           fillColor: colorScheme.surface,
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(AppTheme.radiusM),
                             borderSide: BorderSide.none,
                           ),
                           focusedBorder: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(AppTheme.radiusM),
                             borderSide: BorderSide(
                               color: colorScheme.primary,
                               width: 2,
                             ),
                           ),
                           contentPadding: EdgeInsets.symmetric(
                             horizontal: responsive.spacing(AppTheme.spaceM),
                             vertical: responsive.spacing(AppTheme.spaceM),
                           ),
                         ),
                       ),
                     ),
                     SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                     Expanded(
                       child: TextField(
                         controller: _lastNameController,
                         keyboardType: TextInputType.name,
                         style: TextStyle(
                           color: colorScheme.onSurface,
                           fontSize: responsive.fontSize14,
                         ),
                         decoration: InputDecoration(
                           hintText: 'Last name',
                           hintStyle: TextStyle(
                             color: colorScheme.onSurface.withValues(alpha: 0.4),
                             fontSize: responsive.fontSize14,
                           ),
                           labelText: 'Last Name',
                           labelStyle: TextStyle(
                             color: colorScheme.primary,
                             fontSize: responsive.fontSize14,
                           ),
                           prefixIcon: Icon(
                             Icons.person_outline_rounded,
                             color: colorScheme.primary,
                             size: responsive.iconSize(20),
                           ),
                           filled: true,
                           fillColor: colorScheme.surface,
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(AppTheme.radiusM),
                             borderSide: BorderSide.none,
                           ),
                           focusedBorder: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(AppTheme.radiusM),
                             borderSide: BorderSide(
                               color: colorScheme.primary,
                               width: 2,
                             ),
                           ),
                           contentPadding: EdgeInsets.symmetric(
                             horizontal: responsive.spacing(AppTheme.spaceM),
                             vertical: responsive.spacing(AppTheme.spaceM),
                           ),
                         ),
                       ),
                     ),
                   ],
                 ),
                 SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter email',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: responsive.fontSize14,
                    ),
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: colorScheme.primary,
                      fontSize: responsive.fontSize14,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: colorScheme.primary,
                      size: responsive.iconSize(20),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(AppTheme.spaceL),
                      vertical: responsive.spacing(AppTheme.spaceM),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // Phone Number
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: responsive.fontSize14,
                    ),
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(
                      color: colorScheme.primary,
                      fontSize: responsive.fontSize14,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: colorScheme.primary,
                      size: responsive.iconSize(20),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(AppTheme.spaceL),
                      vertical: responsive.spacing(AppTheme.spaceM),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: responsive.fontSize14,
                    ),
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: colorScheme.primary,
                      fontSize: responsive.fontSize14,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: colorScheme.primary,
                      size: responsive.iconSize(20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: colorScheme.primary,
                        size: responsive.iconSize(20),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(AppTheme.spaceL),
                      vertical: responsive.spacing(AppTheme.spaceM),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // Confirm Password
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: responsive.fontSize14,
                    ),
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(
                      color: colorScheme.primary,
                      fontSize: responsive.fontSize14,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: colorScheme.primary,
                      size: responsive.iconSize(20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: colorScheme.primary,
                        size: responsive.iconSize(20),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
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
                  child: CustomButton(
                    text: 'Sign Up',
                    onPressed: _signup,
                    isLoading: _isLoading,
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
      ),
    );
  }
}

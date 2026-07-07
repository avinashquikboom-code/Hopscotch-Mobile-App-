import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/responsive_text.dart';
import '../../../core/utils/dev_logger.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/api/api_service.dart';
import '../../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty) {
      _showError('Please enter email');
      return;
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Please enter a valid email');
      return;
    }
    
    if (password.isEmpty) {
      _showError('Please enter password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final authApi = AuthApi(apiService);
      
      final response = await authApi.login(
        email: email,
        password: password,
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          _showSuccess('Login successful');
          context.go('/');
        }
      } else if (response.statusCode == 401) {
        _showError('Invalid email or password');
      } else if (response.statusCode == 404) {
        _showError('User not found. Please sign up first');
      } else if (response.statusCode == 429) {
        _showError('Too many attempts. Please try again later');
      } else {
        final errorMessage = response.data['message'] ?? 'Login failed';
        _showError(errorMessage);
      }
    } on DioException catch (e) {
      DevLogger.logError(e.toString(), context: 'Login DioError');
      if (e.type == DioExceptionType.connectionTimeout) {
        _showError('Connection timeout. Please check your internet');
      } else if (e.type == DioExceptionType.connectionError) {
        _showError('No internet connection');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        _showError('Server not responding. Please try again');
      } else if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          _showError('Invalid email or password');
        } else if (statusCode == 404) {
          _showError('User not found. Please sign up first');
        } else if (statusCode == 500) {
          _showError('Server error. Please try again later');
        } else {
          final errorMessage = e.response?.data['message'] ?? 'Login failed';
          _showError(errorMessage);
        }
      } else {
        _showError('An unexpected error occurred');
      }
    } catch (e) {
      DevLogger.logError(e.toString(), context: 'Login General');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
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
          child: Container(
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(AppTheme.spaceXL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Header logo or icon
                Center(
                  child: Container(
                    padding: EdgeInsets.all(
                      responsive.spacing(AppTheme.spaceXL),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                          AppTheme.primaryColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.primaryColor,
                      size: responsive.iconSize(48),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                // Greeting
                Center(
                  child: Text(
                    l10n.welcomeBack,
                    style: responsive.headline4.copyWith(
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                Center(
                  child: Text(
                    l10n.signInDescription,
                    style: responsive.bodyMedium.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter email',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
                      fontSize: responsive.fontSize14,
                    ),
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: AppTheme.primaryColor,
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
                      fontSize: responsive.fontSize14,
                    ),
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: AppTheme.primaryColor,
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
                        color: AppTheme.primaryColor,
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
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

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      context.push('/forgot-password');
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: responsive.fontSize14,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: responsive.spacing(48),
                  child: CustomButton(
                    text: 'Login',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                // Navigation to Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: responsive.bodyMedium.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: Text(
                        'Sign Up',
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

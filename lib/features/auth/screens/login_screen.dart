import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/responsive_text.dart';
import 'package:hopscotch/features/auth/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String _verificationId = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter phone number'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final phoneNumber = '+91$phone';
      
      if (kDebugMode) {
        debugPrint('Sending OTP to: $phoneNumber');
      }
      
      await ref.read(authRepositoryProvider).sendOTP(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false;
          });
        },
        onError: (errorMessage) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter OTP'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 4-digit OTP'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).verifyOTP(
        verificationId: _verificationId,
        smsCode: otp,
      );
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

                // Phone Number
                if (!_isOtpSent) ...[
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: responsive.fontSize14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      hintStyle: TextStyle(
                        color: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
                        fontSize: responsive.fontSize14,
                      ),
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: responsive.fontSize14,
                      ),
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: AppTheme.primaryColor,
                        size: responsive.iconSize(20),
                      ),
                      prefix: Container(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          '+91',
                          style: TextStyle(
                            fontSize: responsive.fontSize14,
                            color: AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

                  // Send OTP Button
                  SizedBox(
                    width: double.infinity,
                    height: responsive.spacing(48),
                    child: CustomButton(
                      text: 'Send OTP',
                      onPressed: _sendOTP,
                      isLoading: _isLoading,
                    ),
                  ),
                ] else ...[
                  // OTP Input
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: responsive.fontSize14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter 4-digit OTP',
                      hintStyle: TextStyle(
                        color: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
                        fontSize: responsive.fontSize14,
                      ),
                      labelText: '4-Digit OTP',
                      labelStyle: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: responsive.fontSize14,
                      ),
                      prefixIcon: Icon(
                        Icons.sms_outlined,
                        color: AppTheme.primaryColor,
                        size: responsive.iconSize(20),
                      ),
                      counterText: '',
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

                  // Verify OTP Button
                  SizedBox(
                    width: double.infinity,
                    height: responsive.spacing(48),
                    child: CustomButton(
                      text: 'Verify OTP',
                      onPressed: _verifyOTP,
                      isLoading: _isLoading,
                    ),
                  ),
                  
                  SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                  
                  // Resend OTP
                  TextButton(
                    onPressed: _sendOTP,
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: responsive.fontSize14,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

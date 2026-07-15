import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/widgets/custom_button.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/utils/error_handler.dart';
import 'package:hopscotch/repositories/auth_repository.dart';
import 'package:hopscotch/l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String _verificationId = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter phone number'),
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
      await ref.read(authRepositoryProvider).sendOTP(
        phoneNumber: _phoneController.text.trim(),
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
        final errorMessage = ErrorHandler.getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            ),
            title: const Text('OTP Verified'),
            content: const Text('You can now set a new password'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = ErrorHandler.getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textPrimaryColor,
            size: responsive.iconSize(24),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(AppTheme.spaceXL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  padding: EdgeInsets.all(
                    responsive.spacing(AppTheme.spaceM),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentColor.withValues(alpha: 0.1),
                        AppTheme.accentColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.key_rounded,
                    color: AppTheme.accentColor,
                    size: responsive.iconSize(32),
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
              Center(
                child: Text(
                  'Reset Password',
                  style: responsive.headline4.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceM)),
              Center(
                child: Text(
                  'Enter your phone number to receive a 4-digit OTP',
                  style: responsive.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

              // Phone Number Input
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
                      color: AppTheme.accentColor,
                      fontSize: responsive.fontSize14,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppTheme.accentColor,
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
                        color: AppTheme.accentColor,
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
                      color: AppTheme.accentColor,
                      fontSize: responsive.fontSize14,
                    ),
                    prefixIcon: Icon(
                      Icons.sms_outlined,
                      color: AppTheme.accentColor,
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
                        color: AppTheme.accentColor,
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
                      color: AppTheme.accentColor,
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
    );
  }
}

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
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

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.enterEmail,
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
                      fontSize: responsive.fontSize14,
                    ),
                    labelText: l10n.emailAddress,
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
                SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: responsive.fontSize14,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.enterPassword,
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
                      fontSize: responsive.fontSize14,
                    ),
                    labelText: l10n.password,
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
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
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
                SizedBox(height: responsive.spacing(AppTheme.spaceS)),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(
                      l10n.forgotPassword,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: responsive.fontSize14,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: responsive.spacing(48),
                  child: CustomButton(
                    text: l10n.signIn,
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // Sign Up Redirection
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.dontHaveAccount,
                        style: responsive.bodyMedium.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/signup'),
                        child: Text(
                          l10n.createAccount,
                          style: responsive.label.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

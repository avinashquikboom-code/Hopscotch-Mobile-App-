import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/responsive_text.dart';
import 'package:hopscotch/features/auth/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signup(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimaryColor, size: responsive.iconSize(24)),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: responsive.spacing(AppTheme.spaceXL)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: responsive.spacing(40)),
                Text(
                  l10n.createAccountTitle,
                  style: responsive.headline2,
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                Text(
                  l10n.signupDescription,
                  style: responsive.bodyMedium,
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                // Name
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  style: TextStyle(fontSize: responsive.fontSize14),
                  decoration: InputDecoration(
                    hintText: l10n.enterFullName,
                    hintStyle: TextStyle(fontSize: responsive.fontSize14),
                    labelText: l10n.fullName,
                    labelStyle: TextStyle(fontSize: responsive.fontSize14),
                    prefixIcon: Icon(Icons.person_outline_rounded, size: responsive.iconSize(20)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.fullNameRequired;
                    }
                    return null;
                  },
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: responsive.fontSize14),
                  decoration: InputDecoration(
                    hintText: l10n.enterEmail,
                    hintStyle: TextStyle(fontSize: responsive.fontSize14),
                    labelText: l10n.emailAddress,
                    labelStyle: TextStyle(fontSize: responsive.fontSize14),
                    prefixIcon: Icon(Icons.email_outlined, size: responsive.iconSize(20)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.emailRequired;
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return l10n.validEmail;
                    }
                    return null;
                  },
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(fontSize: responsive.fontSize14),
                  decoration: InputDecoration(
                    hintText: l10n.choosePassword,
                    hintStyle: TextStyle(fontSize: responsive.fontSize14),
                    labelText: l10n.password,
                    labelStyle: TextStyle(fontSize: responsive.fontSize14),
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: responsive.iconSize(20)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: responsive.iconSize(20),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.passwordRequired;
                    }
                    if (value.length < 6) {
                      return l10n.passwordLength;
                    }
                    return null;
                  },
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: responsive.spacing(56),
                  child: CustomButton(
                    text: l10n.createAccount,
                    onPressed: _handleSignup,
                    isLoading: _isLoading,
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                // Navigation to Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.alreadyHaveAccount,
                      style: responsive.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        l10n.signIn,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_text.dart';
import '../../../core/widgets/custom_button.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General Inquiry';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message sent successfully!', style: TextStyle(fontSize: context.responsive.fontSize14)),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      _formKey.currentState!.reset();
      setState(() {
        _selectedCategory = 'General Inquiry';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Contact Us', style: TextStyle(fontSize: responsive.fontSize18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Get in Touch',
              style: TextStyle(
                fontSize: responsive.fontSize24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceS)),
            Text(
              'We\'d love to hear from you. Send us a message and we\'ll respond as soon as possible.',
              style: responsive.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            // Contact Info Cards
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    context,
                    Icons.email_outlined,
                    'Email',
                    'support@auracouture.com',
                  ),
                ),
                SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                Expanded(
                  child: _buildContactCard(
                    context,
                    Icons.phone_outlined,
                    'Phone',
                    '+91 1800-123-4567',
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildContactCard(
              context,
              Icons.location_on_outlined,
              'Address',
              '123 Fashion Street, Mumbai, Maharashtra 400001',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            // Contact Form
            Container(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(color: AppTheme.borderColor, width: 1),
                boxShadow: AppTheme.softShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEND US A MESSAGE',
                      style: responsive.bodySmall.copyWith(
                        color: AppTheme.textLightColor,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        hintText: 'Select a category',
                        labelStyle: TextStyle(fontSize: responsive.fontSize14),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'General Inquiry',
                          child: Text('General Inquiry'),
                        ),
                        DropdownMenuItem(
                          value: 'Order Related',
                          child: Text('Order Related'),
                        ),
                        DropdownMenuItem(
                          value: 'Product Question',
                          child: Text('Product Question'),
                        ),
                        DropdownMenuItem(
                          value: 'Return/Refund',
                          child: Text('Return/Refund'),
                        ),
                        DropdownMenuItem(
                          value: 'Feedback',
                          child: Text('Feedback'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'Enter your name',
                        labelStyle: TextStyle(fontSize: responsive.fontSize14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter your email',
                        labelStyle: TextStyle(fontSize: responsive.fontSize14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                    TextFormField(
                      controller: _subjectController,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        hintText: 'Enter the subject',
                        labelStyle: TextStyle(fontSize: responsive.fontSize14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 5,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'Message',
                        hintText: 'Type your message here...',
                        labelStyle: TextStyle(fontSize: responsive.fontSize14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your message';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                    SizedBox(
                      width: double.infinity,
                      height: responsive.spacing(56),
                      child: CustomButton(
                        text: 'Send Message',
                        onPressed: _submitForm,
                        icon: Icons.send,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            // Social Links
            Text(
              'Follow Us',
              style: TextStyle(
                fontSize: responsive.fontSize16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            Row(
              children: [
                _buildSocialButton(context, Icons.facebook_outlined),
                SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                _buildSocialButton(context, Icons.camera_alt_outlined),
                SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                _buildSocialButton(context, Icons.alternate_email),
                SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                _buildSocialButton(context, Icons.play_circle_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, IconData icon, String title, String value) {
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceM)),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: responsive.iconSize(24),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceS)),
          Text(
            title,
            style: responsive.bodySmall.copyWith(
              color: AppTheme.textLightColor,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: responsive.spacing(2)),
          Text(
            value,
            style: responsive.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, IconData icon) {
    final responsive = context.responsive;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        splashColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Container(
          width: responsive.spacing(50),
          height: responsive.spacing(50),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: responsive.iconSize(24),
          ),
        ),
      ),
    );
  }
}

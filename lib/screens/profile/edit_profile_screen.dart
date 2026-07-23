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
import 'package:hopscotch/repositories/address_repository.dart';
import 'package:hopscotch/models/address_model.dart';
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
        final rawData = response.data;
        if (rawData is Map<String, dynamic>) {
          final userMap = rawData['data'] ?? rawData['user'];
          if (userMap is Map<String, dynamic>) {
            await ref.read(profileNotifierProvider.notifier).updateProfileState(userMap);
          }
        }
        // Also refresh from API to stay 100% in sync
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

              // ── SAVED ADDRESSES SECTION ──────────────────────────────────
              _buildAddressSection(context, responsive),

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

  Widget _buildAddressSection(BuildContext context, ResponsiveText responsive) {
    final addresses = ref.watch(addressNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: AppTheme.primaryColor, size: responsive.iconSize(20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SAVED DELIVERY ADDRESSES',
                      style: TextStyle(
                        fontSize: responsive.fontSize14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddressDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (addresses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: colorScheme.onSurface.withValues(alpha: 0.5), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No saved delivery addresses. Add one to enable 1-tap checkout.',
                    style: TextStyle(fontSize: responsive.fontSize12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: addresses.map((addr) {
              final typeStr = addr.type.toLowerCase();
              final isHome = typeStr == 'home';
              final isCurrent = typeStr == 'current';
              final isWork = typeStr == 'work' || typeStr == 'office';

              final labelText = isHome
                  ? '🏠 HOME'
                  : (isCurrent
                      ? '📍 CURRENT'
                      : (isWork ? '🏢 OFFICE' : '🏷️ OTHER'));

              final badgeColor = isHome
                  ? Colors.blue.shade700
                  : (isCurrent
                      ? Colors.teal.shade700
                      : (isWork ? Colors.amber.shade900 : Colors.purple.shade700));

              final badgeBg = isHome
                  ? Colors.blue.withValues(alpha: 0.1)
                  : (isCurrent
                      ? Colors.teal.withValues(alpha: 0.1)
                      : (isWork ? Colors.amber.withValues(alpha: 0.1) : Colors.purple.withValues(alpha: 0.1)));

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: addr.isDefault ? AppTheme.primaryColor : colorScheme.outline.withValues(alpha: 0.2),
                    width: addr.isDefault ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            labelText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        if (addr.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                          onSelected: (val) {
                            if (val == 'default') {
                              ref.read(addressNotifierProvider.notifier).setDefault(addr.id);
                            } else if (val == 'edit') {
                              _showAddressDialog(context, existing: addr);
                            } else if (val == 'delete') {
                              ref.read(addressNotifierProvider.notifier).deleteAddress(addr.id);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!addr.isDefault)
                              const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      addr.fullName.isNotEmpty ? addr.fullName : 'Saved Address',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: responsive.fontSize14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      addr.fullAddress,
                      style: TextStyle(fontSize: responsive.fontSize12, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            addr.phone.trim().isNotEmpty
                                ? 'Mobile: ${addr.phone}'
                                : 'Mobile Number: Not Provided',
                            style: TextStyle(
                              fontSize: responsive.fontSize12,
                              fontWeight: FontWeight.w600,
                              color: addr.phone.trim().isNotEmpty
                                  ? colorScheme.onSurface
                                  : Colors.red.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showAddressDialog(BuildContext context, {AddressModel? existing}) {
    final streetCtrl = TextEditingController(text: existing?.addressLine1 ?? '');
    final areaCtrl = TextEditingController(text: existing?.addressLine2 ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final stateCtrl = TextEditingController(text: existing?.state ?? 'Maharashtra');
    final zipCtrl = TextEditingController(text: existing?.pincode ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? _phoneController.text);
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '${_firstNameController.text} ${_lastNameController.text}'.trim());
    String selectedType = existing?.type ?? 'home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      existing != null ? 'Edit Address' : 'Add New Delivery Address',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Address Type Selection Chips (Home, Work/Office, Other)
                    const Text('Save Address As (Type)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _typeChip('home', '🏠 Home', selectedType, (val) => setModalState(() => selectedType = val)),
                        _typeChip('current', '📍 Current', selectedType, (val) => setModalState(() => selectedType = val)),
                        _typeChip('work', '🏢 Office', selectedType, (val) => setModalState(() => selectedType = val)),
                        _typeChip('other', '🏷️ Other', selectedType, (val) => setModalState(() => selectedType = val)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: streetCtrl,
                      decoration: const InputDecoration(labelText: 'House / Flat / Building No. & Street', prefixIcon: Icon(Icons.home_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: areaCtrl,
                      decoration: const InputDecoration(labelText: 'Locality / Landmark / Area (Optional)', prefixIcon: Icon(Icons.map_outlined)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: zipCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'PIN Code', prefixIcon: Icon(Icons.pin_drop_outlined)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty ||
                              phoneCtrl.text.trim().isEmpty ||
                              streetCtrl.text.trim().isEmpty ||
                              cityCtrl.text.trim().isEmpty ||
                              zipCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill full name, mobile number, street address, city, and PIN code'),
                              ),
                            );
                            return;
                          }

                          final model = AddressModel(
                            id: existing?.id ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
                            fullName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            addressLine1: streetCtrl.text.trim(),
                            addressLine2: areaCtrl.text.trim(),
                            city: cityCtrl.text.trim(),
                            state: stateCtrl.text.trim(),
                            pincode: zipCtrl.text.trim(),
                            country: 'India',
                            type: selectedType,
                            isDefault: existing?.isDefault ?? false,
                          );

                          if (existing != null) {
                            ref.read(addressNotifierProvider.notifier).updateAddress(model);
                          } else {
                            ref.read(addressNotifierProvider.notifier).addAddress(model);
                          }
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(existing != null ? 'SAVE ADDRESS' : 'ADD ADDRESS', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _typeChip(String value, String label, String current, Function(String) onSelect) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) => onSelect(value),
    );
  }
}

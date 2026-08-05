import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/widgets/custom_button.dart';
import 'package:hopscotch/models/address_model.dart';
import 'package:hopscotch/repositories/address_repository.dart';
import 'package:hopscotch/repositories/config_repository.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  void _setDefaultAddress(String addressId) {
    HapticFeedback.lightImpact();
    ref.read(addressNotifierProvider.notifier).setDefault(addressId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Default shipping address updated 🌟'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDeleteAddress(AddressModel address) {
    HapticFeedback.mediumImpact();
    final responsive = context.responsive;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Address?',
                style: TextStyle(
                  fontSize: responsive.fontSize18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${address.fullName}" address (${address.city})? This action cannot be undone.',
          style: TextStyle(
            fontSize: responsive.fontSize14,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(addressNotifierProvider.notifier).deleteAddress(address.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Address removed successfully'),
                  backgroundColor: AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddressBottomSheet([AddressModel? existingAddress]) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddressFormBottomSheet(
        existingAddress: existingAddress,
        onSave: (address) {
          HapticFeedback.mediumImpact();
          if (existingAddress != null) {
            ref.read(addressNotifierProvider.notifier).updateAddress(address);
          } else {
            ref.read(addressNotifierProvider.notifier).addAddress(address);
          }
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                existingAddress != null
                    ? 'Address updated successfully ✨'
                    : 'New address added successfully 📍',
              ),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final addresses = ref.watch(addressNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: Text(
          'Saved Addresses',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (addresses.isNotEmpty)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_location_alt_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              onPressed: () => _showAddressBottomSheet(),
              tooltip: 'Add New Address',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: addresses.isEmpty
          ? _buildEmptyState(responsive, colorScheme)
          : ListView(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(AppTheme.spaceL),
                vertical: responsive.spacing(AppTheme.spaceM),
              ),
              children: [
                // Summary Header Banner
                Container(
                  padding: EdgeInsets.all(responsive.spacing(14)),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.06),
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SAVED ADDRESSES (${addresses.length})',
                              style: TextStyle(
                                fontSize: responsive.fontSize11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Default address is automatically selected at checkout',
                              style: TextStyle(
                                fontSize: responsive.fontSize12,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                // Addresses List Cards
                ...addresses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final address = entry.value;

                  return TweenAnimationBuilder<double>(
                    key: ValueKey(address.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 60)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 24 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: responsive.spacing(AppTheme.spaceL)),
                            child: _buildAddressCard(address, isDark, colorScheme, responsive),
                          ),
                        ),
                      );
                    },
                  );
                }),

                const SizedBox(height: 80), // FAB Bottom Spacing
              ],
            ),
      floatingActionButton: addresses.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _showAddressBottomSheet(),
                backgroundColor: AppTheme.primaryColor,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                label: Text(
                  'ADD NEW ADDRESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontSize: responsive.fontSize13,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(ResponsiveText responsive, ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Lottie graphic or Location Hero visual
            SizedBox(
              height: 180,
              width: 180,
              child: Lottie.asset(
                'assets/lottie/success.json',
                repeat: true,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_rounded,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            Text(
              'No Saved Addresses Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceS)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Save your home, office, and delivery locations to enjoy seamless 1-tap checkout.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.fontSize14,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
            CustomButton(
              text: 'ADD NEW ADDRESS',
              onPressed: () => _showAddressBottomSheet(),
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    AddressModel address,
    bool isDark,
    ColorScheme colorScheme,
    ResponsiveText responsive,
  ) {
    final typeDetails = _getTypeDetails(address.type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: address.isDefault
              ? AppTheme.primaryColor
              : colorScheme.outline.withValues(alpha: isDark ? 0.3 : 0.8),
          width: address.isDefault ? 2 : 1,
        ),
        boxShadow: address.isDefault
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppTheme.softShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Row (Type Pill + Default Badge)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(10),
                    vertical: responsive.spacing(5),
                  ),
                  decoration: BoxDecoration(
                    color: typeDetails.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: typeDetails.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        typeDetails.icon,
                        size: responsive.iconSize(14),
                        color: typeDetails.color,
                      ),
                      SizedBox(width: responsive.spacing(6)),
                      Text(
                        typeDetails.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: responsive.fontSize11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: typeDetails.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(10),
                      vertical: responsive.spacing(5),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'DEFAULT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.fontSize10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),

            // Name & Phone Pill
            Row(
              children: [
                Expanded(
                  child: Text(
                    address.fullName,
                    style: TextStyle(
                      fontSize: responsive.fontSize16,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: responsive.iconSize(14),
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: responsive.spacing(6)),
                Text(
                  address.phone.trim().isNotEmpty
                      ? address.phone
                      : 'Mobile Number Not Provided',
                  style: TextStyle(
                    fontSize: responsive.fontSize13,
                    fontWeight: FontWeight.w600,
                    color: address.phone.trim().isNotEmpty
                        ? colorScheme.onSurface.withValues(alpha: 0.8)
                        : AppTheme.errorColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            const Divider(height: 1),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),

            // Address Details Text
            Text(
              address.fullAddress,
              style: TextStyle(
                fontSize: responsive.fontSize14,
                color: colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.45,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),

            // Bottom Actions Row
            Row(
              children: [
                if (!address.isDefault) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setDefaultAddress(address.id),
                      icon: const Icon(Icons.star_outline_rounded, size: 16),
                      label: Text(
                        'SET AS DEFAULT',
                        style: TextStyle(
                          fontSize: responsive.fontSize11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.6)),
                        foregroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: responsive.spacing(10)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(8)),
                ],
                IconButton(
                  onPressed: () => _showAddressBottomSheet(address),
                  tooltip: 'Edit Address',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: responsive.iconSize(16),
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacing(4)),
                IconButton(
                  onPressed: () => _confirmDeleteAddress(address),
                  tooltip: 'Delete Address',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _TypeDetails _getTypeDetails(String type) {
    final lower = type.toLowerCase();
    switch (lower) {
      case 'home':
        return _TypeDetails('Home', Icons.home_rounded, const Color(0xFF2563EB));
      case 'work':
      case 'office':
        return _TypeDetails('Work', Icons.work_rounded, const Color(0xFF7C3AED));
      default:
        return _TypeDetails(
          type.isNotEmpty ? type : 'Other',
          Icons.location_on_rounded,
          const Color(0xFF059669),
        );
    }
  }
}

class _TypeDetails {
  final String label;
  final IconData icon;
  final Color color;

  _TypeDetails(this.label, this.icon, this.color);
}

class _AddressFormBottomSheet extends ConsumerStatefulWidget {
  final AddressModel? existingAddress;
  final Function(AddressModel) onSave;

  const _AddressFormBottomSheet({
    this.existingAddress,
    required this.onSave,
  });

  @override
  ConsumerState<_AddressFormBottomSheet> createState() => _AddressFormBottomSheetState();
}

class _AddressFormBottomSheetState extends ConsumerState<_AddressFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  late String _selectedType;
  late String _selectedCountry;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    _fullNameController = TextEditingController(text: addr?.fullName ?? '');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
    _addressLine1Controller = TextEditingController(text: addr?.addressLine1 ?? '');
    _addressLine2Controller = TextEditingController(text: addr?.addressLine2 ?? '');
    _cityController = TextEditingController(text: addr?.city ?? '');
    _stateController = TextEditingController(text: addr?.state ?? '');
    _pincodeController = TextEditingController(text: addr?.pincode ?? '');
    _selectedType = addr?.type ?? 'home';
    _selectedCountry = (addr?.country != null && addr!.country.trim().isNotEmpty) ? addr.country : 'India';
    _isDefault = addr?.isDefault ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final address = AddressModel(
        id: widget.existingAddress?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        country: _selectedCountry,
        type: _selectedType,
        isDefault: _isDefault,
      );
      widget.onSave(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.existingAddress != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bottom Sheet Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEditing ? 'Edit Address' : 'Add New Address',
                style: TextStyle(
                  fontSize: responsive.fontSize20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, size: responsive.iconSize(22)),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),

          // Scrollable Form Container
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Type Selector Chips
                    Row(
                      children: [
                        _buildTypeChip('home', 'Home', Icons.home_rounded),
                        SizedBox(width: responsive.spacing(AppTheme.spaceS)),
                        _buildTypeChip('work', 'Work', Icons.work_rounded),
                        SizedBox(width: responsive.spacing(AppTheme.spaceS)),
                        _buildTypeChip('other', 'Other', Icons.location_on_rounded),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                    // Input Fields
                    TextFormField(
                      controller: _fullNameController,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter receiver name',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter receiver name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: 'Enter 10-digit mobile number',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter mobile number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                    TextFormField(
                      controller: _addressLine1Controller,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'Flat / House No. / Building *',
                        hintText: 'e.g. Flat 402, Sunshine Heights',
                        prefixIcon: const Icon(Icons.home_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter address line 1';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                    TextFormField(
                      controller: _addressLine2Controller,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'Street / Area / Landmark (Optional)',
                        hintText: 'e.g. Near City Mall, MG Road',
                        prefixIcon: const Icon(Icons.map_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            style: TextStyle(fontSize: responsive.fontSize14),
                            decoration: InputDecoration(
                              labelText: 'City *',
                              hintText: 'e.g. Mumbai',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            style: TextStyle(fontSize: responsive.fontSize14),
                            decoration: InputDecoration(
                              labelText: 'State *',
                              hintText: 'e.g. Maharashtra',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                    TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: responsive.fontSize14),
                      decoration: InputDecoration(
                        labelText: 'Pincode *',
                        hintText: 'e.g. 400001',
                        prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter pincode';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                    // Dynamic Country Dropdown
                    Builder(
                      builder: (context) {
                        final countriesAsync = ref.watch(apiCountriesProvider);
                        final apiList = countriesAsync.value
                            ?.map((c) => c['name']?.toString() ?? '')
                            .where((name) => name.isNotEmpty)
                            .toList();
                        final countriesList = (apiList != null && apiList.isNotEmpty) ? apiList : ['India'];

                        return DropdownButtonFormField<String>(
                          value: countriesList.contains(_selectedCountry)
                              ? _selectedCountry
                              : (countriesList.isNotEmpty ? countriesList.first : null),
                          decoration: InputDecoration(
                            labelText: 'Country *',
                            prefixIcon: const Icon(Icons.public_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: countriesList
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: responsive.fontSize14))))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedCountry = val ?? 'India'),
                          validator: (v) => v == null || v.isEmpty ? 'Please select a country' : null,
                        );
                      },
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                    // Default Address Switch
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: AppTheme.primaryColor,
                        title: const Text(
                          'Set as Default Address',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Use this address automatically for future orders',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        value: _isDefault,
                        onChanged: (val) {
                          setState(() {
                            _isDefault = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: responsive.spacing(AppTheme.spaceM)),

          // Submit CTA Button (Pinned at Bottom)
          SizedBox(
            width: double.infinity,
            height: responsive.spacing(52),
            child: CustomButton(
              text: isEditing ? 'UPDATE ADDRESS' : 'SAVE ADDRESS',
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final responsive = context.responsive;
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.outline,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: responsive.iconSize(16),
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
              SizedBox(width: responsive.spacing(6)),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: responsive.fontSize12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

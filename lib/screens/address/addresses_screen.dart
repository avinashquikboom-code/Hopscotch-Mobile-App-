import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/widgets/custom_button.dart';
import 'package:hopscotch/models/address_model.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final List<AddressModel> _addresses = [
    AddressModel(
      id: '1',
      fullName: 'John Doe',
      phone: '+91 98765 43210',
      addressLine1: '123 Fashion Street',
      addressLine2: 'Apartment 4B',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400001',
      country: 'India',
      isDefault: true,
      type: 'home',
    ),
    AddressModel(
      id: '2',
      fullName: 'John Doe',
      phone: '+91 98765 43210',
      addressLine1: '456 Business Park',
      addressLine2: 'Floor 12, Tower A',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400051',
      country: 'India',
      isDefault: false,
      type: 'work',
    ),
  ];

  void _setDefaultAddress(String addressId) {
    HapticFeedback.lightImpact();
    setState(() {
      for (var address in _addresses) {
        address.isDefault = (address.id == addressId);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default address updated'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteAddress(String addressId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _addresses.removeWhere((a) => a.id == addressId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address deleted'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAddressBottomSheet(
        onAdd: (address) {
          HapticFeedback.lightImpact();
          setState(() {
            _addresses.add(address);
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address added successfully'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('My Addresses', style: TextStyle(fontSize: responsive.fontSize18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _addresses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final address = _addresses[index];
                return TweenAnimationBuilder<double>(
                  key: ValueKey(address.id),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: responsive.spacing(AppTheme.spaceL)),
                          child: _buildAddressCard(address),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddressBottomSheet,
        backgroundColor: AppTheme.primaryColor,
        icon: Icon(Icons.add, color: Colors.white, size: responsive.iconSize(24)),
        label: Text(
          'Add Address',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: responsive.fontSize14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final responsive = context.responsive;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: responsive.iconSize(80),
            color: AppTheme.textLightColor,
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceL)),
          Text(
            'No addresses yet',
            style: TextStyle(
              fontSize: responsive.fontSize20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceS)),
          Text(
            'Add your first address to get started',
            style: responsive.bodyMedium.copyWith(
              color: AppTheme.textLightColor,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
          CustomButton(
            text: 'Add Address',
            onPressed: _showAddAddressBottomSheet,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    final responsive = context.responsive;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: address.isDefault ? AppTheme.primaryColor : AppTheme.borderColor,
          width: address.isDefault ? 2 : 1,
        ),
        boxShadow: address.isDefault ? AppTheme.intenseShadow : AppTheme.softShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getAddressIcon(address.type),
                      size: responsive.iconSize(20),
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: responsive.spacing(AppTheme.spaceS)),
                    Text(
                      address.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: responsive.fontSize12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                if (address.isDefault)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(8),
                      vertical: responsive.spacing(4),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.fontSize10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            // Name and Phone
            Text(
              address.fullName,
              style: TextStyle(
                fontSize: responsive.fontSize16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: responsive.spacing(4)),
            Text(
              address.phone,
              style: responsive.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            // Address
            Text(
              address.fullAddress,
              style: responsive.bodyMedium.copyWith(
                color: AppTheme.textPrimaryColor,
                height: 1.4,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            // Actions
            Row(
              children: [
                if (!address.isDefault)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setDefaultAddress(address.id),
                      icon: Icon(Icons.star_border, size: responsive.iconSize(16)),
                      label: Text('Set Default', style: TextStyle(fontSize: responsive.fontSize12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                        foregroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                      ),
                    ),
                  ),
                if (!address.isDefault) SizedBox(width: responsive.spacing(AppTheme.spaceS)),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteAddress(address.id),
                    icon: Icon(Icons.delete_outline, size: responsive.iconSize(16)),
                    label: Text('Delete', style: TextStyle(fontSize: responsive.fontSize12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorColor),
                      foregroundColor: AppTheme.errorColor,
                      padding: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
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

  IconData _getAddressIcon(String type) {
    switch (type) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }
}

class _AddAddressBottomSheet extends StatefulWidget {
  final Function(AddressModel) onAdd;

  const _AddAddressBottomSheet({required this.onAdd});

  @override
  State<_AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends State<_AddAddressBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _selectedType = 'home';

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
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        country: 'India',
        type: _selectedType,
      );
      widget.onAdd(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXL),
          topRight: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      padding: EdgeInsets.only(
        left: responsive.spacing(AppTheme.spaceL),
        right: responsive.spacing(AppTheme.spaceL),
        top: responsive.spacing(AppTheme.spaceL),
        bottom: MediaQuery.of(context).viewInsets.bottom + responsive.spacing(AppTheme.spaceL),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New Address',
                  style: TextStyle(
                    fontSize: responsive.fontSize20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: responsive.iconSize(24)),
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            // Address Type
            Row(
              children: [
                _buildTypeChip('home', 'Home', Icons.home_outlined),
                SizedBox(width: responsive.spacing(AppTheme.spaceS)),
                _buildTypeChip('work', 'Work', Icons.work_outline),
                SizedBox(width: responsive.spacing(AppTheme.spaceS)),
                _buildTypeChip('other', 'Other', Icons.location_on_outlined),
              ],
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            TextFormField(
              controller: _fullNameController,
              style: TextStyle(fontSize: responsive.fontSize14),
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
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
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(fontSize: responsive.fontSize14),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                labelStyle: TextStyle(fontSize: responsive.fontSize14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            TextFormField(
              controller: _addressLine1Controller,
              style: TextStyle(fontSize: responsive.fontSize14),
              decoration: InputDecoration(
                labelText: 'Address Line 1',
                hintText: 'House/Flat No, Building, Street',
                labelStyle: TextStyle(fontSize: responsive.fontSize14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
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
                labelText: 'Address Line 2 (Optional)',
                hintText: 'Area, Landmark',
                labelStyle: TextStyle(fontSize: responsive.fontSize14),
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
                      labelText: 'City',
                      hintText: 'Enter city',
                      labelStyle: TextStyle(fontSize: responsive.fontSize14),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
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
                      labelText: 'State',
                      hintText: 'Enter state',
                      labelStyle: TextStyle(fontSize: responsive.fontSize14),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
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
                labelText: 'Pincode',
                hintText: 'Enter pincode',
                labelStyle: TextStyle(fontSize: responsive.fontSize14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pincode';
                }
                return null;
              },
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            SizedBox(
              width: double.infinity,
              height: responsive.spacing(56),
              child: CustomButton(
                text: 'Save Address',
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final responsive = context.responsive;
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            ),
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

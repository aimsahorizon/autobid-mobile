import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';
import '../../../data/datasources/philippine_address_data.dart';

class AddressStep extends StatefulWidget {
  final KYCRegistrationController controller;

  const AddressStep({
    super.key,
    required this.controller,
  });

  @override
  State<AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<AddressStep> {
  final _streetController = TextEditingController();
  final _zipCodeController = TextEditingController();

  List<String> _regions = [];
  List<String> _provinces = [];
  List<String> _cities = [];
  List<String> _barangays = [];

  @override
  void initState() {
    super.initState();
    _regions = PhilippineAddressData.getRegions();

    if (widget.controller.street != null) {
      _streetController.text = widget.controller.street!;
    }
    if (widget.controller.zipCode != null) {
      _zipCodeController.text = widget.controller.zipCode!;
    }

    _streetController.addListener(() {
      widget.controller.setStreet(_streetController.text);
    });
    _zipCodeController.addListener(() {
      widget.controller.setZipCode(_zipCodeController.text);
    });

    // Load existing data if any
    if (widget.controller.region != null) {
      _provinces = PhilippineAddressData.getProvinces(widget.controller.region!);
    }
    if (widget.controller.province != null) {
      _cities = PhilippineAddressData.getCities(widget.controller.province!);
    }
    if (widget.controller.city != null) {
      _barangays = PhilippineAddressData.getBarangays(widget.controller.city!);
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _onRegionChanged(String? value) {
    if (value != null) {
      setState(() {
        widget.controller.setRegion(value);
        _provinces = PhilippineAddressData.getProvinces(value);
        _cities = [];
        _barangays = [];
      });
    }
  }

  void _onProvinceChanged(String? value) {
    if (value != null) {
      setState(() {
        widget.controller.setProvince(value);
        _cities = PhilippineAddressData.getCities(value);
        _barangays = [];
      });
    }
  }

  void _onCityChanged(String? value) {
    if (value != null) {
      setState(() {
        widget.controller.setCity(value);
        _barangays = PhilippineAddressData.getBarangays(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address Information',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide your complete Philippine address',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            value: _regions.contains(widget.controller.region)
                ? widget.controller.region
                : null,
            decoration: const InputDecoration(
              labelText: 'Region',
              hintText: 'Select your region',
              prefixIcon: Icon(Icons.map_outlined),
            ),
            items: _regions.toSet().toList().map((region) {
              return DropdownMenuItem(
                value: region,
                child: Text(region, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: _onRegionChanged,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _provinces.contains(widget.controller.province)
                ? widget.controller.province
                : null,
            decoration: const InputDecoration(
              labelText: 'Province',
              hintText: 'Select your province',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            items: _provinces.toSet().toList().map((province) {
              return DropdownMenuItem(
                value: province,
                child: Text(province),
              );
            }).toList(),
            onChanged: _provinces.isEmpty ? null : _onProvinceChanged,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _cities.contains(widget.controller.city)
                ? widget.controller.city
                : null,
            decoration: const InputDecoration(
              labelText: 'City/Municipality',
              hintText: 'Select your city',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
            items: _cities.toSet().toList().map((city) {
              return DropdownMenuItem(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: _cities.isEmpty ? null : _onCityChanged,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _barangays.contains(widget.controller.barangay)
                ? widget.controller.barangay
                : null,
            decoration: const InputDecoration(
              labelText: 'Barangay',
              hintText: 'Select your barangay',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            items: _barangays.toSet().toList().map((barangay) {
              return DropdownMenuItem(
                value: barangay,
                child: Text(barangay),
              );
            }).toList(),
            onChanged: _barangays.isEmpty
                ? null
                : (value) {
                    if (value != null) {
                      widget.controller.setBarangay(value);
                    }
                  },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _streetController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Street Address',
              hintText: 'House No., Street Name',
              prefixIcon: Icon(Icons.signpost_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _zipCodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ZIP Code',
              hintText: 'Enter ZIP code',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
            maxLength: 4,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstants.info.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: ColorConstants.info,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure your address matches the one on your proof of address document',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ColorConstants.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

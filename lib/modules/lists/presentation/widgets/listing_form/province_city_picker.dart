import 'package:flutter/material.dart';
import '../../../../../app/core/data/philippines_locations.dart';

class ProvinceCityPicker extends StatefulWidget {
  final String? province;
  final String? city;
  final void Function(String? province, String? city) onChanged;
  final String? Function(String?)? provinceValidator;
  final String? Function(String?)? cityValidator;
  final bool enabled;

  const ProvinceCityPicker({
    super.key,
    required this.province,
    required this.city,
    required this.onChanged,
    this.provinceValidator,
    this.cityValidator,
    this.enabled = true,
  });

  @override
  State<ProvinceCityPicker> createState() => _ProvinceCityPickerState();
}

class _ProvinceCityPickerState extends State<ProvinceCityPicker> {
  String? _selectedProvince;
  String? _selectedCity;
  List<String> _availableCities = [];

  @override
  void initState() {
    super.initState();
    _selectedProvince = widget.province;
    _selectedCity = widget.city;
    if (_selectedProvince != null) {
      _availableCities = PhilippineLocations.getCities(_selectedProvince!);
    }
  }

  @override
  void didUpdateWidget(ProvinceCityPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.province != oldWidget.province) {
      _selectedProvince = widget.province;
      if (_selectedProvince != null) {
        _availableCities = PhilippineLocations.getCities(_selectedProvince!);
      } else {
        _availableCities = [];
      }
    }
    if (widget.city != oldWidget.city) {
      _selectedCity = widget.city;
    }
  }

  void _onProvinceChanged(String? value) {
    setState(() {
      _selectedProvince = value;
      _selectedCity = null; // Reset city when province changes
      _availableCities = value != null
          ? PhilippineLocations.getCities(value)
          : [];
    });
    widget.onChanged(_selectedProvince, null);
  }

  void _onCityChanged(String? value) {
    setState(() {
      _selectedCity = value;
    });
    widget.onChanged(_selectedProvince, _selectedCity);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedProvince,
          decoration: InputDecoration(
            labelText: 'Province *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: PhilippineLocations.provinces.map((province) {
            return DropdownMenuItem(value: province, child: Text(province));
          }).toList(),
          onChanged: widget.enabled ? _onProvinceChanged : null,
          validator: widget.provinceValidator,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: InputDecoration(
            labelText: 'City/Municipality',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _availableCities.map((city) {
            return DropdownMenuItem(value: city, child: Text(city));
          }).toList(),
          onChanged: widget.enabled && _selectedProvince != null
              ? _onCityChanged
              : null,
          validator: widget.cityValidator,
        ),
      ],
    );
  }
}

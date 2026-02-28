import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../app/di/app_module.dart';
import '../../../../location/domain/entities/location_entities.dart';
import '../../../../location/presentation/bloc/location_bloc.dart';
import '../../../../location/presentation/bloc/location_event.dart';
import '../../../../location/presentation/bloc/location_state.dart';

class LocationPicker extends StatefulWidget {
  final String? province;
  final String? city;
  final String? barangay;
  final void Function(String? province, String? city, String? barangay) onChanged;
  final String? Function(String?)? provinceValidator;
  final String? Function(String?)? cityValidator;
  final String? Function(String?)? barangayValidator;
  final bool enabled;

  const LocationPicker({
    super.key,
    required this.province,
    required this.city,
    required this.barangay,
    required this.onChanged,
    this.provinceValidator,
    this.cityValidator,
    this.barangayValidator,
    this.enabled = true,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late LocationBloc _locationBloc;

  List<RegionEntity> _regions = [];
  List<ProvinceEntity> _provinces = [];
  List<CityEntity> _cities = [];
  List<BarangayEntity> _barangays = [];

  RegionEntity? _selectedRegion;
  ProvinceEntity? _selectedProvince;
  CityEntity? _selectedCity;
  BarangayEntity? _selectedBarangay;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _locationBloc = sl<LocationBloc>();
    _locationBloc.add(LoadRegions());
  }

  @override
  void dispose() {
    _locationBloc.close();
    super.dispose();
  }

  void _onRegionChanged(RegionEntity? region) {
    if (region != null) {
      setState(() {
        _selectedRegion = region;
        _provinces = [];
        _cities = [];
        _barangays = [];
        _selectedProvince = null;
        _selectedCity = null;
        _selectedBarangay = null;
      });
      _locationBloc.add(LoadProvinces(region.id));
      widget.onChanged(null, null, null);
    }
  }

  void _onProvinceChanged(ProvinceEntity? province) {
    if (province != null) {
      setState(() {
        _selectedProvince = province;
        _cities = [];
        _barangays = [];
        _selectedCity = null;
        _selectedBarangay = null;
      });
      _locationBloc.add(LoadCities(province.id));
      widget.onChanged(province.name, null, null);
    }
  }

  void _onCityChanged(CityEntity? city) {
    if (city != null) {
      setState(() {
        _selectedCity = city;
        _barangays = [];
        _selectedBarangay = null;
      });
      _locationBloc.add(LoadBarangays(city.id));
      widget.onChanged(_selectedProvince?.name, city.name, null);
    }
  }

  void _onBarangayChanged(BarangayEntity? barangay) {
    if (barangay != null) {
      setState(() {
        _selectedBarangay = barangay;
      });
      widget.onChanged(_selectedProvince?.name, _selectedCity?.name, barangay.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _locationBloc,
      child: BlocListener<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is LocationLoading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);
          }

          if (state is RegionsLoaded) {
            setState(() {
              _regions = state.regions;
              // Auto-select Region IX for Zamboanga context if possible, or leave empty
              // For now, if user provided province, we try to match it logic (complex without region map)
            });
          } else if (state is ProvincesLoaded) {
            setState(() {
              _provinces = state.provinces;
              // Restore Province
              if (widget.province != null && _selectedProvince == null) {
                try {
                  final match = _provinces.firstWhere((p) => p.name == widget.province);
                  _selectedProvince = match;
                  _locationBloc.add(LoadCities(match.id));
                } catch (_) {}
              }
            });
          } else if (state is CitiesLoaded) {
            setState(() {
              _cities = state.cities;
              // Restore City
              if (widget.city != null && _selectedCity == null) {
                try {
                  final match = _cities.firstWhere((c) => c.name == widget.city);
                  _selectedCity = match;
                  _locationBloc.add(LoadBarangays(match.id));
                } catch (_) {}
              }
            });
          } else if (state is BarangaysLoaded) {
             setState(() {
              _barangays = state.barangays;
              // Restore Barangay
              if (widget.barangay != null && _selectedBarangay == null) {
                try {
                  final match = _barangays.firstWhere((b) => b.name == widget.barangay);
                  _selectedBarangay = match;
                } catch (_) {}
              }
            });
          }
        },
        child: Column(
          children: [
            if (_isLoading)
              const LinearProgressIndicator(minHeight: 2),
              
            // Region Dropdown
            DropdownButtonFormField<RegionEntity>(
              key: ValueKey(_selectedRegion),
              initialValue: _selectedRegion,
              decoration: InputDecoration(
                labelText: 'Region',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _regions.map((region) {
                return DropdownMenuItem(value: region, child: Text(region.name));
              }).toList(),
              onChanged: widget.enabled ? _onRegionChanged : null,
            ),
            const SizedBox(height: 16),

            // Province Dropdown
            DropdownButtonFormField<ProvinceEntity>(
              key: ValueKey(_selectedProvince),
              initialValue: _selectedProvince,
              decoration: InputDecoration(
                labelText: 'Province *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _provinces.map((province) {
                return DropdownMenuItem(value: province, child: Text(province.name));
              }).toList(),
              onChanged: (widget.enabled && _selectedRegion != null)
                  ? _onProvinceChanged
                  : null,
              validator: (val) => widget.provinceValidator?.call(val?.name),
            ),
            const SizedBox(height: 16),

            // City Dropdown
            DropdownButtonFormField<CityEntity>(
              key: ValueKey(_selectedCity),
              initialValue: _selectedCity,
              decoration: InputDecoration(
                labelText: 'City/Municipality *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _cities.map((city) {
                return DropdownMenuItem(value: city, child: Text(city.name));
              }).toList(),
              onChanged: (widget.enabled && _selectedProvince != null)
                  ? _onCityChanged
                  : null,
              validator: (val) => widget.cityValidator?.call(val?.name),
            ),
            const SizedBox(height: 16),

             // Barangay Dropdown
            DropdownButtonFormField<BarangayEntity>(
              key: ValueKey(_selectedBarangay),
              initialValue: _selectedBarangay,
              decoration: InputDecoration(
                labelText: 'Barangay *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _barangays.map((barangay) {
                return DropdownMenuItem(value: barangay, child: Text(barangay.name));
              }).toList(),
              onChanged: (widget.enabled && _selectedCity != null)
                  ? _onBarangayChanged
                  : null,
              validator: (val) => widget.barangayValidator?.call(val?.name),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../app/di/app_module.dart';
import '../../../../location/domain/entities/location_entities.dart';
import '../../../../location/presentation/bloc/location_bloc.dart';
import '../../../../location/presentation/bloc/location_event.dart';
import '../../../../location/presentation/bloc/location_state.dart';

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
  late LocationBloc _locationBloc;

  List<RegionEntity> _regions = [];
  List<ProvinceEntity> _provinces = [];
  List<CityEntity> _cities = [];

  RegionEntity? _selectedRegion;
  ProvinceEntity? _selectedProvince;
  CityEntity? _selectedCity;

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
        _selectedProvince = null;
        _selectedCity = null;
      });
      _locationBloc.add(LoadProvinces(region.id));
      widget.onChanged(null, null);
    }
  }

  void _onProvinceChanged(ProvinceEntity? province) {
    if (province != null) {
      setState(() {
        _selectedProvince = province;
        _cities = [];
        _selectedCity = null;
      });
      _locationBloc.add(LoadCities(province.id));
      widget.onChanged(province.name, null);
    }
  }

  void _onCityChanged(CityEntity? city) {
    if (city != null) {
      setState(() {
        _selectedCity = city;
      });
      widget.onChanged(_selectedProvince?.name, city.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _locationBloc,
      child: BlocListener<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is RegionsLoaded) {
            setState(() {
              _regions = state.regions;
              // If we wanted to pre-select based on existing string values (widget.province),
              // we'd need to know the Region first. Since we don't store Region string,
              // we can't easily auto-select the Region unless we fetch ALL provinces
              // or search for the province.
              // For now, if a value exists but we don't have region, user must re-select.
              // OR: We could iterate regions to find the province? That's expensive.
              // Given the scope change, resetting is acceptable or we assume the backend
              // data migration handles this.
            });
          } else if (state is ProvincesLoaded) {
            setState(() {
              _provinces = state.provinces;
              // Try to restore province selection if names match
              if (widget.province != null && _selectedProvince == null) {
                try {
                  final match = _provinces.firstWhere(
                    (p) => p.name == widget.province,
                  );
                  _selectedProvince = match;
                  _locationBloc.add(LoadCities(match.id));
                } catch (_) {}
              }
            });
          } else if (state is CitiesLoaded) {
            setState(() {
              _cities = state.cities;
              // Try to restore city selection if names match
              if (widget.city != null && _selectedCity == null) {
                try {
                  final match = _cities.firstWhere(
                    (c) => c.name == widget.city,
                  );
                  _selectedCity = match;
                } catch (_) {}
              }
            });
          }
        },
        child: Column(
          children: [
            // Region Dropdown (New)
            DropdownButtonFormField<RegionEntity>(
              initialValue: _selectedRegion,
              decoration: InputDecoration(
                labelText: 'Region',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _regions.map((region) {
                return DropdownMenuItem(
                  value: region,
                  child: Text(region.name),
                );
              }).toList(),
              onChanged: widget.enabled ? _onRegionChanged : null,
            ),
            const SizedBox(height: 16),

            // Province Dropdown
            DropdownButtonFormField<ProvinceEntity>(
              initialValue: _selectedProvince,
              decoration: InputDecoration(
                labelText: 'Province *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _provinces.map((province) {
                return DropdownMenuItem(
                  value: province,
                  child: Text(province.name),
                );
              }).toList(),
              onChanged: (widget.enabled && _selectedRegion != null)
                  ? _onProvinceChanged
                  : null,
              validator: (val) => widget.provinceValidator?.call(val?.name),
            ),
            const SizedBox(height: 16),

            // City Dropdown
            DropdownButtonFormField<CityEntity>(
              initialValue: _selectedCity,
              decoration: InputDecoration(
                labelText: 'City/Municipality',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _cities.map((city) {
                return DropdownMenuItem(value: city, child: Text(city.name));
              }).toList(),
              onChanged: (widget.enabled && _selectedProvince != null)
                  ? _onCityChanged
                  : null,
              validator: (val) => widget.cityValidator?.call(val?.name),
            ),
          ],
        ),
      ),
    );
  }
}

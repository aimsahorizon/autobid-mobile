import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../../../../app/di/app_module.dart';
import '../../../../location/domain/entities/location_entities.dart';
import '../../../../location/presentation/bloc/location_bloc.dart';
import '../../../../location/presentation/bloc/location_event.dart';
import '../../../../location/presentation/bloc/location_state.dart';
import '../../controllers/kyc_registration_controller.dart';

class AddressStep extends StatefulWidget {
  final KYCRegistrationController controller;

  const AddressStep({super.key, required this.controller});

  @override
  State<AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<AddressStep> {
  late LocationBloc _locationBloc;
  final _streetController = TextEditingController();
  final _zipCodeController = TextEditingController();

  List<RegionEntity> _regions = [];
  List<ProvinceEntity> _provinces = [];
  List<CityEntity> _cities = [];
  List<BarangayEntity> _barangays = [];

  @override
  void initState() {
    super.initState();
    _locationBloc = sl<LocationBloc>();
    _locationBloc.add(LoadRegions());

    if (widget.controller.street != null) {
      _streetController.text = widget.controller.street!;
    }

    // Default ZIP for Zamboanga is 7000, but we should probably let user enter it
    // or auto-populate based on city if we had that data.
    // For now, keeping the controller logic but removing the hard lock if possible,
    // though the UI had it read-only. I'll make it editable for scalability
    // or keep it 7000 default but editable.
    if (widget.controller.zipCode != null) {
      _zipCodeController.text = widget.controller.zipCode!;
    } else {
      _zipCodeController.text = '7000'; // Default legacy
    }

    _streetController.addListener(() {
      widget.controller.setStreet(_streetController.text);
    });
    _zipCodeController.addListener(() {
      widget.controller.setZipCode(_zipCodeController.text);
    });
  }

  @override
  void dispose() {
    _locationBloc.close();
    _streetController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _onRegionChanged(RegionEntity? region) {
    if (region != null) {
      setState(() {
        widget.controller.setRegion(region.name);

        // Reset children
        _provinces = [];
        _cities = [];
        _barangays = [];
        widget.controller.setProvince(null); // Clear in controller
        widget.controller.setCity(null);
        widget.controller.setBarangay(null);
      });
      _locationBloc.add(LoadProvinces(region.id));
    }
  }

  void _onProvinceChanged(ProvinceEntity? province) {
    if (province != null) {
      setState(() {
        widget.controller.setProvince(province.name);

        // Reset children
        _cities = [];
        _barangays = [];
        widget.controller.setCity(null);
        widget.controller.setBarangay(null);
      });
      _locationBloc.add(LoadCities(province.id));
    }
  }

  void _onCityChanged(CityEntity? city) {
    if (city != null) {
      setState(() {
        widget.controller.setCity(city.name);

        // Reset children
        _barangays = [];
        widget.controller.setBarangay(null);

        // Basic Zip Code Logic (Hardcoded for now as DB doesn't have it yet)
        if (city.name.contains('Zamboanga City')) {
          _zipCodeController.text = '7000';
          widget.controller.setZipCode('7000');
        } else {
          _zipCodeController.clear();
        }
      });
      _locationBloc.add(LoadBarangays(city.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _locationBloc,
      child: BlocListener<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is RegionsLoaded) {
            setState(() {
              _regions = state.regions;
            });
            // Restore previously selected region or auto-select single option
            final savedRegion = widget.controller.region;
            if (savedRegion != null) {
              final match = _regions.where((r) => r.name == savedRegion);
              if (match.isNotEmpty) {
                // Load provinces without clearing controller values
                _locationBloc.add(LoadProvinces(match.first.id));
              }
            } else if (_regions.length == 1) {
              _onRegionChanged(_regions.first);
            }
          } else if (state is ProvincesLoaded) {
            setState(() {
              _provinces = state.provinces;
            });
            final savedProvince = widget.controller.province;
            if (savedProvince != null) {
              final match = _provinces.where((p) => p.name == savedProvince);
              if (match.isNotEmpty) {
                _locationBloc.add(LoadCities(match.first.id));
              }
            } else if (_provinces.length == 1) {
              _onProvinceChanged(_provinces.first);
            }
          } else if (state is CitiesLoaded) {
            setState(() {
              _cities = state.cities;
            });
            final savedCity = widget.controller.city;
            if (savedCity != null) {
              final match = _cities.where((c) => c.name == savedCity);
              if (match.isNotEmpty) {
                _locationBloc.add(LoadBarangays(match.first.id));
              }
            } else if (_cities.length == 1) {
              _onCityChanged(_cities.first);
            }
          } else if (state is BarangaysLoaded) {
            setState(() {
              _barangays = state.barangays;
            });
          } else if (state is LocationError) {
            (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
              SnackBar(
                content: Text('Error loading location data: ${state.message}'),
              ),
            );
          }
        },
        child: SingleChildScrollView(
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

              // Region
              DropdownButtonFormField<RegionEntity>(
                initialValue:
                    _regions.any((r) => r.name == widget.controller.region)
                    ? _regions.firstWhere(
                        (r) => r.name == widget.controller.region,
                      )
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Region',
                  hintText: 'Select your region',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                items: _regions.map((region) {
                  return DropdownMenuItem(
                    value: region,
                    child: Text(
                      region.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: _onRegionChanged,
              ),
              const SizedBox(height: 16),

              // Province
              DropdownButtonFormField<ProvinceEntity>(
                initialValue:
                    _provinces.any((p) => p.name == widget.controller.province)
                    ? _provinces.firstWhere(
                        (p) => p.name == widget.controller.province,
                      )
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Province',
                  hintText: 'Select your province',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: _provinces.map((province) {
                  return DropdownMenuItem(
                    value: province,
                    child: Text(province.name),
                  );
                }).toList(),
                onChanged: _provinces.isNotEmpty ? _onProvinceChanged : null,
              ),
              const SizedBox(height: 16),

              // City
              DropdownButtonFormField<CityEntity>(
                initialValue:
                    _cities.any((c) => c.name == widget.controller.city)
                    ? _cities.firstWhere(
                        (c) => c.name == widget.controller.city,
                      )
                    : null,
                decoration: const InputDecoration(
                  labelText: 'City/Municipality',
                  hintText: 'Select your city',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                items: _cities.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city.name));
                }).toList(),
                onChanged: _cities.isNotEmpty ? _onCityChanged : null,
              ),
              const SizedBox(height: 16),

              // Barangay
              DropdownButtonFormField<BarangayEntity>(
                initialValue:
                    _barangays.any((b) => b.name == widget.controller.barangay)
                    ? _barangays.firstWhere(
                        (b) => b.name == widget.controller.barangay,
                      )
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Barangay',
                  hintText: 'Select your barangay',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                items: _barangays.map((barangay) {
                  return DropdownMenuItem(
                    value: barangay,
                    child: Text(barangay.name),
                  );
                }).toList(),
                onChanged: _barangays.isEmpty
                    ? null
                    : (value) {
                        if (value != null) {
                          widget.controller.setBarangay(value.name);
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
        ),
      ),
    );
  }
}

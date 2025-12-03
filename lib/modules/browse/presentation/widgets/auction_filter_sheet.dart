import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/auction_filter.dart';
import '../../domain/entities/filter_options.dart';

/// Comprehensive filter bottom sheet for auction browsing
/// Provides all filtering options with professional UX
class AuctionFilterSheet extends StatefulWidget {
  final AuctionFilter initialFilter;
  final Function(AuctionFilter) onApply;

  const AuctionFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<AuctionFilterSheet> createState() => _AuctionFilterSheetState();
}

class _AuctionFilterSheetState extends State<AuctionFilterSheet> {
  late AuctionFilter _filter;

  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();
  final _mileageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;

    // Initialize text controllers
    if (_filter.priceMin != null) {
      _priceMinController.text = _filter.priceMin!.toStringAsFixed(0);
    }
    if (_filter.priceMax != null) {
      _priceMaxController.text = _filter.priceMax!.toStringAsFixed(0);
    }
    if (_filter.maxMileage != null) {
      _mileageController.text = _filter.maxMileage.toString();
    }
  }

  @override
  void dispose() {
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    Navigator.pop(context);
    widget.onApply(_filter);
  }

  void _clearFilters() {
    setState(() {
      _filter = const AuctionFilter();
      _priceMinController.clear();
      _priceMaxController.clear();
      _mileageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? ColorConstants.borderDark
                          : ColorConstants.borderLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Filter Auctions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear All'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Filter options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Make (Brand)
                    _buildSection(
                      title: 'Brand',
                      child: DropdownButtonFormField<String>(
                        value: _filter.make,
                        decoration: const InputDecoration(
                          hintText: 'Select brand',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Any')),
                          ...FilterOptions.makes.map((make) {
                            return DropdownMenuItem(value: make, child: Text(make));
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filter = _filter.copyWith(make: value ?? '');
                          });
                        },
                      ),
                    ),

                    // Year Range
                    _buildSection(
                      title: 'Year Range',
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _filter.yearFrom,
                              decoration: const InputDecoration(
                                labelText: 'From',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Any')),
                                ...FilterOptions.years.map((year) {
                                  return DropdownMenuItem(value: year, child: Text('$year'));
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _filter = _filter.copyWith(yearFrom: value);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _filter.yearTo,
                              decoration: const InputDecoration(
                                labelText: 'To',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Any')),
                                ...FilterOptions.years.map((year) {
                                  return DropdownMenuItem(value: year, child: Text('$year'));
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _filter = _filter.copyWith(yearTo: value);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price Range
                    _buildSection(
                      title: 'Price Range (PHP)',
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _priceMinController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                labelText: 'Min Price',
                                prefixText: '₱ ',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                final price = double.tryParse(value);
                                setState(() {
                                  _filter = _filter.copyWith(priceMin: price);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _priceMaxController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                labelText: 'Max Price',
                                prefixText: '₱ ',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                final price = double.tryParse(value);
                                setState(() {
                                  _filter = _filter.copyWith(priceMax: price);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Transmission
                    _buildSection(
                      title: 'Transmission',
                      child: DropdownButtonFormField<String>(
                        value: _filter.transmission,
                        decoration: const InputDecoration(
                          hintText: 'Select transmission',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Any')),
                          ...FilterOptions.transmissions.map((trans) {
                            return DropdownMenuItem(value: trans, child: Text(trans));
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filter = _filter.copyWith(transmission: value ?? '');
                          });
                        },
                      ),
                    ),

                    // Fuel Type
                    _buildSection(
                      title: 'Fuel Type',
                      child: DropdownButtonFormField<String>(
                        value: _filter.fuelType,
                        decoration: const InputDecoration(
                          hintText: 'Select fuel type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Any')),
                          ...FilterOptions.fuelTypes.map((fuel) {
                            return DropdownMenuItem(value: fuel, child: Text(fuel));
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filter = _filter.copyWith(fuelType: value ?? '');
                          });
                        },
                      ),
                    ),

                    // Drive Type
                    _buildSection(
                      title: 'Drive Type',
                      child: DropdownButtonFormField<String>(
                        value: _filter.driveType,
                        decoration: const InputDecoration(
                          hintText: 'Select drive type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Any')),
                          ...FilterOptions.driveTypes.map((drive) {
                            return DropdownMenuItem(value: drive, child: Text(drive));
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filter = _filter.copyWith(driveType: value ?? '');
                          });
                        },
                      ),
                    ),

                    // Condition
                    _buildSection(
                      title: 'Condition',
                      child: DropdownButtonFormField<String>(
                        value: _filter.condition,
                        decoration: const InputDecoration(
                          hintText: 'Select condition',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Any')),
                          ...FilterOptions.conditions.map((cond) {
                            return DropdownMenuItem(value: cond, child: Text(cond));
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filter = _filter.copyWith(condition: value ?? '');
                          });
                        },
                      ),
                    ),

                    // Max Mileage
                    _buildSection(
                      title: 'Maximum Mileage (km)',
                      child: TextField(
                        controller: _mileageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          hintText: 'Enter max mileage',
                          suffixText: 'km',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final mileage = int.tryParse(value);
                          setState(() {
                            _filter = _filter.copyWith(maxMileage: mileage);
                          });
                        },
                      ),
                    ),

                    // Exterior Color
                    _buildSection(
                      title: 'Exterior Color',
                      child: DropdownButtonFormField<String>(
                        value: _filter.exteriorColor,
                        decoration: const InputDecoration(
                          hintText: 'Select color',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Any')),
                          ...FilterOptions.colors.map((color) {
                            return DropdownMenuItem(value: color, child: Text(color));
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filter = _filter.copyWith(exteriorColor: value ?? '');
                          });
                        },
                      ),
                    ),

                    // Province
                    _buildSection(
                      title: 'Province/Region',
                      child: DropdownButtonFormField<String>(
                        value: _filter.province,
                        decoration: const InputDecoration(
                          hintText: 'Select province',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Any')),
                          ...FilterOptions.regions.map((region) {
                            return DropdownMenuItem(value: region, child: Text(region));
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filter = _filter.copyWith(province: value ?? '');
                          });
                        },
                      ),
                    ),

                    // Ending Soon Toggle
                    _buildSection(
                      title: 'Special Filters',
                      child: SwitchListTile(
                        title: const Text('Ending Soon (within 24 hours)'),
                        value: _filter.endingSoon ?? false,
                        onChanged: (value) {
                          setState(() {
                            _filter = _filter.copyWith(endingSoon: value);
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 80), // Space for bottom button
                  ],
                ),
              ),

              // Apply button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? ColorConstants.backgroundSecondaryDark
                      : ColorConstants.backgroundSecondaryLight,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? ColorConstants.borderDark
                          : ColorConstants.borderLight,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: FilledButton(
                    onPressed: _applyFilters,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      'Apply Filters${_filter.hasActiveFilters ? ' (${_filter.activeFilterCount})' : ''}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

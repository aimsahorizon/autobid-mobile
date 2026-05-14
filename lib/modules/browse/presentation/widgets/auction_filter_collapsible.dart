import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/auction_filter.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/filter_options.dart';

class AuctionFilterCollapsible extends StatefulWidget {
  final AuctionFilter initialFilter;
  final Function(AuctionFilter) onApply;
  final VoidCallback onClear;

  const AuctionFilterCollapsible({
    super.key,
    required this.initialFilter,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<AuctionFilterCollapsible> createState() =>
      _AuctionFilterCollapsibleState();
}

class _AuctionFilterCollapsibleState extends State<AuctionFilterCollapsible> {
  late AuctionFilter _filter;
  bool _isExpanded = false;

  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();
  final _mileageController = TextEditingController();
  final _modelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _syncControllers();
  }

  @override
  void didUpdateWidget(AuctionFilterCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter) {
      _filter = widget.initialFilter;
      _syncControllers();
    }
  }

  void _syncControllers() {
    _priceMinController.text = _filter.priceMin?.toStringAsFixed(0) ?? '';
    _priceMaxController.text = _filter.priceMax?.toStringAsFixed(0) ?? '';
    _mileageController.text = _filter.maxMileage?.toString() ?? '';
    _modelController.text = _filter.model ?? '';
  }

  @override
  void dispose() {
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _mileageController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    widget.onApply(_filter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get screen height to bound the inner scrollable area so it doesn't overflow RenderFlex
    final maxFilterHeight = MediaQuery.of(context).size.height * 0.48;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ColorConstants.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FILTERS & SORTING',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxFilterHeight),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildAccordion(
                            title: 'Auction Type',
                            isActive:
                                _filter.auctionType != null &&
                                _filter.auctionType!.isNotEmpty,
                            child: _buildAuctionTypeSelector(theme),
                          ),

                          _buildAccordion(
                            title: 'Brand',
                            isActive:
                                _filter.make != null &&
                                _filter.make!.isNotEmpty,
                            child: _buildDropdown<String>(
                              value: _filter.make,
                              items: FilterOptions.makes,
                              onChanged: (val) => setState(
                                () =>
                                    _filter = _filter.copyWith(make: val ?? ''),
                              ),
                            ),
                          ),

                          _buildAccordion(
                            title: 'Model',
                            isActive:
                                _filter.model != null &&
                                _filter.model!.isNotEmpty,
                            child: _buildTextField(
                              controller: _modelController,
                              hint: 'Enter model',
                              onChanged: (val) => setState(
                                () => _filter = _filter.copyWith(model: val),
                              ),
                            ),
                          ),

                          _buildAccordion(
                            title: 'Year Range',
                            isActive:
                                _filter.yearFrom != null ||
                                _filter.yearTo != null,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown<int>(
                                    hint: 'From',
                                    value: _filter.yearFrom,
                                    items: FilterOptions.years,
                                    onChanged: (val) => setState(
                                      () => _filter = _filter.copyWith(
                                        yearFrom: val,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDropdown<int>(
                                    hint: 'To',
                                    value: _filter.yearTo,
                                    items: FilterOptions.years,
                                    onChanged: (val) => setState(
                                      () => _filter = _filter.copyWith(
                                        yearTo: val,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _buildAccordion(
                            title: 'Price Range',
                            isActive:
                                _filter.priceMin != null ||
                                _filter.priceMax != null,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _priceMinController,
                                    hint: 'Min Price',
                                    prefix: '₱ ',
                                    isNumber: true,
                                    onChanged: (val) => setState(
                                      () => _filter = _filter.copyWith(
                                        priceMin: double.tryParse(val),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _priceMaxController,
                                    hint: 'Max Price',
                                    prefix: '₱ ',
                                    isNumber: true,
                                    onChanged: (val) => setState(
                                      () => _filter = _filter.copyWith(
                                        priceMax: double.tryParse(val),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _buildAccordion(
                            title: 'Transmission',
                            isActive:
                                _filter.transmission != null &&
                                _filter.transmission!.isNotEmpty,
                            child: _buildDropdown<String>(
                              value: _filter.transmission,
                              items: FilterOptions.transmissions,
                              onChanged: (val) => setState(
                                () => _filter = _filter.copyWith(
                                  transmission: val ?? '',
                                ),
                              ),
                            ),
                          ),

                          _buildAccordion(
                            title: 'Fuel Type',
                            isActive:
                                _filter.fuelType != null &&
                                _filter.fuelType!.isNotEmpty,
                            child: _buildDropdown<String>(
                              value: _filter.fuelType,
                              items: FilterOptions.fuelTypes,
                              onChanged: (val) => setState(
                                () => _filter = _filter.copyWith(
                                  fuelType: val ?? '',
                                ),
                              ),
                            ),
                          ),

                          _buildAccordion(
                            title: 'Drive Type',
                            isActive:
                                _filter.driveType != null &&
                                _filter.driveType!.isNotEmpty,
                            child: _buildDropdown<String>(
                              value: _filter.driveType,
                              items: FilterOptions.driveTypes,
                              onChanged: (val) => setState(
                                () => _filter = _filter.copyWith(
                                  driveType: val ?? '',
                                ),
                              ),
                            ),
                          ),

                          _buildAccordion(
                            title: 'Condition',
                            isActive:
                                _filter.condition != null &&
                                _filter.condition!.isNotEmpty,
                            child: _buildDropdown<String>(
                              value: _filter.condition,
                              items: FilterOptions.conditions,
                              onChanged: (val) => setState(
                                () => _filter = _filter.copyWith(
                                  condition: val ?? '',
                                ),
                              ),
                            ),
                          ),

                          _buildAccordion(
                            title: 'Max Mileage',
                            isActive: _filter.maxMileage != null,
                            child: _buildTextField(
                              controller: _mileageController,
                              hint: 'Max Mileage (km)',
                              isNumber: true,
                              suffix: ' km',
                              onChanged: (val) => setState(
                                () => _filter = _filter.copyWith(
                                  maxMileage: int.tryParse(val),
                                ),
                              ),
                            ),
                          ),

                          _buildAccordion(
                            title: 'Color',
                            isActive:
                                _filter.exteriorColor != null &&
                                _filter.exteriorColor!.isNotEmpty,
                            child: _buildDropdown<String>(
                              value: _filter.exteriorColor,
                              items: FilterOptions.colors,
                              onChanged: (val) => setState(
                                () => _filter = _filter.copyWith(
                                  exteriorColor: val ?? '',
                                ),
                              ),
                            ),
                          ),

                          _buildAccordion(
                            title: 'Province',
                            isActive:
                                _filter.province != null &&
                                _filter.province!.isNotEmpty,
                            child: _buildDropdown<String>(
                              value: _filter.province,
                              items: FilterOptions.regions,
                              onChanged: (val) => setState(
                                () => _filter = _filter.copyWith(
                                  province: val ?? '',
                                ),
                              ),
                            ),
                          ),

                          _buildAccordion(
                            title: 'Visibility',
                            isActive:
                                _filter.visibility != null &&
                                _filter.visibility!.isNotEmpty,
                            child: _buildDropdown<String>(
                              value: _filter.visibility,
                              items: const ['public', 'private'],
                              onChanged: (val) => setState(
                                () => _filter = _filter.copyWith(
                                  visibility: val ?? '',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filter = const AuctionFilter();
                              _syncControllers();
                            });
                            widget.onClear();
                            setState(() => _isExpanded = false);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilters();
                            setState(() => _isExpanded = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildAccordion({
    required String title,
    required Widget child,
    required bool isActive,
  }) {
    return _FilterAccordionItem(title: title, isActive: isActive, child: child);
  }

  Widget _buildAuctionTypeSelector(ThemeData theme) {
    const items = [
      (label: 'All', value: ''),
      (label: 'Open', value: 'open'),
      (label: 'Exclusive', value: 'exclusive'),
      (label: 'Mystery', value: 'mystery'),
    ];

    Color colorFor(String value) {
      switch (value) {
        case 'open':
          return ColorConstants.success;
        case 'exclusive':
          return ColorConstants.warning;
        case 'mystery':
          return ColorConstants.primary;
        default:
          return ColorConstants.primary;
      }
    }

    IconData iconFor(String value) {
      switch (value) {
        case 'open':
          return Icons.public;
        case 'exclusive':
          return Icons.verified_user_outlined;
        case 'mystery':
          return Icons.help_outline;
        default:
          return Icons.dashboard_outlined;
      }
    }

    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = (_filter.auctionType ?? '') == item.value;
          final color = colorFor(item.value);

          return InkWell(
            onTap: () {
              setState(() {
                _filter = _filter.copyWith(auctionType: item.value);
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 96,
              height: 76,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: color.withValues(alpha: 0.3))
                      : Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(iconFor(item.value), color: color, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String hint = 'Any',
  }) {
    final resolvedValue = (value is String && value.isEmpty) ? null : value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: resolvedValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          items: [
            DropdownMenuItem<T>(value: null, child: const Text('Any')),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  item.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    String? suffix,
    bool isNumber = false,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          suffixText: suffix,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _FilterAccordionItem extends StatefulWidget {
  final String title;
  final Widget child;
  final bool isActive;

  const _FilterAccordionItem({
    required this.title,
    required this.child,
    this.isActive = false,
  });

  @override
  State<_FilterAccordionItem> createState() => _FilterAccordionItemState();
}

class _FilterAccordionItemState extends State<_FilterAccordionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: widget.isActive
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: widget.isActive ? ColorConstants.primary : null,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.remove : Icons.add,
                  color: widget.isActive
                      ? ColorConstants.primary
                      : Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: widget.child,
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

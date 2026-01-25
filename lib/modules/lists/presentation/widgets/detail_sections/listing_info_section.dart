import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../domain/entities/listing_detail_entity.dart';

class ListingInfoSection extends StatefulWidget {
  final ListingDetailEntity listing;

  const ListingInfoSection({super.key, required this.listing});

  @override
  State<ListingInfoSection> createState() => _ListingInfoSectionState();
}

class _ListingInfoSectionState extends State<ListingInfoSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: ColorConstants.primary,
            unselectedLabelColor: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
            indicatorColor: ColorConstants.primary,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Specs'),
              Tab(text: 'Condition'),
              Tab(text: 'Documents'),
              Tab(text: 'Photos'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(isDark),
                _buildSpecsTab(isDark),
                _buildConditionTab(isDark),
                _buildDocumentsTab(isDark),
                _buildPhotosTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.listing.description != null) ...[
          Text(
            'Description',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            widget.listing.description!,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (widget.listing.features != null && widget.listing.features!.isNotEmpty) ...[
          Text(
            'Features',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.listing.features!.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  feature,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ColorConstants.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (widget.listing.knownIssues != null) ...[
          Text(
            'Known Issues',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.listing.knownIssues!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSpecGroup(
          'Engine & Performance',
          [
            if (widget.listing.engineType != null)
              _SpecRow('Engine Type', widget.listing.engineType!),
            if (widget.listing.engineDisplacement != null)
              _SpecRow('Displacement', '${widget.listing.engineDisplacement}L'),
            if (widget.listing.cylinderCount != null)
              _SpecRow('Cylinders', '${widget.listing.cylinderCount}'),
            if (widget.listing.horsepower != null)
              _SpecRow('Horsepower', '${widget.listing.horsepower} hp'),
            if (widget.listing.torque != null)
              _SpecRow('Torque', '${widget.listing.torque} Nm'),
            if (widget.listing.transmission != null)
              _SpecRow('Transmission', widget.listing.transmission!),
            if (widget.listing.fuelType != null)
              _SpecRow('Fuel Type', widget.listing.fuelType!),
            if (widget.listing.driveType != null)
              _SpecRow('Drive Type', widget.listing.driveType!),
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildSpecGroup(
          'Dimensions',
          [
            if (widget.listing.length != null)
              _SpecRow('Length', '${widget.listing.length} mm'),
            if (widget.listing.width != null)
              _SpecRow('Width', '${widget.listing.width} mm'),
            if (widget.listing.height != null)
              _SpecRow('Height', '${widget.listing.height} mm'),
            if (widget.listing.wheelbase != null)
              _SpecRow('Wheelbase', '${widget.listing.wheelbase} mm'),
            if (widget.listing.groundClearance != null)
              _SpecRow('Ground Clearance', '${widget.listing.groundClearance} mm'),
            if (widget.listing.seatingCapacity != null)
              _SpecRow('Seating', '${widget.listing.seatingCapacity} seats'),
            if (widget.listing.doorCount != null)
              _SpecRow('Doors', '${widget.listing.doorCount}'),
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildSpecGroup(
          'Exterior',
          [
            if (widget.listing.exteriorColor != null)
              _SpecRow('Color', widget.listing.exteriorColor!),
            if (widget.listing.paintType != null)
              _SpecRow('Paint Type', widget.listing.paintType!),
            if (widget.listing.rimType != null)
              _SpecRow('Rim Type', widget.listing.rimType!),
            if (widget.listing.rimSize != null)
              _SpecRow('Rim Size', widget.listing.rimSize!),
            if (widget.listing.tireSize != null)
              _SpecRow('Tire Size', widget.listing.tireSize!),
            if (widget.listing.tireBrand != null)
              _SpecRow('Tire Brand', widget.listing.tireBrand!),
          ],
          isDark,
        ),
      ],
    );
  }

  Widget _buildConditionTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.listing.condition != null)
          _InfoCard(
            icon: Icons.star,
            title: 'Overall Condition',
            value: widget.listing.condition!,
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        if (widget.listing.mileage != null)
          _InfoCard(
            icon: Icons.speed,
            title: 'Mileage',
            value: '${widget.listing.mileage!.toStringAsFixed(0)} km',
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        if (widget.listing.previousOwners != null)
          _InfoCard(
            icon: Icons.people,
            title: 'Previous Owners',
            value: '${widget.listing.previousOwners}',
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        if (widget.listing.usageType != null)
          _InfoCard(
            icon: Icons.drive_eta,
            title: 'Usage Type',
            value: widget.listing.usageType!,
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        if (widget.listing.hasModifications != null)
          _InfoCard(
            icon: Icons.build,
            title: 'Modifications',
            value: widget.listing.hasModifications!
                ? (widget.listing.modificationsDetails ?? 'Yes')
                : 'None',
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        if (widget.listing.hasWarranty != null)
          _InfoCard(
            icon: Icons.verified_user,
            title: 'Warranty',
            value: widget.listing.hasWarranty!
                ? (widget.listing.warrantyDetails ?? 'Yes')
                : 'No warranty',
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildDocumentsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.listing.plateNumber != null)
          _InfoCard(
            icon: Icons.pin,
            title: 'Plate Number',
            value: widget.listing.plateNumber!,
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        if (widget.listing.orcrStatus != null)
          _InfoCard(
            icon: Icons.description,
            title: 'OR/CR Status',
            value: widget.listing.orcrStatus!,
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        if (widget.listing.registrationStatus != null)
          _InfoCard(
            icon: Icons.check_circle,
            title: 'Registration Status',
            value: widget.listing.registrationStatus!,
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        if (widget.listing.registrationExpiry != null)
          _InfoCard(
            icon: Icons.calendar_today,
            title: 'Registration Expiry',
            value:
                '${widget.listing.registrationExpiry!.month}/${widget.listing.registrationExpiry!.day}/${widget.listing.registrationExpiry!.year}',
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        if (widget.listing.province != null)
          _InfoCard(
            icon: Icons.location_on,
            title: 'Location',
            value:
                '${widget.listing.cityMunicipality ?? ''}, ${widget.listing.province}',
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildPhotosTab(bool isDark) {
    final photoUrls = widget.listing.photoUrls;
    if (photoUrls == null || photoUrls.isEmpty) {
      return const Center(child: Text('No photos available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: photoUrls.keys.length,
      itemBuilder: (context, index) {
        final category = photoUrls.keys.elementAt(index);
        final urls = photoUrls[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: urls.length,
                itemBuilder: (context, photoIndex) {
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark ? ColorConstants.surfaceLight : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        urls[photoIndex],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildSpecGroup(String title, List<Widget> specs, bool isDark) {
    if (specs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? ColorConstants.surfaceLight.withValues(alpha: 0.3)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: specs),
        ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceLight.withValues(alpha: 0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ColorConstants.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

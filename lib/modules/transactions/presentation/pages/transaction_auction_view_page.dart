import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/transactions/presentation/controllers/transaction_controller.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/auction_detail_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/get_auction_detail_usecase.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';

class TransactionAuctionViewPage extends StatefulWidget {
  final String transactionId;
  final String userId;
  const TransactionAuctionViewPage({
    super.key,
    required this.transactionId,
    required this.userId,
  });

  @override
  State<TransactionAuctionViewPage> createState() =>
      _TransactionAuctionViewPageState();
}

class _TransactionAuctionViewPageState
    extends State<TransactionAuctionViewPage> {
  static const List<String> _photoCategories = [
    'Exterior',
    'Interior',
    'Engine',
    'Details',
    'Documents',
  ];

  static const List<String> _carInfoTabs = [
    'Overview',
    'Specs',
    'Condition',
    'Documents',
    'Config',
  ];

  late final TransactionController _controller;
  AuctionDetailEntity? _auctionDetail;
  bool _isLoading = true;
  String? _error;
  Color _overlayIconColor = Colors.white;
  String _activeTab = 'photos';
  String _activePhotoCategory = 'Exterior';
  int _activePhotoCategoryIndex = 0;
  String _activeCarInfoTab = 'Overview';

  @override
  void initState() {
    super.initState();
    _controller = GetIt.instance<TransactionController>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _controller.loadTransaction(widget.transactionId, widget.userId);
      final transaction = _controller.transaction;
      if (transaction == null) {
        setState(() {
          _error = 'Transaction not found';
          _isLoading = false;
        });
        return;
      }
      // Fetch auction detail using listingId
      final getAuctionDetailUseCase = GetIt.instance
          .get<GetAuctionDetailUseCase>();
      final result = await getAuctionDetailUseCase.call(
        auctionId: transaction.listingId,
        userId: widget.userId,
      );
      result.fold(
        (failure) => setState(() {
          _error = failure.message;
          _isLoading = false;
        }),
        (auction) {
          setState(() {
            _auctionDetail = auction;
            _isLoading = false;
          });
          _resolveOverlayIconColor(auction.carImageUrl);
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  bool _isAssetPath(String url) => url.startsWith('assets/');

  Widget _buildCarImage(String imageUrl) {
    if (_isAssetPath(imageUrl)) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: ColorConstants.backgroundSecondaryLight,
          child: const Icon(Icons.directions_car, size: 64),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: ColorConstants.backgroundSecondaryLight,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: ColorConstants.backgroundSecondaryLight,
        child: const Icon(Icons.directions_car, size: 64),
      ),
    );
  }

  List<String> _getCategories() => _photoCategories;

  Future<void> _resolveOverlayIconColor(String imageUrl) async {
    try {
      final provider = _isAssetPath(imageUrl)
          ? AssetImage(imageUrl) as ImageProvider
          : CachedNetworkImageProvider(imageUrl);

      final stream = provider.resolve(const ImageConfiguration());
      final completer = Completer<ui.Image>();

      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          if (!completer.isCompleted) {
            completer.complete(info.image);
          }
          stream.removeListener(listener);
        },
        onError: (_, __) {
          if (!completer.isCompleted) {
            completer.completeError('Unable to resolve image');
          }
          stream.removeListener(listener);
        },
      );

      stream.addListener(listener);

      final image = await completer.future;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return;

      final bytes = data.buffer.asUint8List();
      final width = image.width;
      final sampleHeight = math.max(1, (image.height * 0.24).round());

      double total = 0;
      int count = 0;

      for (int y = 0; y < sampleHeight; y += 8) {
        for (int x = 0; x < width; x += 8) {
          final index = (y * width + x) * 4;
          if (index + 2 >= bytes.length) continue;
          final r = bytes[index] / 255;
          final g = bytes[index + 1] / 255;
          final b = bytes[index + 2] / 255;
          total += (0.299 * r) + (0.587 * g) + (0.114 * b);
          count++;
        }
      }

      if (count == 0) return;
      final avgLuma = total / count;

      if (!mounted) return;
      setState(() {
        _overlayIconColor = avgLuma > 0.55 ? Colors.black : Colors.white;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _overlayIconColor = Colors.white;
      });
    }
  }

  String _formatMoney(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  List<String> _getCurrentPhotos() {
    return _auctionDetail!.photos.getByCategory(_activePhotoCategory);
  }

  int get _activeCarInfoTabIndex {
    final index = _carInfoTabs.indexOf(_activeCarInfoTab);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _auctionDetail == null
          ? const Center(child: Text('Auction details not found'))
          : CustomScrollView(
              slivers: [
                // Car Image Header with Back and Refresh buttons
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: _overlayIconColor,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 6),
                        Shadow(color: Colors.white24, blurRadius: 4),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: _loadData,
                      icon: Icon(
                        Icons.refresh,
                        color: _overlayIconColor,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6),
                          Shadow(color: Colors.white24, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildCarImage(_auctionDetail!.carImageUrl),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.45),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 20,
                          child: Text(
                            _auctionDetail!.carName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Gradient Card with Car Name and Price
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFAD5FFF), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _auctionDetail!.carName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '₱${_formatMoney(_auctionDetail!.currentBid)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildContentCard(isDark),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Widget _buildContentCard(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final muted = isDark ? Colors.grey[300]! : Colors.grey[700]!;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPrimaryTabs(isDark, textColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: _activeTab == 'photos'
                ? _buildPhotosContent(isDark, muted)
                : _buildCarInfoSections(isDark, muted),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryTabs(bool isDark, Color textColor) {
    final inactiveBg = isDark
        ? const ui.Color.fromARGB(0, 39, 39, 42)
        : const ui.Color.fromARGB(0, 242, 243, 245);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'photos'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: _activeTab == 'photos'
                    ? const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                          bottomLeft: Radius.zero,
                        ),
                      )
                    : BoxDecoration(color: Colors.transparent),
                child: Text(
                  'Photos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _activeTab == 'photos' ? Colors.white : textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'info'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: _activeTab == 'info'
                    ? const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.zero,
                        ),
                      )
                    : BoxDecoration(color: inactiveBg),
                child: Text(
                  'Car Info',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _activeTab == 'info' ? Colors.white : textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosContent(bool isDark, Color mutedText) {
    final photos = _getCurrentPhotos();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _getCategories().asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final count = _auctionDetail!.photos
                  .getByCategory(category)
                  .length;
              final isActive = _activePhotoCategory == category;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _activePhotoCategory = category;
                      _activePhotoCategoryIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white,
                                ui.Color.fromARGB(255, 157, 100, 255),
                              ],
                            )
                          : null,
                      color: isActive
                          ? null
                          : (isDark
                                ? const ui.Color.fromARGB(0, 48, 48, 52)
                                : const ui.Color.fromARGB(0, 233, 235, 239)),
                      border: Border.all(
                        color: isActive
                            ? const ui.Color.fromARGB(255, 113, 31, 255)
                            : const ui.Color.fromARGB(255, 155, 164, 176),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$category ($count)',
                      style: TextStyle(
                        color: isActive
                            ? const ui.Color.fromARGB(255, 113, 31, 255)
                            : const ui.Color.fromARGB(255, 155, 164, 176),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_photoCategories.length, (index) {
              final isActive = index == _activePhotoCategoryIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 24 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFB4BAC6),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          itemCount: photos.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final url = photos[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: const Color(0xFFE5E7EB),
                child: _isAssetPath(url)
                    ? Image.asset(url, fit: BoxFit.cover)
                    : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCarInfoSections(bool isDark, Color mutedText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _carInfoTabs.map((tab) {
              final isActive = _activeCarInfoTab == tab;
              return Padding(
                padding: const EdgeInsets.only(right: 0),
                child: GestureDetector(
                  onTap: () => setState(() => _activeCarInfoTab = tab),
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const ui.Color.fromARGB(255, 224, 205, 255)
                          : const ui.Color.fromARGB(0, 124, 58, 237),
                    ),
                    child: Text(
                      textAlign: TextAlign.center,
                      tab,
                      style: TextStyle(
                        color: isActive ? const Color(0xFF7C3AED) : mutedText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_carInfoTabs.length, (index) {
              final isActive = index == _activeCarInfoTabIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 24 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFB4BAC6),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        Column(children: _buildCarInfoContent()),
      ],
    );
  }

  List<Widget> _buildCarInfoContent() {
    final a = _auctionDetail!;

    switch (_activeCarInfoTab) {
      case 'Overview':
        return _buildSectionRows([
          _row('Brand', a.brand),
          _row('Model', a.model),
          _row('Variant', a.variant),
          _row('Year', a.year.toString()),
          _row(
            'Mileage',
            a.mileage != null ? '${a.mileage!.toStringAsFixed(0)} km' : null,
          ),
          _row('Transmission', a.transmission),
          _row('Fuel Type', a.fuelType),
          _row('Drive Type', a.driveType),
          _row('Color', a.exteriorColor),
        ]);
      case 'Specs':
        return _buildSectionRows([
          _row('Engine', a.engineType),
          _row(
            'Displacement',
            a.engineDisplacement != null ? '${a.engineDisplacement}L' : null,
          ),
          _row('Cylinders', a.cylinderCount?.toString()),
          _row(
            'Horsepower',
            a.horsepower != null ? '${a.horsepower} hp' : null,
          ),
          _row('Torque', a.torque != null ? '${a.torque} Nm' : null),
          _row(
            'Length',
            a.length != null ? '${a.length!.toStringAsFixed(0)} mm' : null,
          ),
          _row(
            'Width',
            a.width != null ? '${a.width!.toStringAsFixed(0)} mm' : null,
          ),
          _row(
            'Height',
            a.height != null ? '${a.height!.toStringAsFixed(0)} mm' : null,
          ),
          _row(
            'Wheelbase',
            a.wheelbase != null
                ? '${a.wheelbase!.toStringAsFixed(0)} mm'
                : null,
          ),
          _row(
            'Ground Clearance',
            a.groundClearance != null
                ? '${a.groundClearance!.toStringAsFixed(0)} mm'
                : null,
          ),
          _row(
            'Seating',
            a.seatingCapacity != null ? '${a.seatingCapacity} seats' : null,
          ),
          _row('Doors', a.doorCount?.toString()),
          _row(
            'Fuel Tank',
            a.fuelTankCapacity != null
                ? '${a.fuelTankCapacity!.toStringAsFixed(0)}L'
                : null,
          ),
          _row(
            'Curb Weight',
            a.curbWeight != null
                ? '${a.curbWeight!.toStringAsFixed(0)} kg'
                : null,
          ),
          _row(
            'Gross Weight',
            a.grossWeight != null
                ? '${a.grossWeight!.toStringAsFixed(0)} kg'
                : null,
          ),
          _row('Color', a.exteriorColor),
          _row('Paint Type', a.paintType),
          _row('Rim Type', a.rimType),
          _row('Rim Size', a.rimSize),
          _row('Tire Size', a.tireSize),
          _row('Tire Brand', a.tireBrand),
        ]);
      case 'Condition':
        return _buildSectionRows([
          _row('Overall Condition', a.condition),
          _row(
            'Mileage',
            a.mileage != null ? '${a.mileage!.toStringAsFixed(0)} km' : null,
          ),
          _row('Previous Owners', a.previousOwners?.toString()),
          _row('Usage Type', a.usageType),
          _row(
            'Modifications',
            a.hasModifications == null
                ? null
                : (a.hasModifications!
                      ? (a.modificationsDetails ?? 'Yes')
                      : 'None'),
          ),
          _row(
            'Warranty',
            a.hasWarranty == null
                ? null
                : (a.hasWarranty!
                      ? (a.warrantyDetails ?? 'Yes')
                      : 'No warranty'),
          ),
          _row('Known Issues', a.knownIssues),
        ]);
      case 'Documents':
        return _buildSectionRows([
          _row('Deed of Sale', a.deedOfSaleUrl != null ? 'Verified' : null),
          _row('Plate Number', a.plateNumber),
          _row('Chassis Number (VIN)', a.chassisNumber),
          _row('OR/CR Status', a.orcrStatus),
          _row('Registration', a.registrationStatus),
          _row(
            'Registration Expiry',
            a.registrationExpiry != null
                ? '${a.registrationExpiry!.month}/${a.registrationExpiry!.day}/${a.registrationExpiry!.year}'
                : null,
          ),
          _row(
            'Location',
            (a.cityMunicipality == null && a.province == null)
                ? null
                : [
                    if (a.cityMunicipality != null) a.cityMunicipality,
                    if (a.province != null) a.province,
                  ].join(', '),
          ),
          _row(
            'Features',
            (a.features != null && a.features!.isNotEmpty)
                ? a.features!.join(', ')
                : null,
          ),
        ]);
      case 'Config':
        return _buildSectionRows([
          _row(
            'Bidding Type',
            a.biddingType == 'exclusive'
                ? 'Exclusive'
                : a.biddingType == 'mystery'
                ? 'Mystery'
                : 'Open',
          ),
          _row(
            'Required Tier',
            a.biddingType == 'exclusive'
                ? (a.exclusiveTier == 'silver'
                      ? 'Silver Only'
                      : a.exclusiveTier == 'gold'
                      ? 'Gold Only'
                      : 'Silver & Gold')
                : null,
          ),
          _row(
            'Increment Type',
            a.enableIncrementalBidding ? 'Dynamic' : 'Fixed',
          ),
          _row('Min Increment', '₱${_formatMoney(a.minBidIncrement)}'),
          _row('Buyer Deposit', '₱${_formatMoney(a.depositAmount)}'),
          _row('Snipe Guard', a.snipeGuardEnabled ? 'Enabled' : 'Disabled'),
          _row(
            'Extension',
            a.snipeGuardEnabled ? '+${a.snipeGuardExtendSeconds}s' : null,
          ),
          _row(
            'Reserve Price',
            a.reservePrice != null ? '₱${_formatMoney(a.reservePrice!)}' : null,
          ),
          _row('Reserve Met', a.isReserveMet ? 'Yes' : 'No'),
          _row('Watchers', a.watchersCount.toString()),
          _row('Total Bids', a.totalBids.toString()),
        ]);
      default:
        return [_buildInfoRow('Info', 'No data available.')];
    }
  }

  List<Widget> _buildSectionRows(List<MapEntry<String, String?>> entries) {
    final rows = entries.where((entry) => entry.value != null).toList();
    if (rows.isEmpty) {
      return [_buildInfoRow('Info', 'No data available for this section.')];
    }
    return rows.map((entry) => _buildInfoRow(entry.key, entry.value!)).toList();
  }

  MapEntry<String, String?> _row(String label, String? value) =>
      MapEntry<String, String?>(label, value);

  Widget _buildInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

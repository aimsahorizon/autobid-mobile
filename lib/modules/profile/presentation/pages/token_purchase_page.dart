import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/pricing_entity.dart';
import 'package:autobid_mobile/modules/profile/presentation/controllers/pricing_controller.dart';
import 'package:autobid_mobile/modules/profile/presentation/pages/paymongo_payment_page.dart';

class TokenPurchasePage extends StatefulWidget {
  final String userId;
  final PricingController controller;

  const TokenPurchasePage({
    super.key,
    required this.userId,
    required this.controller,
  });

  @override
  State<TokenPurchasePage> createState() => _TokenPurchasePageState();
}

class _TokenPurchasePageState extends State<TokenPurchasePage> {
  String? _selectedCardId;

  void _selectCard(String cardId) {
    setState(() {
      _selectedCardId = cardId;
    });
  }

  Future<void> _buyPackageBySpec({
    required TokenType type,
    required int tokens,
  }) async {
    TokenPackageEntity? selected;
    for (final package in widget.controller.packages) {
      if (package.type == type && package.tokens == tokens) {
        selected = package;
        break;
      }
    }

    if (selected == null) {
      if (!mounted) return;
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        const SnackBar(
          content: Text('Package is currently unavailable. Please try again.'),
          backgroundColor: ColorConstants.error,
        ),
      );
      return;
    }

    await _purchasePackage(selected);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadUserPricing(widget.userId);
    });
  }

  Future<void> _purchasePackage(TokenPackageEntity package) async {
    // Navigate to PayMongo payment page
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PayMongoPaymentPage(
          package: package,
          userId: widget.userId,
          onSuccess: () {
            // Reload pricing data after successful payment
            widget.controller.loadUserPricing(widget.userId);
          },
        ),
      ),
    );

    // If payment was successful, show success message
    if (result == true && mounted) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Text('Successfully purchased ${package.description}'),
          backgroundColor: ColorConstants.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Tokens')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.error != null) {
            return Center(child: Text(widget.controller.error!));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTokenBalanceHeader(theme),
                const SizedBox(height: 28),

                // Bidding Tokens Section
                Text(
                  'Bidding Tokens',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Each bid consumes 1 bidding token',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildBiddingTokenCard(
                        isSelected: _selectedCardId == 'bidding_5',
                        onCardTap: () => _selectCard('bidding_5'),
                        onBuyTap: () => _buyPackageBySpec(
                          type: TokenType.bidding,
                          tokens: 5,
                        ),
                        title: '5 Bidding Tokens',
                        price: 99,
                        iconAssetPath:
                            'z/inspiration_images/profile_module/single_bid_token.svg',
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBiddingTokenCard(
                        isSelected: _selectedCardId == 'bidding_25',
                        onCardTap: () => _selectCard('bidding_25'),
                        onBuyTap: () => _buyPackageBySpec(
                          type: TokenType.bidding,
                          tokens: 25,
                        ),
                        title: '25 Bidding Tokens',
                        price: 349,
                        iconAssetPath:
                            'z/inspiration_images/profile_module/multiple_bid_token.svg',
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBiddingTokenCard(
                  isSelected: _selectedCardId == 'bidding_100',
                  onCardTap: () => _selectCard('bidding_100'),
                  onBuyTap: () =>
                      _buyPackageBySpec(type: TokenType.bidding, tokens: 100),
                  title: '100 Bidding Tokens',
                  price: 1299,
                  iconAssetPath:
                      'z/inspiration_images/profile_module/bundle_bid_token.svg',
                  isDark: isDark,
                  theme: theme,
                  isFullWidth: true,
                  badgeText: 'MOST POPULAR',
                  subtitle: '₱12.99/token',
                ),

                const SizedBox(height: 32),

                // Listing Tokens Section
                Text(
                  'Listing Tokens',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Each listing submission consumes 1 listing token',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment
                      .end, // Align to bottom to handle badge height differences
                  children: [
                    Expanded(
                      child: _buildListingTokenCard(
                        isSelected: _selectedCardId == 'listing_5',
                        onCardTap: () => _selectCard('listing_5'),
                        onBuyTap: () => _buyPackageBySpec(
                          type: TokenType.listing,
                          tokens: 1,
                        ),
                        title: '1 Listing Token',
                        price: 199,
                        subtitle: 'Single Use',
                        iconAssetPath:
                            'z/inspiration_images/profile_module/single_list_token.svg',
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildListingTokenCard(
                        isSelected: _selectedCardId == 'listing_25',
                        onCardTap: () => _selectCard('listing_25'),
                        onBuyTap: () => _buyPackageBySpec(
                          type: TokenType.listing,
                          tokens: 3,
                        ),
                        title: '3 Listing Token',
                        price: 499,
                        subtitle: 'Save 16%',
                        iconAssetPath:
                            'z/inspiration_images/profile_module/multiple_list_token.svg',
                        isDark: isDark,
                        theme: theme,
                        iconScale: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildListingTokenCard(
                        isSelected: _selectedCardId == 'listing_100',
                        onCardTap: () => _selectCard('listing_100'),
                        onBuyTap: () => _buyPackageBySpec(
                          type: TokenType.listing,
                          tokens: 10,
                        ),
                        title: '10 Listing Token',
                        price: 1499,
                        subtitle: 'Single Use',
                        iconAssetPath:
                            'z/inspiration_images/profile_module/bundle_list_token.svg',
                        isDark: isDark,
                        theme: theme,
                        badgeText: 'BEST VALUE',
                        iconScale: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Secure checkout via top methods',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPaymentLogoContainer(
                            child: SvgPicture.asset(
                              'z/inspiration_images/profile_module/GCash_logo.svg',
                              width: 20,
                              height: 10,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 7),
                          _buildPaymentLogoContainer(
                            child: SvgPicture.asset(
                              'z/inspiration_images/profile_module/Visa_Inc._logo_(2021–present).svg',
                              width: 20,
                              height: 10,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 7),
                          _buildPaymentLogoContainer(
                            child: SvgPicture.asset(
                              'z/inspiration_images/profile_module/Mastercard-logo.svg',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                            ),
                            isToAdjust: true,
                          ),
                          const SizedBox(width: 7),
                          _buildPaymentLogoContainer(
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Color.fromARGB(
                                255,
                                8,
                                57,
                                130,
                              ), // Navy blue
                              size: 20,
                            ),
                            isToAdjust: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTokenBalanceHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF7A2CF2), Color(0xFF23003D)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D1378).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Token Balance',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTokenBalanceItem(
                  label: 'Bidding Tokens',
                  value: widget.controller.biddingTokens,
                  icon: Icons.gavel_rounded,
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: _buildTokenBalanceItem(
                  label: 'Listing Tokens',
                  value: widget.controller.listingTokens,
                  icon: Icons.format_list_bulleted_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenBalanceItem({
    required String label,
    required int value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 207, 184, 236),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: ColorConstants.primary, size: 28),
        ),
      ],
    );
  }

  Widget _buildBiddingTokenCard({
    required bool isSelected,
    required VoidCallback onCardTap,
    required VoidCallback onBuyTap,
    required String title,
    required double price,
    required String iconAssetPath,
    required bool isDark,
    required ThemeData theme,
    bool isFullWidth = false,
    String? badgeText,
    String? subtitle,
  }) {
    const double buyButtonWidth = 70;
    final ButtonStyle buyButtonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onCardTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? ColorConstants.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? ColorConstants.primary.withValues(alpha: 0.3)
                    : (isDark
                          ? ColorConstants.borderDark
                          : ColorConstants.borderLight),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: Color(0x557924E7),
                        blurRadius: 5,
                        spreadRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFullWidth) ...[
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 125,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₱${price.toStringAsFixed(0)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      (theme
                                              .textTheme
                                              .headlineMedium
                                              ?.fontSize ??
                                          28) *
                                      1.2,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: -25,
                          right: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              width: buyButtonWidth,
                              child: FilledButton(
                                onPressed: onBuyTap,
                                style: buyButtonStyle,
                                child: const Text('Buy'),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -10,
                          bottom: -20,
                          child: SvgPicture.asset(
                            iconAssetPath,
                            width: 215,
                            height: 159,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    height: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SvgPicture.asset(
                              iconAssetPath,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '₱${price.toStringAsFixed(0)}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        (theme.textTheme.titleLarge?.fontSize ??
                                            22) *
                                        1.2,
                                  ),
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(
                              width: buyButtonWidth,
                              child: FilledButton(
                                onPressed: onBuyTap,
                                style: buyButtonStyle,
                                child: const Text('Buy'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (badgeText != null)
            Positioned(
              top: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 188, 112, 255),
                        Color.fromARGB(255, 188, 112, 255),
                        Color.fromARGB(255, 142, 50, 234),
                        Color.fromARGB(255, 145, 45, 245),
                        Color.fromARGB(255, 145, 45, 245),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListingTokenCard({
    required bool isSelected,
    required VoidCallback onCardTap,
    required VoidCallback onBuyTap,
    required String title,
    required double price,
    required String subtitle,
    required String iconAssetPath,
    required bool isDark,
    required ThemeData theme,
    String? badgeText,
    double iconScale = 1.0,
  }) {
    const double buyButtonWidth = 70;
    final ButtonStyle buyButtonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    const double cardHeight = 250;

    String _formatListingTitle(String title) {
      final regex = RegExp(r'^(\\d+)\\s+Listing\\s*Token');
      final match = regex.firstMatch(title);
      if (match != null) {
        return '${match.group(1)} Listing\nToken';
      }
      if (title.contains('Listing Token')) {
        final parts = title.split(' ');
        if (parts.length >= 3) {
          return parts[0] + ' ' + parts[1] + '\n' + parts[2];
        }
      }
      return title.replaceFirst(' ', '\n');
    }

    double svgWidth = 90 * iconScale;
    double svgHeight = 72 * iconScale;
    if (iconScale > 1.1) {
      svgWidth = 90;
      svgHeight = 72;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onCardTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(top: (badgeText != null ? 10 : 0) + 5),
            height: cardHeight,
            decoration: BoxDecoration(
              color: isDark ? ColorConstants.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? ColorConstants.primary.withValues(alpha: 0.3)
                    : (isDark
                          ? ColorConstants.borderDark
                          : ColorConstants.borderLight),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: Color(0x557924E7),
                        blurRadius: 5,
                        spreadRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 15,
                    bottom: 10,
                    left: 8,
                    right: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: ColorConstants.primary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatListingTitle(title),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: svgWidth,
                        height: svgHeight,
                        child: SvgPicture.asset(
                          iconAssetPath,
                          width: svgWidth,
                          height: svgHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '₱${price.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                (theme.textTheme.titleMedium?.fontSize ?? 16) *
                                1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: buyButtonWidth,
                          child: FilledButton(
                            onPressed: onBuyTap,
                            style: buyButtonStyle,
                            child: const Text('Buy'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (badgeText != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 188, 112, 255),
                        Color.fromARGB(255, 188, 112, 255),
                        Color.fromARGB(255, 142, 50, 234),
                        Color.fromARGB(255, 145, 45, 245),
                        Color.fromARGB(255, 145, 45, 245),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentLogoContainer({
    required Widget child,
    bool? isToAdjust = false,
  }) {
    return Container(
      padding: isToAdjust!
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 5)
          : const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD9DDE3)),
      ),
      child: child,
    );
  }
}

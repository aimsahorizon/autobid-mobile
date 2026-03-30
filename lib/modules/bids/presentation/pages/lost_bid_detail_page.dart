import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../browse/presentation/pages/auction_detail_page.dart';
import '../../../browse/presentation/controllers/auction_detail_controller.dart';

class LostBidDetailPage extends StatefulWidget {
  final String auctionId;

  const LostBidDetailPage({
    super.key,
    required this.auctionId,
  });

  @override
  State<LostBidDetailPage> createState() => _LostBidDetailPageState();
}

class _LostBidDetailPageState extends State<LostBidDetailPage> {
  @override
  void initState() {
    super.initState();
    // Redirect to the main AuctionDetailPage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuctionDetailPage(
            auctionId: widget.auctionId,
            controller: GetIt.instance<AuctionDetailController>(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

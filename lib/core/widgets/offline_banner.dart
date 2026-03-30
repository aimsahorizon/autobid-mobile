import 'package:flutter/material.dart';
import '../constants/color_constants.dart';
import '../controllers/network_status_controller.dart';

class OfflineBanner extends StatelessWidget {
  final NetworkStatusController controller;

  const OfflineBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isOffline) return const SizedBox.shrink();

        return Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: ColorConstants.error,
            child: SafeArea(
              bottom: false,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'No Internet Connection. Showing cached data.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

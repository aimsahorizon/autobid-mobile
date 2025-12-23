import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../presentation/controllers/kyc_controller.dart';

class KycDocumentViewer extends StatefulWidget {
  final String title;
  final String filePath;
  final KycController controller;

  const KycDocumentViewer({
    super.key,
    required this.title,
    required this.filePath,
    required this.controller,
  });

  @override
  State<KycDocumentViewer> createState() => _KycDocumentViewerState();
}

class _KycDocumentViewerState extends State<KycDocumentViewer> {
  String? _documentUrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocumentUrl();
  }

  Future<void> _loadDocumentUrl() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = await widget.controller.getDocumentUrl(widget.filePath);
      if (mounted) {
        setState(() {
          _documentUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _documentUrl != null ? () => _showFullImage(context) : null,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Title bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ColorConstants.surfaceVariantLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            // Document preview
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: ColorConstants.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Failed to load',
              style: TextStyle(fontSize: 12),
            ),
            TextButton(
              onPressed: _loadDocumentUrl,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_documentUrl == null) {
      return Center(
        child: Icon(
          Icons.image_not_supported,
          color: ColorConstants.textSecondaryLight,
          size: 32,
        ),
      );
    }

    // Check if it's a PDF
    if (widget.filePath.toLowerCase().endsWith('.pdf')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 48,
              color: ColorConstants.primary,
            ),
            const SizedBox(height: 8),
            const Text(
              'PDF Document',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showFullImage(context),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View'),
            ),
          ],
        ),
      );
    }

    // Display image
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: Image.network(
            _documentUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: ColorConstants.error,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Failed to load image',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Overlay icon to indicate it's clickable
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.zoom_in,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context) {
    if (_documentUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: widget.filePath.toLowerCase().endsWith('.pdf')
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 100,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'PDF Viewer not implemented',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please download to view',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : Image.network(
                      _documentUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

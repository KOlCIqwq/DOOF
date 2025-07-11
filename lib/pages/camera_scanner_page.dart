// lib/pages/camera_scanner_page.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../models/food_item.dart';
import '../widgets/product_preview_widget.dart';
import 'food_detail_page.dart';

class CameraScannerPage extends StatefulWidget {
  const CameraScannerPage({super.key});
  @override
  State<CameraScannerPage> createState() => _CameraScannerPageState();
}

class _CameraScannerPageState extends State<CameraScannerPage>
    with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  static const platform = MethodChannel('barcode_scanner');
  String _debugMessage = 'Initializing...';
  String? _errorMessage;
  int _frameSkipCounter = 0;
  bool _isHandlingResult = false;

  FoodItem? _scannedProduct;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeCamera());
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No cameras found');
        return;
      }
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.startImageStream(_processImage);
    } catch (e) {
      if (mounted)
        setState(() => _errorMessage = 'Failed to initialize camera: $e');
    }
  }

  void _processImage(CameraImage image) async {
    if (_isHandlingResult) return;

    _frameSkipCounter++;
    if (_frameSkipCounter % 5 != 0) return;
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final result = await platform.invokeMethod('scanBarcode', {
        'planes': image.planes
            .map((p) => {'bytes': p.bytes, 'bytesPerRow': p.bytesPerRow})
            .toList(),
        'width': image.width,
        'height': image.height,
      });

      if (result != null && result is String && result.isNotEmpty && mounted) {
        _isHandlingResult = true;
        HapticFeedback.lightImpact();

        final product = FoodItem(
          barcode: result,
          name: 'Fresh Banana',
          brand:
              'Nature'
              's Produce',
          imageUrl:
              'https://images.unsplash.com/photo-1571771894824-c8fdc904a423?ixlib=rb-4.0.3&q=80&w=1080',
          scanDate: DateTime.now(),
          calories: 105,
          fat: 0.4,
          carbs: 27,
          protein: 1.3,
          nutrients: [
            'Potassium: 422mg',
            'Vitamin C: 10.3mg',
            'Fiber: 3.1g',
            'Sugar: 14g',
          ],
        );
        setState(() => _scannedProduct = product);
        _slideController.forward();
      }
    } catch (e) {
      // Handle error
    } finally {
      _isProcessing = false;
    }
  }

  void _addToInventory() {
    if (_scannedProduct != null) Navigator.pop(context, _scannedProduct);
  }

  void _dismissPreviewAndRescan() {
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _scannedProduct = null;
          _isHandlingResult = false;
        });
      }
    });
  }

  void _viewDetails() async {
    if (_scannedProduct == null) return;
    final result = await Navigator.push<FoodItem>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailPage(product: _scannedProduct!, showAddButton: true),
      ),
    );
    if (result != null && mounted) Navigator.pop(context, result);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    final newMode = _controller!.value.flashMode == FlashMode.torch
        ? FlashMode.off
        : FlashMode.torch;
    await _controller!.setFlashMode(newMode);
    setState(() {});
  }

  @override
  void dispose() {
    _slideController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The key change to make the background transparent.
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // The CameraPreview is the base layer and will now be visible behind the preview panel.
          if (_isInitialized && _controller != null)
            SizedBox.expand(child: CameraPreview(_controller!)),
          if (_isInitialized)
            CustomPaint(painter: ScannerOverlayPainter(), size: Size.infinite),
          if (!_isInitialized || _errorMessage != null) _buildStatusView(),
          if (_isInitialized) _buildTopControls(),
          if (_scannedProduct != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: ProductPreviewWidget(
                  product: _scannedProduct!,
                  onAddToInventory: _addToInventory,
                  onViewDetails: _viewDetails,
                ),
              ),
            ),
          _buildRescanButton(),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconButton(Icons.close, () => Navigator.pop(context)),
          _iconButton(
            _controller?.value.flashMode == FlashMode.torch
                ? Icons.flash_on
                : Icons.flash_off,
            _toggleFlash,
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.black38,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildRescanButton() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      bottom: _scannedProduct != null ? 170 : -100,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton.extended(
          onPressed: _dismissPreviewAndRescan,
          label: const Text('Scan Again'),
          icon: const Icon(Icons.refresh),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  Widget _buildStatusView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: _errorMessage != null
            ? Text(_errorMessage!, style: const TextStyle(color: Colors.red))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _debugMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final scanWindow = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.8,
      height: size.width * 0.5,
    );
    final scanWindowRRect = RRect.fromRectAndRadius(
      scanWindow,
      const Radius.circular(12),
    );
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.5);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(screenRect),
        Path()..addRRect(scanWindowRRect),
      ),
      backgroundPaint,
    );
    canvas.drawRRect(scanWindowRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

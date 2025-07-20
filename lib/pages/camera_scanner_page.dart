import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
/* import 'package:food/utils/quantity_parser.dart';
import 'package:openfoodfacts/openfoodfacts.dart'; */
import '../models/food_item.dart';
import '../widgets/product_preview_widget.dart';
import 'product_detail_page.dart';
import '../services/open_food_facts_api_service.dart';

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

  @override
  void dispose() {
    _slideController.dispose();
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
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
      if (mounted) {
        setState(() => _errorMessage = 'Failed to initialize camera: $e');
      }
    }
  }

  Future<FoodItem?> _fetchProduct(String barcode) async {
    /* try {
      final ProductQueryConfiguration configuration = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [ProductField.ALL],
        version: ProductQueryVersion.v3,
      );
      final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(
        configuration,
      );

      if (result.status == ProductResultV3.statusSuccess &&
          result.product != null) {
        final product = result.product!;
        final nutrimentsJson = product.nutriments?.toJson() ?? {};

        final packageSize = product.quantity?.isNotEmpty == true
            ? product.quantity!
            : '100 g';
        final initialGrams = QuantityParser.toGrams(
          QuantityParser.parse(packageSize),
        );

        return FoodItem(
          barcode: barcode,
          name: product.productName ?? 'N/A',
          brand: product.brands ?? 'N/A',
          imageUrl: product.imageFrontUrl ?? '',
          insertDate: DateTime.now(),
          packageSize: packageSize,
          inventoryGrams: initialGrams > 0 ? initialGrams : 100.0,
          nutriments: nutrimentsJson,
          fat: (nutrimentsJson['fat_100g'] as num?)?.toDouble() ?? 0.0,
          carbs:
              (nutrimentsJson['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0,
          protein: (nutrimentsJson['proteins_100g'] as num?)?.toDouble() ?? 0.0,
          isKnown: true,
        );
      }
    } catch (e) {
      debugPrint('Error fetching product: $e');
    }
    return null; */
    return await OpenFoodFactsApiService.fetchFoodItem(barcode);
  }

  void _processImage(CameraImage image) async {
    if (_isHandlingResult || _isProcessing) return;
    _frameSkipCounter++;
    if (_frameSkipCounter % 5 != 0) return;
    _isProcessing = true;

    try {
      final String? barcode = await platform.invokeMethod('scanBarcode', {
        'planes': image.planes
            .map((p) => {'bytes': p.bytes, 'bytesPerRow': p.bytesPerRow})
            .toList(),
        'width': image.width,
        'height': image.height,
      });

      if (barcode != null && barcode.isNotEmpty && mounted) {
        setState(() => _isHandlingResult = true);
        HapticFeedback.lightImpact();

        FoodItem? product = await _fetchProduct(barcode);

        product ??= FoodItem(
          barcode: barcode,
          name: 'Unknown Product',
          brand: 'Tap to add details',
          imageUrl: '',
          insertDate: DateTime.now(),
          packageSize: '100 g',
          inventoryGrams: 100.0,
          nutriments: const {},
          fat: 0.0,
          carbs: 0.0,
          protein: 0.0,
          isKnown: false,
        );

        if (!mounted) return;
        setState(() => _scannedProduct = product);
        _slideController.forward();
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      if (mounted) _isProcessing = false;
    }
  }

  void _resetScanner() {
    if (mounted) {
      setState(() {
        _scannedProduct = null;
        _isHandlingResult = false;
      });
    }
  }

  void _addToInventory() {
    if (_scannedProduct != null) Navigator.pop(context, _scannedProduct);
  }

  void _dismissPreviewAndRescan() {
    _slideController.reverse().then((_) => _resetScanner());
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
    try {
      final newMode = _controller!.value.flashMode == FlashMode.torch
          ? FlashMode.off
          : FlashMode.torch;
      await _controller!.setFlashMode(newMode);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized && _controller != null)
            CameraPreview(_controller!),
          if (_isInitialized)
            CustomPaint(painter: ScannerOverlayPainter(), size: Size.infinite),
          if (_isHandlingResult && _scannedProduct == null)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Fetching product...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
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
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initializing...',
                    style: TextStyle(color: Colors.white),
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

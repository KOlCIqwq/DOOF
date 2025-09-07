import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
/* import 'package:food/utils/quantity_parser.dart';
import 'package:openfoodfacts/openfoodfacts.dart'; */
import '../models/food_item.dart';
import '../widgets/product_preview_widget.dart';
import 'product_detail_page.dart';
import '../services/open_food_facts_api_service.dart';
import '../services/user_service.dart';

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
  bool isHandlingResult = false;

  FoodItem? _scannedProduct;
  late AnimationController slideController;
  late Animation<Offset> _slideAnimation;

  final UserService userService = UserService();

  @override
  void initState() {
    super.initState();
    slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(
          CurvedAnimation(parent: slideController, curve: Curves.easeOutBack),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) => initializeCamera());
  }

  @override
  void dispose() {
    slideController.dispose();
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  void showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // Initialize the camera for scanning
  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No cameras found');
        return;
      }
      // Select the first available camera
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
      // Start image stream for barcode processing
      await _controller!.startImageStream(processImage);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to initialize camera: $e');
      }
    }
  }

  /// Fetch product details from Open Food Facts API
  Future<FoodItem?> fetchProduct(String barcode) async {
    return await OpenFoodFactsApiService.fetchFoodItem(barcode);
  }

  /// Process camera image frames for barcode detection
  void processImage(CameraImage image) async {
    if (isHandlingResult || _isProcessing) return;
    _frameSkipCounter++;
    if (_frameSkipCounter % 5 != 0) return; // Process every 5th frame
    _isProcessing = true;

    try {
      // Invoke native method to scan barcode
      final String? barcode = await platform.invokeMethod('scanBarcode', {
        'planes': image.planes
            .map((p) => {'bytes': p.bytes, 'bytesPerRow': p.bytesPerRow})
            .toList(),
        'width': image.width,
        'height': image.height,
      });

      if (barcode != null && barcode.isNotEmpty && mounted) {
        setState(() => isHandlingResult = true);
        HapticFeedback.lightImpact(); // Provide haptic feedback

        FoodItem? product = await fetchProduct(barcode);

        // Create unknown product if not found
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
          categories: '',
          expirationDate: null,
        );

        try {
          await userService.upsertFoodItem(product);
          //showErrorSnackbar("immediately save food item to Supabase:");
        } catch (e) {
          // If this fails
          /* showErrorSnackbar(
            "Failed to immediately save food item to Supabase: $e",
          ); */
          // Scanning twice the same product will result an error, don't display it
        }

        if (!mounted) return;
        setState(() => _scannedProduct = product);
        slideController.forward(); // Animate product preview in
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      if (mounted) _isProcessing = false;
    }
  }

  /// Reset the scanner state and clear scanned product
  void resetScanner() {
    if (mounted) {
      setState(() {
        _scannedProduct = null;
        isHandlingResult = false;
      });
    }
  }

  /// Add the scanned product to inventory and navigate back
  void addToInventory() {
    if (_scannedProduct != null) Navigator.pop(context, _scannedProduct);
  }

  /// Dismiss product preview and restart scanning
  void dismissPreviewAndRescan() {
    slideController.reverse().then((_) => resetScanner());
  }

  /// View details of the scanned product
  void viewDetails() async {
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

  // Toggle camera flash on/off
  Future<void> toggleFlash() async {
    if (_controller == null) return;
    try {
      final newMode = _controller!.value.flashMode == FlashMode.torch
          ? FlashMode.off
          : FlashMode.torch;
      await _controller!.setFlashMode(newMode);
      if (mounted) setState(() {}); // Update UI
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
          // Camera preview
          if (_isInitialized && _controller != null)
            CameraPreview(_controller!),
          // Scanner overlay UI
          if (_isInitialized)
            CustomPaint(painter: ScannerOverlayPainter(), size: Size.infinite),
          // Loading indicator while fetching product
          if (isHandlingResult && _scannedProduct == null)
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
          // Status view (error or initializing)
          if (!_isInitialized || _errorMessage != null) buildStatusView(),
          // Top control buttons (close, flash)
          if (_isInitialized) buildTopControls(),
          // Product preview widget
          if (_scannedProduct != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: ProductPreviewWidget(
                  product: _scannedProduct!,
                  onAddToInventory: addToInventory,
                  onViewDetails: viewDetails,
                ),
              ),
            ),
          // Rescan button
          buildRescanButton(),
        ],
      ),
    );
  }

  // Build top control buttons (close, flash)
  Widget buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          iconButton(Icons.close, () => Navigator.pop(context)), // Close button
          iconButton(
            _controller?.value.flashMode == FlashMode.torch
                ? Icons.flash_on
                : Icons.flash_off,
            toggleFlash, // Toggle flash button
          ),
        ],
      ),
    );
  }

  // Helper widget for an icon button
  Widget iconButton(IconData icon, VoidCallback onPressed) {
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

  // Build the rescan button
  Widget buildRescanButton() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      bottom: _scannedProduct != null ? 170 : -100,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton.extended(
          onPressed: dismissPreviewAndRescan, // Dismiss preview and rescan
          label: const Text('Scan Again'),
          icon: const Icon(Icons.refresh),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  // Build the status view (initializing or error message)
  Widget buildStatusView() {
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

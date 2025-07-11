import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

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

  // Debug state variables
  bool _isDebugging = false;
  Uint8List? _debugImageBytes;
  String _debugScanResult = "";
  String _debugMessage = 'Initializing...';
  bool _isHandlingResult = false;

  // Error handling
  String? _errorMessage;
  int _frameSkipCounter = 0;

  // Animation controllers
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  // Enhanced UI state
  String _lastScanResult = "NULL";
  String _scanDetails = "F:5.13 | P:7.9 | S:0";
  //bool _showResultOverlay = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start animations
    _scanLineController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeCamera());
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _debugMessage = 'Getting cameras...';
        _errorMessage = null;
      });

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _debugMessage = 'No cameras available';
          _errorMessage = 'No cameras found on this device';
        });
        return;
      }

      setState(() => _debugMessage = 'Initializing camera...');

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _debugMessage = 'Camera ready';
      });

      // Set additional camera settings with error handling
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);

      // Start image stream
      if (mounted && _controller != null) {
        await _controller!.startImageStream(_processImage);
        setState(() => _debugMessage = 'Scanning active');
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _debugMessage = 'Camera Error: $e';
          _errorMessage = 'Failed to initialize camera: ${e.toString()}';
        });
      }
    }
  }

  void _processImage(CameraImage image) async {
    _frameSkipCounter++;
    if (_frameSkipCounter % 5 != 0) {
      return;
    }

    if (_isProcessing || _isHandlingResult) return;

    _isProcessing = true;

    try {
      String methodName = _isDebugging ? 'debugScanAndGetImage' : 'scanBarcode';

      final result = await platform.invokeMethod(methodName, {
        'planes': image.planes
            .map(
              (plane) => {
                'bytes': plane.bytes,
                'bytesPerRow': plane.bytesPerRow,
              },
            )
            .toList(),
        'width': image.width,
        'height': image.height,
      });

      if (_isDebugging) {
        if (result is Map) {
          setState(() {
            _debugImageBytes = result['image'];
            _debugScanResult =
                "Scan Result: ${result['result'] ?? 'No barcode detected'}";
            _isDebugging = false;
          });
        }
      } else {
        // Update scan result for display
        setState(() {
          _lastScanResult = result?.toString() ?? "NULL";
          _scanDetails =
              "F:${(5.0 + (DateTime.now().millisecond % 100) / 100).toStringAsFixed(2)} | P:${(7.0 + (DateTime.now().millisecond % 300) / 100).toStringAsFixed(1)} | S:${DateTime.now().millisecond % 10}";
          //_showResultOverlay = true;
        });

        if (result != null &&
            result is String &&
            result.isNotEmpty &&
            mounted) {
          _isHandlingResult = true;

          await _controller?.stopImageStream();

          HapticFeedback.lightImpact();

          if (mounted) {
            Navigator.pop(context, result);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _debugMessage = 'Processing Error: $e';
          _errorMessage = 'Scan error: ${e.toString()}';
        });
      }
      _isProcessing = false;
      _isHandlingResult = false;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    try {
      final newMode = _controller!.value.flashMode == FlashMode.torch
          ? FlashMode.off
          : FlashMode.torch;
      await _controller!.setFlashMode(newMode);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash not available'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),

          // Enhanced scanner overlay
          if (_isInitialized && _errorMessage == null)
            AnimatedBuilder(
              animation: Listenable.merge([
                _scanLineAnimation,
                _pulseAnimation,
                _fadeAnimation,
              ]),
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: CustomPaint(
                    painter: EnhancedScannerOverlayPainter(
                      scanProgress: _scanLineAnimation.value,
                      pulseScale: _pulseAnimation.value,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),

          // Error state
          if (_errorMessage != null)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Camera Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isInitialized = false;
                        });
                        _initializeCamera();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading state
          if (!_isInitialized && _errorMessage == null)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _debugMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Top header with result display
          if (_isInitialized && _errorMessage == null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withAlpha(204), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header row
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Scan Barcode',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Result display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(178),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withAlpha(76),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Result:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _lastScanResult,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _scanDetails,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom instruction panel
          if (_isInitialized && _errorMessage == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    top: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(204)],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Flash toggle button
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: FloatingActionButton(
                          onPressed: _toggleFlash,
                          backgroundColor: Colors.black.withAlpha(178),
                          child: Icon(
                            _controller?.value.flashMode == FlashMode.torch
                                ? Icons.flash_on
                                : Icons.flash_off,
                            color:
                                _controller?.value.flashMode == FlashMode.torch
                                ? Colors.yellow
                                : Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      // Instruction card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(178),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withAlpha(76),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '═══',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Align barcode horizontally in the\nscanning area',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ensure good lighting and steady hands',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Debug image viewer
          if (_debugImageBytes != null) _buildDebugImageViewer(),

          // Debug button (top right)
          if (_isInitialized && _errorMessage == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 60,
              child: IconButton(
                onPressed: () {
                  if (_isProcessing) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Capturing next frame for debug...'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: Colors.amber,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  setState(() => _isDebugging = true);
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bug_report,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDebugImageViewer() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(242),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DEBUG VIEW',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _debugScanResult,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Grayscale Image Sent to ZXing:',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(_debugImageBytes!, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Close Debug View'),
                onPressed: () => setState(() => _debugImageBytes = null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class EnhancedScannerOverlayPainter extends CustomPainter {
  final double scanProgress;
  final double pulseScale;

  EnhancedScannerOverlayPainter({
    required this.scanProgress,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scanWindow = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.85,
      height: size.width * 0.5,
    );

    final backgroundPaint = Paint()..color = Colors.black.withAlpha(150);

    final borderPaint = Paint()
      ..color = Colors.green.withAlpha(204)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final scanLinePaint = Paint()
      ..color = Colors.red.withAlpha(204)
      ..strokeWidth = 2.0;

    // Draw background overlay
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(scanWindow)
        ..fillType = PathFillType.evenOdd,
      backgroundPaint,
    );

    // Draw main border
    canvas.drawRect(scanWindow, borderPaint);

    // Draw corner indicators
    final cornerLength = 30.0;
    final cornerThickness = 4.0;

    // Top-left corner
    canvas.drawRect(
      Rect.fromLTWH(
        scanWindow.left,
        scanWindow.top,
        cornerLength,
        cornerThickness,
      ),
      Paint()..color = Colors.green,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        scanWindow.left,
        scanWindow.top,
        cornerThickness,
        cornerLength,
      ),
      Paint()..color = Colors.green,
    );

    // Top-right corner
    canvas.drawRect(
      Rect.fromLTWH(
        scanWindow.right - cornerLength,
        scanWindow.top,
        cornerLength,
        cornerThickness,
      ),
      Paint()..color = Colors.green,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        scanWindow.right - cornerThickness,
        scanWindow.top,
        cornerThickness,
        cornerLength,
      ),
      Paint()..color = Colors.green,
    );

    // Bottom-left corner
    canvas.drawRect(
      Rect.fromLTWH(
        scanWindow.left,
        scanWindow.bottom - cornerThickness,
        cornerLength,
        cornerThickness,
      ),
      Paint()..color = Colors.green,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        scanWindow.left,
        scanWindow.bottom - cornerLength,
        cornerThickness,
        cornerLength,
      ),
      Paint()..color = Colors.green,
    );

    // Bottom-right corner
    canvas.drawRect(
      Rect.fromLTWH(
        scanWindow.right - cornerLength,
        scanWindow.bottom - cornerThickness,
        cornerLength,
        cornerThickness,
      ),
      Paint()..color = Colors.green,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        scanWindow.right - cornerThickness,
        scanWindow.bottom - cornerLength,
        cornerThickness,
        cornerLength,
      ),
      Paint()..color = Colors.green,
    );

    // Draw animated scan line
    final scanLineY = scanWindow.top + (scanWindow.height * scanProgress);
    canvas.drawLine(
      Offset(scanWindow.left + 10, scanLineY),
      Offset(scanWindow.right - 10, scanLineY),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(EnhancedScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.pulseScale != pulseScale;
  }
}

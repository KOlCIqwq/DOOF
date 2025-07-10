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
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;

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

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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
        ResolutionPreset.high, // Use high resolution for better detection
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
      try {
        await _controller!.setFocusMode(FocusMode.auto);
        await _controller!.setExposureMode(ExposureMode.auto);
      } catch (e) {
        print('Camera settings error: $e');
        // Continue without failing - these are nice-to-have features
      }

      // Start image stream immediately without delay
      if (mounted && _controller != null) {
        await _controller!.startImageStream(_processImage);
        setState(() => _debugMessage = 'Scanning active');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _debugMessage = 'Camera Error: $e';
          _errorMessage = 'Failed to initialize camera: ${e.toString()}';
        });
      }
      print('Camera initialization error: $e');
    }
  }

  void _processImage(CameraImage image) async {
    // Skip frames more aggressively to reduce lag
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
        // Handle debug response
        if (result is Map) {
          setState(() {
            _debugImageBytes = result['image'];
            _debugScanResult =
                "Scan Result: ${result['result'] ?? 'No barcode detected'}";
            _isDebugging = false;
          });
        }
      } else {
        // Handle normal scan response
        if (result != null &&
            result is String &&
            result.isNotEmpty &&
            mounted) {
          _isHandlingResult = true;

          // Stop image stream before navigation
          try {
            await _controller?.stopImageStream();
          } catch (e) {
            print('Error stopping image stream: $e');
          }

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

      // Reset processing state on error
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
      print('Flash toggle error: $e');
      // Show a snackbar for user feedback
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
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Barcode',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.bug_report,
                color: Colors.amber,
                size: 20,
              ),
            ),
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
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (_controller?.value.flashMode == FlashMode.torch
                            ? Colors.yellow
                            : Colors.white)
                        .withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _controller?.value.flashMode == FlashMode.torch
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: _controller?.value.flashMode == FlashMode.torch
                    ? Colors.yellow
                    : Colors.white,
                size: 20,
              ),
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Camera preview - original approach without scaling
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
                    Text(
                      'Camera Error',
                      style: const TextStyle(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
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

          // Enhanced scanner overlay with animations
          if (_isInitialized && _errorMessage == null)
            AnimatedBuilder(
              animation: Listenable.merge([
                _scanLineAnimation,
                _pulseAnimation,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: EnhancedScannerOverlayPainter(
                    scanProgress: _scanLineAnimation.value,
                    pulseScale: _pulseAnimation.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          // Status indicator
          if (_isInitialized && _errorMessage == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ready to scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Debug image viewer
          if (_debugImageBytes != null) _buildDebugImageViewer(),
        ],
      ),
    );
  }

  Widget _buildDebugImageViewer() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
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
                  color: Colors.white.withOpacity(0.1),
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
      width: size.width * 0.8,
      height: size.width * 0.45,
    );

    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.6);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cornerPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final scanLinePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.8)
      ..strokeWidth = 2.0;

    // Draw background overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(scanWindow),
      ),
      backgroundPaint,
    );

    // Draw animated border with pulse effect
    canvas.save();
    canvas.translate(scanWindow.center.dx, scanWindow.center.dy);
    canvas.scale(pulseScale);
    canvas.translate(-scanWindow.center.dx, -scanWindow.center.dy);
    canvas.drawRect(scanWindow, borderPaint);
    canvas.restore();

    // Draw animated corner indicators
    final cornerLength = 25.0;
    final cornerOffset = 8.0;

    final corners = [
      // Top-left
      [
        Offset(scanWindow.left - cornerOffset, scanWindow.top - cornerOffset),
        Offset(scanWindow.left + cornerLength, scanWindow.top - cornerOffset),
      ],
      [
        Offset(scanWindow.left - cornerOffset, scanWindow.top - cornerOffset),
        Offset(scanWindow.left - cornerOffset, scanWindow.top + cornerLength),
      ],
      // Top-right
      [
        Offset(scanWindow.right - cornerLength, scanWindow.top - cornerOffset),
        Offset(scanWindow.right + cornerOffset, scanWindow.top - cornerOffset),
      ],
      [
        Offset(scanWindow.right + cornerOffset, scanWindow.top - cornerOffset),
        Offset(scanWindow.right + cornerOffset, scanWindow.top + cornerLength),
      ],
      // Bottom-left
      [
        Offset(
          scanWindow.left - cornerOffset,
          scanWindow.bottom - cornerLength,
        ),
        Offset(
          scanWindow.left - cornerOffset,
          scanWindow.bottom + cornerOffset,
        ),
      ],
      [
        Offset(
          scanWindow.left - cornerOffset,
          scanWindow.bottom + cornerOffset,
        ),
        Offset(
          scanWindow.left + cornerLength,
          scanWindow.bottom + cornerOffset,
        ),
      ],
      // Bottom-right
      [
        Offset(
          scanWindow.right - cornerLength,
          scanWindow.bottom + cornerOffset,
        ),
        Offset(
          scanWindow.right + cornerOffset,
          scanWindow.bottom + cornerOffset,
        ),
      ],
      [
        Offset(
          scanWindow.right + cornerOffset,
          scanWindow.bottom - cornerLength,
        ),
        Offset(
          scanWindow.right + cornerOffset,
          scanWindow.bottom + cornerOffset,
        ),
      ],
    ];

    for (final corner in corners) {
      canvas.drawLine(corner[0], corner[1], cornerPaint);
    }

    // Draw animated scan line
    final scanLineY = scanWindow.top + (scanWindow.height * scanProgress);
    canvas.drawLine(
      Offset(scanWindow.left + 20, scanLineY),
      Offset(scanWindow.right - 20, scanLineY),
      scanLinePaint,
    );

    // Add instruction text with better styling
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Position barcode within the frame',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, scanWindow.bottom + 40),
    );

    // Add tips text
    final tipsPainter = TextPainter(
      text: const TextSpan(
        text: 'Hold steady • Ensure good lighting',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    tipsPainter.layout();
    tipsPainter.paint(
      canvas,
      Offset((size.width - tipsPainter.width) / 2, scanWindow.bottom + 70),
    );
  }

  @override
  bool shouldRepaint(EnhancedScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.pulseScale != pulseScale;
  }
}

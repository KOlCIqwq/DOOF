package com.example.food // Make sure this matches your package name

import android.graphics.Bitmap
import android.graphics.Color
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import com.google.zxing.*
import com.google.zxing.common.HybridBinarizer
import java.io.ByteArrayOutputStream
import java.util.EnumSet
import java.util.HashMap

class MainActivity: FlutterActivity() {
    private val CHANNEL = "barcode_scanner"

    private val zxingReader: Reader = MultiFormatReader().apply {
        val hints = HashMap<DecodeHintType, Any>()
        hints[DecodeHintType.TRY_HARDER] = true
        hints[DecodeHintType.POSSIBLE_FORMATS] = EnumSet.of(
            BarcodeFormat.EAN_13, 
            BarcodeFormat.EAN_8, 
            BarcodeFormat.UPC_A,
            BarcodeFormat.UPC_E,
            BarcodeFormat.CODE_128,
            BarcodeFormat.CODE_39,
            BarcodeFormat.QR_CODE
        )
        setHints(hints)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanBarcode" -> handleScanBarcode(call, result)
                "debugScanAndGetImage" -> handleDebugScan(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleScanBarcode(call: MethodCall, result: MethodChannel.Result) {
        try {
            val source = getLuminanceSourceFromCall(call) ?: return result.success(null)
            val barcodeResult = tryMultipleOrientations(source)
            result.success(barcodeResult?.text)
        } catch (e: Exception) {
            result.error("NATIVE_ERROR", e.message, e.stackTraceToString())
        }
    }

    private fun handleDebugScan(call: MethodCall, result: MethodChannel.Result) {
        try {
            val source = getLuminanceSourceFromCall(call) ?: return result.success(null)
            
            val finalResult = tryMultipleOrientations(source)
            val debugImage = convertLuminanceSourceToJpeg(source)
            
            val response = mapOf(
                "result" to finalResult?.text,
                "image" to debugImage
            )
            result.success(response)

        } catch (e: Exception) {
            result.error("NATIVE_ERROR_DEBUG", e.message, e.stackTraceToString())
        }
    }

    private fun getLuminanceSourceFromCall(call: MethodCall): LuminanceSource? {
        val planes = call.argument<List<Map<String, Any>>>("planes") ?: return null
        val imageWidth = call.argument<Int>("width") ?: return null
        val imageHeight = call.argument<Int>("height") ?: return null
        val yPlane = planes[0]["bytes"] as ByteArray
        val yRowStride = planes[0]["bytesPerRow"] as Int

        // Create a luminance source for the full, unrotated (landscape) image
        val fullLandscapeSource = PlanarYUVLuminanceSource(
            yPlane, yRowStride, imageHeight, 0, 0, imageWidth, imageHeight, false
        )

        // Rotate the source to portrait to match the Flutter preview
        val rotatedPortraitSource = if (fullLandscapeSource.isRotateSupported) {
            fullLandscapeSource.rotateCounterClockwise().rotateCounterClockwise().rotateCounterClockwise()
        } else {
            rotateImageData90Clockwise(yPlane, imageWidth, imageHeight, yRowStride)
        }

        // Now crop the rotated source to the scanning area defined in the Flutter UI
        // UI proportions: width=85% of screen width, height=50% of screen width, centered.
        val portraitWidth = rotatedPortraitSource.width
        val portraitHeight = rotatedPortraitSource.height
        
        val cropWidth = (portraitWidth * 0.85).toInt()
        val cropHeight = (portraitWidth * 0.50).toInt() // Height is also relative to portrait width

        val cropLeft = (portraitWidth - cropWidth) / 2
        val cropTop = (portraitHeight - cropHeight) / 2

        // Ensure the source supports cropping and the dimensions are valid
        if (rotatedPortraitSource.isCropSupported && cropLeft >= 0 && cropTop >= 0 && cropWidth + cropLeft <= portraitWidth && cropHeight + cropTop <= portraitHeight) {
            try {
                return rotatedPortraitSource.crop(cropLeft, cropTop, cropWidth, cropHeight)
            } catch (e: Exception) {
                // If cropping fails, fall back to the full image.
            }
        }
        
        // If not croppable or dimensions are invalid, return the full rotated image as a fallback.
        return rotatedPortraitSource
    }

    private fun rotateImageData90Clockwise(
        originalData: ByteArray,
        originalWidth: Int,
        originalHeight: Int,
        originalRowStride: Int
    ): LuminanceSource {
        // For 90-degree clockwise rotation:
        // - New width = original height
        // - New height = original width
        // - Pixel at (x, y) in original becomes pixel at (originalHeight - 1 - y, x) in rotated
        
        val rotatedWidth = originalHeight
        val rotatedHeight = originalWidth
        val rotatedData = ByteArray(rotatedWidth * rotatedHeight)

        for (y in 0 until originalHeight) {
            for (x in 0 until originalWidth) {
                val originalIndex = y * originalRowStride + x
                val rotatedX = originalHeight - 1 - y
                val rotatedY = x
                val rotatedIndex = rotatedY * rotatedWidth + rotatedX
                
                if (originalIndex < originalData.size && rotatedIndex < rotatedData.size) {
                    rotatedData[rotatedIndex] = originalData[originalIndex]
                }
            }
        }

        return PlanarYUVLuminanceSource(
            rotatedData,      // Rotated Y plane data
            rotatedWidth,     // New width as row stride
            rotatedHeight,    // New height
            0,                // left offset
            0,                // top offset
            rotatedWidth,     // crop width
            rotatedHeight,    // crop height
            false             // reverseHorizontal
        )
    }

    private fun tryMultipleOrientations(source: LuminanceSource): Result? {
        var currentSource = source

        // Try decoding in up to 4 different orientations
        for (i in 1..4) {
            // Attempt to decode the image in its current orientation
            decode(currentSource)?.let { return it }

            // If it fails and we have more orientations to try, rotate the image.
            // No need to rotate on the final attempt.
            if (i < 4) {
                if (currentSource.isRotateSupported) {
                    currentSource = currentSource.rotateCounterClockwise()
                } else {
                    // If rotation is not supported at any point, we can't try other orientations.
                    break
                }
            }
        }

        // If no barcode was found in any orientation, return null.
        return null
    }

    private fun convertLuminanceSourceToJpeg(source: LuminanceSource): ByteArray {
        val bitmapWidth = source.width
        val bitmapHeight = source.height
        val luminanceBytes = source.matrix
        val pixels = IntArray(bitmapWidth * bitmapHeight)
        
        for (i in pixels.indices) {
            val luminance = luminanceBytes[i].toInt() and 0xFF
            pixels[i] = Color.rgb(luminance, luminance, luminance)
        }
        
        val bitmap = Bitmap.createBitmap(pixels, bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, stream)
        return stream.toByteArray()
    }

    private fun decode(source: LuminanceSource): Result? {
        val bitmap = BinaryBitmap(HybridBinarizer(source))
        return try {
            zxingReader.decode(bitmap)
        } catch (e: NotFoundException) {
            null
        } catch (e: Exception) {
            null
        } finally {
            zxingReader.reset()
        }
    }
}
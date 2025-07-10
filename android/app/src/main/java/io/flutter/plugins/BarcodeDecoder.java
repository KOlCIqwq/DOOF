package io.flutter.plugins;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.LuminanceSource;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.PlanarYUVLuminanceSource; 
import com.google.zxing.Reader;
import com.google.zxing.Result;
import com.google.zxing.common.HybridBinarizer;

import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;

public class BarcodeDecoder {

    public String decode(byte[] imageBytes, int width, int height) {
        if (imageBytes == null || imageBytes.length == 0) {
            return null;
        }

        LuminanceSource source = new PlanarYUVLuminanceSource(
                imageBytes, width, height, 0, 0, width, height, false);

        BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));

        Map<DecodeHintType, Object> hints = new HashMap<>();
        hints.put(DecodeHintType.TRY_HARDER, Boolean.TRUE);
        hints.put(DecodeHintType.POSSIBLE_FORMATS, EnumSet.allOf(BarcodeFormat.class)); 

        Reader reader = new MultiFormatReader();
        try {
            System.out.println("Attempting to decode with ZXing...");
            Result result = reader.decode(bitmap, hints);
            return result.getText();
        } catch (Exception e) {
            System.out.println("ZXing could not find a barcode in the image: " + e.getMessage());
            return null;
        }
    }
}
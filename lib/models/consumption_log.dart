// lib/models/consumption_log.dart

import 'package:flutter/foundation.dart';

class ConsumptionLog {
  final String barcode;
  final String productName;
  final double consumedGrams;
  final DateTime consumedDate;
  final Map<String, double> consumedNutrients;

  ConsumptionLog({
    required this.barcode,
    required this.productName,
    required this.consumedGrams,
    required this.consumedDate,
    required this.consumedNutrients,
  });

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'productName': productName,
      'consumedGrams': consumedGrams,
      'consumedDate': consumedDate.toIso8601String(),
      'consumedNutrients': consumedNutrients,
    };
  }

  factory ConsumptionLog.fromJson(Map<String, dynamic> json) {
    return ConsumptionLog(
      barcode: json['barcode'] ?? '',
      productName: json['productName'] ?? '',
      consumedGrams: (json['consumedGrams'] as num?)?.toDouble() ?? 0.0,
      consumedDate: DateTime.parse(
        json['consumedDate'] ?? DateTime.now().toIso8601String(),
      ),
      consumedNutrients: Map<String, double>.from(
        json['consumedNutrients'] ?? {},
      ),
    );
  }
}

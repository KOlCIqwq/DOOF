class DailyStatsSummary {
  final DateTime date;
  final Map<String, double> nutrientTotals;

  DailyStatsSummary({required this.date, required this.nutrientTotals});

  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'nutrientTotals': nutrientTotals};
  }

  factory DailyStatsSummary.fromJson(Map<String, dynamic> json) {
    return DailyStatsSummary(
      date: DateTime.parse(json['date']),
      nutrientTotals: Map<String, double>.from(json['nutrientTotals']),
    );
  }
}

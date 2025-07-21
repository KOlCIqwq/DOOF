import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_stats_summary.dart';
import 'daily_detail_page.dart';

class HistoryPage extends StatelessWidget {
  final List<DailyStatsSummary> dailySummaries;

  const HistoryPage({super.key, required this.dailySummaries});

  @override
  Widget build(BuildContext context) {
    // Sort summaries by date in descending order
    final sortedSummaries = List.from(dailySummaries)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly History')), // App bar title
      body: sortedSummaries.isEmpty
          ? const Center(child: Text('No historical data available yet.')) // No data message
          : ListView.builder(
              itemCount: sortedSummaries.length,
              itemBuilder: (context, index) {
                final summary = sortedSummaries[index];
                // Calories from nutrient totals
                final calories = (summary.nutrientTotals['energy-kcal'] ?? 0)
                    .round();

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(DateFormat('EEEE, MMM d').format(summary.date)), // Date of summary
                    trailing: Text('$calories kcal'), // Calories consumed
                    onTap: () {
                      // Navigate to daily detail page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DailyDetailPage(summary: summary),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

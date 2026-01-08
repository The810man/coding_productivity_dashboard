import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/git_data.dart';

class StatChart extends StatelessWidget {
  final GitStat stats;
  final String title;

  const StatChart({super.key, required this.stats, required this.title});

  @override
  Widget build(BuildContext context) {
    final double maxY =
        (stats.added > stats.deleted ? stats.added : stats.deleted).toDouble() *
        1.2;
    final double safeMaxY = maxY == 0 ? 10 : maxY;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: safeMaxY,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val == 0)
                            return const Text(
                              'Added',
                              style: TextStyle(color: Colors.green),
                            );
                          if (val == 1)
                            return const Text(
                              'Deleted',
                              style: TextStyle(color: Colors.red),
                            );
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: stats.added.toDouble(),
                          color: Colors.green,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: stats.deleted.toDouble(),
                          color: Colors.red,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Churn Ratio: ${(stats.deleted / (stats.added == 0 ? 1 : stats.added) * 100).toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

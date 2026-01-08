import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContributionHeatmap extends StatelessWidget {
  final Map<DateTime, int> data;
  final Color primaryColor;

  const ContributionHeatmap({
    super.key,
    required this.data,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Datenaufbereitung: Letzte 52 Wochen
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 365));
    // Start auf Sonntag runden
    final startDate = start.subtract(Duration(days: start.weekday % 7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CONTRIBUTION_GRAPH (LAST 365 DAYS)",
          style: GoogleFonts.robotoMono(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 53, // Etwas Puffer
            itemBuilder: (ctx, weekIndex) {
              final weekStart = startDate.add(Duration(days: weekIndex * 7));

              return Column(
                children: List.generate(7, (dayIndex) {
                  final dayDate = weekStart.add(Duration(days: dayIndex));
                  if (dayDate.isAfter(now))
                    return const SizedBox(width: 12, height: 12);

                  final key = DateTime(
                    dayDate.year,
                    dayDate.month,
                    dayDate.day,
                  );
                  final count = data[key] ?? 0;

                  return Container(
                    margin: const EdgeInsets.all(2),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColor(count),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: count > 0
                        ? Tooltip(
                            message:
                                "$count commits\n${dayDate.toString().split(' ')[0]}",
                            child: const SizedBox(),
                          )
                        : null,
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getColor(int count) {
    if (count == 0) return Colors.white.withOpacity(0.05);
    if (count <= 2) return primaryColor.withOpacity(0.3);
    if (count <= 5) return primaryColor.withOpacity(0.5);
    if (count <= 10) return primaryColor.withOpacity(0.7);
    return primaryColor;
  }
}

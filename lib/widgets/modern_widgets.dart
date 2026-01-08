import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/git_data.dart';

class AppColors {
  static const neonGreen = Color(0xFF00FF9D);
  static const neonRed = Color(0xFFFF0055);
  static const neonBlue = Color(0xFF00E5FF);
  static const darkBg = Color(0xFF121212);
  static const glassBorder = Colors.white10;
}

// 1. Reusable Glass Card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(
            0.6,
          ), // Dunkler Halbtransparenter Hintergrund
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// 2. Modern Pie Chart
class CodePieChart extends StatelessWidget {
  final GitStat stats;
  final String title;

  const CodePieChart({super.key, required this.stats, required this.title});

  @override
  Widget build(BuildContext context) {
    final total = stats.added + stats.deleted;
    final isZero = total == 0;

    return Column(
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 140,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: isZero
                      ? [
                          PieChartSectionData(
                            color: Colors.white10,
                            value: 1,
                            title: "",
                            radius: 15,
                          ),
                        ]
                      : [
                          PieChartSectionData(
                            color: AppColors.neonGreen,
                            value: stats.added.toDouble(),
                            title: "${stats.added}",
                            titleStyle: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            radius: 20,
                            showTitle: true,
                          ),
                          PieChartSectionData(
                            color: AppColors.neonRed,
                            value: stats.deleted.toDouble(),
                            title: "${stats.deleted}",
                            titleStyle: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            radius: 20,
                            showTitle: true,
                          ),
                        ],
                ),
              ),
              // Center Text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isZero ? "Zzz" : "$total",
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "LINES",
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white38,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/git_provider.dart';
import 'providers/settings_provider.dart';
import 'models/git_data.dart';
import 'widgets/modern_widgets.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/heatmap_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Window.initialize();
    await Window.setEffect(
      effect: WindowEffect.acrylic,
      color: const Color(0xCC000000),
      dark: true,
    );
  } catch (_) {}

  runApp(const ProviderScope(child: ModernApp()));
}

class ModernApp extends ConsumerWidget {
  const ModernApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DevHUD',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.robotoMonoTextTheme(
          ThemeData.dark().textTheme,
        ), // Sicherer Font
        colorScheme: ColorScheme.dark(
          primary: theme.primaryColor,
          surface: Colors.transparent,
        ),
      ),
      home: const ModernDashboard(),
    );
  }
}

class ModernDashboard extends HookConsumerWidget {
  const ModernDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(gitStatsProvider);
    final theme = ref.watch(settingsProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(209, 0, 0, 0),
                  Color.fromARGB(188, 30, 30, 30),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, ref),
                Expanded(
                  child: reportAsync.when(
                    data: (report) => _buildContent(report, theme),
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        "ERR: $err",
                        style: TextStyle(color: AppColors.neonRed),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.terminal, color: theme.primaryColor),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "DEV.HUD_V1",
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: Colors.white38,
                  letterSpacing: 2,
                ),
              ),
              Text(
                "DAILY REPORT",
                style: GoogleFonts.robotoMono(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.primaryColor),
            onPressed: () => ref.invalidate(gitStatsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(GitReport report, AppTheme theme) {
    if (report.repos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.code_off, size: 50, color: Colors.white24),
            const SizedBox(height: 10),
            Text(
              "NO REPOSITORIES LINKED",
              style: GoogleFonts.robotoMono(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    final today = report.totals['TODAY'] ?? GitStat.zero();
    final week = report.totals['THIS_WEEK'] ?? GitStat.zero();
    final month = report.totals['THIS_MONTH'] ?? GitStat.zero();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (theme.showPieCharts)
            GlassCard(
              child: Row(
                children: [
                  Expanded(
                    child: CodePieChart(stats: today, title: "Today"),
                  ),
                  Container(width: 1, height: 80, color: Colors.white10),
                  Expanded(
                    child: CodePieChart(stats: week, title: "Week"),
                  ),
                  Container(width: 1, height: 80, color: Colors.white10),
                  Expanded(
                    child: CodePieChart(stats: month, title: "Month"),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: ContributionHeatmap(
              data: report.heatmap,
              primaryColor: theme.primaryColor,
            ),
          ),

          const SizedBox(height: 30),
          Text(
            "ACTIVE_REPOS",
            style: GoogleFonts.robotoMono(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 15),

          ...report.repos.values.map((repo) => _buildRepoTile(repo, theme)),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildRepoTile(RepoData repo, AppTheme theme) {
    final today = repo.stats['TODAY'] ?? GitStat.zero();
    final branches = repo.branches['TODAY'] ?? [];

    if (today.files == 0 && branches.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    repo.name,
                    style: GoogleFonts.robotoMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "+${today.added}",
                      style: GoogleFonts.robotoMono(
                        color: AppColors.neonGreen,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "-${today.deleted}",
                      style: GoogleFonts.robotoMono(
                        color: AppColors.neonRed,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (branches.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: branches
                    .map(
                      (b) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          b,
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

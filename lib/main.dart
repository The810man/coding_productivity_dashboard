import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart'; // WICHTIG
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'providers/git_provider.dart';
import 'models/git_data.dart';
import 'widgets/modern_widgets.dart'; // Unsere neuen Widgets

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Acrylic Initialisierung (Nur Desktop)
  try {
    await Window.initialize();
    await Window.setEffect(
      effect: WindowEffect.acrylic, // Oder WindowEffect.mica auf Windows 11
      color: const Color.fromARGB(232, 0, 0, 0), // Hex CC = 80% Opacity
      dark: true,
    );
  } catch (e) {
    print("Acrylic not supported or not on desktop: $e");
  }

  runApp(const ProviderScope(child: ModernApp()));
}

class ModernApp extends StatelessWidget {
  const ModernApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DevHUD',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent.withAlpha(
          150,
        ), // WICHTIG für Acrylic
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.neonBlue,
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

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (subtil)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x44000000), // Sehr dunkel
                  Color(0x881E1E1E),
                ],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, ref),
                Expanded(
                  child: reportAsync.when(
                    data: (report) => _buildContent(report),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.neonGreen,
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        "ERR: $err",
                        style: const TextStyle(color: AppColors.neonRed),
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

  // Header Bar
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.terminal, color: AppColors.neonGreen),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "DEV.HUD_V1",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: Colors.white38,
                  letterSpacing: 2,
                ),
              ),
              Text(
                "DAILY REPORT",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.white70),
            onPressed: () => _showConfig(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.neonBlue),
            onPressed: () => ref.invalidate(gitStatsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(GitReport report) {
    if (report.repos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.code_off, size: 50, color: Colors.white24),
            const SizedBox(height: 10),
            Text(
              "NO REPOSITORIES LINKED",
              style: GoogleFonts.jetBrainsMono(color: Colors.white54),
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
          // 1. STATS ROW (Pie Charts)
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

          const SizedBox(height: 30),
          Text(
            "ACTIVE_REPOS",
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.neonBlue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 15),

          // 2. REPO LIST
          ...report.repos.values.map((repo) => _buildRepoTile(repo)),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildRepoTile(RepoData repo) {
    final today = repo.stats['TODAY'] ?? GitStat.zero();
    final branches = repo.branches['TODAY'] ?? [];

    // Nur anzeigen, wenn heute was passiert ist (oder änderbar nach Geschmack)
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
                    style: GoogleFonts.inter(
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
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.neonGreen,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "-${today.deleted}",
                      style: GoogleFonts.jetBrainsMono(
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
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppColors.neonBlue,
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

  void _showConfig(BuildContext context, WidgetRef ref) {
    // Einfacher Config Dialog (kannst du auch stylen)
    final paths = ref.read(repoConfigProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          "Manage Repos",
          style: GoogleFonts.jetBrainsMono(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...paths.map(
                (p) => ListTile(
                  title: Text(
                    p,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.neonRed),
                    onPressed: () {
                      ref.read(repoConfigProvider.notifier).removePath(p);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonBlue,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.add),
                label: const Text("ADD FOLDER"),
                onPressed: () async {
                  String? selectedDirectory = await FilePicker.platform
                      .getDirectoryPath();
                  if (selectedDirectory != null) {
                    ref
                        .read(repoConfigProvider.notifier)
                        .addPath(selectedDirectory);
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

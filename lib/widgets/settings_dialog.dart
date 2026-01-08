import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/git_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider);
    final paths = ref.watch(repoConfigProvider);

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(
          "SYSTEM_CONFIG",
          style: GoogleFonts.robotoMono(letterSpacing: 2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionHeader(title: "VISUALS"),
                SwitchListTile(
                  title: Text(
                    "Glass/Acrylic",
                    style: GoogleFonts.robotoMono(color: Colors.white),
                  ),
                  value: theme.enableAcrylic,
                  activeColor: theme.primaryColor,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).toggleAcrylic(v),
                ),
                SwitchListTile(
                  title: Text(
                    "Show Charts",
                    style: GoogleFonts.robotoMono(color: Colors.white),
                  ),
                  value: theme.showPieCharts,
                  activeColor: theme.primaryColor,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).toggleCharts(v),
                ),
                const SizedBox(height: 20),
                _SectionHeader(title: "FILTERS"),
                SwitchListTile(
                  title: Text(
                    "Smart Copy-Paste Filter",
                    style: GoogleFonts.robotoMono(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Ignore > 600 lines",
                    style: GoogleFonts.robotoMono(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  value: theme.smartFiltering,
                  activeColor: theme.primaryColor,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .toggleSmartFiltering(v),
                ),
                const SizedBox(height: 20),
                Text(
                  "ACCENT COLOR",
                  style: GoogleFonts.robotoMono(color: Colors.white54),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    _ColorBtn(const Color(0xFF00E5FF), ref),
                    _ColorBtn(const Color(0xFF00FF9D), ref),
                    _ColorBtn(const Color(0xFFFF0055), ref),
                    _ColorBtn(const Color(0xFFFFD700), ref),
                    _ColorBtn(const Color(0xFFBD00FF), ref),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, color: Colors.white12),
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionHeader(title: "DATA_SOURCES"),
                ...paths.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.folder, color: Colors.white30),
                    title: Text(
                      p,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () =>
                          ref.read(repoConfigProvider.notifier).removePath(p),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("ADD REPOSITORY PATH"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor),
                    padding: const EdgeInsets.all(20),
                  ),
                  onPressed: () async {
                    String? selectedDirectory = await FilePicker.platform
                        .getDirectoryPath();
                    if (selectedDirectory != null) {
                      ref
                          .read(repoConfigProvider.notifier)
                          .addPath(selectedDirectory);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: GoogleFonts.robotoMono(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }
}

class _ColorBtn extends StatelessWidget {
  final Color color;
  final WidgetRef ref;
  const _ColorBtn(this.color, this.ref);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).updateColor(color),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

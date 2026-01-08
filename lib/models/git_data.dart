class GitStat {
  final int files;
  final int added;
  final int deleted;

  GitStat({required this.files, required this.added, required this.deleted});

  factory GitStat.zero() => GitStat(files: 0, added: 0, deleted: 0);

  factory GitStat.fromParts(List<String> parts) {
    return GitStat(
      files: int.tryParse(parts[3]) ?? 0,
      added: int.tryParse(parts[4]) ?? 0,
      deleted: int.tryParse(parts[5]) ?? 0,
    );
  }
}

class RepoData {
  final String name;
  final Map<String, GitStat> stats;
  final Map<String, List<String>> branches;

  RepoData({required this.name, required this.stats, required this.branches});
}

class GitReport {
  final String date;
  final Map<String, RepoData> repos;
  final Map<String, GitStat> totals;
  final Map<DateTime, int> heatmap; // <-- NEU

  GitReport({
    required this.date,
    required this.repos,
    required this.totals,
    required this.heatmap, // <-- NEU
  });

  factory GitReport.parse(String rawOutput) {
    String date = "";
    final Map<String, RepoData> repos = {};
    final Map<String, GitStat> totals = {};
    final Map<DateTime, int> heatmap = {};

    RepoData getRepo(String name) {
      if (!repos.containsKey(name)) {
        repos[name] = RepoData(name: name, stats: {}, branches: {});
      }
      return repos[name]!;
    }

    final lines = rawOutput.split('\n');
    for (var line in lines) {
      if (line.isEmpty) continue;
      final parts = line.split('|');

      // Heatmap Parsing
      if (parts[0] == 'HEATMAP_TOTAL' && parts.length >= 3) {
        final dateStr = parts[1];
        final count = int.tryParse(parts[2]) ?? 0;
        try {
          final dt = DateTime.parse(dateStr);
          heatmap[DateTime(dt.year, dt.month, dt.day)] = count;
        } catch (_) {}
        continue;
      }

      if (parts.length < 3) continue;
      final type = parts[0];

      if (type == 'META' && parts[1] == 'DATE') {
        date = parts[2];
      } else if (type == 'REPO') {
        final name = parts[1];
        final period = parts[2];
        getRepo(name).stats[period] = GitStat.fromParts(parts);
      } else if (type == 'BRANCHES') {
        final name = parts[1];
        final period = parts[2];
        if (parts.length > 3) {
          getRepo(name).branches[period] = parts[3]
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } else if (type == 'TOTAL') {
        final period = parts[2];
        totals[period] = GitStat.fromParts(parts);
      }
    }

    return GitReport(
      date: date,
      repos: repos,
      totals: totals,
      heatmap: heatmap,
    );
  }
}

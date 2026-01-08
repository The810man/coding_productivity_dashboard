class GitStat {
  final int files;
  final int added;
  final int deleted;

  GitStat({required this.files, required this.added, required this.deleted});

  factory GitStat.zero() => GitStat(files: 0, added: 0, deleted: 0);

  factory GitStat.fromParts(List<String> parts) {
    // Erwartet parts ab Index 3: [files, added, deleted]
    return GitStat(
      files: int.tryParse(parts[3]) ?? 0,
      added: int.tryParse(parts[4]) ?? 0,
      deleted: int.tryParse(parts[5]) ?? 0,
    );
  }
}

class RepoData {
  final String name;
  final Map<String, GitStat> stats; // Key: 'TODAY', 'THIS_WEEK' etc.
  final Map<String, List<String>> branches;

  RepoData({required this.name, required this.stats, required this.branches});
}

class GitReport {
  final String date;
  final Map<String, RepoData> repos;
  final Map<String, GitStat> totals;

  GitReport({required this.date, required this.repos, required this.totals});

  // Parsing Logic
  factory GitReport.parse(String rawOutput) {
    String date = "";
    final Map<String, RepoData> repos = {};
    final Map<String, GitStat> totals = {};

    // Helper um Repos sicher zu holen oder zu erstellen
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
      if (parts.length < 3) continue;

      final type = parts[0]; // META, REPO, BRANCHES, TOTAL

      if (type == 'META' && parts[1] == 'DATE') {
        date = parts[2];
      } else if (type == 'REPO') {
        final name = parts[1];
        final period = parts[2];
        getRepo(name).stats[period] = GitStat.fromParts(parts);
      } else if (type == 'BRANCHES') {
        final name = parts[1];
        final period = parts[2];
        // Branches sind komma-getrennt in parts[3]
        if (parts.length > 3) {
          final branchList = parts[3]
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList();
          getRepo(name).branches[period] = branchList;
        }
      } else if (type == 'TOTAL') {
        final period = parts[2];
        totals[period] = GitStat.fromParts(parts);
      }
    }

    return GitReport(date: date, repos: repos, totals: totals);
  }
}

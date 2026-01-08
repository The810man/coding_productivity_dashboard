import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/git_data.dart';
import 'settings_provider.dart';

const String kConfigFileName = 'repos.conf';
const String kScriptFileName = 'git_status.sh';

class RepoConfigNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final file = File(kConfigFileName);
    if (await file.exists()) {
      final lines = await file.readAsLines();
      state = lines
          .where((l) => l.trim().isNotEmpty && !l.startsWith('#'))
          .toList();
    }
  }

  Future<void> addPath(String path) async {
    if (state.contains(path)) return;
    state = [...state, path];
    await _save();
  }

  Future<void> removePath(String path) async {
    state = state.where((p) => p != path).toList();
    await _save();
  }

  Future<void> _save() async {
    final file = File(kConfigFileName);
    await file.writeAsString(state.join('\n'));
  }
}

final repoConfigProvider = NotifierProvider<RepoConfigNotifier, List<String>>(
  RepoConfigNotifier.new,
);

final gitStatsProvider = StreamProvider<GitReport>((ref) {
  ref.watch(repoConfigProvider);
  final settings = ref.watch(settingsProvider);

  return Stream.periodic(
        const Duration(minutes: 10),
        (_) => _runScript(settings.smartFiltering),
      )
      .asyncMap((event) async => await event)
      .startWith(_runScript(settings.smartFiltering));
});

extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(Future<T> initial) async* {
    yield await initial;
    yield* this;
  }
}

Future<GitReport> _runScript(bool useSmartFilter) async {
  try {
    if (!await File(kScriptFileName).exists()) {
      // HIER WAR DER FEHLER: heatmap: {} fehlte
      return GitReport(
        date: "Script Missing",
        repos: {},
        totals: {},
        heatmap: {},
      );
    }

    final String thresholdArg = useSmartFilter ? "600" : "0";
    final result = await Process.run('sh', [
      kScriptFileName,
      kConfigFileName,
      thresholdArg,
    ]);

    if (result.exitCode != 0) {
      print("Script Error: ${result.stderr}");
      throw Exception("Script failed");
    }

    return GitReport.parse(result.stdout.toString());
  } catch (e) {
    print("Error running script: $e");
    rethrow;
  }
}

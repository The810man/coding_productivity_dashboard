import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/git_data.dart';

// Pfad zur repos.conf (im gleichen Ordner wie die App oder das Skript)
const String kConfigFileName = 'repos.conf';
const String kScriptFileName = 'git_status.sh';

// 1. Config Provider (Liest/Schreibt repos.conf)
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
      // Filter Kommentare und leere Zeilen
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

// 2. Stats Provider (Führt Skript aus & refreshed alle 10 min)
final gitStatsProvider = StreamProvider<GitReport>((ref) {
  // Wir hören auf Config Änderungen, um sofort neu zu laden
  ref.watch(repoConfigProvider);

  // Timer Stream: Startet sofort, dann alle 10 Minuten
  return Stream.periodic(const Duration(minutes: 10), (_) => _runScript())
      .asyncMap((event) async => await event)
      .startWith(_runScript()); // Sofortiger Start beim Init
});

// Extension für startWith (einfacher Hack für Streams)
extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(Future<T> initial) async* {
    yield await initial;
    yield* this;
  }
}

// Hilfsfunktion: Skript ausführen
Future<GitReport> _runScript() async {
  try {
    // Prüfen ob Skript existiert
    if (!await File(kScriptFileName).exists()) {
      // Dummy Daten falls Skript fehlt (zum Testen der UI)
      return GitReport(date: "Script Missing", repos: {}, totals: {});
    }

    final result = await Process.run('sh', [kScriptFileName]);

    if (result.exitCode != 0) {
      print("Script Error: ${result.stderr}");
      throw Exception("Script failed");
    }

    // Debug Output im Terminal
    if (result.stderr.toString().isNotEmpty) {
      print("DEBUG: ${result.stderr}");
    }

    return GitReport.parse(result.stdout.toString());
  } catch (e) {
    print("Error running script: $e");
    rethrow;
  }
}

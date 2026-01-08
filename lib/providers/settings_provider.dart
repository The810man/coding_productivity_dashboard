import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final Color primaryColor;
  final bool enableAcrylic;
  final bool showPieCharts;
  final bool smartFiltering;

  AppTheme({
    required this.primaryColor,
    required this.enableAcrylic,
    required this.showPieCharts,
    required this.smartFiltering,
  });

  AppTheme copyWith({
    Color? primaryColor,
    bool? enableAcrylic,
    bool? showPieCharts,
    bool? smartFiltering,
  }) {
    return AppTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      enableAcrylic: enableAcrylic ?? this.enableAcrylic,
      showPieCharts: showPieCharts ?? this.showPieCharts,
      smartFiltering: smartFiltering ?? this.smartFiltering,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppTheme> {
  SettingsNotifier()
    : super(
        AppTheme(
          primaryColor: const Color(0xFF00E5FF),
          enableAcrylic: true,
          showPieCharts: true,
          smartFiltering: false,
        ),
      ) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppTheme(
      primaryColor: Color(prefs.getInt('primaryColor') ?? 0xFF00E5FF),
      enableAcrylic: prefs.getBool('enableAcrylic') ?? true,
      showPieCharts: prefs.getBool('showPieCharts') ?? true,
      smartFiltering: prefs.getBool('smartFiltering') ?? false,
    );
  }

  Future<void> updateColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.value);
  }

  Future<void> toggleAcrylic(bool val) async {
    state = state.copyWith(enableAcrylic: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableAcrylic', val);
  }

  Future<void> toggleCharts(bool val) async {
    state = state.copyWith(showPieCharts: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPieCharts', val);
  }

  Future<void> toggleSmartFiltering(bool val) async {
    state = state.copyWith(smartFiltering: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smartFiltering', val);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppTheme>(
  (ref) => SettingsNotifier(),
);

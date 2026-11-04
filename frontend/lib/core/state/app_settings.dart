import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_store.dart';

/// User preferences that survive restarts.
@immutable
class AppSettings {
  final ThemeMode themeMode;
  final bool reducedMotion;
  final String currencySymbol;

  /// Monthly spend limit; null means no limit.
  final double? monthlyBudget;
  final bool remindersEnabled;
  final bool onboarded;
  final String displayName;

  /// Minutes away (backgrounded or idle) before the app locks again; 0 = immediately.
  /// Only applies when an app PIN is set.
  final int autoLockMinutes;

  /// Covers the screen while the app is in the app switcher or inactive.
  final bool privacyShield;

  /// Android: block screenshots and screen recording (FLAG_SECURE).
  final bool blockScreenshots;

  /// Send relevant snippets to the cloud model (via the ai-assist function) for
  /// answers, group names and transcription. Off = everything stays on the device.
  final bool cloudAi;

  /// On-device suggestions while typing (categories, priorities, tags, moods).
  final bool smartSuggestions;

  /// Sovereign Administrative Console Session
  final bool isAdminSession;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.reducedMotion = false,
    this.currencySymbol = '₹',
    this.monthlyBudget,
    this.remindersEnabled = false,
    this.onboarded = false,
    this.displayName = '',
    this.autoLockMinutes = 5,
    this.privacyShield = true,
    this.blockScreenshots = false,
    this.cloudAi = true,
    this.smartSuggestions = true,
    this.isAdminSession = false,
  });

  static const List<int> autoLockChoices = [0, 1, 5, 15, 60];

  String get initial => displayName.trim().isEmpty ? 'N' : displayName.trim()[0].toUpperCase();

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? reducedMotion,
    String? currencySymbol,
    double? monthlyBudget,
    bool clearMonthlyBudget = false,
    bool? remindersEnabled,
    bool? onboarded,
    String? displayName,
    int? autoLockMinutes,
    bool? privacyShield,
    bool? blockScreenshots,
    bool? cloudAi,
    bool? smartSuggestions,
    bool? isAdminSession,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      monthlyBudget: clearMonthlyBudget ? null : (monthlyBudget ?? this.monthlyBudget),
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      onboarded: onboarded ?? this.onboarded,
      displayName: displayName ?? this.displayName,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      privacyShield: privacyShield ?? this.privacyShield,
      blockScreenshots: blockScreenshots ?? this.blockScreenshots,
      cloudAi: cloudAi ?? this.cloudAi,
      smartSuggestions: smartSuggestions ?? this.smartSuggestions,
      isAdminSession: isAdminSession ?? this.isAdminSession,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'reducedMotion': reducedMotion,
        'currencySymbol': currencySymbol,
        'monthlyBudget': monthlyBudget,
        'remindersEnabled': remindersEnabled,
        'onboarded': onboarded,
        'displayName': displayName,
        'autoLockMinutes': autoLockMinutes,
        'privacyShield': privacyShield,
        'blockScreenshots': blockScreenshots,
        'cloudAi': cloudAi,
        'smartSuggestions': smartSuggestions,
        'isAdminSession': isAdminSession,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        themeMode: ThemeMode.values.asNameMap()[j['themeMode']] ?? ThemeMode.system,
        reducedMotion: j['reducedMotion'] as bool? ?? false,
        currencySymbol: j['currencySymbol'] as String? ?? '₹',
        monthlyBudget: (j['monthlyBudget'] as num?)?.toDouble(),
        remindersEnabled: j['remindersEnabled'] as bool? ?? false,
        onboarded: j['onboarded'] as bool? ?? false,
        displayName: j['displayName'] as String? ?? '',
        autoLockMinutes: (j['autoLockMinutes'] as num?)?.toInt() ?? 5,
        privacyShield: j['privacyShield'] as bool? ?? true,
        blockScreenshots: j['blockScreenshots'] as bool? ?? false,
        cloudAi: j['cloudAi'] as bool? ?? true,
        smartSuggestions: j['smartSuggestions'] as bool? ?? true,
        isAdminSession: j['isAdminSession'] as bool? ?? (LocalStore().readBool('is_admin_session') ?? false),
      );
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  static const String storageKey = 'settings';

  AppSettingsNotifier() : super(_load());

  static AppSettings _load() {
    // Theme and motion are mirrored unencrypted so the lock screen can use them.
    final public = LocalStore().readPublic();
    final raw = LocalStore().readMap(storageKey);
    return AppSettings.fromJson({...public, ...?raw});
  }

  @override
  set state(AppSettings value) {
    super.state = value;
    LocalStore().writeMap(storageKey, value.toJson());
    LocalStore().writePublic({'themeMode': value.themeMode.name, 'reducedMotion': value.reducedMotion});
  }

  void reloadFromStore() => super.state = _load();

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);
  void setReducedMotion(bool value) => state = state.copyWith(reducedMotion: value);
  void setCurrency(String symbol) => state = state.copyWith(currencySymbol: symbol);
  void setRemindersEnabled(bool value) => state = state.copyWith(remindersEnabled: value);
  void completeOnboarding() => state = state.copyWith(onboarded: true);
  void setDisplayName(String name) => state = state.copyWith(displayName: name.trim());

  void setMonthlyBudget(double? amount) => state = (amount == null || amount <= 0)
      ? state.copyWith(clearMonthlyBudget: true)
      : state.copyWith(monthlyBudget: amount);

  void setAutoLockMinutes(int minutes) => state = state.copyWith(autoLockMinutes: minutes);
  void setPrivacyShield(bool value) => state = state.copyWith(privacyShield: value);
  void setBlockScreenshots(bool value) => state = state.copyWith(blockScreenshots: value);
  void setCloudAi(bool value) => state = state.copyWith(cloudAi: value);
  void setSmartSuggestions(bool value) => state = state.copyWith(smartSuggestions: value);
  void setAdminSession(bool value) {
    LocalStore().writeBool('is_admin_session', value);
    state = state.copyWith(isAdminSession: value);
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) => AppSettingsNotifier());

/// Formats an amount with the user's currency symbol, e.g. "₹2,400".
String formatMoney(double amount, String symbol, {int decimals = 0}) {
  final fixed = amount.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  final sign = amount < 0 ? '-' : '';
  return '$sign$symbol$whole${parts.length > 1 ? '.${parts[1]}' : ''}';
}

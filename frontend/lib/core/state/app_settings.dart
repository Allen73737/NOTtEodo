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

  /// Custom avatar settings
  final String? avatarPreset;
  final String? avatarCustomPath;
  final String bioMotto;

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

  /// General experience preferences
  final int defaultStartScreen; // 0: Home, 1: Notes, 2: Tasks, 3: Planner
  final int firstDayOfWeek; // 1: Monday, 7: Sunday
  final bool timeFormat24h;
  final String hapticIntensity; // 'off', 'light', 'medium', 'crisp'
  final bool soundFxEnabled;

  /// Audio studio sound assignments
  final String notificationSound; // 'velvet_obsidian', 'celestial_shimmer', etc. or 'custom'
  final String? customNotificationSoundPath;
  final String? customNotificationSoundName;

  final String alarmSound; // 'horology_cascade', 'golden_dawn', etc. or 'custom'
  final String? customAlarmSoundPath;
  final String? customAlarmSoundName;

  /// Scheduled notifications and quiet hours
  final String morningBriefingTime; // e.g. '07:30'
  final String eveningReflectionTime; // e.g. '21:30'
  final bool quietHoursEnabled;
  final String quietHoursStart; // e.g. '22:00'
  final String quietHoursEnd; // e.g. '07:00'
  final int budgetAlertThreshold; // e.g. 75, 80, 90, 100

  /// AI Tone & Style
  final String aiToneStyle; // 'executive', 'coach', 'architect'
  final bool excludePrivateNotesFromAi;

  /// Animated Nodo AI Companion
  final bool nodoCompanionEnabled;

  /// Typography & Font Customizations
  final String fontFamilyGlobal; // 'DM Sans', 'Inter', 'Space Grotesk', etc.
  final String fontFamilyNotes;
  final String fontFamilyTasks;
  final String fontFamilyJournal;
  final String fontFamilyTreasury;

  /// Native OS System Notifications & Daily Engagement
  final bool deviceSystemNotifications;
  final bool dailyEngagementNotifications;

  /// Vault PIN & Biometric Protection
  final String? vaultPin;
  final bool vaultBiometricsEnabled;

  /// AI Assistant Persona & Character
  final String aiPersona; // 'sarcastic', 'scholarly', 'energetic', 'stoic'

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.reducedMotion = false,
    this.currencySymbol = '₹',
    this.monthlyBudget,
    this.remindersEnabled = false,
    this.onboarded = false,
    this.displayName = '',
    this.avatarPreset,
    this.avatarCustomPath,
    this.bioMotto = 'Focus on high-leverage priorities.',
    this.autoLockMinutes = 5,
    this.privacyShield = true,
    this.blockScreenshots = false,
    this.cloudAi = true,
    this.smartSuggestions = true,
    this.isAdminSession = false,
    this.defaultStartScreen = 0,
    this.firstDayOfWeek = 1,
    this.timeFormat24h = false,
    this.hapticIntensity = 'crisp',
    this.soundFxEnabled = true,
    this.notificationSound = 'velvet_obsidian',
    this.customNotificationSoundPath,
    this.customNotificationSoundName,
    this.alarmSound = 'horology_cascade',
    this.customAlarmSoundPath,
    this.customAlarmSoundName,
    this.morningBriefingTime = '07:30',
    this.eveningReflectionTime = '21:30',
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.budgetAlertThreshold = 80,
    this.aiToneStyle = 'executive',
    this.excludePrivateNotesFromAi = true,
    this.nodoCompanionEnabled = true,
    this.fontFamilyGlobal = 'DM Sans',
    this.fontFamilyNotes = 'Default',
    this.fontFamilyTasks = 'Default',
    this.fontFamilyJournal = 'Default',
    this.fontFamilyTreasury = 'Default',
    this.deviceSystemNotifications = true,
    this.dailyEngagementNotifications = true,
    this.vaultPin,
    this.vaultBiometricsEnabled = true,
    this.aiPersona = 'sarcastic',
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
    String? avatarPreset,
    bool clearAvatarPreset = false,
    String? avatarCustomPath,
    bool clearAvatarCustomPath = false,
    String? bioMotto,
    int? autoLockMinutes,
    bool? privacyShield,
    bool? blockScreenshots,
    bool? cloudAi,
    bool? smartSuggestions,
    bool? isAdminSession,
    int? defaultStartScreen,
    int? firstDayOfWeek,
    bool? timeFormat24h,
    String? hapticIntensity,
    bool? soundFxEnabled,
    String? notificationSound,
    String? customNotificationSoundPath,
    String? customNotificationSoundName,
    String? alarmSound,
    String? customAlarmSoundPath,
    String? customAlarmSoundName,
    String? morningBriefingTime,
    String? eveningReflectionTime,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    int? budgetAlertThreshold,
    String? aiToneStyle,
    bool? excludePrivateNotesFromAi,
    bool? nodoCompanionEnabled,
    String? fontFamilyGlobal,
    String? fontFamilyNotes,
    String? fontFamilyTasks,
    String? fontFamilyJournal,
    String? fontFamilyTreasury,
    bool? deviceSystemNotifications,
    bool? dailyEngagementNotifications,
    String? vaultPin,
    bool clearVaultPin = false,
    bool? vaultBiometricsEnabled,
    String? aiPersona,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      monthlyBudget: clearMonthlyBudget ? null : (monthlyBudget ?? this.monthlyBudget),
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      onboarded: onboarded ?? this.onboarded,
      displayName: displayName ?? this.displayName,
      avatarPreset: clearAvatarPreset ? null : (avatarPreset ?? this.avatarPreset),
      avatarCustomPath: clearAvatarCustomPath ? null : (avatarCustomPath ?? this.avatarCustomPath),
      bioMotto: bioMotto ?? this.bioMotto,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      privacyShield: privacyShield ?? this.privacyShield,
      blockScreenshots: blockScreenshots ?? this.blockScreenshots,
      cloudAi: cloudAi ?? this.cloudAi,
      smartSuggestions: smartSuggestions ?? this.smartSuggestions,
      isAdminSession: isAdminSession ?? this.isAdminSession,
      defaultStartScreen: defaultStartScreen ?? this.defaultStartScreen,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      timeFormat24h: timeFormat24h ?? this.timeFormat24h,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
      soundFxEnabled: soundFxEnabled ?? this.soundFxEnabled,
      notificationSound: notificationSound ?? this.notificationSound,
      customNotificationSoundPath: customNotificationSoundPath ?? this.customNotificationSoundPath,
      customNotificationSoundName: customNotificationSoundName ?? this.customNotificationSoundName,
      alarmSound: alarmSound ?? this.alarmSound,
      customAlarmSoundPath: customAlarmSoundPath ?? this.customAlarmSoundPath,
      customAlarmSoundName: customAlarmSoundName ?? this.customAlarmSoundName,
      morningBriefingTime: morningBriefingTime ?? this.morningBriefingTime,
      eveningReflectionTime: eveningReflectionTime ?? this.eveningReflectionTime,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
      aiToneStyle: aiToneStyle ?? this.aiToneStyle,
      excludePrivateNotesFromAi: excludePrivateNotesFromAi ?? this.excludePrivateNotesFromAi,
      nodoCompanionEnabled: nodoCompanionEnabled ?? this.nodoCompanionEnabled,
      fontFamilyGlobal: fontFamilyGlobal ?? this.fontFamilyGlobal,
      fontFamilyNotes: fontFamilyNotes ?? this.fontFamilyNotes,
      fontFamilyTasks: fontFamilyTasks ?? this.fontFamilyTasks,
      fontFamilyJournal: fontFamilyJournal ?? this.fontFamilyJournal,
      fontFamilyTreasury: fontFamilyTreasury ?? this.fontFamilyTreasury,
      deviceSystemNotifications: deviceSystemNotifications ?? this.deviceSystemNotifications,
      dailyEngagementNotifications: dailyEngagementNotifications ?? this.dailyEngagementNotifications,
      vaultPin: clearVaultPin ? null : (vaultPin ?? this.vaultPin),
      vaultBiometricsEnabled: vaultBiometricsEnabled ?? this.vaultBiometricsEnabled,
      aiPersona: aiPersona ?? this.aiPersona,
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
        'avatarPreset': avatarPreset,
        'avatarCustomPath': avatarCustomPath,
        'bioMotto': bioMotto,
        'autoLockMinutes': autoLockMinutes,
        'privacyShield': privacyShield,
        'blockScreenshots': blockScreenshots,
        'cloudAi': cloudAi,
        'smartSuggestions': smartSuggestions,
        'isAdminSession': isAdminSession,
        'defaultStartScreen': defaultStartScreen,
        'firstDayOfWeek': firstDayOfWeek,
        'timeFormat24h': timeFormat24h,
        'hapticIntensity': hapticIntensity,
        'soundFxEnabled': soundFxEnabled,
        'notificationSound': notificationSound,
        'customNotificationSoundPath': customNotificationSoundPath,
        'customNotificationSoundName': customNotificationSoundName,
        'alarmSound': alarmSound,
        'customAlarmSoundPath': customAlarmSoundPath,
        'customAlarmSoundName': customAlarmSoundName,
        'morningBriefingTime': morningBriefingTime,
        'eveningReflectionTime': eveningReflectionTime,
        'quietHoursEnabled': quietHoursEnabled,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'budgetAlertThreshold': budgetAlertThreshold,
        'aiToneStyle': aiToneStyle,
        'excludePrivateNotesFromAi': excludePrivateNotesFromAi,
        'nodoCompanionEnabled': nodoCompanionEnabled,
        'fontFamilyGlobal': fontFamilyGlobal,
        'fontFamilyNotes': fontFamilyNotes,
        'fontFamilyTasks': fontFamilyTasks,
        'fontFamilyJournal': fontFamilyJournal,
        'fontFamilyTreasury': fontFamilyTreasury,
        'deviceSystemNotifications': deviceSystemNotifications,
        'dailyEngagementNotifications': dailyEngagementNotifications,
        'vaultPin': vaultPin,
        'vaultBiometricsEnabled': vaultBiometricsEnabled,
        'aiPersona': aiPersona,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        themeMode: ThemeMode.values.asNameMap()[j['themeMode']] ?? ThemeMode.system,
        reducedMotion: j['reducedMotion'] as bool? ?? false,
        currencySymbol: j['currencySymbol'] as String? ?? '₹',
        monthlyBudget: (j['monthlyBudget'] as num?)?.toDouble(),
        remindersEnabled: j['remindersEnabled'] as bool? ?? false,
        onboarded: j['onboarded'] as bool? ?? false,
        displayName: j['displayName'] as String? ?? '',
        avatarPreset: j['avatarPreset'] as String?,
        avatarCustomPath: j['avatarCustomPath'] as String?,
        bioMotto: j['bioMotto'] as String? ?? 'Focus on high-leverage priorities.',
        autoLockMinutes: (j['autoLockMinutes'] as num?)?.toInt() ?? 5,
        privacyShield: j['privacyShield'] as bool? ?? true,
        blockScreenshots: j['blockScreenshots'] as bool? ?? false,
        cloudAi: j['cloudAi'] as bool? ?? true,
        smartSuggestions: j['smartSuggestions'] as bool? ?? true,
        isAdminSession: j['isAdminSession'] as bool? ?? (LocalStore().readBool('is_admin_session') ?? false),
        defaultStartScreen: (j['defaultStartScreen'] as num?)?.toInt() ?? 0,
        firstDayOfWeek: (j['firstDayOfWeek'] as num?)?.toInt() ?? 1,
        timeFormat24h: j['timeFormat24h'] as bool? ?? false,
        hapticIntensity: j['hapticIntensity'] as String? ?? 'crisp',
        soundFxEnabled: j['soundFxEnabled'] as bool? ?? true,
        notificationSound: j['notificationSound'] as String? ?? 'velvet_obsidian',
        customNotificationSoundPath: j['customNotificationSoundPath'] as String?,
        customNotificationSoundName: j['customNotificationSoundName'] as String?,
        alarmSound: j['alarmSound'] as String? ?? 'horology_cascade',
        customAlarmSoundPath: j['customAlarmSoundPath'] as String?,
        customAlarmSoundName: j['customAlarmSoundName'] as String?,
        morningBriefingTime: j['morningBriefingTime'] as String? ?? '07:30',
        eveningReflectionTime: j['eveningReflectionTime'] as String? ?? '21:30',
        quietHoursEnabled: j['quietHoursEnabled'] as bool? ?? false,
        quietHoursStart: j['quietHoursStart'] as String? ?? '22:00',
        quietHoursEnd: j['quietHoursEnd'] as String? ?? '07:00',
        budgetAlertThreshold: (j['budgetAlertThreshold'] as num?)?.toInt() ?? 80,
        aiToneStyle: j['aiToneStyle'] as String? ?? 'executive',
        excludePrivateNotesFromAi: j['excludePrivateNotesFromAi'] as bool? ?? true,
        nodoCompanionEnabled: j['nodoCompanionEnabled'] as bool? ?? true,
        fontFamilyGlobal: j['fontFamilyGlobal'] as String? ?? 'DM Sans',
        fontFamilyNotes: j['fontFamilyNotes'] as String? ?? 'Default',
        fontFamilyTasks: j['fontFamilyTasks'] as String? ?? 'Default',
        fontFamilyJournal: j['fontFamilyJournal'] as String? ?? 'Default',
        fontFamilyTreasury: j['fontFamilyTreasury'] as String? ?? 'Default',
        deviceSystemNotifications: j['deviceSystemNotifications'] as bool? ?? true,
        dailyEngagementNotifications: j['dailyEngagementNotifications'] as bool? ?? true,
        vaultPin: j['vaultPin'] as String? ?? LocalStore().readString('vault_pin'),
        vaultBiometricsEnabled: j['vaultBiometricsEnabled'] as bool? ?? (LocalStore().readBool('vault_biometrics_enabled') ?? true),
        aiPersona: j['aiPersona'] as String? ?? 'sarcastic',
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
  void setBioMotto(String motto) => state = state.copyWith(bioMotto: motto.trim());

  void setAvatarPreset(String? preset) {
    state = state.copyWith(avatarPreset: preset, clearAvatarCustomPath: true);
  }

  void setAvatarCustomPath(String? path) {
    state = state.copyWith(avatarCustomPath: path, clearAvatarPreset: true);
  }

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

  void setDefaultStartScreen(int index) => state = state.copyWith(defaultStartScreen: index);
  void setFirstDayOfWeek(int day) => state = state.copyWith(firstDayOfWeek: day);
  void setTimeFormat24h(bool value) => state = state.copyWith(timeFormat24h: value);
  void setHapticIntensity(String intensity) => state = state.copyWith(hapticIntensity: intensity);
  void setSoundFxEnabled(bool value) => state = state.copyWith(soundFxEnabled: value);

  void setNotificationSound(String sound, {String? customPath, String? customName}) {
    state = state.copyWith(
      notificationSound: sound,
      customNotificationSoundPath: customPath,
      customNotificationSoundName: customName,
    );
  }

  void setAlarmSound(String sound, {String? customPath, String? customName}) {
    state = state.copyWith(
      alarmSound: sound,
      customAlarmSoundPath: customPath,
      customAlarmSoundName: customName,
    );
  }

  void setMorningBriefingTime(String time) => state = state.copyWith(morningBriefingTime: time);
  void setEveningReflectionTime(String time) => state = state.copyWith(eveningReflectionTime: time);

  void setQuietHours({bool? enabled, String? start, String? end}) {
    state = state.copyWith(
      quietHoursEnabled: enabled ?? state.quietHoursEnabled,
      quietHoursStart: start ?? state.quietHoursStart,
      quietHoursEnd: end ?? state.quietHoursEnd,
    );
  }

  void setBudgetAlertThreshold(int threshold) => state = state.copyWith(budgetAlertThreshold: threshold);
  void setAiToneStyle(String tone) => state = state.copyWith(aiToneStyle: tone);
  void setExcludePrivateNotesFromAi(bool value) => state = state.copyWith(excludePrivateNotesFromAi: value);

  void setNodoCompanionEnabled(bool value) => state = state.copyWith(nodoCompanionEnabled: value);
  void setFontFamilyGlobal(String font) => state = state.copyWith(fontFamilyGlobal: font);
  void setFontFamilyNotes(String font) => state = state.copyWith(fontFamilyNotes: font);
  void setFontFamilyTasks(String font) => state = state.copyWith(fontFamilyTasks: font);
  void setFontFamilyJournal(String font) => state = state.copyWith(fontFamilyJournal: font);
  void setFontFamilyTreasury(String font) => state = state.copyWith(fontFamilyTreasury: font);
  void setDeviceSystemNotifications(bool value) => state = state.copyWith(deviceSystemNotifications: value);
  void setDailyEngagementNotifications(bool value) => state = state.copyWith(dailyEngagementNotifications: value);

  void setVaultPin(String? pin) {
    if (pin == null || pin.isEmpty) {
      LocalStore().removeKey('vault_pin');
      state = state.copyWith(clearVaultPin: true);
    } else {
      LocalStore().writeString('vault_pin', pin);
      state = state.copyWith(vaultPin: pin);
    }
  }

  void setVaultBiometricsEnabled(bool value) {
    LocalStore().writeBool('vault_biometrics_enabled', value);
    state = state.copyWith(vaultBiometricsEnabled: value);
  }

  void setAiPersona(String persona) => state = state.copyWith(aiPersona: persona);
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

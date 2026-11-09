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
  final String morningBriefingTime; // e.g. '09:30'
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

  /// Interval in hours between on-device daily engagement/streak notifications (1, 2, 3, 4, 6, 12, 24).
  final int notificationCadenceHours;

  /// Vault PIN & Biometric Protection
  final String? vaultPin;
  final bool vaultBiometricsEnabled;

  /// AI Assistant Persona & Character
  final String aiPersona; // 'sarcastic', 'scholarly', 'energetic', 'stoic'

  /// Minimalist / Uncluttered Clean Homescreen Mode
  final bool cleanHomescreenMode;

  /// Card Container Display Style
  /// 'bento': Architectural Bento Pods with rounded chamfers, depth & soft shadows
  /// 'editorial': Swiss Minimalist Editorial with borderless flush paper & razor hairline dividers
  final String cardStyle;

  /// Sub-Admin Accounts & Shareable Delegation Invite Codes
  final List<String> subAdminEmails;
  final List<String> subAdminInviteCodes;

  /// Live Real Streaks & Badges
  final int activeStreak;
  final String lastActiveDate;
  final int longestStreak;
  final String? userLocation;
  final int streakFreezesCount;
  final String streakFreezeUsedDate;
  final int lastMilestoneCelebrated;

  /// Display Cards Visibility Toggles
  final bool hideDailyBriefing;
  final bool hideMonthlyBudget;
  final bool hideExpensesSummary;

  /// Focus Timer Looping Ambient Sounds
  final String focusLoopSound; // 'rain', 'zen_drone', 'forest_wind', 'singing_bowl', 'campfire', 'custom', 'none'
  final String? customFocusSoundPath;
  final String? customFocusSoundName;
  final bool focusMultiTrackEnabled;
  final Map<String, double> focusMixerVolumes;

  /// Look-and-feel choices (accent, text size, type, density, gestures, dock…), read
  /// through [UiPrefs]. One open map so new options need no schema change, and they
  /// sync with the rest of the preferences.
  final Map<String, dynamic> ui;

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
    this.morningBriefingTime = '09:30',
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
    this.notificationCadenceHours = 12,
    this.vaultPin,
    this.vaultBiometricsEnabled = true,
    this.aiPersona = 'sarcastic',
    this.cleanHomescreenMode = false,
    this.cardStyle = 'editorial',
    this.subAdminEmails = const [],
    this.subAdminInviteCodes = const [],
    this.activeStreak = 1,
    this.lastActiveDate = '',
    this.longestStreak = 1,
    this.userLocation,
    this.streakFreezesCount = 2,
    this.streakFreezeUsedDate = '',
    this.lastMilestoneCelebrated = 0,
    this.hideDailyBriefing = false,
    this.hideMonthlyBudget = false,
    this.hideExpensesSummary = false,
    this.focusLoopSound = 'rain',
    this.customFocusSoundPath,
    this.customFocusSoundName,
    this.focusMultiTrackEnabled = false,
    this.focusMixerVolumes = const {
      'rain': 0.7,
      'zen_drone': 0.4,
      'forest_wind': 0.3,
      'singing_bowl': 0.2,
      'campfire': 0.5,
    },
    this.ui = const {},
  });

  static const List<int> autoLockChoices = [0, 1, 5, 15, 60];

  String get initial => displayName.trim().isEmpty ? 'N' : displayName.trim()[0].toUpperCase();

  bool isSubAdmin(String? email) {
    if (email == null) return false;
    return subAdminEmails.contains(email.trim().toLowerCase());
  }

  String get notificationCadenceLabel {
    switch (notificationCadenceHours) {
      case 1:
        return 'Every 1 Hour';
      case 2:
        return 'Every 2 Hours';
      case 3:
        return 'Every 3 Hours';
      case 4:
        return 'Every 4 Hours';
      case 6:
        return 'Every 6 Hours';
      case 12:
        return 'Twice Daily (Recommended)';
      case 24:
      case 0:
        return 'Once Daily';
      default:
        return 'Every $notificationCadenceHours Hours';
    }
  }

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
    int? notificationCadenceHours,
    String? vaultPin,
    bool clearVaultPin = false,
    bool? vaultBiometricsEnabled,
    String? aiPersona,
    bool? cleanHomescreenMode,
    String? cardStyle,
    List<String>? subAdminEmails,
    List<String>? subAdminInviteCodes,
    int? activeStreak,
    String? lastActiveDate,
    int? longestStreak,
    String? userLocation,
    bool clearUserLocation = false,
    int? streakFreezesCount,
    String? streakFreezeUsedDate,
    int? lastMilestoneCelebrated,
    bool? hideDailyBriefing,
    bool? hideMonthlyBudget,
    bool? hideExpensesSummary,
    String? focusLoopSound,
    String? customFocusSoundPath,
    String? customFocusSoundName,
    bool? focusMultiTrackEnabled,
    Map<String, double>? focusMixerVolumes,
    Map<String, dynamic>? ui,
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
      notificationCadenceHours: notificationCadenceHours ?? this.notificationCadenceHours,
      vaultPin: clearVaultPin ? null : (vaultPin ?? this.vaultPin),
      vaultBiometricsEnabled: vaultBiometricsEnabled ?? this.vaultBiometricsEnabled,
      aiPersona: aiPersona ?? this.aiPersona,
      cleanHomescreenMode: cleanHomescreenMode ?? this.cleanHomescreenMode,
      cardStyle: cardStyle ?? this.cardStyle,
      subAdminEmails: subAdminEmails ?? this.subAdminEmails,
      subAdminInviteCodes: subAdminInviteCodes ?? this.subAdminInviteCodes,
      activeStreak: activeStreak ?? this.activeStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      longestStreak: longestStreak ?? this.longestStreak,
      userLocation: clearUserLocation ? null : (userLocation ?? this.userLocation),
      streakFreezesCount: streakFreezesCount ?? this.streakFreezesCount,
      streakFreezeUsedDate: streakFreezeUsedDate ?? this.streakFreezeUsedDate,
      lastMilestoneCelebrated: lastMilestoneCelebrated ?? this.lastMilestoneCelebrated,
      hideDailyBriefing: hideDailyBriefing ?? this.hideDailyBriefing,
      hideMonthlyBudget: hideMonthlyBudget ?? this.hideMonthlyBudget,
      hideExpensesSummary: hideExpensesSummary ?? this.hideExpensesSummary,
      focusLoopSound: focusLoopSound ?? this.focusLoopSound,
      customFocusSoundPath: customFocusSoundPath ?? this.customFocusSoundPath,
      customFocusSoundName: customFocusSoundName ?? this.customFocusSoundName,
      focusMultiTrackEnabled: focusMultiTrackEnabled ?? this.focusMultiTrackEnabled,
      focusMixerVolumes: focusMixerVolumes ?? this.focusMixerVolumes,
      ui: ui ?? this.ui,
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
        'notificationCadenceHours': notificationCadenceHours,
        'vaultPin': vaultPin,
        'vaultBiometricsEnabled': vaultBiometricsEnabled,
        'aiPersona': aiPersona,
        'cleanHomescreenMode': cleanHomescreenMode,
        'cardStyle': cardStyle,
        'subAdminEmails': subAdminEmails,
        'subAdminInviteCodes': subAdminInviteCodes,
        'activeStreak': activeStreak,
        'lastActiveDate': lastActiveDate,
        'longestStreak': longestStreak,
        'userLocation': userLocation,
        'streakFreezesCount': streakFreezesCount,
        'streakFreezeUsedDate': streakFreezeUsedDate,
        'lastMilestoneCelebrated': lastMilestoneCelebrated,
        'hideDailyBriefing': hideDailyBriefing,
        'hideMonthlyBudget': hideMonthlyBudget,
        'hideExpensesSummary': hideExpensesSummary,
        'focusLoopSound': focusLoopSound,
        'customFocusSoundPath': customFocusSoundPath,
        'customFocusSoundName': customFocusSoundName,
        'focusMultiTrackEnabled': focusMultiTrackEnabled,
        'focusMixerVolumes': focusMixerVolumes,
        'ui': ui,
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
        morningBriefingTime: j['morningBriefingTime'] as String? ?? '09:30',
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
        notificationCadenceHours: (j['notificationCadenceHours'] as num?)?.toInt() ?? (LocalStore().readInt('notification_cadence_hours') ?? 12),
        vaultPin: j['vaultPin'] as String? ?? LocalStore().readString('vault_pin'),
        vaultBiometricsEnabled: j['vaultBiometricsEnabled'] as bool? ?? (LocalStore().readBool('vault_biometrics_enabled') ?? true),
        aiPersona: j['aiPersona'] as String? ?? 'sarcastic',
        cleanHomescreenMode: j['cleanHomescreenMode'] as bool? ?? false,
        cardStyle: j['cardStyle'] as String? ?? (LocalStore().readString('card_style') ?? 'editorial'),
        subAdminEmails: (j['subAdminEmails'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        subAdminInviteCodes: (j['subAdminInviteCodes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        activeStreak: (j['activeStreak'] as num?)?.toInt() ?? 1,
        lastActiveDate: j['lastActiveDate'] as String? ?? '',
        longestStreak: (j['longestStreak'] as num?)?.toInt() ?? 1,
        userLocation: j['userLocation'] as String?,
        streakFreezesCount: (j['streakFreezesCount'] as num?)?.toInt() ?? 2,
        streakFreezeUsedDate: j['streakFreezeUsedDate'] as String? ?? '',
        lastMilestoneCelebrated: (j['lastMilestoneCelebrated'] as num?)?.toInt() ?? 0,
        hideDailyBriefing: j['hideDailyBriefing'] as bool? ?? false,
        hideMonthlyBudget: j['hideMonthlyBudget'] as bool? ?? false,
        hideExpensesSummary: j['hideExpensesSummary'] as bool? ?? false,
        focusLoopSound: j['focusLoopSound'] as String? ?? 'rain',
        customFocusSoundPath: j['customFocusSoundPath'] as String?,
        customFocusSoundName: j['customFocusSoundName'] as String?,
        focusMultiTrackEnabled: j['focusMultiTrackEnabled'] as bool? ?? false,
        focusMixerVolumes: (j['focusMixerVolumes'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ??
            const {
              'rain': 0.7,
              'zen_drone': 0.4,
              'forest_wind': 0.3,
              'singing_bowl': 0.2,
              'campfire': 0.5,
            },
        ui: (j['ui'] as Map?)?.map((k, v) => MapEntry('$k', v)) ?? const {},
      );
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  static const String storageKey = 'settings';

  /// Synced collection holding one row: the preferences that should follow the
  /// account to a new device (look, layout, budget, streak…).
  static const String syncKey = 'preferences';

  /// Settings that belong to this device only: secrets, admin state and paths to
  /// local files. They are never synced.
  static const Set<String> deviceOnlyKeys = {
    'vaultPin',
    'vaultBiometricsEnabled',
    'isAdminSession',
    'subAdminEmails',
    'subAdminInviteCodes',
    'customFocusSoundPath',
    'customNotificationSoundPath',
    'customAlarmSoundPath',
  };

  AppSettingsNotifier() : super(_load());

  static AppSettings _load() {
    // Theme and motion are mirrored unencrypted so the lock screen can use them.
    final public = LocalStore().readPublic();
    final raw = LocalStore().readMap(storageKey);
    return AppSettings.fromJson({...public, ...?raw});
  }

  /// The synced row for [s]. A local avatar file path is left out until it is backed up.
  static Map<String, dynamic> syncRow(AppSettings s) {
    final json = s.toJson()..removeWhere((k, _) => deviceOnlyKeys.contains(k));
    final avatar = json['avatarCustomPath'];
    if (avatar is String && !avatar.startsWith('https://')) json.remove('avatarCustomPath');
    return {'id': syncKey, ...json, 'updatedAt': DateTime.now().toUtc().toIso8601String()};
  }

  /// Applies a synced preferences [row] over [local]. Device-only settings stay local,
  /// and the app streak keeps whichever record is more recent (or longer, on the same day).
  static Map<String, dynamic> mergeSynced(Map<String, dynamic> local, Map<String, dynamic> row) {
    final remote = {...row}
      ..remove('id')
      ..remove('updatedAt')
      ..removeWhere((k, _) => deviceOnlyKeys.contains(k));
    final merged = {...local, ...remote};
    final localDay = '${local['lastActiveDate'] ?? ''}', remoteDay = '${row['lastActiveDate'] ?? ''}';
    final keepLocal = localDay.compareTo(remoteDay) > 0 ||
        (localDay == remoteDay && ((local['activeStreak'] as num?) ?? 0) > ((row['activeStreak'] as num?) ?? 0));
    if (keepLocal) {
      for (final k in ['activeStreak', 'lastActiveDate', 'streakFreezesCount', 'streakFreezeUsedDate']) {
        if (local.containsKey(k)) merged[k] = local[k];
      }
    }
    final longest = [local['longestStreak'], row['longestStreak']].whereType<num>().fold<num>(0, (a, b) => a > b ? a : b);
    merged['longestStreak'] = longest.toInt();
    return merged;
  }

  @override
  set state(AppSettings value) {
    super.state = value;
    LocalStore().writeMap(storageKey, value.toJson());
    LocalStore().writePublic({'themeMode': value.themeMode.name, 'reducedMotion': value.reducedMotion});
    LocalStore().writeList(syncKey, [syncRow(value)]);
  }

  /// Re-reads settings after a sync or import, folding in the synced preferences row.
  void reloadFromStore() {
    final local = _load().toJson();
    final rows = LocalStore().readList<Map<String, dynamic>>(syncKey, (j) => j);
    final merged = rows == null || rows.isEmpty ? local : mergeSynced(local, rows.first);
    final next = AppSettings.fromJson(merged);
    super.state = next;
    LocalStore().writeMap(storageKey, next.toJson());
    LocalStore().writePublic({'themeMode': next.themeMode.name, 'reducedMotion': next.reducedMotion});
  }

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

  void resetAvatar() {
    state = state.copyWith(clearAvatarPreset: true, clearAvatarCustomPath: true);
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

  void setNotificationCadenceHours(int hours) {
    LocalStore().writeInt('notification_cadence_hours', hours);
    state = state.copyWith(notificationCadenceHours: hours);
  }

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

  void setCleanHomescreenMode(bool value) {
    LocalStore().writeBool('clean_homescreen_mode', value);
    state = state.copyWith(cleanHomescreenMode: value);
  }

  /// Sets one look-and-feel option (see [UiPrefs]); null restores the default.
  void setUi(String key, Object? value) {
    final next = {...state.ui};
    if (value == null) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    state = state.copyWith(ui: next);
  }

  void setCardStyle(String value) {
    LocalStore().writeString('card_style', value);
    state = state.copyWith(cardStyle: value);
  }

  void promoteSubAdmin(String email) {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty || state.subAdminEmails.contains(clean)) return;
    final updated = [...state.subAdminEmails, clean];
    state = state.copyWith(subAdminEmails: updated);
  }

  void revokeSubAdmin(String email) {
    final clean = email.trim().toLowerCase();
    final updated = state.subAdminEmails.where((e) => e != clean).toList();
    state = state.copyWith(subAdminEmails: updated);
  }

  String createSubAdminInviteCode() {
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    final randomSuffix = (1000 + (DateTime.now().microsecond % 9000)).toString();
    final code = 'NT-SUB-$now-$randomSuffix';
    final updated = [...state.subAdminInviteCodes, code];
    state = state.copyWith(subAdminInviteCodes: updated);
    return code;
  }

  void revokeSubAdminInviteCode(String code) {
    final updated = state.subAdminInviteCodes.where((c) => c != code).toList();
    state = state.copyWith(subAdminInviteCodes: updated);
  }

  bool redeemSubAdminInviteCode(String code, String email) {
    final trimmedCode = code.trim().toUpperCase();
    if (!state.subAdminInviteCodes.contains(trimmedCode)) return false;
    revokeSubAdminInviteCode(trimmedCode);
    promoteSubAdmin(email);
    return true;
  }

  bool isSubAdmin(String email) {
    final clean = email.trim().toLowerCase();
    return state.subAdminEmails.contains(clean);
  }

  void setActiveStreak(int streak) => state = state.copyWith(activeStreak: streak);
  void setLastActiveDate(String date) => state = state.copyWith(lastActiveDate: date);
  void setLongestStreak(int streak) => state = state.copyWith(longestStreak: streak);
  void setUserLocation(String? loc) => state = state.copyWith(userLocation: loc, clearUserLocation: loc == null);
  void useStreakFreeze(String date) {
    if (state.streakFreezesCount > 0) {
      state = state.copyWith(
        streakFreezesCount: state.streakFreezesCount - 1,
        streakFreezeUsedDate: date,
      );
    }
  }
  void addStreakFreeze([int count = 1]) => state = state.copyWith(streakFreezesCount: state.streakFreezesCount + count);
  void setLastMilestoneCelebrated(int milestone) => state = state.copyWith(lastMilestoneCelebrated: milestone);
  void setHideDailyBriefing(bool value) => state = state.copyWith(hideDailyBriefing: value);
  void setHideMonthlyBudget(bool value) => state = state.copyWith(hideMonthlyBudget: value);
  void setHideExpensesSummary(bool value) => state = state.copyWith(hideExpensesSummary: value);
  void setFocusLoopSound(String sound, {String? customPath, String? customName}) {
    state = state.copyWith(
      focusLoopSound: sound,
      customFocusSoundPath: customPath,
      customFocusSoundName: customName,
    );
  }

  void setFocusMultiTrackEnabled(bool enabled) => state = state.copyWith(focusMultiTrackEnabled: enabled);

  void setFocusTrackVolume(String trackId, double volume) {
    final updated = Map<String, double>.from(state.focusMixerVolumes)..[trackId] = volume.clamp(0.0, 1.0);
    state = state.copyWith(focusMixerVolumes: updated);
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

/// Typed access to [AppSettings.ui], with the defaults in one place.
class UiPrefs {
  final Map<String, dynamic> _m;
  const UiPrefs(this._m);
  factory UiPrefs.of(AppSettings s) => UiPrefs(s.ui);

  static const accents = ['terracotta', 'ink', 'olive', 'plum', 'gold'];
  static const textScales = {'smaller': 0.92, 'regular': 1.0, 'larger': 1.12, 'largest': 1.25};
  static const headlines = {'classic': 'Bodoni Moda', 'modern': 'DM Sans', 'technical': 'Space Grotesk'};
  static const densities = {'compact': 8.0, 'comfortable': 13.0, 'airy': 18.0};

  String get accent => _m['accent'] as String? ?? 'terracotta';
  String get textScale => _m['textScale'] as String? ?? 'regular';
  double get textScaleFactor => textScales[textScale] ?? 1.0;
  String get headline => _m['headline'] as String? ?? 'classic';
  String get density => _m['density'] as String? ?? 'comfortable';
  double get rowPadding => densities[density] ?? 13.0;
  bool get swipeActions => _m['swipeActions'] as bool? ?? true;
  bool get confirmDeletes => _m['confirmDeletes'] as bool? ?? false;
  bool get celebrate => _m['celebrate'] as bool? ?? true;

  /// Shell indexes shown as words in the editorial dock (four).
  List<int> get dock => ((_m['dock'] as List?) ?? const [0, 1, 2, 3]).map((e) => (e as num).toInt()).toList();

  /// Modules hidden from the menu and dock.
  Set<int> get hiddenModules => ((_m['hidden'] as List?) ?? const []).map((e) => (e as num).toInt()).toSet();
}

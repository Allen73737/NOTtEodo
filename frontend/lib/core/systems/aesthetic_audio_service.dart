import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../performance/sanctuary_motion_engine.dart';
import '../state/app_settings.dart';
import '../widgets/app_toast_engine.dart';

/// A definition of an aesthetic audio cue
class AestheticSound {
  final String id;
  final String name;
  final String subtitle;
  final String styleDescription;
  final IconData icon;
  final Color accentColor;
  final bool isAlarm;

  const AestheticSound({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.styleDescription,
    required this.icon,
    required this.accentColor,
    this.isAlarm = false,
  });
}

/// Service providing curated, aesthetic notification and alarm sounds
/// with custom device audio upload and interactive real-time previewing.
class AestheticAudioService {
  static final AestheticAudioService _instance = AestheticAudioService._internal();
  factory AestheticAudioService() => _instance;
  AestheticAudioService._internal();

  static const MethodChannel _audioChannel = MethodChannel('notteodo/audio');

  /// 5 distinct, highly aesthetic and trendy notification sounds (completely different styles)
  static const List<AestheticSound> notificationPresets = [
    AestheticSound(
      id: 'velvet_obsidian',
      name: 'Velvet Obsidian',
      subtitle: 'Warm Glass Marimba',
      styleDescription: 'Deep, rounded wooden marimba tone. Subtle and understated.',
      icon: LucideIcons.disc,
      accentColor: Color(0xFFD9725B),
    ),
    AestheticSound(
      id: 'celestial_shimmer',
      name: 'Celestial Shimmer',
      subtitle: 'Crystal Bell Chime',
      styleDescription: 'High-frequency crystal harmonics with an airy decay.',
      icon: LucideIcons.sparkles,
      accentColor: Color(0xFFE8927C),
    ),
    AestheticSound(
      id: 'minimalist_ping',
      name: 'Minimalist Ping',
      subtitle: 'Digital Micro-Drop',
      styleDescription: 'Ultra-short precision droplet with zero resonance.',
      icon: LucideIcons.radio,
      accentColor: Color(0xFFC48B71),
    ),
    AestheticSound(
      id: 'analog_switch',
      name: 'Analog Switch',
      subtitle: 'Tactile Mechanical Key',
      styleDescription: 'Satisfying mechanical keyboard click with dampener pad.',
      icon: LucideIcons.toggleRight,
      accentColor: Color(0xFFD9725B),
    ),
    AestheticSound(
      id: 'zen_bloom',
      name: 'Zen Bloom',
      subtitle: 'Acoustic Singing Bowl',
      styleDescription: 'Gentle bronze resonance that expands smoothly into silence.',
      icon: LucideIcons.flower2,
      accentColor: Color(0xFFE8927C),
    ),
  ];

  /// 5 distinct, highly aesthetic and trendy alarm/reminder sounds (entirely different character)
  static const List<AestheticSound> alarmPresets = [
    AestheticSound(
      id: 'horology_cascade',
      name: 'Horology Cascade',
      subtitle: 'Swiss Escapement Rhythms',
      styleDescription: 'Mechanical watch tick cadence ascending into a melodic chime.',
      icon: LucideIcons.watch,
      accentColor: Color(0xFFD9725B),
      isAlarm: true,
    ),
    AestheticSound(
      id: 'golden_dawn',
      name: 'Sunrise Swell',
      subtitle: 'Ambient Analog Swell',
      styleDescription: 'Warm analog synthesizer swell that gently increases in presence.',
      icon: LucideIcons.sunMedium,
      accentColor: Color(0xFFE8927C),
      isAlarm: true,
    ),
    AestheticSound(
      id: 'terracotta_pulse',
      name: 'Terracotta Pulse',
      subtitle: 'Lo-Fi Rhythmic Pulse',
      styleDescription: 'Mellow percussion beat with warm rhythmic bell taps.',
      icon: LucideIcons.activity,
      accentColor: Color(0xFFD9725B),
      isAlarm: true,
    ),
    AestheticSound(
      id: 'architect_echo',
      name: 'Architect Echo',
      subtitle: 'Resonant Temple Gong',
      styleDescription: 'Deep, deliberate woodblock and gong resonance for grounded focus.',
      icon: LucideIcons.landmark,
      accentColor: Color(0xFFC48B71),
      isAlarm: true,
    ),
    AestheticSound(
      id: 'starlight_aura',
      name: 'Starlight Aura',
      subtitle: 'Ethereal Harp Glissando',
      styleDescription: 'Serene, celestial harp strings floating through spatial reverberation.',
      icon: LucideIcons.orbit,
      accentColor: Color(0xFFE8927C),
      isAlarm: true,
    ),
  ];

  /// Previews an aesthetic sound with bespoke haptic choreography and acoustic cues
  Future<void> previewSound({
    required String soundId,
    String? customPath,
    bool isAlarm = false,
  }) async {
    // 1. Tactile haptic feedback matching the sonic identity
    if (soundId == 'analog_switch') {
      HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 60));
      HapticFeedback.lightImpact();
    } else if (soundId == 'celestial_shimmer' || soundId == 'starlight_aura') {
      HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 80));
      HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 140));
      HapticFeedback.lightImpact();
    } else if (soundId == 'horology_cascade') {
      for (int i = 0; i < 4; i++) {
        HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 90));
      }
      HapticFeedback.mediumImpact();
    } else if (soundId == 'golden_dawn' || soundId == 'zen_bloom') {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    // 2. Play native acoustic audio wave synthesized through AudioTrack
    try {
      if (!kIsWeb) {
        if (Platform.isAndroid || Platform.isIOS) {
          await _audioChannel.invokeMethod('playSound', {
            'soundId': soundId,
            'isAlarm': isAlarm,
            'customPath': customPath,
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback on web/desktop
    if (isAlarm) {
      SystemSound.play(SystemSoundType.alert);
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Lets the user upload a custom sound file from their device
  Future<void> pickCustomSound({
    required bool isAlarm,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final path = file.path;
        final name = file.name;

        if (isAlarm) {
          ref.read(appSettingsProvider.notifier).setAlarmSound(
            'custom',
            customPath: path,
            customName: name,
          );
        } else {
          ref.read(appSettingsProvider.notifier).setNotificationSound(
            'custom',
            customPath: path,
            customName: name,
          );
        }

        SanctuaryHapticEngine.sealImpression();
        if (context.mounted) {
          AppToastEngine().showToast(
            context,
            title: isAlarm ? 'Custom Alarm Set' : 'Custom Notification Set',
            message: '"$name" selected from your device.',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToastEngine().showToast(
          context,
          title: 'Upload Audio',
          message: 'Could not select audio file: $e',
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class UserFeedbackItem {
  final String id;
  final String type; // 'feature_suggestion', 'general_feedback', 'bug_report', 'ui_enhancement'
  final String title;
  final String description;
  final String impact; // 'nice_to_have', 'important', 'critical'
  final String category; // 'General', 'AI Assistant', 'Tasks & Planner', 'Notes & Vault', 'Design & UI', etc.
  final String userIdentifier;
  final String? userEmail;
  final DateTime submittedAt;
  final String status; // 'pending', 'reviewed', 'planned', 'resolved'
  final String? adminNotes;
  final String? deviceInfo;

  const UserFeedbackItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.impact,
    required this.category,
    required this.userIdentifier,
    this.userEmail,
    required this.submittedAt,
    this.status = 'pending',
    this.adminNotes,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'impact': impact,
        'category': category,
        'user_identifier': userIdentifier,
        'user_email': userEmail,
        'submitted_at': submittedAt.toIso8601String(),
        'status': status,
        'admin_notes': adminNotes,
        'device_info': deviceInfo,
      };

  factory UserFeedbackItem.fromJson(Map<String, dynamic> json) {
    return UserFeedbackItem(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      type: json['type'] as String? ?? 'feature_suggestion',
      title: json['title'] as String? ?? 'Untitled Suggestion',
      description: json['description'] as String? ?? '',
      impact: json['impact'] as String? ?? 'nice_to_have',
      category: json['category'] as String? ?? 'General',
      userIdentifier: json['user_identifier'] as String? ?? 'Sanctuary Curator',
      userEmail: json['user_email'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'] as String) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
              : DateTime.now()),
      status: json['status'] as String? ?? 'pending',
      adminNotes: json['admin_notes'] as String?,
      deviceInfo: json['device_info'] as String?,
    );
  }

  UserFeedbackItem copyWith({
    String? status,
    String? adminNotes,
    String? title,
    String? description,
    String? impact,
    String? category,
  }) {
    return UserFeedbackItem(
      id: id,
      type: type,
      title: title ?? this.title,
      description: description ?? this.description,
      impact: impact ?? this.impact,
      category: category ?? this.category,
      userIdentifier: userIdentifier,
      userEmail: userEmail,
      submittedAt: submittedAt,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      deviceInfo: deviceInfo,
    );
  }

  String get typeLabel => switch (type) {
        'feature_suggestion' => 'Feature Suggestion',
        'general_feedback' => 'App Feedback',
        'bug_report' => 'Bug Report',
        'ui_enhancement' => 'UI / Aesthetic Request',
        _ => 'Feedback',
      };

  IconData get typeIcon => switch (type) {
        'feature_suggestion' => LucideIcons.sparkles,
        'general_feedback' => LucideIcons.messageSquare,
        'bug_report' => LucideIcons.bug,
        'ui_enhancement' => LucideIcons.palette,
        _ => LucideIcons.messageSquare,
      };

  Color get typeColor => switch (type) {
        'feature_suggestion' => const Color(0xFFD9725B), // Warm Terracotta
        'general_feedback' => const Color(0xFF8FA878), // Warm Olive Sage
        'bug_report' => const Color(0xFFC84B31), // Coral Crimson
        'ui_enhancement' => const Color(0xFFD4AF37), // Executive Gold
        _ => const Color(0xFFD9725B),
      };

  String get impactLabel => switch (impact) {
        'critical' => '🔥 Game Changer',
        'important' => '⚡ High Priority',
        'nice_to_have' => '🌿 Nice to Have',
        _ => 'Standard',
      };

  String get statusLabel => switch (status) {
        'reviewed' => 'Under Review',
        'planned' => 'Planned for Release',
        'resolved' => 'Completed / Implemented',
        _ => 'Pending Review',
      };

  Color get statusColor => switch (status) {
        'reviewed' => const Color(0xFFD4AF37), // Gold
        'planned' => const Color(0xFF8FA878), // Olive Sage
        'resolved' => const Color(0xFF5A8E65), // Emerald
        _ => const Color(0xFFD9725B), // Terracotta
      };
}


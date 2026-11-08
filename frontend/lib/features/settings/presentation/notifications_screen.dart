import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/motion/motion.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/services/device_notification_service.dart';
import '../../../core/state/notification_log_state.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/bento_pod.dart';

/// Dedicated Notification History & Log Screen inside Settings.
/// Displays an audit trail of all alerts, reminders, daily engagement, alarms, and system notifications.
/// Supports filtering by user profile, category, read status, and search keywords.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedUser = 'All Users';
  NotificationCategory _selectedCategory = NotificationCategory.all;
  bool _onlyUnread = false;
  bool _searchVisible = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && dt.day == now.day) {
      return 'Today · ${DateFormat('hh:mm a').format(dt)}';
    }
    if (diff.inDays < 2 && dt.day == now.subtract(const Duration(days: 1)).day) {
      return 'Yesterday · ${DateFormat('hh:mm a').format(dt)}';
    }
    return DateFormat('MMM d · hh:mm a').format(dt);
  }

  IconData _categoryIcon(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.reminder:
        return LucideIcons.bellRing;
      case NotificationCategory.dailyEngagement:
        return LucideIcons.flame;
      case NotificationCategory.alarm:
        return LucideIcons.clock;
      case NotificationCategory.aiAssistant:
        return LucideIcons.sparkles;
      case NotificationCategory.security:
        return LucideIcons.shieldCheck;
      case NotificationCategory.system:
      case NotificationCategory.all:
        return LucideIcons.bell;
    }
  }

  Color _categoryColor(NotificationCategory cat, bool isDark) {
    switch (cat) {
      case NotificationCategory.reminder:
        return isDark ? const Color(0xFFE8927C) : AppColors.secondary;
      case NotificationCategory.dailyEngagement:
        return const Color(0xFFD9725B); // Terracotta flame
      case NotificationCategory.alarm:
        return const Color(0xFFD9725B);
      case NotificationCategory.aiAssistant:
        return isDark ? const Color(0xFFE8927C) : const Color(0xFFD9725B);
      case NotificationCategory.security:
        return isDark ? const Color(0xFFE5C07B) : const Color(0xFF8A6D3B);
      case NotificationCategory.system:
      case NotificationCategory.all:
        return isDark ? AppColors.darkTextPrimary : AppColors.primary;
    }
  }

  void _showDetailModal(BuildContext context, NotificationLogEntry entry, bool isDark) {
    ref.read(notificationLogsProvider.notifier).markAsRead(entry.id);
    final accent = _categoryColor(entry.category, isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? const Color(0xFF262626) : const Color(0xFFE8E3D8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_categoryIcon(entry.category), size: 18, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.category.label.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: accent,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d, y · hh:mm:ss a').format(entry.timestamp),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                entry.title,
                style: GoogleFonts.bodoniModa(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                entry.message,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? const Color(0xFFE8DFC8) : const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECIPIENT USER',
                        style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.userIdentifier,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'DISPATCH CHANNEL',
                        style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.channel,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        ref.read(notificationLogsProvider.notifier).deleteEntry(entry.id);
                        Navigator.pop(context);
                        SanctuaryHapticEngine.dialDetent();
                      },
                      icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                      label: const Text('Delete Entry', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final allLogs = ref.watch(notificationLogsProvider);
    final notifier = ref.read(notificationLogsProvider.notifier);
    final availableUsers = ['All Users', ...notifier.availableUsers];

    // Filter by user
    List<NotificationLogEntry> filtered = allLogs;
    if (_selectedUser != 'All Users') {
      filtered = filtered.where((e) => e.userIdentifier == _selectedUser).toList();
    }

    // Filter by category
    if (_selectedCategory != NotificationCategory.all) {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    // Filter by unread
    if (_onlyUnread) {
      filtered = filtered.where((e) => !e.isRead).toList();
    }

    // Filter by search query
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.message.toLowerCase().contains(query) ||
            e.userIdentifier.toLowerCase().contains(query);
      }).toList();
    }

    final unreadCount = filtered.where((e) => !e.isRead).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: primaryTextColor),
          onPressed: () {
            SanctuaryHapticEngine.selection();
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NOTIFICATIONS & LOGS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: accentColor,
              ),
            ),
            Text(
              'Audit Trail & Dispatched Alerts',
              style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _searchVisible ? 'Hide search' : 'Search logs',
            icon: Icon(_searchVisible ? LucideIcons.searchX : LucideIcons.search, size: 18, color: primaryTextColor),
            onPressed: () {
              SanctuaryHapticEngine.selection();
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) _searchCtrl.clear();
              });
            },
          ),
          IconButton(
            tooltip: 'Mark all as read',
            icon: Icon(LucideIcons.checkCheck, size: 18, color: primaryTextColor),
            onPressed: () {
              SanctuaryHapticEngine.sealImpression();
              notifier.markAllAsRead(user: _selectedUser);
              AppToastEngine().showToast(
                context,
                title: 'Marked as Read',
                message: 'All notifications for $_selectedUser marked as read.',
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            icon: Icon(LucideIcons.moreVertical, size: 18, color: primaryTextColor),
            onSelected: (val) async {
              if (val == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
                    title: const Text('Clear Notification Logs?'),
                    content: Text('This will clear log entries for "$_selectedUser".'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  SanctuaryHapticEngine.sealImpression();
                  notifier.clearAll(user: _selectedUser);
                }
              } else if (val == 'test') {
                SanctuaryHapticEngine.sealImpression();
                final ok = await DeviceNotificationService().showSystemNotification(
                  title: 'Test Notification Log',
                  message: 'Manual test alert dispatched and recorded in user logs.',
                );
                AppToastEngine().notify(
                  title: ok ? 'Notification Triggered' : 'Notification Recorded',
                  message: 'Logged under ${NotificationLogger.resolveActiveUser()}',
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 15, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Clear Logs for Selected User'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    Icon(LucideIcons.send, size: 15),
                    SizedBox(width: 8),
                    Text('Simulate Test Alert'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Box (Collapsible)
          if (_searchVisible) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: GoogleFonts.dmSans(color: primaryTextColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search notification logs by title, message or user…',
                  hintStyle: GoogleFonts.dmSans(color: subtextColor, fontSize: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF141414) : const Color(0xFFF3EFE9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: subtextColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],

          // 2. User Filter Selector Card
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141210) : const Color(0xFFF7F5F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFE2DDD2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.userCheck, size: 14, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          'FILTER BY PARTICULAR USER',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount UNREAD',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableUsers.map((u) {
                      final isSelected = _selectedUser == u;
                      final userCount = u == 'All Users'
                          ? allLogs.length
                          : allLogs.where((e) => e.userIdentifier == u).length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('$u ($userCount)'),
                          selected: isSelected,
                          onSelected: (_) {
                            SanctuaryHapticEngine.selection();
                            setState(() => _selectedUser = u);
                          },
                          labelStyle: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? (isDark ? Colors.black : Colors.white) : primaryTextColor,
                          ),
                          selectedColor: accentColor,
                          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(
                            color: isSelected
                                ? accentColor
                                : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFDDD8CE)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 3. Category & Unread Filters Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                FilterChip(
                  avatar: Icon(
                    _onlyUnread ? LucideIcons.checkCircle2 : LucideIcons.circle,
                    size: 14,
                    color: _onlyUnread ? (isDark ? Colors.black : Colors.white) : subtextColor,
                  ),
                  label: const Text('Unread Only'),
                  selected: _onlyUnread,
                  onSelected: (val) {
                    SanctuaryHapticEngine.selection();
                    setState(() => _onlyUnread = val);
                  },
                  labelStyle: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: _onlyUnread ? FontWeight.bold : FontWeight.normal,
                    color: _onlyUnread ? (isDark ? Colors.black : Colors.white) : primaryTextColor,
                  ),
                  selectedColor: accentColor,
                  backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF3EFE9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2DDD2)),
                ),
                const SizedBox(width: 8),
                for (final cat in NotificationCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.label),
                      selected: _selectedCategory == cat,
                      onSelected: (_) {
                        SanctuaryHapticEngine.selection();
                        setState(() => _selectedCategory = cat);
                      },
                      labelStyle: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: _selectedCategory == cat ? FontWeight.bold : FontWeight.normal,
                        color: _selectedCategory == cat
                            ? (isDark ? Colors.black : Colors.white)
                            : primaryTextColor,
                      ),
                      selectedColor: _categoryColor(cat, isDark),
                      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF3EFE9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2DDD2)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4. Notification History List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.bellOff, size: 36, color: subtextColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No Notifications Found',
                            style: GoogleFonts.bodoniModa(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedUser == 'All Users'
                                ? 'No alerts match your current filter settings.'
                                : 'No notifications logged for user "$_selectedUser".',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              SanctuaryHapticEngine.selection();
                              setState(() {
                                _selectedUser = 'All Users';
                                _selectedCategory = NotificationCategory.all;
                                _onlyUnread = false;
                                _searchCtrl.clear();
                              });
                            },
                            icon: const Icon(LucideIcons.rotateCcw, size: 14),
                            label: const Text('Reset All Filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      final catColor = _categoryColor(item.category, isDark);

                      return Reveal(
                        style: RevealStyle.slideIn,
                        distance: 14,
                        child: Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(LucideIcons.trash2, color: Colors.white, size: 18),
                          ),
                          onDismissed: (_) {
                            notifier.deleteEntry(item.id);
                            SanctuaryHapticEngine.dialDetent();
                          },
                          child: InkWell(
                            onTap: () => _showDetailModal(context, item, isDark),
                            borderRadius: BorderRadius.circular(14),
                            child: BentoPod(
                              style: item.isRead ? PodTextureStyle.glass : PodTextureStyle.polaroid,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Icon Badge
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: isDark ? 0.18 : 0.10),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: catColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Icon(_categoryIcon(item.category), size: 16, color: catColor),
                                  ),
                                  const SizedBox(width: 12),
                                  // Content Body
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 13,
                                                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                                  color: primaryTextColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _formatTimestamp(item.timestamp),
                                                  style: GoogleFonts.dmSans(fontSize: 10, color: subtextColor),
                                                ),
                                                if (!item.isRead) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    width: 7,
                                                    height: 7,
                                                    decoration: BoxDecoration(
                                                      color: accentColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.message,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: subtextColor,
                                            height: 1.35,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        // Metadata pills (channel, user)
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBE6DC),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.channel,
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: subtextColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: catColor.withValues(alpha: 0.10),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  item.userIdentifier,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.spaceGrotesk(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: catColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

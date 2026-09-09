import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/stitch_logo_widget.dart';

import '../../../core/widgets/fluid_ui_effects.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURATOR SANCTUARY PROFILE', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Curator Profile',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Profile Card
          BentoPod(
            style: PodTextureStyle.glass,
            showWaxSeal: true,
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar Container with Stitch Monogram N
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.secondary, width: 2),
                          ),
                          child: const Center(
                            child: StitchLogoWidget(fontSize: 20, showTagline: false, showMonogramN: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Allen Curator', style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
                                child: Text('PRO CURATOR', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('allen@notteodo.com · Joined Aug 2026', style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const StitchMonogramNWidget(size: 18),
                              const SizedBox(width: 6),
                              Text('Google Stitch Design Verified', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Sanctuary Statistics Grid
                Row(
                  children: [
                    _statItem('24', 'Notes Saved', primaryTextColor, subtextColor),
                    _statItem('18', 'Ritual Streaks', primaryTextColor, subtextColor),
                    _statItem('4', 'Trips Planned', primaryTextColor, subtextColor),
                    _statItem('100%', 'Local Vault', primaryTextColor, subtextColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Curator Achievement Milestone Badges
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CURATOR SANCTUARY MILESTONES', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _badgeCard('🌿', '100 Days Serene', 'Consistency Streak', primaryTextColor, subtextColor),
                    _badgeCard('🎨', 'Design Virtuoso', 'Moodboard Master', primaryTextColor, subtextColor),
                    _badgeCard('✈️', 'Passport Wanderer', '4 Trips Curated', primaryTextColor, subtextColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Sanctuary Spaces Card
          BentoPod(
            style: PodTextureStyle.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE SPACES & COLLECTIONS', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                const SizedBox(height: 12),

                _spaceTile('🎓 Academic Space', 'Computer Networks, Algorithms, Unit 1 Notes', '5 Collections', primaryTextColor, subtextColor),
                const SizedBox(height: 10),
                _spaceTile('🎨 Studio Fashion Space', 'Goa Trip Outfits, Linen Collection, Loafers', '8 Items', primaryTextColor, subtextColor),
                const SizedBox(height: 10),
                _spaceTile('✈️ Travel & Passport Space', 'Goa Villa 2026, Flights IX-382, Settlements', '3 Trips', primaryTextColor, subtextColor),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Action Button
          if (onLogout != null)
            BouncyTouchEffect(
              pressedScale: 0.94,
              onTap: onLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.logOut, size: 18, color: AppColors.secondary),
                    const SizedBox(width: 10),
                    Text(
                      'Log Out & Seal Sanctuary Session',
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badgeCard(String icon, String title, String subtitle, Color primaryTextColor, Color subtextColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(title, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(subtitle, style: GoogleFonts.dmSans(fontSize: 9, color: subtextColor), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String val, String label, Color primaryTextColor, Color subtextColor) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: subtextColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _spaceTile(String title, String desc, String badge, Color primaryTextColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text(desc, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(badge, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

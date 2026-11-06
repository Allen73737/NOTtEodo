import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/stitched_leather_card.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import 'encrypted_vault_view.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/utils/date_labels.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  bool _showVault = false;
  int _selectedMemoirIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final memoirs = ref.watch(journalProvider).where((m) => !m.isPrivate).toList();

    if (_showVault) {
      return EncryptedVaultView(onClose: () => setState(() => _showVault = false));
    }

    final activeMemoir = memoirs.isNotEmpty && _selectedMemoirIndex < memoirs.length
        ? memoirs[_selectedMemoirIndex]
        : (memoirs.isNotEmpty ? memoirs.first : null);

    return SingleChildScrollView(
      physics: SanctuaryMotionEngine.fluidPhysics,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
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
                    Text('LIFESTYLE', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Journal',
                      style: GoogleFonts.bodoniModa(fontSize: 26, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => openEntryEditor(context, EntryKind.memoir),
                icon: const Icon(LucideIcons.plus, size: 14),
                label: Text('New Entry', style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.bold)),
              )),
              const SizedBox(width: 8),
              Pressable(pressedScale: 0.95, hoverLift: 0, child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => setState(() => _showVault = true),
                icon: Icon(LucideIcons.lock, size: 13, color: accentColor),
                label: Text('Vault', style: GoogleFonts.dmSans(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
              )),
            ],
          ),
          const SizedBox(height: 24),

          // The selected entry, in full.
          if (activeMemoir != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF000000) : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(activeMemoir.mood.toUpperCase(),
                            style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: accentColor)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(DateLabels.dateTime(activeMemoir.createdAt),
                            style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                      ),
                      IconButton(
                        tooltip: 'Edit entry',
                        icon: Icon(LucideIcons.pencil, size: 16, color: subtextColor),
                        onPressed: () => openEntryEditor(context, EntryKind.memoir, editing: activeMemoir),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeMemoir.title,
                    style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    activeMemoir.excerpt,
                    style: GoogleFonts.dmSans(fontSize: 14, height: 1.6, color: primaryTextColor.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Hand-Stitched Leather Journal Memoirs List
          if (memoirs.isEmpty)
            const SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: EmptyState(
                    icon: LucideIcons.bookOpen,
                    title: 'Your journal is quiet',
                    message: 'Tap "New Entry" to write a reflection.',
                  ),
                ),
              ),
            )
          else
            MotionColumn(
  spacing: 0,
  // Pinterest-style board on wide screens; one column on phones.
  minTileWidth: 320,
  children: [
    for (var idx = 0; idx < memoirs.length; idx++)
      Builder(key: ValueKey(memoirs[idx].id), builder: (context) {
                final memoir = memoirs[idx];
                return Reveal(style: RevealStyle.slideIn, distance: 18, child: GestureDetector(
                  onTap: () => setState(() => _selectedMemoirIndex = idx),
                  child: StaggeredEntrance(
                    index: idx,
                    stepDelayMs: 60,
                    child: StitchedLeatherCard(
                      title: memoir.title,
                      date: memoir.date,
                      content: memoir.excerpt,
                    ),
                  ),
                ));
              }),
  ],
),
        ].revealed(),
          ),
        ),
      ),
    );
  }
}

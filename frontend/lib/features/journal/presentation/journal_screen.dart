import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/circular_spectrum_ring.dart';
import '../../../core/widgets/stitched_leather_card.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import 'encrypted_vault_view.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  bool _isPlaying = false;
  bool _showVault = false;
  int _selectedMemoirIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final memoirs = ref.watch(journalProvider);

    if (_showVault) {
      return EncryptedVaultView(onClose: () => setState(() => _showVault = false));
    }

    final activeMemoir = memoirs.isNotEmpty && _selectedMemoirIndex < memoirs.length
        ? memoirs[_selectedMemoirIndex]
        : (memoirs.isNotEmpty ? memoirs.first : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
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
                    Text('TACTILE VOICE JOURNAL SANCTUARY', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Voice Journal & Memoirs',
                      style: GoogleFonts.bodoniModa(fontSize: 26, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => setState(() => _showVault = true),
                icon: Icon(LucideIcons.lock, size: 13, color: accentColor),
                label: Text('Vault', style: GoogleFonts.dmSans(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Active Voice Memoir Audio Deck Player
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NOW PLAYING MEMOIR',
                        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accentColor),
                      ),
                      Text(activeMemoir.duration, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activeMemoir.title,
                    style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  const SizedBox(height: 16),

                  // Circular Spectrum Visualizer Ring
                  Center(
                    child: CircularSpectrumRing(
                      isPlaying: _isPlaying,
                      child: IconButton(
                        iconSize: 42,
                        icon: Icon(_isPlaying ? LucideIcons.pauseCircle : LucideIcons.playCircle, color: accentColor),
                        onPressed: () => setState(() => _isPlaying = !_isPlaying),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Hand-Stitched Leather Journal Memoirs List
          if (memoirs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('No memoirs recorded. Use the central + dial to record a reflection.', style: GoogleFonts.dmSans(color: subtextColor)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: memoirs.length,
              itemBuilder: (context, idx) {
                final memoir = memoirs[idx];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMemoirIndex = idx;
                      _isPlaying = true;
                    });
                  },
                  child: StaggeredEntrance(
                    index: idx,
                    stepDelayMs: 60,
                    child: StitchedLeatherCard(
                      title: memoir.title,
                      date: memoir.date,
                      content: memoir.excerpt,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

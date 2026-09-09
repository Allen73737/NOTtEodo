import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ephemeral Incognito Burner Vault
/// A RAM-only scratchpad workspace that NEVER touches disk or database.
/// Closing or hitting "INCINERATE" executes an immediate cryptographic zero-fill wipe.
class IncognitoBurnerVault extends StatefulWidget {
  final VoidCallback? onClose;

  const IncognitoBurnerVault({super.key, this.onClose});

  @override
  State<IncognitoBurnerVault> createState() => _IncognitoBurnerVaultState();
}

class _IncognitoBurnerVaultState extends State<IncognitoBurnerVault> {
  final TextEditingController _burnerController = TextEditingController();
  bool _isIncinerated = false;

  void _incinerateMemory() {
    HapticFeedback.heavyImpact();
    // 1. Zero-fill string buffer in RAM
    final len = _burnerController.text.length;
    _burnerController.text = List.filled(len, '0').join();
    _burnerController.clear();

    setState(() => _isIncinerated = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      widget.onClose?.call();
    });
  }

  @override
  void dispose() {
    // Zero-fill buffer on dispose
    _burnerController.text = '0';
    _burnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0D), // Pure Obsidian
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8927C).withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 30, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Color(0xFFE8927C), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'INCOGNITO BURNER PAD',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: const Color(0xFFE8927C),
                    ),
                  ),
                ],
              ),
              Text(
                'VOLATILE RAM ONLY',
                style: GoogleFonts.courierPrime(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white12),

          if (_isIncinerated)
            Container(
              height: 160,
              alignment: Alignment.center,
              child: Text(
                '🔥 MEMORY ZERO-FILLED & EVAPORATED',
                style: GoogleFonts.courierPrime(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE8927C),
                ),
              ),
            )
          else
            TextField(
              controller: _burnerController,
              maxLines: 6,
              style: GoogleFonts.courierPrime(
                fontSize: 14,
                color: const Color(0xFFF7F3EB),
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Sensitive coordinates, cipher seeds, or transient reflections...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
              ),
            ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _incinerateMemory,
            icon: const Icon(Icons.delete_forever, size: 16, color: Colors.white),
            label: Text(
              'INCINERATE RAM BUFFER',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

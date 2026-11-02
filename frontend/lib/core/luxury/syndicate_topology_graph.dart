import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../state/sanctuary_state.dart';

class SyndicateTopologyGraph extends StatefulWidget {
  final List<SettlementItem> settlements;
  final bool isDark;
  final ValueChanged<String>? onMemberTapped;

  const SyndicateTopologyGraph({
    super.key,
    required this.settlements,
    required this.isDark,
    this.onMemberTapped,
  });

  @override
  State<SyndicateTopologyGraph> createState() => _SyndicateTopologyGraphState();
}

class _SyndicateTopologyGraphState extends State<SyndicateTopologyGraph> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _selectedMember;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cyanAccent = isDark ? const Color(0xFF86CBB0) : const Color(0xFF5A947E);
    const emerald = Color(0xFF34D399);

    // Extract unique members
    final Set<String> members = {'Allen'};
    for (final s in widget.settlements) {
      members.add(s.from);
      members.add(s.to);
    }
    final memberList = members.toList();

    // Compute net debt for each member
    final Map<String, double> netDebt = {};
    for (final m in memberList) {
      netDebt[m] = 0.0;
    }
    for (final s in widget.settlements) {
      if (!s.isSettled) {
        final amt = double.tryParse(s.amount.replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0;
        netDebt[s.from] = (netDebt[s.from] ?? 0.0) - amt;
        netDebt[s.to] = (netDebt[s.to] ?? 0.0) + amt;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD6CA),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: emerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: emerald.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(LucideIcons.gitFork, color: emerald, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                      child: Text(
                    'ORBITAL SETTLEMENT TOPOLOGY',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: emerald,
                    ),
                  )),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cyanAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.settlements.length} ACTIVE CHANNELS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: cyanAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Network Canvas
          SizedBox(
            height: 220,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _TopologyNetworkPainter(
                    members: memberList,
                    settlements: widget.settlements,
                    pulseProgress: _pulseController.value,
                    isDark: isDark,
                    selectedMember: _selectedMember,
                    cyanColor: cyanAccent,
                    emeraldColor: emerald,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Member Nodes Selector Ribbon
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: memberList.map((m) {
                final isSelected = _selectedMember == m;
                final net = netDebt[m] ?? 0.0;
                final isPositive = net >= 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedMember = isSelected ? null : m;
                      });
                      widget.onMemberTapped?.call(m);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE0F2FE))
                            : (isDark ? const Color(0xFF0A0A0A) : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? cyanAccent : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: m == 'Allen' ? cyanAccent : (isPositive ? emerald : const Color(0xFFF87171)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              m.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            m,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            net == 0 ? 'Settled' : '${isPositive ? '+' : '-'}₹${net.abs().toInt()}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: net == 0 ? subtextColor : (isPositive ? emerald : const Color(0xFFF87171)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopologyNetworkPainter extends CustomPainter {
  final List<String> members;
  final List<SettlementItem> settlements;
  final double pulseProgress;
  final bool isDark;
  final String? selectedMember;
  final Color cyanColor;
  final Color emeraldColor;

  _TopologyNetworkPainter({
    required this.members,
    required this.settlements,
    required this.pulseProgress,
    required this.isDark,
    required this.selectedMember,
    required this.cyanColor,
    required this.emeraldColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.40;

    // Position map for nodes
    final Map<String, Offset> nodePositions = {};
    nodePositions['Allen'] = center;

    final outerMembers = members.where((m) => m != 'Allen').toList();
    for (int i = 0; i < outerMembers.length; i++) {
      final angle = (i * 2 * math.pi / outerMembers.length) - (math.pi / 2);
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      nodePositions[outerMembers[i]] = pos;
    }

    // Draw background concentric orbit guide rings
    final guidePaint = Paint()
      ..color = (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD6CA)).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawCircle(center, radius * 0.5, guidePaint);
    canvas.drawCircle(center, radius, guidePaint);

    // Draw directed connection lines & animated pulses
    for (final s in settlements) {
      final p1 = nodePositions[s.from];
      final p2 = nodePositions[s.to];
      if (p1 == null || p2 == null) continue;

      final isSettled = s.isSettled;
      final isHighlighted = selectedMember == null || selectedMember == s.from || selectedMember == s.to;

      final linePaint = Paint()
        ..color = (isSettled ? emeraldColor : (isHighlighted ? cyanColor : const Color(0xFF64748B)))
            .withValues(alpha: isSettled ? 0.3 : (isHighlighted ? 0.6 : 0.15))
        ..strokeWidth = isHighlighted ? 1.5 : 0.8;

      canvas.drawLine(p1, p2, linePaint);

      // Draw animated energy pulse particle moving along line
      if (!isSettled && isHighlighted) {
        final t = (pulseProgress + (s.id.hashCode % 10) / 10.0) % 1.0;
        final pulsePos = Offset.lerp(p1, p2, t)!;

        final particlePaint = Paint()
          ..color = cyanColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pulsePos, 3.5, particlePaint);

        final glowPaint = Paint()
          ..color = cyanColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pulsePos, 7.0, glowPaint);
      }
    }

    // Draw Nodes
    nodePositions.forEach((name, pos) {
      final isCenter = name == 'Allen';
      final isSelected = selectedMember == name;
      final nodeRadius = isCenter ? 22.0 : 16.0;

      // Glow halo
      if (isSelected || isCenter) {
        final glowHalo = Paint()
          ..color = (isCenter ? cyanColor : emeraldColor).withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, nodeRadius + 6, glowHalo);
      }

      // Outer rim
      final rimPaint = Paint()
        ..color = isCenter
            ? cyanColor
            : (isSelected ? emeraldColor : (isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.2;

      // Background fill
      final fillPaint = Paint()
        ..color = isDark ? const Color(0xFF131722) : Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, nodeRadius, fillPaint);
      canvas.drawCircle(pos, nodeRadius, rimPaint);

      // Node label
      final textSpan = TextSpan(
        text: name.substring(0, 1).toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: isCenter ? 12 : 10,
          fontWeight: FontWeight.bold,
          color: isCenter ? cyanColor : (isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));

      // Label below outer node
      if (!isCenter) {
        final nameSpan = TextSpan(
          text: name,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFDDD6CA) : const Color(0xFF334155),
          ),
        );
        final nameTp = TextPainter(
          text: nameSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();
        nameTp.paint(canvas, Offset(pos.dx - nameTp.width / 2, pos.dy + nodeRadius + 3));
      }
    });
  }

  @override
  bool shouldRepaint(covariant _TopologyNetworkPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.selectedMember != selectedMember ||
        oldDelegate.settlements != settlements;
  }
}

import '../services/cloudinary_media_service.dart';
import 'skeleton_loader.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

class PolaroidFlipCard extends StatefulWidget {
  final String title;
  final String date;
  final String imageUrl;
  final String handwrittenNote;
  final Widget? frontChild;

  const PolaroidFlipCard({
    super.key,
    required this.title,
    required this.date,
    required this.imageUrl,
    required this.handwrittenNote,
    this.frontChild,
  });

  @override
  State<PolaroidFlipCard> createState() => _PolaroidFlipCardState();
}

class _PolaroidFlipCardState extends State<PolaroidFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    HapticFeedback.mediumImpact();
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF4F1EA) : AppColors.primary;
    final subtextColor = isDark ? const Color(0xFFB8C5C8) : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isUnder = angle > pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isUnder
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildBackCard(isDark, primaryTextColor, subtextColor),
                  )
                : _buildFrontCard(isDark, primaryTextColor, subtextColor),
          );
        },
      ),
    );
  }

  Widget _buildUniversalImage(String url, bool isDark) {
    final bgColor = isDark ? const Color(0xFF0D0C0B) : const Color(0xFFF6F3EB);
    final placeholder = Container(
      height: 180,
      color: (isDark ? AppColors.goldLight : AppColors.secondary).withValues(alpha: 0.15),
      child: Center(
        child: Icon(Icons.image, color: isDark ? AppColors.goldLight : AppColors.secondary),
      ),
    );

    final optimizedUrl = CloudinaryMediaService.getTransformedUrl(url, 'f_auto,q_auto,w_1080');

    Widget wrapCardImage(Widget img) {
      return Container(
        constraints: const BoxConstraints(minHeight: 180, maxHeight: 360),
        width: double.infinity,
        color: bgColor,
        alignment: Alignment.center,
        child: img,
      );
    }

    Widget buildNetworkImg(String u) {
      return wrapCardImage(
        Image.network(
          u,
          fit: BoxFit.contain,
          cacheWidth: 1080,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 180,
              width: double.infinity,
              color: bgColor,
              child: const SkeletonShimmer(
                child: SkeletonBox(
                  height: 180,
                  width: double.infinity,
                  borderRadius: 8,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    }

    if (url.startsWith('http://') || url.startsWith('https://') || kIsWeb) {
      return buildNetworkImg(optimizedUrl);
    } else {
      try {
        final f = File(url);
        if (f.existsSync()) {
          return wrapCardImage(
            Image.file(
              f,
              fit: BoxFit.contain,
              cacheWidth: 1080,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => placeholder,
            ),
          );
        }
      } catch (_) {}
      return buildNetworkImg(optimizedUrl);
    }
  }

  Widget _buildFrontCard(bool isDark, Color primaryTextColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.goldBorderDark : AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primary).withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildUniversalImage(widget.imageUrl, isDark),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.bodoniModa(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TAP TO FLIP 🔄',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.goldLight : AppColors.secondary,
                ),
              ),
            ],
          ),
          Text(widget.date, style: GoogleFonts.dmSans(fontSize: 10, color: subtextColor)),
        ],
      ),
    );
  }

  Widget _buildBackCard(bool isDark, Color primaryTextColor, Color subtextColor) {
    final noteAccent = isDark ? AppColors.goldLight : AppColors.secondary;
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.goldBorderDark : noteAccent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : noteAccent).withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('BACKSTAGE NOTES', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: noteAccent)),
                  Icon(Icons.flip, size: 14, color: noteAccent),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '"${widget.handwrittenNote}"',
                style: GoogleFonts.dmSans(fontSize: 13, fontStyle: FontStyle.italic, color: primaryTextColor, height: 1.5),
              ),
            ],
          ),
          Text('Archived Memoir · Tap to flip front', style: GoogleFonts.dmSans(fontSize: 9, color: subtextColor)),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A picture from a URL or from a file on this device. The web has no device files,
/// so there a path is loaded as a URL instead of crashing; anything unreadable shows
/// [fallback] (nothing by default).
class AnyImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallback;

  const AnyImage(this.source, {super.key, this.fit = BoxFit.cover, this.width, this.height, this.fallback});

  @override
  Widget build(BuildContext context) {
    Widget none(BuildContext _, Object __, StackTrace? ___) => fallback ?? const SizedBox.shrink();
    if (kIsWeb || source.startsWith('http://') || source.startsWith('https://') || source.startsWith('blob:')) {
      return Image.network(source, fit: fit, width: width, height: height, errorBuilder: none);
    }
    return Image.file(File(source), fit: fit, width: width, height: height, errorBuilder: none);
  }
}

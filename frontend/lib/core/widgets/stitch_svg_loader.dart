import 'package:flutter/material.dart';
import 'sanctuary_loaders.dart';

/// Legacy entry point kept for existing call sites; renders the brand [MonogramLoader].
class StitchSvgLoader extends StatelessWidget {
  final double size;
  final String label;

  const StitchSvgLoader({
    super.key,
    this.size = 72.0,
    this.label = 'Loading Sanctuary...',
  });

  @override
  Widget build(BuildContext context) => MonogramLoader(size: size, label: label);
}

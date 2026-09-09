import 'package:flutter/material.dart';
import 'stitch_svg_loader.dart';

class EditorialLoading extends StatelessWidget {
  final String label;

  const EditorialLoading({
    super.key,
    this.label = 'Loading Sanctuary...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StitchSvgLoader(
        size: 72,
        label: label,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SandDuneRippleScrollView extends StatelessWidget {
  final Widget child;

  const SandDuneRippleScrollView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return const BouncingScrollPhysics().parent != null
        ? SingleChildScrollView(physics: const BouncingScrollPhysics(), child: child)
        : SingleChildScrollView(physics: const BouncingScrollPhysics(), child: child);
  }
}

import 'package:flutter/material.dart';

class AccordionBambooBlindFold extends StatefulWidget {
  final Widget child;
  final bool isExpanded;

  const AccordionBambooBlindFold({
    super.key,
    required this.child,
    this.isExpanded = true,
  });

  @override
  State<AccordionBambooBlindFold> createState() => _AccordionBambooBlindFoldState();
}

class _AccordionBambooBlindFoldState extends State<AccordionBambooBlindFold>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.isExpanded) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AccordionBambooBlindFold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      child: widget.child,
    );
  }
}

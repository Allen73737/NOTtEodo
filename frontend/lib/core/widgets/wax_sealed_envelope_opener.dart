import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WaxSealedEnvelopeOpener extends StatefulWidget {
  final Widget child;

  const WaxSealedEnvelopeOpener({super.key, required this.child});

  @override
  State<WaxSealedEnvelopeOpener> createState() => _WaxSealedEnvelopeOpenerState();
}

class _WaxSealedEnvelopeOpenerState extends State<WaxSealedEnvelopeOpener> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _isOpen = !_isOpen);
      },
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 500),
        crossFadeState: _isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9EE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD9725B)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail, color: Color(0xFFD9725B)),
              SizedBox(width: 10),
              Text(
                'TAP RIBBON TO OPEN ENVELOPE',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16282C)),
              ),
            ],
          ),
        ),
        secondChild: widget.child,
      ),
    );
  }
}

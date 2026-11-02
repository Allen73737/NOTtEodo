import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/services/sanctuary_supabase_service.dart';

String _friendly(Object e) {
  if (e is AuthException) return e.message;
  final t = e.toString();
  return t.startsWith('Bad state: ') ? t.substring(11) : t;
}

/// Asks for the current authenticator code to raise this session to AAL2.
/// Returns true once verified.
Future<bool> showMfaChallenge(BuildContext context) async {
  final factors = await SanctuarySupabaseService().totpFactors();
  if (factors.isEmpty || !context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CodeDialog(
      title: 'Two-step verification',
      message: 'Enter the 6-digit code from your authenticator app.',
      onSubmit: (code) => SanctuarySupabaseService().verifyTotp(factors.first.id, code),
    ),
  );
  return ok == true;
}

/// Walks through adding an authenticator app (TOTP). Returns true when enabled.
Future<bool> showMfaEnrollment(BuildContext context) async {
  final ({String factorId, String uri, String secret}) enrollment;
  try {
    enrollment = await SanctuarySupabaseService().enrollTotp();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendly(e))));
    }
    return false;
  }
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _CodeDialog(
      title: 'Add an authenticator',
      message: 'Scan this code with an authenticator app (1Password, Google Authenticator, Authy…), '
          'then enter the 6-digit code it shows.',
      header: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10),
            child: QrImageView(data: enrollment.uri, size: 180, backgroundColor: Colors.white),
          ),
          const SizedBox(height: 10),
          Text('Or enter this key manually:', style: GoogleFonts.dmSans(fontSize: 11)),
          const SizedBox(height: 4),
          SelectableText(
            enrollment.secret.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trim(),
            style: GoogleFonts.courierPrime(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
      onSubmit: (code) => SanctuarySupabaseService().verifyTotp(enrollment.factorId, code),
    ),
  );
  if (ok != true) {
    // Abandoned enrolment: remove the half-made factor.
    try {
      await SanctuarySupabaseService().removeTotp(enrollment.factorId);
    } catch (_) {}
  }
  return ok == true;
}

class _CodeDialog extends StatefulWidget {
  final String title;
  final String message;
  final Widget? header;
  final Future<void> Function(String code) onSubmit;

  const _CodeDialog({required this.title, required this.message, required this.onSubmit, this.header});

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _ctrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(code);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _friendly(e);
          _ctrl.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.header != null) widget.header!,
            Text(widget.message, style: GoogleFonts.dmSans(fontSize: 13, height: 1.4)),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              autofocus: true,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              textAlign: TextAlign.center,
              style: GoogleFonts.courierPrime(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(border: const OutlineInputBorder(), errorText: _error, hintText: '000000'),
              onChanged: (v) {
                if (v.length == 6) _submit();
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Verify'),
        ),
      ],
    );
  }
}

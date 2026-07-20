import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  String? _info;
  String? _error;

  static const _defaultCountry = '+91';

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  String get _e164 {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.length == 10) {
      return '$_defaultCountry$digits';
    }
    if (_phone.text.trim().startsWith('+')) {
      return _phone.text.trim();
    }
    return '$_defaultCountry$digits';
  }

  Future<void> _sendOtp() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _e164,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          setState(() => _error = e.message ?? e.code);
        },
        codeSent: (verificationId, _) {
          setState(() {
            _verificationId = verificationId;
            _info = 'OTP sent. Enter the code below.';
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId ??= verificationId;
        },
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmOtp() async {
    final vid = _verificationId;
    if (vid == null) {
      setState(() => _error = 'Request an OTP first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: _code.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Mobile OTP',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the mobile number your centre registered for you. Default country code is +91.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
            ],
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              hintText: '9876543210',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _sendOtp,
            child: Text(_busy ? 'Please wait…' : 'Send OTP'),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'SMS code'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : _confirmOtp,
            child: const Text('Verify & sign in'),
          ),
          if (_info != null) ...[
            const SizedBox(height: 16),
            Text(_info!,
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

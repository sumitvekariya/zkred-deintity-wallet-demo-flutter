import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class ClaimCredentialScreen extends StatefulWidget {
  const ClaimCredentialScreen({super.key});

  @override
  State<ClaimCredentialScreen> createState() => _ClaimCredentialScreenState();
}

enum _ClaimStep { initial, processing, done, error }

class _ClaimCredentialScreenState extends State<ClaimCredentialScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  _ClaimStep _step = _ClaimStep.initial;
  String? _errorMessage;
  int _phase = 0;

  static const _phases = [
    'Authenticating',
    'Fetching credential',
    'Saving to wallet',
  ];

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        // Map progress to phase index
        final p = (_progressCtrl.value * _phases.length).floor();
        final clamped = p.clamp(0, _phases.length - 1);
        if (clamped != _phase) {
          setState(() => _phase = clamped);
        }
      });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            const {};
    final url = (args['url'] as String?) ?? '';

    setState(() {
      _step = _ClaimStep.processing;
      _phase = 0;
    });
    _progressCtrl.forward(from: 0);

    bool ok = true;
    String? error;
    if (url.isNotEmpty) {
      final provider = context.read<WalletProvider>();
      ok = await provider.handleQrMessage(url);
      error = provider.error;
    } else {
      // Simulate processing for demo flows without a real URL
      await Future.delayed(const Duration(seconds: 3));
    }
    if (!mounted) return;
    // Allow the animation to finish visually
    if (_progressCtrl.value < 1) {
      await _progressCtrl.forward();
    }
    if (!mounted) return;
    setState(() {
      if (ok) {
        _step = _ClaimStep.done;
      } else {
        _step = _ClaimStep.error;
        _errorMessage = error ?? 'Could not claim credential';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            const {};
    final title = (args['title'] as String?) ?? 'Issuer';
    final subtitle = (args['subtitle'] as String?) ?? 'Verifiable Credential';

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      color: ZKColors.electric,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Claim credential',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ZKColors.text,
                      ),
                    ),
                  ],
                ),
                Expanded(child: _buildBody(title, subtitle)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(String title, String subtitle) {
    switch (_step) {
      case _ClaimStep.initial:
        return _Initial(title: title, subtitle: subtitle, onClaim: _claim);
      case _ClaimStep.processing:
        return _Processing(
          phase: _phase,
          phaseLabels: _phases,
          progress: _progressCtrl,
        );
      case _ClaimStep.done:
        return _Done(onBack: () {
          Navigator.popUntil(context, (r) => r.settings.name == '/home');
        });
      case _ClaimStep.error:
        return _Error(
          message: _errorMessage ?? 'Something went wrong',
          onRetry: _claim,
        );
    }
  }
}

class _Initial extends StatelessWidget {
  const _Initial({
    required this.title,
    required this.subtitle,
    required this.onClaim,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ZKColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ZKColors.cardBorder),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(17, 78, 246, 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: ZKColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ZKColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: ZKColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onClaim,
            child: const Text('Claim Credential'),
          ),
        ),
      ],
    );
  }
}

class _Processing extends StatelessWidget {
  const _Processing({
    required this.phase,
    required this.phaseLabels,
    required this.progress,
  });

  final int phase;
  final List<String> phaseLabels;
  final AnimationController progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Text(
          'Processing...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ZKColors.text,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedBuilder(
            animation: progress,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.value,
                minHeight: 8,
                backgroundColor: const Color(0xFFEFEFEF),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(ZKColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          phaseLabels[phase],
          style: const TextStyle(
            fontSize: 14,
            color: ZKColors.electric,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: ZKColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 18),
        const Text(
          'Credential claimed!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: ZKColors.text,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onBack,
            child: const Text('Back to Home'),
          ),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.error_outline, color: ZKColors.error, size: 56),
        const SizedBox(height: 14),
        const Text(
          'Failed to claim',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ZKColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ZKColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}

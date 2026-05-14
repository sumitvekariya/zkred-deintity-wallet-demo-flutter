import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scrollCtrl;
  final TextEditingController _privateKeyCtrl = TextEditingController();

  bool _initStarted = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (_initStarted) return;
    _initStarted = true;
    final provider = context.read<WalletProvider>();
    await provider.initSdk();
    _maybeAdvance();
  }

  void _maybeAdvance() {
    if (_navigated || !mounted) return;
    final provider = context.read<WalletProvider>();
    if (provider.isReady && provider.hasIdentity) {
      _navigated = true;
      Navigator.pushReplacementNamed(context, '/passcode');
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _privateKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _createIdentity() async {
    final provider = context.read<WalletProvider>();
    await provider.createIdentity();
    if (!mounted) return;
    if (provider.hasIdentity) {
      _navigated = true;
      Navigator.pushReplacementNamed(context, '/passcode');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();

    // React when SDK becomes ready with existing identity
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAdvance());

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 28),
              const Text(
                'ZKRED',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w600,
                  color: ZKColors.electric,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Identity Wallet',
                style: TextStyle(
                  fontSize: 14,
                  color: ZKColors.electric,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              // Two rows of scrolling cards
              Expanded(
                child: ClipRect(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ScrollingRow(
                          controller: _scrollCtrl, reverse: false),
                      const SizedBox(height: 14),
                      _ScrollingRow(
                          controller: _scrollCtrl, reverse: true),
                    ],
                  ),
                ),
              ),
              // Bottom panel
              _BottomPanel(
                provider: provider,
                privateKeyCtrl: _privateKeyCtrl,
                onCreate: _createIdentity,
                onRetry: () {
                  _initStarted = false;
                  _init();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrollingRow extends StatelessWidget {
  const _ScrollingRow({required this.controller, required this.reverse});

  final AnimationController controller;
  final bool reverse;

  static const _cardCount = 6;
  static const _cardWidth = 140.0;
  static const _gap = 14.0;

  @override
  Widget build(BuildContext context) {
    const totalWidth = (_cardWidth + _gap) * _cardCount;

    return SizedBox(
      height: 90,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          double offset = controller.value * totalWidth;
          if (reverse) offset = -offset;
          // Wrap offset within [-totalWidth, totalWidth]
          final wrapped = offset % totalWidth;
          final translateX = reverse ? -wrapped : wrapped - totalWidth;

          return OverflowBox(
            maxWidth: double.infinity,
            child: Transform.translate(
              offset: Offset(translateX, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_cardCount * 2, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: _gap),
                    child: _SkeletonCard(seed: i),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    // Vary widths slightly to mimic mockup
    final double width = 140 + (seed % 3) * 8.0;
    return Container(
      width: width,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: ZKColors.electric,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 60,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          Container(
            width: 100,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            width: 70,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.provider,
    required this.privateKeyCtrl,
    required this.onCreate,
    required this.onRetry,
  });

  final WalletProvider provider;
  final TextEditingController privateKeyCtrl;
  final VoidCallback onCreate;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isError = provider.status == WalletStatus.error;
    final showCreate = provider.isReady && !provider.hasIdentity;
    final isDownloading =
        provider.status == WalletStatus.initializing && !isError;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isError) ...[
            const Icon(Icons.error_outline,
                color: ZKColors.error, size: 36),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'Initialization failed',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ZKColors.textOnLight, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ] else if (showCreate) ...[
            const Text(
              'Create your identity',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ZKColors.textOnLight,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Generate a new DID on Polygon Amoy and start collecting verifiable credentials.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF5566AA), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.isLoading ? null : onCreate,
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Get Started'),
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: provider.circuitProgress > 0 &&
                        provider.circuitProgress < 1
                    ? provider.circuitProgress
                    : null,
                minHeight: 8,
                backgroundColor: const Color(0xFFEFEFEF),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    ZKColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              provider.statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ZKColors.textOnLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isDownloading
                  ? 'Setting things up, hang tight...'
                  : 'Almost there...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5566AA),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

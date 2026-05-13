import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final provider = context.read<WalletProvider>();
    await provider.initSdk();
    if (mounted && provider.isReady) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha:0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),

                // App name
                Text(
                  'ZKred Wallet',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Powered by Privado ID',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha:0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 48),

                // Progress / status
                if (provider.status == WalletStatus.initializing) ...[
                  if (provider.circuitProgress > 0 &&
                      provider.circuitProgress < 1.0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: provider.circuitProgress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFF2D2D4E),
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    provider.statusMessage,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha:0.6),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Error state
                if (provider.status == WalletStatus.error) ...[
                  Icon(Icons.error_outline,
                      color: cs.error, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    provider.error ?? 'Initialization failed',
                    style: TextStyle(color: cs.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _init,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

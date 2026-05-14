import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WalletProvider>();
      if (provider.hasIdentity) {
        provider.loadCredentials();
      }
    });
  }

  String _shortDid(String? did) {
    if (did == null || did.isEmpty) return 'Friend';
    // Show last segment of DID: did:polygonid:polygon:amoy:<last>
    final parts = did.split(':');
    final last = parts.last;
    if (last.length <= 16) return last;
    return '${last.substring(0, 6)}…${last.substring(last.length - 6)}';
  }

  String _prettyType(String type) {
    if (type.isEmpty) return 'Verifiable Credential';
    final parts = type.split('/');
    final last = parts.last.isNotEmpty ? parts.last : type;
    return last.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final credentials = provider.credentials;
    final latest = credentials.isNotEmpty ? credentials.first : null;
    final activeCount =
        credentials.where((c) => c.state == ClaimState.active).length;

    return GradientBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 14,
                            color: ZKColors.electric,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            if (provider.identifier == null) return;
                            Clipboard.setData(
                                ClipboardData(text: provider.identifier!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('DID copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _shortDid(provider.identifier),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: ZKColors.text,
                                ),
                              ),
                              if (provider.identifier != null) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.copy_outlined,
                                    size: 14, color: ZKColors.textSecondary),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ScanIconButton(
                    onTap: () =>
                        Navigator.pushNamed(context, '/scanner'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Congratulations section
              const Text(
                'Congratulations',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: ZKColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'on your last credential',
                style: TextStyle(
                  fontSize: 16,
                  color: ZKColors.text,
                ),
              ),
              const SizedBox(height: 12),
              if (latest != null) ...[
                Text(
                  _prettyType(latest.type),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ZKColors.electric,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(latest.info['issuanceDate'] as String?),
                  style: const TextStyle(
                    fontSize: 13,
                    color: ZKColors.textMuted,
                  ),
                ),
              ] else
                const Text(
                  'Scan a QR code to claim your first credential.',
                  style: TextStyle(
                    fontSize: 14,
                    color: ZKColors.textMuted,
                  ),
                ),
              const SizedBox(height: 24),
              // Notifications card
              _CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ZKColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (credentials.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'No new notifications',
                          style: TextStyle(
                            color: ZKColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ...credentials.take(3).map(
                            (c) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: ZKColors.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.download_outlined,
                                      size: 18,
                                      color: ZKColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _prettyType(c.type),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: ZKColors.text,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // My credentials counters card
              _CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My credentials',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ZKColors.text,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _CounterTile(
                            count: credentials.length,
                            label: 'Claimed',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: ZKColors.border,
                        ),
                        Expanded(
                          child: _CounterTile(
                            count: activeCount,
                            label: 'Verified',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/scanner'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanIconButton extends StatelessWidget {
  const _ScanIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ZKColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'Scan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZKColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZKColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: ZKColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: ZKColors.text,
          ),
        ),
      ],
    );
  }
}

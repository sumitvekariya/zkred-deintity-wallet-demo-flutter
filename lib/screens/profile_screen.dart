import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/passcode_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PasscodeProvider>().checkPasscode();
    });
  }

  String _initials(String? did) {
    if (did == null || did.isEmpty) return '?';
    // Use last 2 characters as a stable mini-avatar
    final clean = did.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (clean.isEmpty) return '?';
    return clean.substring(clean.length - 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final passcode = context.watch<PasscodeProvider>();
    final did = wallet.identifier ?? 'No identity';

    return GradientBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: ZKColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(wallet.identifier),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Identity Wallet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ZKColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SelectableText(
                      did,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: ZKColors.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (wallet.identifier != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: ZKColors.electric,
                      ),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: wallet.identifier!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('DID copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: const Text('Copy DID'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Security',
                children: [
                  _Row(
                    icon: Icons.lock_outline,
                    title: 'Passcode',
                    trailing: Switch(
                      value: passcode.hasPasscode,
                      activeThumbColor: ZKColors.primary,
                      onChanged: null,
                    ),
                  ),
                  const Divider(height: 1, color: ZKColors.border),
                  _Row(
                    icon: Icons.key_outlined,
                    title: 'Export Private Key',
                    trailing: const Icon(Icons.chevron_right,
                        color: ZKColors.textMuted),
                    onTap: () => _showPrivateKey(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Wallet',
                children: [
                  _Row(
                    icon: Icons.refresh,
                    title: 'Regenerate Identity',
                    trailing: const Icon(Icons.chevron_right,
                        color: ZKColors.textMuted),
                    onTap: () => _confirmRegenerate(context),
                  ),
                  const Divider(height: 1, color: ZKColors.border),
                  _Row(
                    icon: Icons.delete_outline,
                    title: 'Clear All Data',
                    danger: true,
                    trailing: const Icon(Icons.chevron_right,
                        color: ZKColors.error),
                    onTap: () => _confirmClear(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _SectionCard(
                title: 'About',
                children: [
                  _Row(
                    icon: Icons.lan_outlined,
                    title: 'Network',
                    trailing: Text(
                      'Polygon Amoy',
                      style:
                          TextStyle(color: ZKColors.textMuted, fontSize: 14),
                    ),
                  ),
                  Divider(height: 1, color: ZKColors.border),
                  _Row(
                    icon: Icons.extension_outlined,
                    title: 'SDK Version',
                    trailing: Text(
                      'Privado ID v2.4',
                      style:
                          TextStyle(color: ZKColors.textMuted, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPrivateKey(BuildContext context) async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final pk =
        await storage.read(key: AppConfig.keyPrivateKey) ?? '(none)';
    if (!context.mounted) return;

    bool revealed = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: ZKColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ZKColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Private Key',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ZKColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Never share this with anyone. Anyone with this key can control your identity.',
                  style: TextStyle(
                    color: ZKColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => setSheet(() => revealed = !revealed),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      revealed ? pk : '•' * (pk.length.clamp(0, 32)),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: ZKColors.text,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  revealed ? 'Tap to hide' : 'Tap to reveal',
                  style: const TextStyle(
                    color: ZKColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: pk));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text('Private key copied')),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRegenerate(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate identity'),
        content: const Text(
            'This deletes your current DID and credentials. A fresh identity will be created. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ZKColors.error),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<WalletProvider>().regenerateIdentity();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Identity regenerated')),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This removes the identity, all credentials and your passcode from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ZKColors.error),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;
    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text(
            'This action cannot be undone. Your private key will be wiped permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ZKColors.error),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (second != true || !context.mounted) return;
    final wallet = context.read<WalletProvider>();
    final passcode = context.read<PasscodeProvider>();
    await wallet.removeIdentity();
    await passcode.clear();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/splash', (_) => false);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ZKColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZKColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ZKColors.electric,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? ZKColors.error : ZKColors.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

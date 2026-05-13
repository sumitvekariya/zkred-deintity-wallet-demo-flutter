import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';

class IdentityScreen extends StatelessWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Identity')),
      body: SafeArea(
        child: provider.hasIdentity
            ? _IdentityDetails(provider: provider)
            : _CreateIdentityView(provider: provider),
      ),
    );
  }
}

// ---- No Identity ----

class _CreateIdentityView extends StatelessWidget {
  const _CreateIdentityView({required this.provider});

  final WalletProvider provider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.primary.withOpacity(0.3)),
              ),
              child: Icon(Icons.person_add_outlined,
                  size: 40, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'No Identity Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a self-sovereign identity (DID) to start '
              'receiving and sharing verifiable credentials with zero-knowledge proofs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : () => _create(context),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  provider.isLoading ? 'Creating...' : 'Create Identity',
                ),
              ),
            ),
            if (provider.error != null) ...[
              const SizedBox(height: 16),
              _ErrorBox(message: provider.error!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    await provider.createIdentity();
    if (context.mounted && provider.hasIdentity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identity created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// ---- Has Identity ----

class _IdentityDetails extends StatelessWidget {
  const _IdentityDetails({required this.provider});

  final WalletProvider provider;

  @override
  Widget build(BuildContext context) {
    final did = provider.identifier!;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.verified_user,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'Identity Active',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your DID is ready to use',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // DID card
          _InfoCard(
            title: 'Decentralized Identifier (DID)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    did,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: did));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('DID copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('Copy DID'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primary,
                    side: BorderSide(color: cs.primary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Network info
          _InfoCard(
            title: 'Network',
            child: _InfoRow(
              items: const [
                ('Blockchain', 'Polygon'),
                ('Network', 'Amoy (Testnet)'),
                ('Protocol', 'Iden3 / Privado ID'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Danger zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.error.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danger Zone',
                  style: TextStyle(
                    color: cs.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Removing your identity will delete all credentials and '
                  'private keys from this device. This cannot be undone.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => _confirmRegenerate(context),
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      provider.isLoading
                          ? 'Regenerating...'
                          : 'Regenerate Key Pair',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => _confirmRemove(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove Identity'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (provider.error != null) ...[
            const SizedBox(height: 16),
            _ErrorBox(message: provider.error!),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRegenerate(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('Regenerate Key Pair',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete your current identity and generate a brand-new '
          'DID + private key. All existing credentials will be lost. Continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await provider.regenerateIdentity();
      if (context.mounted && provider.hasIdentity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New key pair generated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('Remove Identity',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete your identity and all credentials '
          'from this device. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await provider.removeIdentity();
      if (context.mounted && !provider.hasIdentity) {
        Navigator.pop(context);
      }
    }
  }
}

// ---- Shared Widgets ----

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D4E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.$1,
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  Text(item.$2,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.error.withOpacity(0.3)),
      ),
      child: Text(message,
          style: TextStyle(color: cs.error, fontSize: 13)),
    );
  }
}

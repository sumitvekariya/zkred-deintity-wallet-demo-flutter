import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final cs = Theme.of(context).colorScheme;

    // Show errors as snackbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: cs.error,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: provider.clearError,
            ),
          ),
        );
        provider.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZKred Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Identity',
            onPressed: () => Navigator.pushNamed(context, '/identity'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IdentityCard(provider: provider),
              const SizedBox(height: 28),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              _ActionGrid(provider: provider),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.provider});

  final WalletProvider provider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final did = provider.identifier;
    final shortDid = did != null && did.length > 20
        ? '${did.substring(0, 12)}...${did.substring(did.length - 8)}'
        : did ?? 'No identity';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Self-Sovereign Identity',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (provider.hasIdentity)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'DID',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  shortDid,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (did != null)
                IconButton(
                  icon: const Icon(Icons.copy_outlined,
                      color: Colors.white54, size: 18),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Copy DID',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: did));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('DID copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
          if (!provider.hasIdentity) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/identity'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Create Identity'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.provider});

  final WalletProvider provider;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.qr_code_scanner,
        label: 'Scan QR',
        subtitle: 'Auth or get credentials',
        gradient: const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
        onTap: provider.hasIdentity
            ? () => Navigator.pushNamed(context, '/scanner')
            : () => _requireIdentity(context),
      ),
      _ActionItem(
        icon: Icons.badge_outlined,
        label: 'Credentials',
        subtitle: '${provider.credentials.length} stored',
        gradient: const [Color(0xFF2563EB), Color(0xFF1E40AF)],
        onTap: provider.hasIdentity
            ? () => Navigator.pushNamed(context, '/credentials')
            : () => _requireIdentity(context),
      ),
      _ActionItem(
        icon: Icons.fingerprint,
        label: 'Identity',
        subtitle: provider.hasIdentity ? 'View details' : 'Setup required',
        gradient: const [Color(0xFF059669), Color(0xFF065F46)],
        onTap: () => Navigator.pushNamed(context, '/identity'),
      ),
      _ActionItem(
        icon: Icons.info_outline,
        label: 'About',
        subtitle: 'Privado ID POC',
        gradient: const [Color(0xFF9333EA), Color(0xFF7E22CE)],
        onTap: () => _showAboutDialog(context),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions
          .map((a) => _ActionCard(item: a))
          .toList(),
    );
  }

  void _requireIdentity(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Create an identity first')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ZKred Wallet',
      applicationVersion: '1.0.0',
      applicationLegalese:
          'POC built on Privado ID Flutter SDK v2.x\n'
          'Zero-knowledge proof identity wallet',
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.item});

  final _ActionItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D2D4E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: item.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

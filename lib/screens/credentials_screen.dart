import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../widgets/credential_card.dart';

class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadCredentials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credentials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: provider.isLoading
                ? null
                : () => provider.loadCredentials(),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: 'Scan to get credential',
            onPressed: () => Navigator.pushNamed(context, '/scanner'),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context, provider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WalletProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading credentials...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  provider.clearError();
                  provider.loadCredentials();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.credentials.isEmpty) {
      return _EmptyCredentials();
    }

    return RefreshIndicator(
      onRefresh: provider.loadCredentials,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.credentials.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final claim = provider.credentials[index];
          return Dismissible(
            key: Key(claim.id),
            direction: DismissDirection.endToStart,
            background: _SwipeDeleteBackground(),
            confirmDismiss: (_) => _confirmDelete(context, claim.id),
            onDismissed: (_) => provider.removeCredential(claim.id),
            child: CredentialCard(
              claim: claim,
              onDelete: () async {
                final ok = await _confirmDelete(context, claim.id);
                if (ok == true) provider.removeCredential(claim.id);
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String id) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('Delete Credential',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Remove this credential from your wallet?',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCredentials extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.badge_outlined,
                  size: 52, color: cs.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Credentials Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan a QR code from an issuer to receive '
              'your first verifiable credential.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/scanner'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, color: Colors.white),
          SizedBox(height: 4),
          Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

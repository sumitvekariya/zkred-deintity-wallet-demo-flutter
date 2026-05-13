import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final _pasteController = TextEditingController();

  bool _processing = false;
  bool _scanned = false;
  bool _showPasteField = false;

  @override
  void dispose() {
    _controller.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _handleQr(String value) async {
    if (_processing || _scanned || value.trim().isEmpty) return;

    setState(() {
      _processing = true;
      _scanned = true;
    });

    await _controller.stop();

    final provider = context.read<WalletProvider>();
    final success = await provider.handleQrMessage(value.trim());

    if (!mounted) return;

    if (!success && provider.hasPendingAuthSelection) {
      // Multiple credentials match — show picker before running auth
      await _showCredentialPicker(provider);
      return;
    }

    if (success) {
      _showResult(
        title: 'Success',
        message: 'QR code processed successfully!',
        icon: Icons.check_circle_outline,
        color: Colors.green,
        onDone: () => Navigator.pop(context),
      );
    } else {
      _showResult(
        title: 'Failed',
        message: provider.error ?? 'Unknown error',
        icon: Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        onDone: () {
          provider.clearError();
          setState(() {
            _processing = false;
            _scanned = false;
          });
          _controller.start();
        },
      );
    }
  }

  Future<void> _showCredentialPicker(WalletProvider provider) async {
    final candidates = provider.pendingMatchingCredentials;

    final ClaimEntity? selected = await showModalBottomSheet<ClaimEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CredentialPickerSheet(credentials: candidates),
    );

    if (!mounted) return;

    if (selected == null) {
      // User dismissed — cancel
      provider.cancelPendingAuth();
      setState(() {
        _processing = false;
        _scanned = false;
      });
      _controller.start();
      return;
    }

    setState(() => _processing = true);
    final ok = await provider.confirmAuthWithCredential(selected);
    if (!mounted) return;

    if (ok) {
      _showResult(
        title: 'Success',
        message: 'Proof generated successfully!',
        icon: Icons.check_circle_outline,
        color: Colors.green,
        onDone: () => Navigator.pop(context),
      );
    } else {
      _showResult(
        title: 'Failed',
        message: provider.error ?? 'Unknown error',
        icon: Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        onDone: () {
          provider.clearError();
          setState(() {
            _processing = false;
            _scanned = false;
          });
          _controller.start();
        },
      );
    }
  }

  void _showResult({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required VoidCallback onDone,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onDone();
                },
                child: Text(title == 'Success' ? 'Done' : 'Try Again'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle flash',
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_outlined),
            onPressed: () =>
                setState(() => _showPasteField = !_showPasteField),
            tooltip: 'Paste QR content',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          if (!_processing)
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull;
                if (barcode?.rawValue != null) {
                  _handleQr(barcode!.rawValue!);
                }
              },
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Scan overlay
          if (!_processing) const _ScanOverlay(),

          // Processing overlay
          if (_processing || provider.isLoading)
            _ProcessingOverlay(message: provider.statusMessage),

          // Paste input for testing
          if (_showPasteField)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              child: _PasteInputCard(
                controller: _pasteController,
                onSubmit: () => _handleQr(_pasteController.text),
                onClose: () =>
                    setState(() => _showPasteField = false),
              ),
            ),
        ],
      ),
    );
  }
}

// ---- Overlay Widgets ----

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF7C3AED),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
        ),
        Container(
          color: Colors.black.withOpacity(0.6),
          padding: const EdgeInsets.all(24),
          child: const Text(
            'Point the camera at an iden3comm QR code\n'
            '(Auth request or Credential offer)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Credential Picker ----

class _CredentialPickerSheet extends StatelessWidget {
  const _CredentialPickerSheet({required this.credentials});

  final List<ClaimEntity> credentials;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Credential',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${credentials.length} matching credentials found. '
                  'Pick one to use for this proof.',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2D2D4E)),
          Expanded(
            child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: credentials.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (ctx, i) =>
                  _CredentialPickerCard(
                credential: credentials[i],
                isNewest: i == 0,
                onTap: () =>
                    Navigator.of(ctx).pop(credentials[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialPickerCard extends StatelessWidget {
  const _CredentialPickerCard({
    required this.credential,
    required this.isNewest,
    required this.onTap,
  });

  final ClaimEntity credential;
  final bool isNewest;
  final VoidCallback onTap;

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Unknown date';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String get _credentialType {
    final t = credential.type;
    // Strip namespace prefix if present (last segment after /)
    final slash = t.lastIndexOf('/');
    return slash >= 0 ? t.substring(slash + 1) : t;
  }

  @override
  Widget build(BuildContext context) {
    final issuanceDate = credential.info['issuanceDate'] as String?;
    final expirationDate = credential.info['expirationDate'] as String?;
    final issuer = credential.issuer;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNewest
                ? const Color(0xFF7C3AED)
                : const Color(0xFF2D2D4E),
            width: isNewest ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: Color(0xFF7C3AED), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _credentialType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isNewest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          const Color.fromRGBO(124, 58, 237, 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Newest',
                      style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Issued',
              value: _formatDate(issuanceDate),
            ),
            if (expirationDate != null && expirationDate.isNotEmpty)
              _InfoRow(
                label: 'Expires',
                value: _formatDate(expirationDate),
              ),
            _InfoRow(
              label: 'Issuer',
              value: issuer.length > 28
                  ? '${issuer.substring(0, 12)}…${issuer.substring(issuer.length - 10)}'
                  : issuer,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasteInputCard extends StatelessWidget {
  const _PasteInputCard({
    required this.controller,
    required this.onSubmit,
    required this.onClose,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D4E)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Paste QR Content',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Paste iden3comm message or deep link here...',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              child: const Text('Process'),
            ),
          ),
        ],
      ),
    );
  }
}

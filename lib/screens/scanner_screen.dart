import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

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

    final provider = context.read<WalletProvider>();
    await _controller.stop();
    final success = await provider.handleQrMessage(value.trim());

    if (!mounted) return;

    if (!success && provider.hasPendingProofPreview) {
      await _showProofPreview(provider);
      return;
    }

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
        color: ZKColors.success,
        onDone: () => Navigator.pop(context),
      );
    } else {
      _showResult(
        title: 'Failed',
        message: provider.error ?? 'Unknown error',
        icon: Icons.error_outline,
        color: ZKColors.error,
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
      backgroundColor: ZKColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CredentialPickerSheet(credentials: candidates),
    );

    if (!mounted) return;

    if (selected == null) {
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
        color: ZKColors.success,
        onDone: () => Navigator.pop(context),
      );
    } else {
      _showResult(
        title: 'Failed',
        message: provider.error ?? 'Unknown error',
        icon: Icons.error_outline,
        color: ZKColors.error,
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

  Future<void> _showProofPreview(WalletProvider provider) async {
    final approved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: ZKColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ProofPreviewSheet(),
    );

    if (!mounted) return;

    if (approved != true) {
      provider.cancelProofPreview();
      setState(() {
        _processing = false;
        _scanned = false;
      });
      _controller.start();
      return;
    }

    setState(() => _processing = true);
    final ok = await provider.confirmProof();
    if (!mounted) return;

    if (ok) {
      _showResult(
        title: 'Success',
        message: 'Proof submitted successfully!',
        icon: Icons.check_circle_outline,
        color: ZKColors.success,
        onDone: () => Navigator.pop(context),
      );
    } else {
      _showResult(
        title: 'Failed',
        message: provider.error ?? 'Unknown error',
        icon: Icons.error_outline,
        color: ZKColors.error,
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
      backgroundColor: ZKColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: ZKColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ZKColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 22),
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
            const SizedBox(height: 8),
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
        title: const Text('Scan QR Code',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
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

          if (!_processing) const _ScanOverlay(),

          if (_processing || provider.isLoading)
            _ProcessingOverlay(message: provider.statusMessage),

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

class _ProofPreviewSheet extends StatelessWidget {
  const _ProofPreviewSheet();

  String _verifierHost(AuthBodyRequest body) {
    final url = body.callbackUrl ?? '';
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      return url;
    }
  }

  List<Widget> _buildSubjectRows(Map<String, dynamic>? subject) {
    if (subject == null || subject.isEmpty) return const [];
    final entries = subject.entries
        .where((e) => e.key != 'id' && e.key != 'type')
        .toList();
    return entries
        .map((e) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        color: ZKColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${e.value}',
                      style: const TextStyle(
                        color: ZKColors.text,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  String _credShortLabel(ClaimEntity c) {
    final issuanceDate = c.info['issuanceDate'] as String?;
    final issuer = c.issuer;
    final shortIssuer = issuer.length > 16
        ? '${issuer.substring(0, 8)}…${issuer.substring(issuer.length - 6)}'
        : issuer;
    return '$shortIssuer · ${issuanceDate ?? c.id.substring(0, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        final message = provider.pendingProofMessage;
        if (message == null) {
          return const SizedBox.shrink();
        }
        final authBody = message.body as AuthBodyRequest;
        final scopes = authBody.scope ?? [];
        final matchingByType = provider.proofMatchingByType;
        final selectedByType = provider.proofSelectedByType;
        final allFound =
            scopes.every((s) => (matchingByType[s.query.type ?? '']?.isNotEmpty ?? false));

        return SizedBox(
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.policy_outlined,
                        color: ZKColors.primary, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Proof Request',
                      style: TextStyle(
                        color: ZKColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: ZKColors.textSecondary, size: 20),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
              const Divider(color: ZKColors.border),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    if (!allFound)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          border:
                              Border.all(color: const Color(0xFFFFEEBA)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Color(0xFF856404), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Required credential not found in your wallet. '
                                'Please obtain the necessary credential before proving.',
                                style: TextStyle(
                                  color: Color(0xFF856404),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Verifier info
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: ZKColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ZKColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _verifierHost(authBody),
                            style: const TextStyle(
                              color: ZKColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'requests you to sign in',
                            style: TextStyle(
                                color: ZKColors.textSecondary,
                                fontSize: 14),
                          ),
                          if (authBody.reason != null &&
                              authBody.reason!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Reason: ${authBody.reason}',
                              style: const TextStyle(
                                color: ZKColors.textMuted,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Scope cards
                    ...scopes.asMap().entries.map((entry) {
                      final i = entry.key;
                      final scope = entry.value;
                      final queryType = scope.query.type ?? '';
                      final matches = matchingByType[queryType] ?? [];
                      final found = matches.isNotEmpty;
                      final selected = selectedByType[queryType];
                      final credSubject =
                          scope.query.credentialSubject ?? {};
                      return Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: ZKColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: found
                                ? ZKColors.cardBorder
                                : const Color(0xFFFFCDD2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Proof ${i + 1}',
                                  style: const TextStyle(
                                    color: ZKColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  found
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  color: found
                                      ? ZKColors.success
                                      : ZKColors.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  found
                                      ? 'Credential found'
                                      : 'Not found',
                                  style: TextStyle(
                                    color: found
                                        ? ZKColors.success
                                        : ZKColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _ScopeRow('Type', queryType),
                            _ScopeRow('Circuit', scope.circuitId),
                            if (matches.length == 1 && selected != null) ...[
                              const SizedBox(height: 8),
                              _CredentialDataExpansion(
                                credential: selected,
                              ),
                            ],
                            if (matches.length > 1 && selected != null) ...[
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () => _pickCredential(
                                  context,
                                  provider,
                                  queryType,
                                  matches,
                                  selected,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                        17, 78, 246, 0.08),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color.fromRGBO(
                                          17, 78, 246, 0.25),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.swap_horiz,
                                              size: 16,
                                              color: ZKColors.primary),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Select Credential',
                                            style: TextStyle(
                                              color: ZKColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${matches.length} options',
                                            style: const TextStyle(
                                              color: ZKColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ..._buildSubjectRows(selected.info[
                                              'credentialSubject']
                                          as Map<String, dynamic>?),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (credSubject.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Credential Subject',
                                style: TextStyle(
                                  color: ZKColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...credSubject.entries.map(
                                (e) {
                                  final isEmpty = e.value is Map &&
                                      (e.value as Map).isEmpty;
                                  return _ScopeRow(
                                    e.key,
                                    isEmpty ? '(any)' : '${e.value}',
                                  );
                                },
                              ),
                            ],
                            if (scope.query.context != null &&
                                scope.query.context!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                scope.query.context!,
                                style: const TextStyle(
                                  color: ZKColors.textMuted,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20,
                    MediaQuery.of(context).padding.bottom + 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: allFound
                            ? () => Navigator.of(context).pop(true)
                            : null,
                        child: const Text('Prove'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCredential(
    BuildContext context,
    WalletProvider provider,
    String queryType,
    List<ClaimEntity> candidates,
    ClaimEntity current,
  ) async {
    final picked = await showModalBottomSheet<ClaimEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ZKColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ZKColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Select Credential',
                style: TextStyle(
                  color: ZKColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'For: $queryType',
                style: const TextStyle(
                    color: ZKColors.textSecondary, fontSize: 13),
              ),
            ),
            const Divider(color: ZKColors.border, height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: candidates.length,
                itemBuilder: (_, i) {
                  final c = candidates[i];
                  final isSelected = c.id == current.id;
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(c),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ZKColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? ZKColors.primary
                              : ZKColors.cardBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Credential ${i + 1}',
                                  style: const TextStyle(
                                    color: ZKColors.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: ZKColors.primary, size: 20),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _credShortLabel(c),
                            style: const TextStyle(
                              color: ZKColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ..._buildSubjectRows(c.info['credentialSubject']
                              as Map<String, dynamic>?),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      provider.setProofSelection(queryType, picked);
    }
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                  color: ZKColors.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: ZKColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

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
                  color: ZKColors.primary,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
        ),
        Container(
          color: const Color.fromRGBO(0, 0, 0, 0.6),
          padding: const EdgeInsets.all(24),
          child: const Text(
            'Point the camera at an iden3comm QR code\n'
            '(Auth request or Credential offer)',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
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
      color: const Color.fromRGBO(0, 0, 0, 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ZKColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialDataExpansion extends StatefulWidget {
  const _CredentialDataExpansion({required this.credential});

  final ClaimEntity credential;

  @override
  State<_CredentialDataExpansion> createState() =>
      _CredentialDataExpansionState();
}

class _CredentialDataExpansionState
    extends State<_CredentialDataExpansion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final subject = widget.credential.info['credentialSubject']
        as Map<String, dynamic>?;
    final entries = (subject ?? const {})
        .entries
        .where((e) => e.key != 'id' && e.key != 'type')
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(17, 78, 246, 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromRGBO(17, 78, 246, 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined,
                      size: 14, color: ZKColors.primary),
                  const SizedBox(width: 6),
                  const Text(
                    'View credential data',
                    style: TextStyle(
                      color: ZKColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: ZKColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.isEmpty
                    ? const [
                        Text(
                          'No additional fields',
                          style: TextStyle(
                              color: ZKColors.textMuted, fontSize: 11),
                        ),
                      ]
                    : entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    e.key,
                                    style: const TextStyle(
                                      color: ZKColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${e.value}',
                                    style: const TextStyle(
                                      color: ZKColors.text,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

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
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ZKColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Credential',
                  style: TextStyle(
                    color: ZKColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pick the credential to use for this proof.',
                  style: TextStyle(color: ZKColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(color: ZKColors.border),
          Expanded(
            child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: credentials.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _CredentialPickerCard(
                credential: credentials[i],
                isNewest: i == 0,
                onTap: () => Navigator.of(ctx).pop(credentials[i]),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ZKColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNewest ? ZKColors.electric : ZKColors.cardBorder,
            width: isNewest ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: ZKColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _credentialType,
                    style: const TextStyle(
                      color: ZKColors.text,
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
                      color: const Color.fromRGBO(17, 78, 246, 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Newest',
                      style: TextStyle(
                        color: ZKColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(label: 'Issued', value: _formatDate(issuanceDate)),
            if (expirationDate != null && expirationDate.isNotEmpty)
              _InfoRow(
                  label: 'Expires', value: _formatDate(expirationDate)),
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
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                color: ZKColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: ZKColors.text, fontSize: 12),
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
        color: ZKColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZKColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.4),
            blurRadius: 20,
            offset: Offset(0, -4),
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
                  color: ZKColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close,
                    color: ZKColors.textSecondary, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style:
                const TextStyle(color: ZKColors.text, fontSize: 13),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Paste iden3comm message or deep link here...',
              hintStyle: TextStyle(color: ZKColors.textSecondary, fontSize: 13),
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

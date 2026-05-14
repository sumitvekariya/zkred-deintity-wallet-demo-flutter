import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class CredentialDetailScreen extends StatelessWidget {
  const CredentialDetailScreen({super.key});

  String _prettyType(String type) {
    if (type.isEmpty) return 'Verifiable Credential';
    final parts = type.split('/');
    final last = parts.last.isNotEmpty ? parts.last : type;
    return last.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
  }

  String _shortDid(String did) {
    if (did.length <= 24) return did;
    return '${did.substring(0, 14)}…${did.substring(did.length - 8)}';
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  ({String label, Color bg, Color fg}) _statusFor(ClaimState s) {
    switch (s) {
      case ClaimState.active:
        return (
          label: 'Active',
          bg: const Color(0xFFE7F7EC),
          fg: ZKColors.success
        );
      case ClaimState.expired:
        return (
          label: 'Expired',
          bg: const Color(0xFFFFF6E0),
          fg: ZKColors.warning
        );
      case ClaimState.revoked:
        return (
          label: 'Revoked',
          bg: const Color(0xFFFFE9E9),
          fg: ZKColors.error
        );
      default:
        return (
          label: s.name,
          bg: const Color(0xFFEFEFEF),
          fg: ZKColors.textMuted,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final claim =
        ModalRoute.of(context)!.settings.arguments as ClaimEntity;
    final status = _statusFor(claim.state);
    final type = _prettyType(claim.type);
    final issuanceDate = claim.info['issuanceDate'] as String?;
    final expirationDate =
        claim.info['expirationDate'] as String? ?? claim.expiration;

    // Extract credentialSubject fields, mirroring the RN app.
    // Flatten one level of nesting; skip 'id' and 'type'.
    final subject =
        (claim.info['credentialSubject'] as Map<String, dynamic>?) ?? {};
    final subjectEntries = subject.entries
        .where((e) => e.key != 'id' && e.key != 'type')
        .expand<MapEntry<String, dynamic>>((e) {
      final v = e.value;
      if (v is Map<String, dynamic>) {
        return v.entries.expand((inner) {
          final iv = inner.value;
          if (iv is Map<String, dynamic>) {
            return iv.entries.map((deep) =>
                MapEntry('${e.key}.${inner.key}.${deep.key}', deep.value));
          }
          return [MapEntry('${e.key}.${inner.key}', iv)];
        });
      }
      return [e];
    }).toList();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                    Expanded(
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ZKColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ZKColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ZKColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color.fromRGBO(17, 78, 246, 0.15),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: ZKColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: ZKColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _shortDid(claim.issuer),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: ZKColors.textMuted,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status.bg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.label,
                              style: TextStyle(
                                color: status.fg,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _kvRow('Issued', _formatDate(issuanceDate)),
                          if (expirationDate != null &&
                              expirationDate.isNotEmpty)
                            _kvRow('Expires', _formatDate(expirationDate)),
                          _kvRow('Credential ID', claim.id, mono: true),
                          const SizedBox(height: 16),
                          const Divider(color: ZKColors.border, height: 1),
                          const SizedBox(height: 14),
                          const Text(
                            'Credential Data',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ZKColors.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (subjectEntries.isEmpty)
                            const Text(
                              'No additional fields',
                              style: TextStyle(
                                color: ZKColors.textMuted,
                                fontSize: 13,
                              ),
                            )
                          else
                            ...subjectEntries.map(
                              (e) => _kvRow(e.key, '${e.value}'),
                            ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: const JsonEncoder.withIndent(
                                                '  ')
                                            .convert(claim.info),
                                      ),
                                    );
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text('Copied to clipboard'),
                                    ));
                                  },
                                  icon: const Icon(Icons.copy_outlined,
                                      size: 18),
                                  label: const Text('Copy JSON'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ZKColors.error,
                                    side: const BorderSide(
                                        color: ZKColors.error),
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, claim),
                                  icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18),
                                  label: const Text('Delete'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kvRow(String key, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 13,
                color: ZKColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: ZKColors.text,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ClaimEntity claim) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZKColors.surface,
        title: const Text('Delete credential'),
        content: const Text(
            'This will remove the credential from your wallet. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ZKColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<WalletProvider>().removeCredential(claim.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

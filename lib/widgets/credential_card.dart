import 'package:flutter/material.dart';
import 'package:polygonid_flutter_sdk/credential/domain/entities/claim_entity.dart';

class CredentialCard extends StatelessWidget {
  const CredentialCard({
    super.key,
    required this.claim,
    this.onDelete,
  });

  final ClaimEntity claim;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isExpired = claim.state == ClaimState.expired ||
        claim.state == ClaimState.revoked;
    final label = _prettyType(claim.type);
    final issuerShort = _shortDid(claim.issuer);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? Colors.red.withValues(alpha: 0.4)
              : const Color(0xFF2D2D4E),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: isExpired
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: isExpired
                            ? Colors.grey.withValues(alpha: 0.2)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconForType(label),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Issuer: $issuerShort',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(state: claim.state),
                  ],
                ),
                if (claim.expiration != null) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF2D2D4E), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        isExpired
                            ? Icons.event_busy_outlined
                            : Icons.event_available_outlined,
                        size: 14,
                        color: isExpired
                            ? Colors.red.withValues(alpha: 0.7)
                            : Colors.white38,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${isExpired ? "Expired" : "Expires"} ${_formatDate(claim.expiration!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired
                              ? Colors.red.withValues(alpha: 0.8)
                              : Colors.white60,
                        ),
                      ),
                      const Spacer(),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.white30,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16162A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              _prettyType(claim.type),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Verifiable Credential',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _DetailRow(label: 'ID', value: claim.id),
            _DetailRow(label: 'ISSUER', value: claim.issuer),
            _DetailRow(label: 'TYPE', value: claim.type),
            _DetailRow(label: 'STATE', value: claim.state.name.toUpperCase()),
            if (claim.expiration != null)
              _DetailRow(label: 'EXPIRES', value: claim.expiration!),
          ],
        ),
      ),
    );
  }

  String _prettyType(String type) {
    if (type.isEmpty) return 'Verifiable Credential';
    // Extract last part of URL-style type (e.g. .../KYCAgeCredential)
    final parts = type.split('/');
    final last = parts.last.isNotEmpty ? parts.last : type;
    // Insert spaces before capitals
    return last.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
  }

  String _shortDid(String did) {
    if (did.length <= 20) return did;
    return '${did.substring(0, 10)}…${did.substring(did.length - 6)}';
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('kyc') || t.contains('age') || t.contains('person')) {
      return Icons.person_outlined;
    }
    if (t.contains('degree') || t.contains('education')) {
      return Icons.school_outlined;
    }
    if (t.contains('membership') || t.contains('access')) {
      return Icons.card_membership_outlined;
    }
    return Icons.badge_outlined;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final ClaimState state;

  @override
  Widget build(BuildContext context) {
    final isGood = state == ClaimState.active;
    final label = state.name[0].toUpperCase() + state.name.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGood
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGood
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.red.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isGood ? Colors.greenAccent : Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

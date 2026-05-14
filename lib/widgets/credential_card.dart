import 'package:flutter/material.dart';
import 'package:polygonid_flutter_sdk/credential/domain/entities/claim_entity.dart';

import '../theme/app_theme.dart';

/// Compact credential row matching the production Cleo "CredentialItem".
///
/// Renders as: eye icon (teal) + title/issuer column + status dot.
class CredentialCard extends StatelessWidget {
  const CredentialCard({
    super.key,
    required this.claim,
    this.onTap,
    this.onDelete,
  });

  final ClaimEntity claim;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  String _prettyType(String type) {
    if (type.isEmpty) return 'Verifiable Credential';
    final parts = type.split('/');
    final last = parts.last.isNotEmpty ? parts.last : type;
    return last.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
  }

  String _shortIssuer(String did) {
    if (did.length <= 20) return did;
    return '${did.substring(0, 10)}…${did.substring(did.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final active = claim.state == ClaimState.active;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.visibility_outlined,
                color: ZKColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _prettyType(claim.type),
                    style: const TextStyle(
                      color: ZKColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _shortIssuer(claim.issuer),
                    style: const TextStyle(
                      color: ZKColors.textMuted,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: active ? ZKColors.primary : Colors.transparent,
                border: Border.all(color: ZKColors.primary, width: 1.4),
                shape: BoxShape.circle,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: ZKColors.textMuted, size: 18),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

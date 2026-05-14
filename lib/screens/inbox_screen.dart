import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  String _query = '';

  String _shortIssuer(String issuer) {
    if (issuer.length <= 18) return issuer;
    return '${issuer.substring(0, 12)}…${issuer.substring(issuer.length - 4)}';
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _prettyType(String type) {
    if (type.isEmpty) return 'Credential';
    final parts = type.split('/');
    final last = parts.last.isNotEmpty ? parts.last : type;
    return last.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
  }

  List<_InboxItemData> _buildItems(List<ClaimEntity> credentials) {
    if (credentials.isEmpty) {
      return [
        _InboxItemData(
          organization: 'ZKred',
          type: 'Welcome to your wallet',
          subtitle: 'Scan a QR to claim your first credential',
          date: 'Today',
          isUnread: true,
        ),
        _InboxItemData(
          organization: 'Privado ID',
          type: 'Your DID is ready',
          subtitle: 'You can now share verifiable credentials',
          date: 'Today',
          isUnread: false,
        ),
        _InboxItemData(
          organization: 'Polygon',
          type: 'Network: Amoy testnet',
          subtitle: 'Connected and ready for proof generation',
          date: 'Today',
          isUnread: false,
        ),
      ];
    }
    return credentials.map((c) {
      return _InboxItemData(
        organization: _shortIssuer(c.issuer),
        type: 'Credential received',
        subtitle: _prettyType(c.type),
        date: _formatDate(c.info['issuanceDate'] as String?),
        isUnread: c.state == ClaimState.active,
        credential: c,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final items = _buildItems(provider.credentials);
    final filtered = _query.isEmpty
        ? items
        : items
            .where((i) =>
                i.organization.toLowerCase().contains(_query.toLowerCase()) ||
                i.type.toLowerCase().contains(_query.toLowerCase()) ||
                i.subtitle.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return GradientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My inbox',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: ZKColors.text,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: ZKColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ZKColors.cardBorder),
                  ),
                  padding:
                      const EdgeInsets.fromLTRB(12, 14, 12, 8),
                  child: Column(
                    children: [
                      _SearchBar(
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? const _EmptyInbox()
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: ZKColors.border,
                                ),
                                itemBuilder: (context, i) {
                                  final item = filtered[i];
                                  return _InboxRow(
                                    item: item,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/message-detail',
                                        arguments: {
                                          'title': item.organization,
                                          'subtitle': item.type,
                                          'date': item.date,
                                          'content': item.subtitle,
                                          'isClaimable':
                                              item.credential == null,
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxItemData {
  _InboxItemData({
    required this.organization,
    required this.type,
    required this.subtitle,
    required this.date,
    required this.isUnread,
    this.credential,
  });

  final String organization;
  final String type;
  final String subtitle;
  final String date;
  final bool isUnread;
  final ClaimEntity? credential;
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: ZKColors.text),
        decoration: const InputDecoration(
          hintText: 'Search messages',
          prefixIcon: Icon(Icons.search, color: ZKColors.textMuted, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          hintStyle: TextStyle(color: ZKColors.textMuted, fontSize: 14),
        ),
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.item, required this.onTap});

  final _InboxItemData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = item.organization.isNotEmpty
        ? item.organization[0].toUpperCase()
        : '?';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: ZKColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.organization,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ZKColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.type,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ZKColors.electric,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ZKColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ZKColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:
                        item.isUnread ? ZKColors.primary : Colors.transparent,
                    border: Border.all(color: ZKColors.primary, width: 1.4),
                    shape: BoxShape.circle,
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

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No messages match your search',
          style: TextStyle(color: ZKColors.textMuted, fontSize: 14),
        ),
      ),
    );
  }
}

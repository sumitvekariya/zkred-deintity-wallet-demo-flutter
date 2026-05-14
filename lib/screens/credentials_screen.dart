import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/credential_card.dart';

class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _query = '';

  static const _tabs = [
    _TabSpec('All', null),
    _TabSpec('Education', 'education'),
    _TabSpec('Achievements', 'achievement'),
    _TabSpec('Training', 'training'),
    _TabSpec('Job', 'job'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WalletProvider>();
      if (provider.hasIdentity) provider.loadCredentials();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<ClaimEntity> _filter(List<ClaimEntity> all) {
    final keyword = _tabs[_tabCtrl.index].keyword;
    Iterable<ClaimEntity> result = all;
    if (keyword != null) {
      result = result.where((c) =>
          c.type.toLowerCase().contains(keyword));
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result.where((c) =>
          c.type.toLowerCase().contains(q) ||
          c.issuer.toLowerCase().contains(q));
    }
    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final filtered = _filter(provider.credentials);

    return GradientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My credentials',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: ZKColors.text,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/scanner'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: ZKColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner,
                              size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Scan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.06),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabCtrl,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: ZKColors.primary,
                        unselectedLabelColor: ZKColors.textMuted,
                        indicatorColor: ZKColors.primary,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle:
                            const TextStyle(fontSize: 14),
                        tabs: _tabs
                            .map((t) => Tab(text: t.label))
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(
                            fontSize: 14,
                            color: ZKColors.text,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search credentials',
                            prefixIcon: Icon(Icons.search,
                                color: ZKColors.textMuted, size: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filtered.isEmpty
                            ? const _EmptyState()
                            : RefreshIndicator(
                                onRefresh: provider.loadCredentials,
                                color: ZKColors.primary,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: ZKColors.border,
                                  ),
                                  itemBuilder: (context, i) {
                                    final claim = filtered[i];
                                    return CredentialCard(
                                      claim: claim,
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/credential-detail',
                                        arguments: claim,
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: filtered.isEmpty ? null : () {},
                          child: const Text('Share'),
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

class _TabSpec {
  final String label;
  final String? keyword;
  const _TabSpec(this.label, this.keyword);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined,
                color: ZKColors.primary, size: 40),
            SizedBox(height: 12),
            Text(
              'No credentials yet.\nScan a QR to claim one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ZKColors.textMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

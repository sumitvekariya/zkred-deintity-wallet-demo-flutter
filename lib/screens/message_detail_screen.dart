import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MessageDetailScreen extends StatelessWidget {
  const MessageDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments
            as Map<String, dynamic>? ??
        const {};
    final title = (args['title'] as String?) ?? 'Message';
    final subtitle = (args['subtitle'] as String?) ?? '';
    final date = (args['date'] as String?) ?? '';
    final content = (args['content'] as String?) ?? '';
    final isClaimable = (args['isClaimable'] as bool?) ?? false;

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
                    const Expanded(
                      child: Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: ZKColors.text,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: ZKColors.primaryDark,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chevron_left, size: 18),
                          Text('Back'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: ZKColors.text,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 14,
                                color: ZKColors.primary,
                              ),
                            ),
                          ],
                          if (date.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: ZKColors.textMuted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          const Divider(color: ZKColors.border, height: 1),
                          const SizedBox(height: 14),
                          Text(
                            content.isEmpty
                                ? 'No additional details.'
                                : content,
                            style: const TextStyle(
                              fontSize: 14,
                              color: ZKColors.text,
                              height: 1.5,
                            ),
                          ),
                          if (isClaimable) ...[
                            const SizedBox(height: 18),
                            InkWell(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/claim-credential',
                                arguments: args,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  'Claim credential',
                                  style: TextStyle(
                                    color: ZKColors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
}

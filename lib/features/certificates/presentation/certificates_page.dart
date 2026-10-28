import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../messaging/data/messaging_providers.dart';
import '../data/certificates_repository.dart';
import 'certificate_view_page.dart';

String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

class CertificatesPage extends ConsumerWidget {
  const CertificatesPage({
    super.key,
    this.menteeId,
    this.menteeName,
  });

  final int? menteeId;
  final String? menteeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myIdAsync = ref.watch(currentUserIdProvider);
    final targetId = menteeId ?? (myIdAsync.isLoading ? null : myIdAsync.value);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          menteeName != null ? 'Certificates: $menteeName' : 'My Certificates',
        ),
      ),
      body: targetId == null
          ? const Center(child: CircularProgressIndicator())
          : ref.watch(menteeCertificatesProvider(targetId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
                        const SizedBox(height: 12),
                        const Text('Could not load certificates.'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(menteeCertificatesProvider(targetId)),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(menteeCertificatesProvider(targetId)),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Certificates Issued Yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete all clinical competency evaluations and theory assessments with your mentor to earn an official certificate.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.checklist, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Certificate Requirements',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _reqItem('Finalized clinical competency assessment sign-off'),
                                _reqItem('Theory exam pass score (80% or higher)'),
                                _reqItem('Procedural checklist verification by mentor'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(menteeCertificatesProvider(targetId)),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final cert in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => CertificateViewPage(certificate: cert),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFD4AF37)),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium,
                                        color: Color(0xFFB8860B),
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cert.thematicAreaName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Issued ${_fmtDate(cert.issuedAt)} • ${cert.cycleName}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Credential: CBCM-CERT-${cert.id.toString().padLeft(5, '0')}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  Widget _reqItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

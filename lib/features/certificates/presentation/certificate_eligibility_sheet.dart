import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../data/certificates_repository.dart';
import 'certificate_view_page.dart';

class CertificateEligibilitySheet extends ConsumerStatefulWidget {
  const CertificateEligibilitySheet({
    super.key,
    required this.menteeId,
    required this.menteeName,
    required this.cycleId,
    required this.thematicAreaId,
  });

  final int menteeId;
  final String menteeName;
  final int cycleId;
  final int thematicAreaId;

  @override
  ConsumerState<CertificateEligibilitySheet> createState() =>
      _CertificateEligibilitySheetState();
}

class _CertificateEligibilitySheetState
    extends ConsumerState<CertificateEligibilitySheet> {
  bool _issuing = false;

  Future<void> _issue() async {
    setState(() => _issuing = true);
    try {
      final cert = await ref.read(certificatesRepositoryProvider).issueCertificate(
            menteeId: widget.menteeId,
            cycleId: widget.cycleId,
            thematicAreaId: widget.thematicAreaId,
          );

      ref.invalidate(menteeCertificatesProvider(widget.menteeId));

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => CertificateViewPage(certificate: cert),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _issuing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not issue certificate: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = EligibilityQuery(
      menteeId: widget.menteeId,
      cycleId: widget.cycleId,
      thematicAreaId: widget.thematicAreaId,
    );
    final async = ref.watch(certificateEligibilityProvider(query));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Certificate Eligibility',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            'Evaluation status for ${widget.menteeName}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Could not check eligibility: $e'),
            ),
            data: (elig) {
              return Column(
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _statusTile(
                          'Finalized Competency Assessment',
                          elig.hasFinalizedAssessment,
                          'Mentor sign-off recorded',
                        ),
                        const Divider(height: 16),
                        _statusTile(
                          'Theory Exam Evaluation',
                          elig.theoryPassed,
                          'Pass threshold >= 80%',
                        ),
                        const Divider(height: 16),
                        _statusTile(
                          'Practical Competency Evaluation',
                          elig.practicalPassed,
                          'Prerequisites & checklist met',
                        ),
                        if (elig.hasExistingCertificate) ...[
                          const Divider(height: 16),
                          _statusTile(
                            'Active Certificate',
                            true,
                            'Certificate already issued',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (elig.isEligible)
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: _issuing ? 'Issuing Certificate...' : 'Issue Certificate',
                        variant: AppButtonVariant.primary,
                        icon: const Icon(Icons.workspace_premium, size: 18),
                        onPressed: _issuing ? null : _issue,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade900),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              elig.message ?? 'Mentee has not met all criteria for certificate issuance yet.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statusTile(String title, bool pass, String subtitle) {
    return Row(
      children: [
        Icon(
          pass ? Icons.check_circle : Icons.radio_button_unchecked,
          color: pass ? Colors.green.shade600 : Colors.grey,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

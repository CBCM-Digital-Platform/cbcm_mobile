import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../data/assigned_mentees_provider.dart';

/// Shows a bottom sheet listing all assigned mentees.
/// When tapped, returns the selected [AssignedMentee].
class MenteePickerSheet {
  static Future<AssignedMentee?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    return showModalBottomSheet<AssignedMentee>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MenteePickerContent(
        sheetContext: sheetContext,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}

class _MenteePickerContent extends ConsumerWidget {
  const _MenteePickerContent({
    required this.sheetContext,
    required this.title,
    this.subtitle,
  });

  final BuildContext sheetContext;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menteesAsync = ref.watch(assignedMenteesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Contacd C:\dev\cbcm_mobile
$files = Get-ChildItem lib -Recurse -Filter *.dart | ? { $_.Name -notlike '*.g.dart' }
$out = @("=== LINES  FILE ===")
$files | % { $out += ("{0,5}  {1}" -f (Get-Content $_.FullName).Count, $_.FullName.Substring((Get-Location).Path.Length+1)) }
$out += "", "=== UNREFERENCED FILES (no other file mentions the name) ==="
$all = $files | % { [pscustomobject]@{ Name=$_.Name; Text=(Get-Content $_.FullName -Raw) } }
foreach($f in $files){ $n=$f.Name; if(-not ($all | ? { $_.Name -ne $n -and $_.Text -match [regex]::Escape($n) })){ $out += $n } }
$out += "", "=== LEFTOVER KEYWORDS ==="
$out += $files | Select-String -Pattern 'mock|seed|sample|dummy|demo|fake|placeholder|TODO|FIXME|coming soon|Color\(0x|[^a-zA-Z_]print\(' | % { "{0}:{1}: {2}" -f $_.Filename, $_.LineNumber, $_.Line.Trim() }
$out | Out-File C:\dev\lib_inventory.txt -Encoding utf8
"Saved C:\dev\lib_inventory.txt ($($out.Count) lines)"iner(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                    ),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: menteesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Could not load mentees: $e'),
                  ),
                ),
                data: (mentees) {
                  if (mentees.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No assigned mentees found.',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: mentees.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final m = mentees[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(sheetContext).pop(m),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                  child: Text(
                                    m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : 'M',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.fullName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: isDark ? AppColors.darkTextPrimary : null,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${m.facility.isNotEmpty ? m.facility : "Clinical Facility"} • ${m.level}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

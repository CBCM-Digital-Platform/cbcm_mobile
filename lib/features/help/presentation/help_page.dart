import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_response.dart';
import '../../../core/widgets/app_card.dart';
import '../data/help_providers.dart';
import '../domain/faq_item.dart';
import '../domain/user_guide_item.dart';
import 'guide_detail_page.dart';

class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> {
  String _faqQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.error.message;
    }
    return error.toString();
  }

  Future<void> _openGuide(UserGuideItem guide) async {
    if (guide.isUrl) {
      final uri = Uri.tryParse(guide.content.trim());
      if (uri != null) {
        try {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open guide URL.')),
            );
          }
          return;
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open guide URL.')),
            );
          }
          return;
        }
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuideDetailPage(guide: guide),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            'Help & Support',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(
                icon: Icon(Icons.quiz_outlined, size: 20),
                text: 'FAQs',
              ),
              Tab(
                icon: Icon(Icons.menu_book_outlined, size: 20),
                text: 'User Guides',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFaqsTab(theme),
            _buildGuidesTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqsTab(ThemeData theme) {
    final asyncFaqs = ref.watch(faqsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(faqsProvider.future),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _faqQuery = v.trim().toLowerCase()),
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                suffixIcon: _faqQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _faqQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: asyncFaqs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(
                theme: theme,
                message: _errorMessage(e),
                onRetry: () => ref.invalidate(faqsProvider),
              ),
              data: (faqs) {
                final filtered = faqs.where((f) {
                  if (_faqQuery.isEmpty) return true;
                  final matchQuestion = f.question.toLowerCase().contains(_faqQuery);
                  final matchAnswer = f.answer.toLowerCase().contains(_faqQuery);
                  final matchCat = f.category?.toLowerCase().contains(_faqQuery) ?? false;
                  return matchQuestion || matchAnswer || matchCat;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(
                    theme: theme,
                    icon: Icons.search_off_outlined,
                    message: _faqQuery.isEmpty
                        ? 'No FAQs available.'
                        : 'No FAQs found matching "$_faqQuery".',
                  );
                }

                // Group by category
                final Map<String, List<FaqItem>> grouped = {};
                for (final item in filtered) {
                  final cat = (item.category != null && item.category!.trim().isNotEmpty)
                      ? item.category!.trim()
                      : 'General';
                  grouped.putIfAbsent(cat, () => []).add(item);
                }

                final categories = grouped.keys.toList()..sort();

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: categories.length,
                  itemBuilder: (context, catIndex) {
                    final category = categories[catIndex];
                    final items = grouped[category]!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map(
                            (faq) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AppCard(
                                padding: EdgeInsets.zero,
                                child: Theme(
                                  data: theme.copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    iconColor: theme.colorScheme.primary,
                                    collapsedIconColor: theme.colorScheme.onSurfaceVariant,
                                    title: Text(
                                      faq.question,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: SelectableText(
                                          faq.answer,
                                          style: TextStyle(
                                            height: 1.5,
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidesTab(ThemeData theme) {
    final asyncGuides = ref.watch(userGuidesProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(userGuidesProvider.future),
      child: asyncGuides.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildErrorState(
          theme: theme,
          message: _errorMessage(e),
          onRetry: () => ref.invalidate(userGuidesProvider),
        ),
        data: (guides) {
          if (guides.isEmpty) {
            return _buildEmptyState(
              theme: theme,
              icon: Icons.menu_book_outlined,
              message: 'No user guides available.',
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: guides.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final guide = guides[i];
              final hasAttachment = guide.attachmentFileId != null;

              return AppCard(
                padding: const EdgeInsets.all(14),
                child: InkWell(
                  onTap: () => _openGuide(guide),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          guide.isUrl
                              ? Icons.open_in_new_outlined
                              : Icons.article_outlined,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guide.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              guide.isUrl
                                  ? 'External web resource'
                                  : guide.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (hasAttachment) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.attachment_outlined,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Has attachment',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required ThemeData theme,
    required IconData icon,
    required String message,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState({
    required ThemeData theme,
    required String message,
    required VoidCallback onRetry,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

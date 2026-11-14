import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import 'assign_resources_page.dart';
import 'open_modules_page.dart';

class LearningAccessPage extends StatelessWidget {
  const LearningAccessPage(
    this.menteeId,
    this.menteeName, {
    super.key,
  });

  const LearningAccessPage.named({
    super.key,
    required this.menteeId,
    required this.menteeName,
  });

  final int menteeId;
  final String menteeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Learning Access: $menteeName',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 2.5,
            labelColor: AppColors.primary,
            unselectedLabelColor:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            dividerColor: isDark ? AppColors.darkBorder : AppColors.border,
            tabs: const [
              Tab(
                icon: Icon(Icons.menu_book),
                text: 'Modules',
              ),
              Tab(
                icon: Icon(Icons.folder_shared),
                text: 'Resources',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _KeepAliveTab(
              child: OpenModulesPage(
                menteeId: menteeId,
                menteeName: menteeName,
                embedded: true,
              ),
            ),
            _KeepAliveTab(
              child: AssignResourcesPage(
                menteeId: menteeId,
                menteeName: menteeName,
                embedded: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});
  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

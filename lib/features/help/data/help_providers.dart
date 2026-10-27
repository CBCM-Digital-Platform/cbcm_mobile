import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../auth/presentation/current_role_provider.dart';
import '../domain/audience_filter.dart';
import '../domain/faq_item.dart';
import '../domain/user_guide_item.dart';
import 'help_repository.dart';

final helpRepositoryProvider = Provider<HelpRepository>((ref) {
  return HelpRepository(ref.watch(dioProvider));
});

final faqsProvider = FutureProvider.autoDispose<List<FaqItem>>((ref) async {
  final repo = ref.watch(helpRepositoryProvider);
  final role = ref.watch(currentRoleProvider);
  final all = await repo.getFaqs();
  final roleName = role?.name;
  return all.where((f) => matchesRoleAudience(f.targetAudience, roleName)).toList();
});

final userGuidesProvider = FutureProvider.autoDispose<List<UserGuideItem>>((ref) async {
  final repo = ref.watch(helpRepositoryProvider);
  final role = ref.watch(currentRoleProvider);
  final all = await repo.getGuides();
  final roleName = role?.name;
  return all.where((g) => matchesRoleAudience(g.targetAudience, roleName)).toList();
});

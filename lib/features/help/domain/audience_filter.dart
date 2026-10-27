bool matchesRoleAudience(String? targetAudience, String? roleName) {
  if (targetAudience == null || targetAudience.trim().isEmpty) return true;
  final clean = targetAudience.trim().toLowerCase();
  if (clean == 'all') return true;
  if (roleName == null || roleName.isEmpty) return true;
  final tokens = clean.split(',').map((s) => s.trim().toLowerCase());
  return tokens.contains(roleName.toLowerCase());
}

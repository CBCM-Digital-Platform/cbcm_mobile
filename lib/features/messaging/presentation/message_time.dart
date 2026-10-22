const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "09:42 AM"
String clockTime(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  final suffix = t.hour >= 12 ? 'PM' : 'AM';
  return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
}

/// Short label for the conversation list: "Now", "5m ago", "2h ago",
/// "Yesterday", "Tue", or a date.
String listTime(DateTime? t, {DateTime? now}) {
  if (t == null) return '';
  final current = now ?? DateTime.now();
  final diff = current.difference(t);

  if (diff.inMinutes < 1) return 'Now';
  if (_sameDay(t, current)) {
    return diff.inHours < 1 ? '${diff.inMinutes}m ago' : '${diff.inHours}h ago';
  }
  final yesterday = current.subtract(const Duration(days: 1));
  if (_sameDay(t, yesterday)) return 'Yesterday';
  if (diff.inDays < 7) return _weekdays[t.weekday - 1];
  return '${t.day} ${_months[t.month - 1]} ${t.year}';
}

/// Separator label inside a chat: "Today", "Yesterday", "12 Oct 2026".
String dayLabel(DateTime t, {DateTime? now}) {
  final current = now ?? DateTime.now();
  if (_sameDay(t, current)) return 'Today';
  if (_sameDay(t, current.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  }
  return '${t.day} ${_months[t.month - 1]} ${t.year}';
}

bool isSameDay(DateTime a, DateTime b) => _sameDay(a, b);
/// Foundation only. Real enqueue/replay logic is built in Week 4
/// alongside the Mentee logbook and offline sync.
class SyncQueue {
  SyncQueue();

  final List<Map<String, dynamic>> _pending = [];

  void enqueue(Map<String, dynamic> action) {
    _pending.add(action);
  }

  List<Map<String, dynamic>> get pending => List.unmodifiable(_pending);

  void clear() => _pending.clear();
}
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../storage/secure_storage.dart';
import '../storage/storage_keys.dart';

enum ReadAloudStatus { preparing, ready, playing, paused, finished, unavailable }

/// Reads text aloud in short passages, so it can pause, resume, skip
/// forward and back, jump anywhere, and remember where the user stopped.
/// The place is saved per user and per document, so it survives logging
/// out and back in.
class ReadAloudController extends ChangeNotifier {
  ReadAloudController({
    required Future<String> Function() loadText,
    required SecureStorage storage,
    required String resourceKey,
  })  : _loadText = loadText,
        _storage = storage,
        _resourceKey = resourceKey {
    _prepare();
  }

  static const _maxChunk = 350;

  final Future<String> Function() _loadText;
  final SecureStorage _storage;
  final String _resourceKey;
  final FlutterTts _tts = FlutterTts();

  String? _positionKey;
  List<String> _chunks = const [];
  int _index = 0;
  int _runId = 0;
  int _quickReturns = 0;
  bool _disposed = false;

  ReadAloudStatus status = ReadAloudStatus.preparing;
  double speed = 1.0;
  String? problem;

  /// True when the saved place was restored and playback has not started yet.
  bool resumed = false;

  int get total => _chunks.length;
  int get position => _index;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _prepare() async {
    try {
      _chunks = _split(await _loadText());
    } catch (e) {
      debugPrint('[READ-ALOUD] could not read text: $e');
      _chunks = const [];
    }

    if (_chunks.isEmpty) {
      status = ReadAloudStatus.unavailable;
      problem = 'There is no readable text here. A scanned document has none.';
      _notify();
      return;
    }

    try {
      final userId = await _storage.read(StorageKeys.userId);
      _positionKey = 'read_pos:${userId ?? 'anon'}:$_resourceKey';
      final saved = int.tryParse(await _storage.read(_positionKey!) ?? '');
      if (saved != null && saved > 0 && saved < _chunks.length) {
        _index = saved;
        resumed = true;
      }
    } catch (_) {
      // Could not restore the place: start from the beginning.
    }

    status = ReadAloudStatus.ready;
    _notify();
  }

  Future<void> _savePosition() async {
    final key = _positionKey;
    if (key == null) return;
    try {
      await _storage.write(key, _index.toString());
    } catch (_) {}
  }

  /// Joins the document's hard line breaks, then groups sentences into
  /// passages short enough for the phone's voice engine.
  List<String> _split(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return const [];

    final pieces = <String>[];
    for (final sentence in clean.split(RegExp(r'(?<=[.!?])\s+'))) {
      var s = sentence;
      while (s.length > _maxChunk) {
        var cut = s.lastIndexOf(' ', _maxChunk);
        if (cut <= 0) cut = _maxChunk;
        pieces.add(s.substring(0, cut).trim());
        s = s.substring(cut).trim();
      }
      if (s.isNotEmpty) pieces.add(s);
    }

    final chunks = <String>[];
    var current = '';
    for (final p in pieces) {
      if (current.isNotEmpty && current.length + p.length + 1 > _maxChunk) {
        chunks.add(current);
        current = p;
      } else {
        current = current.isEmpty ? p : '$current $p';
      }
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  Future<void> play() async {
    if (_chunks.isEmpty ||
        status == ReadAloudStatus.preparing ||
        status == ReadAloudStatus.unavailable) {
      return;
    }
    if (status == ReadAloudStatus.finished) _index = 0;

    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5 * speed);

    _quickReturns = 0;
    resumed = false;
    status = ReadAloudStatus.playing;
    _notify();
    _run();
  }

  Future<void> _run() async {
    final myRun = ++_runId;

    while (!_disposed &&
        myRun == _runId &&
        status == ReadAloudStatus.playing &&
        _index < _chunks.length) {
      final chunk = _chunks[_index];
      final started = DateTime.now();
      try {
        await _tts.speak(chunk);
      } catch (_) {}
      if (_disposed || myRun != _runId || status != ReadAloudStatus.playing) {
        return;
      }

      // A long passage that "finishes" instantly means the phone's voice
      // engine isn't actually speaking.
      final tooFast = chunk.length > 40 &&
          DateTime.now().difference(started) < const Duration(milliseconds: 200);
      _quickReturns = tooFast ? _quickReturns + 1 : 0;
      if (_quickReturns >= 3) {
        status = ReadAloudStatus.unavailable;
        problem = "The phone's voice engine did not respond. Check that a "
            'text-to-speech voice is installed in the phone settings.';
        _notify();
        return;
      }

      _index++;
      _savePosition();
      _notify();
    }

    if (!_disposed && myRun == _runId && status == ReadAloudStatus.playing) {
      await _finish();
    }
  }

  Future<void> _finish() async {
    _runId++;
    await _tts.stop();
    status = ReadAloudStatus.finished;
    _index = 0;
    _savePosition();
    _notify();
  }

  Future<void> pause() async {
    if (status != ReadAloudStatus.playing) return;
    status = ReadAloudStatus.paused;
    _runId++;
    _savePosition();
    _notify();
    await _tts.stop();
  }

  Future<void> toggle() => status == ReadAloudStatus.playing ? pause() : play();

  /// Jumps to passage [target]. Keeps playing if it was playing.
  Future<void> seekTo(int target) async {
    if (_chunks.isEmpty ||
        status == ReadAloudStatus.preparing ||
        status == ReadAloudStatus.unavailable) {
      return;
    }
    if (target >= _chunks.length) {
      await _finish();
      return;
    }

    final next = target.clamp(0, _chunks.length - 1).toInt();
    final wasPlaying = status == ReadAloudStatus.playing;

    _runId++;
    await _tts.stop();
    _index = next;
    resumed = false;
    _savePosition();

    if (wasPlaying) {
      _run();
    } else {
      status = ReadAloudStatus.paused;
    }
    _notify();
  }

  Future<void> skipForward() => seekTo(_index + 1);
  Future<void> skipBack() => seekTo(_index - 1);

  Future<void> setSpeed(double value) async {
    speed = value;
    await _tts.setSpeechRate(0.5 * speed);
    if (status == ReadAloudStatus.playing) {
      // Restart the current passage so the new speed applies right away.
      _runId++;
      await _tts.stop();
      _run();
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _runId++;
    _savePosition();
    _tts.stop();
    super.dispose();
  }
}
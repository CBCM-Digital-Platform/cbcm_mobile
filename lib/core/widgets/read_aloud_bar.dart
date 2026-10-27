import 'package:flutter/material.dart';
import '../audio/read_aloud_controller.dart';
import '../theme/colors.dart';

/// Player controls for [ReadAloudController]: previous and next passage,
/// play and pause, a slider to jump anywhere, and the reading speed.
class ReadAloudBar extends StatefulWidget {
  const ReadAloudBar({super.key, required this.reader, this.safeBottom = true});

  final ReadAloudController reader;

  /// Set to false when something else below it already handles the bottom
  /// safe area.
  final bool safeBottom;

  @override
  State<ReadAloudBar> createState() => _ReadAloudBarState();
}

class _ReadAloudBarState extends State<ReadAloudBar> {
  static const _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  double? _drag;

  String _label(ReadAloudController r) {
    switch (r.status) {
      case ReadAloudStatus.preparing:
        return 'Preparing text...';
      case ReadAloudStatus.ready:
        return r.resumed ? 'Resume where you stopped' : 'Tap play to listen';
      case ReadAloudStatus.playing:
        return 'Reading aloud';
      case ReadAloudStatus.paused:
        return 'Paused';
      case ReadAloudStatus.finished:
        return 'Finished. Tap play to listen again.';
      case ReadAloudStatus.unavailable:
        return r.problem ?? 'Read-aloud is not available.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reader = widget.reader;

    return ListenableBuilder(
      listenable: reader,
      builder: (context, _) {
        final status = reader.status;
        final canUse = status != ReadAloudStatus.preparing &&
            status != ReadAloudStatus.unavailable;
        final playing = status == ReadAloudStatus.playing;
        final total = reader.total;

        final maxValue = total > 1 ? (total - 1).toDouble() : 1.0;
        final value =
            (_drag ?? reader.position.toDouble()).clamp(0.0, maxValue).toDouble();

        final content = Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _label(reader),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (canUse && total > 0)
                    Text(
                      '${value.round() + 1} / $total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (canUse)
                Slider(
                  value: value,
                  min: 0,
                  max: maxValue,
                  activeColor: AppColors.primary,
                  onChanged: total > 1
                      ? (v) => setState(() => _drag = v)
                      : null,
                  onChangeEnd: (v) {
                    setState(() => _drag = null);
                    reader.seekTo(v.round());
                  },
                )
              else
                const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PopupMenuButton<double>(
                    tooltip: 'Reading speed',
                    initialValue: reader.speed,
                    onSelected: reader.setSpeed,
                    itemBuilder: (_) => [
                      for (final s in _speeds)
                        PopupMenuItem(value: s, child: Text('${s}x')),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${reader.speed}x',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Previous passage',
                        onPressed: canUse ? reader.skipBack : null,
                        icon: const Icon(Icons.skip_previous),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        tooltip: playing ? 'Pause' : 'Listen',
                        onPressed: canUse ? reader.toggle : null,
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        tooltip: 'Next passage',
                        onPressed: canUse ? reader.skipForward : null,
                        icon: const Icon(Icons.skip_next),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        );

        return Material(
          elevation: 8,
          color: Theme.of(context).colorScheme.surface,
          child: widget.safeBottom
              ? SafeArea(top: false, child: content)
              : content,
        );
      },
    );
  }
}
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// Voice note recording and playback widget for chat.
/// WhatsApp-style voice message for Tier 2/3 users who prefer speaking.
class VoiceNoteRecorder extends StatefulWidget {
  final Function(String filePath, Duration duration) onRecordingComplete;

  const VoiceNoteRecorder({super.key, required this.onRecordingComplete});

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _duration = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000, // Low bitrate for smaller files
          sampleRate: 22050,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _duration = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _duration += const Duration(seconds: 1));
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    if (path != null) {
      widget.onRecordingComplete(path, _duration);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRecording) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, color: Colors.red.shade600, size: 16),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.stop_circle, color: Colors.red, size: 32),
            onPressed: _stopRecording,
          ),
        ] else
          IconButton(
            icon: Icon(Icons.mic_none, color: Theme.of(context).colorScheme.primary),
            onPressed: _startRecording,
            tooltip: 'Record voice note',
          ),
      ],
    );
  }
}

/// Widget to play back a voice note
class VoiceNotePlayer extends StatefulWidget {
  final String audioUrl;
  final Duration? duration;

  const VoiceNotePlayer({super.key, required this.audioUrl, this.duration});

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    _total = widget.duration ?? Duration.zero;
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playing = false; _position = Duration.zero; });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      if (widget.audioUrl.startsWith('http')) {
        await _player.play(UrlSource(widget.audioUrl));
      } else {
        await _player.play(DeviceFileSource(widget.audioUrl));
      }
    }
    setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total.inMilliseconds > 0
        ? _position.inMilliseconds / _total.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Icon(
              _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_total - _position),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Voice input widget for search — critical for regional language users.
/// Supports Telugu, Hindi, and English speech recognition.
/// Falls back gracefully if speech recognition is unavailable.
class VoiceSearchButton extends StatefulWidget {
  final ValueChanged<String> onResult;
  final String? locale; // 'te-IN', 'hi-IN', 'en-IN'

  const VoiceSearchButton({super.key, required this.onResult, this.locale});

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _available = false;
  String _partialResult = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _available = await _speech.initialize(
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
          _pulseController.stop();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
            _pulseController.stop();
          }
        },
      );
    } catch (_) {
      _available = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice input not available on this device')),
      );
      return;
    }

    setState(() { _isListening = true; _partialResult = ''; });
    _pulseController.repeat(reverse: true);

    // Determine locale — Telugu first for AP/Telangana market
    final locale = widget.locale ?? 'te-IN';

    await _speech.listen(
      onResult: (result) {
        setState(() => _partialResult = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          widget.onResult(result.recognizedWords);
          setState(() => _isListening = false);
          _pulseController.stop();
        }
      },
      localeId: locale,
      listenMode: stt.ListenMode.search,
      cancelOnError: true,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    _pulseController.stop();
    if (_partialResult.isNotEmpty) {
      widget.onResult(_partialResult);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) {
      return const SizedBox.shrink(); // Hide if not available
    }

    return _isListening
        ? _buildListeningUI(context)
        : IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Voice search',
            onPressed: _startListening,
          );
  }

  Widget _buildListeningUI(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary.withAlpha((50 + _pulseController.value * 50).toInt()),
          ),
          child: IconButton(
            icon: Icon(Icons.mic, color: cs.primary),
            onPressed: _stopListening,
            tooltip: 'Stop listening',
          ),
        );
      },
    );
  }
}

/// Full-screen voice search overlay for immersive voice input experience.
class VoiceSearchOverlay extends StatefulWidget {
  final ValueChanged<String> onResult;
  final String? locale;

  const VoiceSearchOverlay({super.key, required this.onResult, this.locale});

  @override
  State<VoiceSearchOverlay> createState() => _VoiceSearchOverlayState();
}

class _VoiceSearchOverlayState extends State<VoiceSearchOverlay> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _available = false;
  String _text = '';
  String _selectedLocale = 'te-IN';
  late AnimationController _animation;

  static const _locales = {
    'te-IN': 'తెలుగు',
    'hi-IN': 'हिन्दी',
    'en-IN': 'English',
  };

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.locale ?? 'te-IN';
    _animation = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _init();
  }

  @override
  void dispose() {
    _animation.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _init() async {
    _available = await _speech.initialize();
    if (_available && mounted) {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_available) return;
    setState(() { _isListening = true; _text = ''; });
    _animation.repeat(reverse: true);

    await _speech.listen(
      onResult: (result) {
        setState(() => _text = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _animation.stop();
          // Auto-submit after brief pause
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              widget.onResult(result.recognizedWords);
              Navigator.of(context).pop();
            }
          });
        }
      },
      localeId: _selectedLocale,
      listenMode: stt.ListenMode.search,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 4),
    );
  }

  void _cancel() {
    _speech.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.close), onPressed: _cancel),
                  // Language selector
                  SegmentedButton<String>(
                    segments: _locales.entries.map((e) =>
                      ButtonSegment(value: e.key, label: Text(e.value, style: const TextStyle(fontSize: 12)))
                    ).toList(),
                    selected: {_selectedLocale},
                    onSelectionChanged: (s) {
                      setState(() => _selectedLocale = s.first);
                      _speech.stop();
                      _startListening();
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Mic animation
            AnimatedBuilder(
              animation: _animation,
              builder: (_, __) => Container(
                width: 120 + _animation.value * 30,
                height: 120 + _animation.value * 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? cs.primary.withAlpha((30 + _animation.value * 40).toInt())
                      : cs.surfaceContainerHighest,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_off,
                  size: 48,
                  color: _isListening ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status text
            Text(
              _isListening
                  ? (_text.isEmpty ? 'Listening...' : _text)
                  : 'Tap mic to start',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),
            Text(
              _isListening ? 'Speak your search in ${_locales[_selectedLocale]}' : '',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),

            const Spacer(),

            // Retry button
            if (!_isListening && _text.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton.icon(
                  onPressed: _startListening,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ),

            // Submit button if we have text
            if (_text.isNotEmpty && !_isListening)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(width: double.infinity, child: FilledButton(
                  onPressed: () {
                    widget.onResult(_text);
                    Navigator.of(context).pop();
                  },
                  child: Text('Search: "$_text"'),
                )),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

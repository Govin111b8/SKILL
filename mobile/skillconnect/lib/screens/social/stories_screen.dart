import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class StoriesScreen extends StatefulWidget {
  final String professionalId;
  final String? storyId;

  const StoriesScreen({super.key, required this.professionalId, this.storyId});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  List<Story> _stories = [];
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _goNext();
      });
    _loadStories();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  Future<void> _loadStories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/stories/feed', queryParams: const {'limit': '50'});
      var stories = _parseFeed(res['data']);
      if (widget.professionalId.isNotEmpty) {
        stories = stories.where((story) => story.professionalId == widget.professionalId).toList();
      }
      if (stories.isEmpty && widget.professionalId.isNotEmpty) {
        final fallback = await ApiService.get('/stories/professional/${widget.professionalId}');
        stories = _parseStories(fallback['data']);
      }
      if (!mounted) return;
      setState(() {
        _stories = stories;
        final requestedIndex = widget.storyId == null ? -1 : stories.indexWhere((story) => story.id == widget.storyId);
        _currentIndex = requestedIndex >= 0 ? requestedIndex : 0;
      });
      if (_stories.isNotEmpty) {
        await _activateStory(_currentIndex);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Story> _parseFeed(dynamic data) {
    if (data is! List) return const [];
    final stories = <Story>[];
    for (final entry in data.whereType<Map>()) {
      final map = Map<String, dynamic>.from(entry);
      if (map['stories'] is List) {
        for (final rawStory in (map['stories'] as List).whereType<Map>()) {
          final storyMap = Map<String, dynamic>.from(rawStory);
          storyMap.putIfAbsent('professional_id', () => map['professional_id']);
          storyMap.putIfAbsent('professional_name', () => map['professional_name']);
          storyMap.putIfAbsent('avatar_url', () => map['avatar_url']);
          stories.add(Story.fromJson(storyMap));
        }
      } else {
        stories.add(Story.fromJson(map));
      }
    }
    return stories;
  }

  List<Story> _parseStories(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => Story.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _activateStory(int index) async {
    if (index < 0 || index >= _stories.length) return;
    await _prepareMedia(_stories[index]);
    _progressController
      ..stop()
      ..reset()
      ..forward();
    _markViewed(_stories[index]);
  }

  Future<void> _prepareMedia(Story story) async {
    await _disposeVideoController();
    if (story.mediaType != 'video' || story.mediaUrl.isEmpty) {
      if (mounted) setState(() {});
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _videoController = controller);
    } catch (_) {
      await _disposeVideoController();
      if (mounted) setState(() {});
    }
  }

  Future<void> _disposeVideoController() async {
    final controller = _videoController;
    _videoController = null;
    if (controller != null) {
      await controller.pause();
      await controller.dispose();
    }
  }

  Future<void> _markViewed(Story story) async {
    try {
      await ApiService.post('/stories/${story.id}/view', {}, auth: true);
    } catch (_) {}
  }

  Future<void> _goNext() async {
    if (_stories.isEmpty) return;
    if (_currentIndex >= _stories.length - 1) {
      if (mounted) context.pop();
      return;
    }
    setState(() => _currentIndex += 1);
    await _activateStory(_currentIndex);
  }

  Future<void> _goPrevious() async {
    if (_stories.isEmpty) return;
    if (_currentIndex <= 0) {
      _progressController
        ..stop()
        ..reset()
        ..forward();
      return;
    }
    setState(() => _currentIndex -= 1);
    await _activateStory(_currentIndex);
  }

  Future<void> _handleCta(Story story) async {
    if (story.ctaUrl != null && story.ctaUrl!.isNotEmpty) {
      final uri = Uri.tryParse(story.ctaUrl!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (!mounted || story.professionalId.isEmpty) return;
    context.push('/professional/${story.professionalId}');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 24),
              SkeletonLoader(height: 8, radius: 999),
              SizedBox(height: 24),
              Row(
                children: [
                  SkeletonLoader(width: 44, height: 44, radius: 22),
                  SizedBox(width: 12),
                  SkeletonLoader(width: 140, height: 16),
                ],
              ),
              SizedBox(height: 24),
              Expanded(child: SkeletonLoader(height: 400, radius: 24)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: ListView(
          children: [
            EmptyStateWidget(
              icon: Icons.auto_stories_outlined,
              iconColor: Colors.red,
              title: 'Could not load stories',
              subtitle: _error!,
              actionLabel: 'Retry',
              onAction: _loadStories,
            ),
          ],
        ),
      );
    }

    if (_stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: ListView(
          children: const [
            EmptyStateWidget(
              icon: Icons.auto_stories_outlined,
              title: 'No stories right now',
              subtitle: 'Fresh updates from this professional will appear here when they share new stories.',
            ),
          ],
        ),
      );
    }

    final story = _stories[_currentIndex];
    final ctaLabel = story.ctaLabel ?? (story.ctaUrl != null ? 'Open Link' : 'View Profile');

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final width = MediaQuery.sizeOf(context).width;
          if (details.localPosition.dx < width / 2) {
            _goPrevious();
          } else {
            _goNext();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _StoryMedia(story: story, controller: _videoController),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Colors.transparent, Color(0xD9000000)],
                  stops: [0, 0.35, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(_stories.length, (index) {
                        final value = index < _currentIndex ? 1.0 : index == _currentIndex ? _progressController.value : 0.0;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 4,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: cs.primaryContainer,
                          backgroundImage: (story.professionalAvatar ?? '').isNotEmpty ? CachedNetworkImageProvider(story.professionalAvatar!) : null,
                          child: (story.professionalAvatar ?? '').isEmpty
                              ? Text(story.professionalName.isEmpty ? '?' : story.professionalName[0].toUpperCase())
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(story.professionalName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                              Text(
                                'Viewed ${story.viewCount} times',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if ((story.textOverlay ?? '').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(110),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          story.textOverlay!,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.35),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (ctaLabel.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _handleCta(story),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(ctaLabel),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryMedia extends StatelessWidget {
  final Story story;
  final VideoPlayerController? controller;

  const _StoryMedia({required this.story, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (story.mediaType == 'video' && controller != null && controller!.value.isInitialized) {
      final size = controller!.value.size;
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(controller!),
        ),
      );
    }

    if (story.mediaUrl.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        alignment: Alignment.center,
        child: const Icon(Icons.auto_stories_outlined, size: 88, color: Colors.white70),
      );
    }

    return CachedNetworkImage(
      imageUrl: story.mediaUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, size: 72, color: Colors.white70),
      ),
    );
  }
}

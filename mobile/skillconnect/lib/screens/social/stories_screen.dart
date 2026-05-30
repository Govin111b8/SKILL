import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';

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
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..addListener(() {
        if (mounted) setState(() {});
      })
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
    return data.whereType<Map>().map((item) => Story.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<void> _activateStory(int index) async {
    if (index < 0 || index >= _stories.length) return;
    _isPaused = false;
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

  void _pauseStory() {
    if (_isPaused) return;
    _isPaused = true;
    _progressController.stop();
    _videoController?.pause();
    if (mounted) setState(() {});
  }

  void _resumeStory() {
    if (!_isPaused) return;
    _isPaused = false;
    if (_videoController != null && _videoController!.value.isInitialized) {
      unawaited(_videoController!.play());
    }
    _progressController.forward();
    if (mounted) setState(() {});
  }

  Future<void> _handleTapUp(TapUpDetails details) async {
    HapticFeedback.mediumImpact();
    final width = MediaQuery.sizeOf(context).width;
    if (details.localPosition.dx < width / 2) {
      await _goPrevious();
    } else {
      await _goNext();
    }
  }

  Future<void> _handleVerticalDragEnd(DragEndDetails details) async {
    if ((_stories.isEmpty) || (details.primaryVelocity ?? 0) >= -200) return;
    HapticFeedback.mediumImpact();
    await _handleCta(_stories[_currentIndex]);
  }

  String _timeAgo(DateTime value) {
    final now = DateTime.now();
    final difference = now.difference(value);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    final weeks = (difference.inDays / 7).floor();
    if (weeks < 5) return '${weeks}w ago';
    final months = (difference.inDays / 30).floor();
    return '${months}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: PremiumBackground(
          dark: true,
          child: const Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: PremiumBackground(
          dark: true,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                PremiumEmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: 'Could not load stories',
                  subtitle: _error!,
                  actionLabel: 'Retry',
                  onAction: _loadStories,
                  gradient: AppColors.warmGradient,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: PremiumBackground(
          dark: true,
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: PremiumEmptyState(
                icon: Icons.auto_stories_outlined,
                title: 'No stories right now',
                subtitle: 'Fresh updates from this professional will appear here when they share new stories.',
              ),
            ),
          ),
        ),
      );
    }

    final story = _stories[_currentIndex];
    final ctaLabel = story.ctaLabel ?? (story.ctaUrl != null ? 'Open Link' : 'View Profile');

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: PremiumBackground(
        dark: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _handleTapUp,
          onLongPressStart: (_) => _pauseStory(),
          onLongPressEnd: (_) => _resumeStory(),
          onVerticalDragEnd: _handleVerticalDragEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _StoryMedia(story: story, controller: _videoController),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(150),
                      Colors.black.withAlpha(30),
                      Colors.black.withAlpha(180),
                    ],
                    stops: const [0, 0.35, 1],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(_stories.length, (index) {
                          final value = index < _currentIndex ? 1.0 : index == _currentIndex ? _progressController.value : 0.0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                child: Stack(
                                  children: [
                                    Container(height: 4, color: Colors.white.withAlpha(40)),
                                    FractionallySizedBox(
                                      widthFactor: value,
                                      child: Container(
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(colors: AppColors.heroGradient),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: PremiumGlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              gradient: [
                                Colors.white.withAlpha(28),
                                Colors.white.withAlpha(12),
                              ],
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.visibility_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    '${story.viewCount}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                  if (_isPaused) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    const Icon(Icons.pause_circle_filled_rounded, color: Colors.white70, size: 14),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.pop();
                            },
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(18),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withAlpha(38)),
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if ((story.textOverlay ?? '').isNotEmpty)
                        Center(
                          child: PremiumGlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                            gradient: [
                              Colors.black.withAlpha(110),
                              Colors.black.withAlpha(70),
                            ],
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            child: Text(
                              story.textOverlay!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.35,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: PremiumGlassCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              gradient: [
                                Colors.black.withAlpha(110),
                                Colors.black.withAlpha(70),
                              ],
                              borderRadius: BorderRadius.circular(AppRadius.xxl),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(colors: AppColors.heroGradient),
                                      border: Border.all(color: Colors.white.withAlpha(70), width: 2),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: CircleAvatar(
                                        backgroundColor: Colors.black,
                                        backgroundImage: (story.professionalAvatar ?? '').isNotEmpty
                                            ? CachedNetworkImageProvider(story.professionalAvatar!)
                                            : null,
                                        child: (story.professionalAvatar ?? '').isEmpty
                                            ? Text(
                                                story.professionalName.isEmpty ? '?' : story.professionalName[0].toUpperCase(),
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          story.professionalName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          _timeAgo(story.createdAt),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (ctaLabel.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: PremiumGradientButton(
                            label: ctaLabel,
                            icon: Icons.arrow_upward_rounded,
                            colors: AppColors.primaryGradient,
                            onPressed: () => _handleCta(story),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Swipe up to open action',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

    if (story.mediaType == 'video') {
      return Container(
        color: const Color(0xFF050816),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (story.mediaUrl.isEmpty) {
      return Container(
        color: const Color(0xFF101828),
        alignment: Alignment.center,
        child: const Icon(Icons.auto_stories_outlined, size: 88, color: Colors.white70),
      );
    }

    return CachedNetworkImage(
      imageUrl: story.mediaUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: const Color(0xFF101828),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFF101828),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, size: 72, color: Colors.white70),
      ),
    );
  }
}

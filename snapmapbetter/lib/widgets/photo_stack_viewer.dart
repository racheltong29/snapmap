import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/photo.dart';
import '../services/photo_service.dart';
import '../theme/app_theme.dart';
import '../ui/ui.dart';

class PhotoStackViewer extends StatefulWidget {
  final List<Photo> photos;

  const PhotoStackViewer({super.key, required this.photos});

  @override
  State<PhotoStackViewer> createState() => _PhotoStackViewerState();
}

class _PhotoStackViewerState extends State<PhotoStackViewer> {
  final PageController _pageController = PageController();
  final PhotoService _photoService = PhotoService();

  int _currentIndex = 0;
  final Set<String> _likedPhotos = {};

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: Container(
            color: AppTheme.bg,
            child: Stack(
              children: [
                // Full-bleed photos
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemCount: total,
                  itemBuilder: (context, index) {
                    final photo = widget.photos[index];
                    return _buildStoryPhoto(photo);
                  },
                ),

                // Top scrim
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: GradientScrim(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    height: 170,
                  ),
                ),

                // Bottom scrim
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GradientScrim(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    height: 220,
                  ),
                ),

                // Story progress bars
                Positioned(
                  left: 12,
                  right: 12,
                  top: 10,
                  child: _StoryProgress(
                    total: total,
                    current: _currentIndex,
                  ).animate().fadeIn(duration: 180.ms),
                ),

                // Top header (glass)
                Positioned(
                  left: 12,
                  right: 12,
                  top: 34,
                  child: Row(
                    children: [
                      // a tiny “story ring” avatar placeholder
                      StoryRing(
                        size: 40,
                        child: Container(
                          color: AppTheme.surface,
                          child: const Icon(Icons.public, size: 18, color: AppTheme.text),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                total == 1 ? 'Story' : 'Story stack',
                                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                '${_currentIndex + 1}/$total',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      GlassCard(
                        padding: const EdgeInsets.all(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.12, end: 0),
                ),

                // Bottom actions (like pill + count)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 18,
                  child: _buildBottomBar(widget.photos[_currentIndex])
                      .animate()
                      .fadeIn(duration: 180.ms)
                      .slideY(begin: 0.12, end: 0),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoryPhoto(Photo photo) {
    return Stack(
      children: [
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: photo.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppTheme.surface,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppTheme.surface,
              child: const Center(
                child: Icon(Icons.broken_image_rounded, size: 42, color: AppTheme.muted),
              ),
            ),
          ),
        ),

        // subtle vignette (makes text readable)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Photo photo) {
    final liked = _likedPhotos.contains(photo.id);
    final displayLikes = photo.likes + (liked ? 1 : 0);

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.favorite_rounded,
                    size: 18, color: liked ? Colors.redAccent : AppTheme.muted),
                const SizedBox(width: 10),
                Text(
                  '$displayLikes likes',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        PillButton(
          bg: liked ? const Color(0xFFFF4D6D) : AppTheme.accent,
          onTap: () async {
            final wasLiked = _likedPhotos.contains(photo.id);

            setState(() {
              if (wasLiked) {
                _likedPhotos.remove(photo.id);
              } else {
                _likedPhotos.add(photo.id);
              }
            });

            // update Supabase (simple toggle)
            final newLikes = photo.likes + (wasLiked ? -1 : 1);
            await _photoService.likePhoto(photo.id, newLikes);
          },
          child: Row(
            children: [
              Icon(liked ? Icons.favorite : Icons.favorite_border, size: 18),
              const SizedBox(width: 8),
              Text(liked ? 'Liked' : 'Like'),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoryProgress extends StatelessWidget {
  final int total;
  final int current;

  const _StoryProgress({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 3.2,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withOpacity(0.28),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

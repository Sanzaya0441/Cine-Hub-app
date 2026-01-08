import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../data/models/watch_history.dart';
import '../screens/tv_detail_screen.dart';
import '../screens/video_player_screen.dart';

/// Card widget for Continue Watching items
class ContinueWatchingCard extends StatelessWidget {
  final WatchHistory watchHistory;

  const ContinueWatchingCard({
    Key? key,
    required this.watchHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (watchHistory.contentType == 'movie') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                title: watchHistory.title,
                embedUrl: ApiConstants.movieEmbedUrl(watchHistory.contentId),
                contentId: watchHistory.contentId,
                contentType: watchHistory.contentType,
                posterPath: watchHistory.posterPath,
                backdropPath: watchHistory.backdropPath,
              ),
            ),
          );
        } else {
          // For TV shows, navigate to detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TvDetailScreen(tvId: watchHistory.contentId),
            ),
          );
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.cardBackground,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster/Thumbnail with progress bar
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: watchHistory.posterPath != null
                      ? CachedNetworkImage(
                          imageUrl: ApiConstants.getImageUrl(watchHistory.posterPath),
                          width: 280,
                          height: 160,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 280,
                            height: 160,
                            color: AppTheme.cardBackground,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 280,
                            height: 160,
                            color: AppTheme.cardBackground,
                            child: const Icon(
                              Icons.movie,
                              color: AppTheme.textSecondary,
                              size: 48,
                            ),
                          ),
                        )
                      : Container(
                          width: 280,
                          height: 160,
                          color: AppTheme.cardBackground,
                          child: const Icon(
                            Icons.movie,
                            color: AppTheme.textSecondary,
                            size: 48,
                          ),
                        ),
                ),
                // Progress bar overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: watchHistory.progressPercentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Title and info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    watchHistory.displayTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${watchHistory.formattedPosition} remaining',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

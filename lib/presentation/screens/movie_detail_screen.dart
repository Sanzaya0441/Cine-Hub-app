import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../data/models/movie.dart';
import '../providers/content_provider.dart';
import '../providers/watch_history_provider.dart';
import 'video_player_screen.dart';

class MovieDetailScreen extends ConsumerWidget {
  final int movieId;

  const MovieDetailScreen({Key? key, required this.movieId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieDetailsAsync = ref.watch(movieDetailsProvider(movieId));

    return Scaffold(
      body: movieDetailsAsync.when(
        data: (movie) {
          return CustomScrollView(
            slivers: [
              // App Bar with Backdrop
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Backdrop Image
                      if (movie.backdropPath != null)
                        CachedNetworkImage(
                          imageUrl: ApiConstants.getImageUrl(
                            movie.backdropPath,
                            original: true,
                          ),
                          fit: BoxFit.cover,
                        )
                      else
                        Container(color: AppTheme.cardBackground),
                      
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppTheme.primaryBackground.withOpacity(0.8),
                              AppTheme.primaryBackground,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        movie.title,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      
                      // Meta Info
                      Row(
                        children: [
                          // Rating
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            movie.rating,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(width: 16),
                          
                          // Year
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.textSecondary),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              movie.year,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Play/Resume Button
                      _buildPlayButton(context, ref, movie),
                      const SizedBox(height: 24),
                      
                      // Overview Section
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.overview ?? 'No overview available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.accentColor,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load movie details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, WidgetRef ref, Movie movie) {
    final watchHistoryAsync = ref.watch(
      watchHistoryProvider((
        contentId: movie.id,
        contentType: 'movie',
        seasonNumber: null,
        episodeNumber: null,
      )),
    );

    return watchHistoryAsync.when(
      data: (watchHistory) {
        final hasHistory = watchHistory != null && !watchHistory.isCompleted;
        
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              final embedUrl = ApiConstants.movieEmbedUrl(movieId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(
                    title: movie.title,
                    embedUrl: embedUrl,
                    contentId: movie.id,
                    contentType: 'movie',
                    posterPath: movie.posterPath,
                    backdropPath: movie.backdropPath,
                  ),
                ),
              );
            },
            icon: Icon(
              hasHistory ? Icons.play_circle : Icons.play_arrow,
              size: 28,
            ),
            label: Text(
              hasHistory ? 'Continue Watching' : 'Play Movie',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        );
      },
      loading: () => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {
            final embedUrl = ApiConstants.movieEmbedUrl(movieId);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  title: movie.title,
                  embedUrl: embedUrl,
                  contentId: movie.id,
                  contentType: 'movie',
                  posterPath: movie.posterPath,
                  backdropPath: movie.backdropPath,
                ),
              ),
            );
          },
          icon: const Icon(Icons.play_arrow, size: 28),
          label: const Text(
            'Play Movie',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
      error: (_, __) => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {
            final embedUrl = ApiConstants.movieEmbedUrl(movieId);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  title: movie.title,
                  embedUrl: embedUrl,
                  contentId: movie.id,
                  contentType: 'movie',
                  posterPath: movie.posterPath,
                  backdropPath: movie.backdropPath,
                ),
              ),
            );
          },
          icon: const Icon(Icons.play_arrow, size: 28),
          label: const Text(
            'Play Movie',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../providers/content_provider.dart';
import '../providers/watch_history_provider.dart';
import '../widgets/content_card.dart';
import '../widgets/continue_watching_card.dart';
import 'movie_detail_screen.dart';
import 'tv_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
Widget build(BuildContext context, WidgetRef ref) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Cine Hub'),
      actions: [
        // DEBUG TEST BUTTON - RED BUG ICON
        IconButton(
          icon: const Icon(Icons.bug_report, color: Colors.red),
          onPressed: () {
            Navigator.pushNamed(context, '/test');
          },
        ),
        // Original search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.pushNamed(context, '/search');
          },
        ),
      ],
    ),
    body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Continue Watching Section
            _buildContinueWatchingSection(context, ref),
            
            const SizedBox(height: 16),
            
            // Trending Movies Section
            const SectionHeader(title: 'Trending Movies'),
            _buildMoviesSection(
              ref.watch(trendingMoviesProvider),
              context,
            ),
            
            const SizedBox(height: 16),
            
            // Latest Movies Section
            const SectionHeader(title: 'Latest Movies'),
            _buildMoviesSection(
              ref.watch(latestMoviesProvider),
              context,
            ),
            
            const SizedBox(height: 16),
            
            // Popular TV Series Section
            const SectionHeader(title: 'Popular TV Series'),
            _buildTvSeriesSection(
              ref.watch(popularTvSeriesProvider),
              context,
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviesSection(AsyncValue moviesAsync, BuildContext context) {
    return SizedBox(
      height: 280,
      child: moviesAsync.when(
        data: (movies) {
          if (movies.isEmpty) {
            return const Center(
              child: Text(
                'No movies available',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: ContentCard(
                  posterPath: movie.posterPath,
                  title: movie.title,
                  rating: movie.rating,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(movieId: movie.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              child: const ContentCardSkeleton(),
            );
          },
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
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load content',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTvSeriesSection(AsyncValue tvSeriesAsync, BuildContext context) {
    return SizedBox(
      height: 280,
      child: tvSeriesAsync.when(
        data: (tvShows) {
          if (tvShows.isEmpty) {
            return const Center(
              child: Text(
                'No TV shows available',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tvShows.length,
            itemBuilder: (context, index) {
              final tvShow = tvShows[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: ContentCard(
                  posterPath: tvShow.posterPath,
                  title: tvShow.name,
                  rating: tvShow.rating,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TvDetailScreen(tvId: tvShow.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              child: const ContentCardSkeleton(),
            );
          },
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load TV shows',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueWatchingSection(BuildContext context, WidgetRef ref) {
    final continueWatchingAsync = ref.watch(continueWatchingProvider);

    return continueWatchingAsync.when(
      data: (watchHistoryList) {
        if (watchHistoryList.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filter out completed items
        final activeHistory = watchHistoryList
            .where((h) => !h.isCompleted)
            .toList();

        if (activeHistory.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Continue Watching'),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: activeHistory.length,
                itemBuilder: (context, index) {
                  return ContinueWatchingCard(
                    watchHistory: activeHistory[index],
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
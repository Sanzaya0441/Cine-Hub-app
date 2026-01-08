import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../data/models/movie.dart';
import '../providers/content_provider.dart';
import '../providers/watch_history_provider.dart';
import 'video_player_screen.dart';

class TvDetailScreen extends ConsumerStatefulWidget {
  final int tvId;

  const TvDetailScreen({Key? key, required this.tvId}) : super(key: key);

  @override
  ConsumerState<TvDetailScreen> createState() => _TvDetailScreenState();
}

class _TvDetailScreenState extends ConsumerState<TvDetailScreen> {
  int selectedSeasonNumber = 1;

  @override
  Widget build(BuildContext context) {
    final tvDetailsAsync = ref.watch(tvShowDetailsProvider(widget.tvId));

    return Scaffold(
      body: tvDetailsAsync.when(
        data: (tvData) {
          final tvShow = TvShow.fromJson(tvData);
          final seasons = (tvData['seasons'] as List?)
              ?.map((s) => Season.fromJson(s))
              .where((s) => s.seasonNumber > 0)
              .toList() ?? [];

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
                      if (tvShow.backdropPath != null)
                        CachedNetworkImage(
                          imageUrl: ApiConstants.getImageUrl(
                            tvShow.backdropPath,
                            original: true,
                          ),
                          fit: BoxFit.cover,
                        )
                      else
                        Container(color: AppTheme.cardBackground),
                      
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
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        tvShow.name,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      
                      // Meta Info
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            tvShow.rating,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(width: 16),
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
                              tvShow.year,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Overview
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tvShow.overview ?? 'No overview available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      
                      // Seasons Selector
                      if (seasons.isNotEmpty) ...[
                        Text(
                          'Seasons',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: seasons.length,
                            itemBuilder: (context, index) {
                              final season = seasons[index];
                              final isSelected = season.seasonNumber == selectedSeasonNumber;
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('Season ${season.seasonNumber}'),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedSeasonNumber = season.seasonNumber;
                                      });
                                    }
                                  },
                                  selectedColor: AppTheme.accentColor,
                                  backgroundColor: AppTheme.cardBackground,
                                  labelStyle: TextStyle(
                                    color: isSelected 
                                        ? Colors.white 
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Episodes List
                        _buildEpisodesList(widget.tvId, selectedSeasonNumber, tvShow),
                      ],
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
                  'Failed to load TV show details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodesList(int tvId, int season, TvShow tvShow) {
    final episodesAsync = ref.watch(
      seasonEpisodesProvider((tvId: tvId, season: season)),
    );

    return episodesAsync.when(
      data: (episodes) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: episodes.length,
          itemBuilder: (context, index) {
            final episode = episodes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: episode.stillPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: ApiConstants.getImageUrl(episode.stillPath),
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.tv, color: AppTheme.textSecondary),
                      ),
                title: Text(
                  'Episode ${episode.episodeNumber}: ${episode.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: episode.overview != null && episode.overview!.isNotEmpty
                    ? Text(
                        episode.overview!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : null,
                trailing: const Icon(Icons.play_circle_outline, color: AppTheme.accentColor),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        title: '${tvShow.name} - S${season}E${episode.episodeNumber}',
                        embedUrl: ApiConstants.tvEmbedUrl(
                          tvId,
                          season,
                          episode.episodeNumber,
                        ),
                        contentId: tvId,
                        contentType: 'tv',
                        posterPath: tvShow.posterPath,
                        backdropPath: tvShow.backdropPath,
                        seasonNumber: season,
                        episodeNumber: episode.episodeNumber,
                        episodeTitle: episode.name,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Failed to load episodes',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
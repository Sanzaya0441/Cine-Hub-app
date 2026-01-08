import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/watch_history_service.dart';
import '../../data/models/watch_history.dart';

/// Watch History Service Provider
final watchHistoryServiceProvider = Provider<WatchHistoryService>((ref) {
  return WatchHistoryService();
});

/// Continue Watching Provider
final continueWatchingProvider = FutureProvider.autoDispose<List<WatchHistory>>((ref) async {
  final service = ref.read(watchHistoryServiceProvider);
  return await service.getContinueWatching();
});

/// Watch History Provider (for specific content)
final watchHistoryProvider = FutureProvider.family<WatchHistory?, ({
  int contentId,
  String contentType,
  int? seasonNumber,
  int? episodeNumber,
})>((ref, params) async {
  final service = ref.read(watchHistoryServiceProvider);
  return await service.getWatchHistory(
    contentId: params.contentId,
    contentType: params.contentType,
    seasonNumber: params.seasonNumber,
    episodeNumber: params.episodeNumber,
  );
});

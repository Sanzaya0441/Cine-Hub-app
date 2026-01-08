/// Watch History Model
/// Tracks user's watch progress for movies and TV shows
class WatchHistory {
  final int id;
  final int contentId;
  final String contentType; // 'movie' or 'tv'
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final int watchPosition; // Position in seconds
  final int? totalDuration; // Total duration in seconds (null if unknown)
  final DateTime lastWatched;
  final int? seasonNumber; // For TV shows
  final int? episodeNumber; // For TV shows
  final String? episodeTitle; // For TV shows

  WatchHistory({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.watchPosition,
    this.totalDuration,
    required this.lastWatched,
    this.seasonNumber,
    this.episodeNumber,
    this.episodeTitle,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentId': contentId,
      'contentType': contentType,
      'title': title,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'watchPosition': watchPosition,
      'totalDuration': totalDuration ?? 0,
      'lastWatched': lastWatched.toIso8601String(),
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'episodeTitle': episodeTitle,
    };
  }

  factory WatchHistory.fromJson(Map<String, dynamic> json) {
    return WatchHistory(
      id: json['id'] as int,
      contentId: json['contentId'] as int,
      contentType: json['contentType'] as String,
      title: json['title'] as String,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      watchPosition: json['watchPosition'] as int,
      totalDuration: json['totalDuration'] as int?,
      lastWatched: DateTime.parse(json['lastWatched'] as String),
      seasonNumber: json['seasonNumber'] as int?,
      episodeNumber: json['episodeNumber'] as int?,
      episodeTitle: json['episodeTitle'] as String?,
    );
  }

  /// Get watch progress percentage (0-100)
  double get progressPercentage {
    if (totalDuration == null || totalDuration! == 0) return 0.0;
    return (watchPosition / totalDuration! * 100).clamp(0.0, 100.0);
  }

  /// Check if content is completed (>90% watched)
  bool get isCompleted => progressPercentage >= 90.0;

  /// Get formatted watch position (e.g., "15:30")
  String get formattedPosition {
    final hours = watchPosition ~/ 3600;
    final minutes = (watchPosition % 3600) ~/ 60;
    final seconds = watchPosition % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get display title (includes episode info for TV shows)
  String get displayTitle {
    if (contentType == 'tv' && episodeTitle != null) {
      return '$title - S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}: $episodeTitle';
    }
    return title;
  }
}

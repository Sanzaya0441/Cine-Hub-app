import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/watch_history.dart';

/// Service for managing watch history in local database
class WatchHistoryService {
  static final WatchHistoryService _instance = WatchHistoryService._internal();
  factory WatchHistoryService() => _instance;
  WatchHistoryService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFile = path.join(dbPath, 'watch_history.db');

    return await openDatabase(
      dbFile,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE watch_history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            contentId INTEGER NOT NULL,
            contentType TEXT NOT NULL,
            title TEXT NOT NULL,
            posterPath TEXT,
            backdropPath TEXT,
            watchPosition INTEGER NOT NULL DEFAULT 0,
            totalDuration INTEGER DEFAULT 0,
            lastWatched TEXT NOT NULL,
            seasonNumber INTEGER,
            episodeNumber INTEGER,
            episodeTitle TEXT,
            UNIQUE(contentId, contentType, seasonNumber, episodeNumber)
          )
        ''');
        
        // Create index for faster queries
        await db.execute('''
          CREATE INDEX idx_content ON watch_history(contentId, contentType)
        ''');
        await db.execute('''
          CREATE INDEX idx_last_watched ON watch_history(lastWatched DESC)
        ''');
      },
    );
  }

  /// Save or update watch history
  Future<void> saveWatchHistory(WatchHistory history) async {
    final db = await database;
    
    await db.insert(
      'watch_history',
      history.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update watch position for existing history
  Future<void> updateWatchPosition({
    required int contentId,
    required String contentType,
    required int watchPosition,
    int? totalDuration,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    final db = await database;
    
    final where = 'contentId = ? AND contentType = ?';
    final whereArgs = [contentId, contentType];
    
    if (seasonNumber != null && episodeNumber != null) {
      whereArgs.addAll([seasonNumber, episodeNumber]);
      await db.update(
        'watch_history',
        {
          'watchPosition': watchPosition,
          if (totalDuration != null) 'totalDuration': totalDuration,
          'lastWatched': DateTime.now().toIso8601String(),
        },
        where: '$where AND seasonNumber = ? AND episodeNumber = ?',
        whereArgs: whereArgs,
      );
    } else {
      await db.update(
        'watch_history',
        {
          'watchPosition': watchPosition,
          if (totalDuration != null) 'totalDuration': totalDuration,
          'lastWatched': DateTime.now().toIso8601String(),
        },
        where: where,
        whereArgs: whereArgs,
      );
    }
  }

  /// Get watch history for a specific content
  Future<WatchHistory?> getWatchHistory({
    required int contentId,
    required String contentType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    final db = await database;
    
    String where = 'contentId = ? AND contentType = ?';
    List<dynamic> whereArgs = [contentId, contentType];
    
    if (seasonNumber != null && episodeNumber != null) {
      where += ' AND seasonNumber = ? AND episodeNumber = ?';
      whereArgs.addAll([seasonNumber, episodeNumber]);
    }
    
    final results = await db.query(
      'watch_history',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    
    return WatchHistory.fromJson(results.first);
  }

  /// Get all continue watching items (sorted by last watched)
  Future<List<WatchHistory>> getContinueWatching({int limit = 20}) async {
    final db = await database;
    
    final results = await db.query(
      'watch_history',
      orderBy: 'lastWatched DESC',
      limit: limit,
    );
    
    return results.map((json) => WatchHistory.fromJson(json)).toList();
  }

  /// Delete watch history for a content
  Future<void> deleteWatchHistory({
    required int contentId,
    required String contentType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    final db = await database;
    
    String where = 'contentId = ? AND contentType = ?';
    List<dynamic> whereArgs = [contentId, contentType];
    
    if (seasonNumber != null && episodeNumber != null) {
      where += ' AND seasonNumber = ? AND episodeNumber = ?';
      whereArgs.addAll([seasonNumber, episodeNumber]);
    }
    
    await db.delete('watch_history', where: where, whereArgs: whereArgs);
  }

  /// Clear all watch history
  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('watch_history');
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

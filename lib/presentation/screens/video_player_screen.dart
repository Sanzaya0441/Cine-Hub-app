import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_theme.dart';
import '../../data/services/watch_history_service.dart';
import '../../data/models/watch_history.dart';

/// Video Player Screen with Ad Blocking
class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String embedUrl;
  final int? contentId;
  final String? contentType; // 'movie' or 'tv'
  final String? posterPath;
  final String? backdropPath;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? episodeTitle;

  const VideoPlayerScreen({
    Key? key,
    required this.title,
    required this.embedUrl,
    this.contentId,
    this.contentType,
    this.posterPath,
    this.backdropPath,
    this.seasonNumber,
    this.episodeNumber,
    this.episodeTitle,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _navigationCount = 0;
  int _resourceErrorCount = 0;
  DateTime? _pageStartTime;
  DateTime? _pageFinishTime;
  bool _isPageLoaded = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _watchHistoryTimer;
  final WatchHistoryService _watchHistoryService = WatchHistoryService();
  int _lastSavedPosition = 0;
  
  // Ad domains to block
  final List<String> blockedDomains = [
    '1xbet',
    '1x-bet',
    'betting',
    'casino',
    'ads',
    'advertisement',
    'popup',
    'redirect',
    'promo',
    'download',
  ];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  
  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    
    // Start timer to hide controls after delay - simplified, always hides
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
        debugPrint('🎬 Hiding controls via timer');
      }
    });
  }
  
  void _toggleControls() {
    if (!mounted) return;
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  bool _shouldBlockUrl(String url) {
    final lowercaseUrl = url.toLowerCase();
    
    // Block if URL contains any blocked domain
    for (final domain in blockedDomains) {
      if (lowercaseUrl.contains(domain)) {
        debugPrint('🚫 Blocked: $url');
        return true;
      }
    }
    
    // Only allow vidking.net and related video domains
    if (!lowercaseUrl.contains('vidking.net') && 
        !lowercaseUrl.contains('vidking') &&
        !lowercaseUrl.contains('player') &&
        !lowercaseUrl.contains('embed')) {
      debugPrint('🚫 Blocked external: $url');
      return true;
    }
    
    return false;
  }

  // #region agent log
  void _logDebug(String location, String message, Map<String, dynamic> data) {
    final logEntry = {
      'id': 'log_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      'data': data,
      'sessionId': 'debug-session',
      'runId': 'run1',
    };
    try {
      final file = File(r'd:\cine_hub\.cursor\debug.log');
      file.writeAsStringSync('${jsonEncode(logEntry)}\n', mode: FileMode.append);
    } catch (e) {
      // Ignore logging errors
    }
  }
  // #endregion

  void _initializePlayer() {
    // #region agent log
    _logDebug('video_player_screen.dart:76', 'Initializing player', {
      'embedUrl': widget.embedUrl,
      'hypothesisId': 'A',
    });
    // #endregion
    debugPrint('🎬 Initializing player: ${widget.embedUrl}');
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false) // Disable zoom for better video performance
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // #region agent log
            _pageStartTime = DateTime.now();
            _logDebug('video_player_screen.dart:84', 'Page started', {
              'url': url,
              'navigationCount': _navigationCount,
              'hypothesisId': 'B',
            });
            // #endregion
            debugPrint('📄 Page started: $url');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            // #region agent log
            _pageFinishTime = DateTime.now();
            final loadTime = _pageStartTime != null 
                ? _pageFinishTime!.difference(_pageStartTime!).inMilliseconds 
                : 0;
            
            // Start tracking watch history after page loads
            Future.delayed(const Duration(seconds: 2), () {
              _startWatchHistoryTracking();
            });
            _logDebug('video_player_screen.dart:91', 'Page finished', {
              'url': url,
              'loadTimeMs': loadTime,
              'navigationCount': _navigationCount,
              'hypothesisId': 'C',
            });
            // #endregion
            debugPrint('✅ Page finished: $url');
            
            // Optimize: Mark page as loaded and delay setState to reduce rebuilds
            _isPageLoaded = true;
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted && _isPageLoaded) {
                setState(() {
                  _isLoading = false;
                });
                debugPrint('🎬 Page loaded, starting hide timer');
                
                // Force hide controls after fixed delay - guaranteed to hide
                Future.delayed(const Duration(seconds: 4), () {
                  if (mounted) {
                    setState(() {
                      _showControls = false;
                    });
                    debugPrint('✅ Title bar hidden after 4 seconds');
                  }
                });
              }
            });
            
            // Optimize: Inject minimal JavaScript after video has started loading
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (!mounted) return;
              _controller.runJavaScript('''
                (function() {
                  // Block popup ads (minimal overhead)
                  window.open = function() { return null; };
                  window.alert = function() { };
                  
                  // Remove overlay ads only once, after video is playing
                  setTimeout(function() {
                    try {
                      var selectors = ['[class*="ad-"]', '[id*="ad-"]', '[class*="popup"]', '[id*="popup"]'];
                      selectors.forEach(function(sel) {
                        var ads = document.querySelectorAll(sel);
                        ads.forEach(function(ad) {
                          if (ad && ad.parentNode && !ad.querySelector('video')) {
                            ad.remove();
                          }
                        });
                      });
                    } catch(e) {}
                  }, 5000);
                })();
              ''');
            });
            
            // Optimize: Inject video performance hints and optimizations
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (!mounted) return;
              _controller.runJavaScript('''
                (function() {
                  // Find video elements and optimize them for smooth playback
                  var videos = document.querySelectorAll('video');
                  videos.forEach(function(video) {
                    if (video) {
                      // Enable hardware acceleration
                      video.setAttribute('playsinline', 'true');
                      video.setAttribute('webkit-playsinline', 'true');
                      video.setAttribute('preload', 'auto');
                      video.setAttribute('x5-video-player-type', 'h5');
                      video.setAttribute('x5-video-player-fullscreen', 'true');
                      
                      // Hardware acceleration CSS - more aggressive
                      video.style.transform = 'translateZ(0)';
                      video.style.webkitTransform = 'translateZ(0)';
                      video.style.willChange = 'transform';
                      video.style.backfaceVisibility = 'hidden';
                      video.style.perspective = '1000px';
                      video.style.transformStyle = 'preserve-3d';
                      video.style.isolation = 'isolate';
                      
                      // Optimize playback
                      video.playbackRate = 1.0;
                      video.defaultPlaybackRate = 1.0;
                      
                      // Force hardware acceleration
                      video.style.webkitBackfaceVisibility = 'hidden';
                      video.style.mozBackfaceVisibility = 'hidden';
                      video.style.msBackfaceVisibility = 'hidden';
                      
                      // Listen for play event and force hide controls
                      video.addEventListener('play', function() {
                        if (window.VideoPlayerChannel) {
                          window.VideoPlayerChannel.postMessage('video_playing');
                        }
                        // Also hide controls directly after a delay
                        setTimeout(function() {
                          if (window.VideoPlayerChannel) {
                            window.VideoPlayerChannel.postMessage('hide_controls');
                          }
                        }, 3000);
                      }, { once: true });
                      
                      // Also listen for playing event (when actually playing, not just started)
                      video.addEventListener('playing', function() {
                        if (window.VideoPlayerChannel) {
                          window.VideoPlayerChannel.postMessage('video_playing');
                        }
                      });
                    }
                  });
                  
                  // Optimize page rendering for video - more aggressive
                  document.body.style.overflow = 'hidden';
                  document.body.style.margin = '0';
                  document.body.style.padding = '0';
                  document.body.style.position = 'fixed';
                  document.body.style.width = '100%';
                  document.body.style.height = '100%';
                  
                  // Disable animations that could interfere
                  var style = document.createElement('style');
                  style.textContent = '* { animation-duration: 0s !important; transition-duration: 0s !important; }';
                  document.head.appendChild(style);
                })();
              ''');
            });
          },
          onWebResourceError: (WebResourceError error) {
            // #region agent log
            _resourceErrorCount++;
            _logDebug('video_player_screen.dart:114', 'Web resource error', {
              'errorType': error.errorType.toString(),
              'description': error.description,
              'errorCode': error.errorCode,
              'resourceErrorCount': _resourceErrorCount,
              'hypothesisId': 'D',
            });
            // #endregion
            debugPrint('❌ Error: ${error.description}');
            
            if (error.errorType == WebResourceErrorType.hostLookup ||
                error.errorType == WebResourceErrorType.timeout ||
                error.errorType == WebResourceErrorType.connect) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // #region agent log
            _navigationCount++;
            final shouldBlock = _shouldBlockUrl(request.url);
            _logDebug('video_player_screen.dart:126', 'Navigation request', {
              'url': request.url,
              'navigationCount': _navigationCount,
              'shouldBlock': shouldBlock,
              'isMainFrame': request.isMainFrame,
              'hypothesisId': 'E',
            });
            // #endregion
            debugPrint('🔗 Navigation request: ${request.url}');
            
            // Optimize: Allow ALL video-related resources immediately (critical for smooth playback)
            final urlLower = request.url.toLowerCase();
            if (urlLower.contains('.m3u8') || 
                urlLower.contains('.mp4') || 
                urlLower.contains('.m4v') ||
                urlLower.contains('.m4s') ||
                urlLower.contains('.ts') ||
                urlLower.contains('.webm') ||
                urlLower.contains('.mkv') ||
                urlLower.contains('video') ||
                urlLower.contains('stream') ||
                urlLower.contains('media') ||
                urlLower.contains('cdn') ||
                urlLower.contains('hls') ||
                urlLower.contains('dash')) {
              return NavigationDecision.navigate;
            }
            
            // Block ads and unwanted redirects
            if (shouldBlock) {
              debugPrint('🚫 BLOCKED: ${request.url}');
              return NavigationDecision.prevent;
            }
            
            // Allow navigation to embed and player URLs, CDNs, and video domains
            if (request.url.contains('vidking.net') ||
                request.url.contains('embed') ||
                request.url.contains('player') ||
                request.url.contains('cdn') ||
                request.url.contains('cloudflare') ||
                request.url.contains('cloudfront')) {
              return NavigationDecision.navigate;
            }
            
            // Block everything else
            debugPrint('🚫 External link blocked: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..addJavaScriptChannel(
        'VideoPlayerChannel',
        onMessageReceived: (JavaScriptMessage message) {
          // When video starts playing, hide controls immediately
          if (message.message == 'video_playing' || message.message == 'hide_controls') {
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) {
                setState(() {
                  _showControls = false;
                });
                debugPrint('🎬 Hiding controls from JS: ${message.message}');
              }
            });
          }
        },
      )
      ..loadRequest(
        Uri.parse(widget.embedUrl),
        headers: {
          'Referer': 'https://www.cineby.gd/',
          'Origin': 'https://www.cineby.gd',
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Cache-Control': 'no-cache',
        },
      );
  }

  /// Save watch history periodically
  void _startWatchHistoryTracking() {
    if (widget.contentId == null || widget.contentType == null) {
      return;
    }
    
    _watchHistoryTimer?.cancel();
    
    // Save watch history every 10 seconds
    _watchHistoryTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        // Get video current time from JavaScript
        final timeResult = await _controller.runJavaScriptReturningResult('''
          (function() {
            var video = document.querySelector('video');
            if (video && !video.paused) {
              return Math.floor(video.currentTime);
            }
            return 0;
          })();
        ''');
        
        int currentPosition = 0;
        if (timeResult != null) {
          try {
            currentPosition = int.parse(timeResult.toString().replaceAll(RegExp(r'[^0-9]'), ''));
          } catch (e) {
            debugPrint('Error parsing video time: $e');
          }
        }
        
        // Save if position changed significantly (at least 5 seconds) or if this is first save
        if ((currentPosition - _lastSavedPosition).abs() >= 5 || _lastSavedPosition == 0) {
          _lastSavedPosition = currentPosition;
          
          // Get video duration
          final durationResult = await _controller.runJavaScriptReturningResult('''
            (function() {
              var video = document.querySelector('video');
              if (video) {
                return Math.floor(video.duration || 0);
              }
              return 0;
            })();
          ''');
          
          int totalDuration = 0;
          if (durationResult != null) {
            try {
              totalDuration = int.parse(durationResult.toString().replaceAll(RegExp(r'[^0-9]'), ''));
            } catch (e) {
              // Ignore
            }
          }
          
          // Save watch history (ensure at least 10 seconds to appear in continue watching)
          final savePosition = currentPosition >= 10 ? currentPosition : 10;
          final history = WatchHistory(
            id: 0, // Will be auto-generated
            contentId: widget.contentId!,
            contentType: widget.contentType!,
            title: widget.title,
            posterPath: widget.posterPath,
            backdropPath: widget.backdropPath,
            watchPosition: savePosition,
            totalDuration: totalDuration > 0 ? totalDuration : null,
            lastWatched: DateTime.now(),
            seasonNumber: widget.seasonNumber,
            episodeNumber: widget.episodeNumber,
            episodeTitle: widget.episodeTitle,
          );
          
          await _watchHistoryService.saveWatchHistory(history);
          debugPrint('💾 Saved watch history: ${widget.title} at ${savePosition}s');
        }
      } catch (e) {
        debugPrint('Error saving watch history: $e');
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _watchHistoryTimer?.cancel();
    
    // Save final watch position
    if (widget.contentId != null && widget.contentType != null) {
      // Always save at least something if contentId is provided, even if position is 0
      // This ensures the item appears in continue watching
      final finalPosition = _lastSavedPosition > 0 ? _lastSavedPosition : 10; // Save at least 10 seconds
      
      final history = WatchHistory(
        id: 0,
        contentId: widget.contentId!,
        contentType: widget.contentType!,
        title: widget.title,
        posterPath: widget.posterPath,
        backdropPath: widget.backdropPath,
        watchPosition: finalPosition,
        totalDuration: null,
        lastWatched: DateTime.now(),
        seasonNumber: widget.seasonNumber,
        episodeNumber: widget.episodeNumber,
        episodeTitle: widget.episodeTitle,
      );
      
      _watchHistoryService.saveWatchHistory(history).catchError((e) {
        debugPrint('Error saving final position: $e');
      });
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // #region agent log
    _logDebug('video_player_screen.dart:177', 'Build called', {
      'isLoading': _isLoading,
      'hasError': _hasError,
      'navigationCount': _navigationCount,
      'resourceErrorCount': _resourceErrorCount,
      'isPageLoaded': _isPageLoaded,
      'showControls': _showControls,
      'hypothesisId': 'F',
    });
    // #endregion
    
    // Optimize: Reduce rebuilds - only rebuild when necessary
    return WillPopScope(
      onWillPop: () async {
        // Handle back button - go back in webview history if possible
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              children: [
                // WebView - Optimized for video playback with performance optimizations
                RepaintBoundary(
                  child: IgnorePointer(
                    ignoring: _isLoading,
                    child: WebViewWidget(controller: _controller),
                  ),
                ),
              
              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.accentColor,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Loading player...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Blocking ads...',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Error overlay
              if (_hasError)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            color: AppTheme.accentColor,
                            size: 80,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Failed to Load Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Possible causes:\n'
                            '• No internet connection\n'
                            '• Video source unavailable\n'
                            '• Content region-locked',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _hasError = false;
                                    _isLoading = true;
                                  });
                                  _controller.reload();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Go Back'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white38),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Top bar with close button - Auto-hides during playback
              // Only show if controls are visible, loading, or error
              if (_showControls || _isLoading || _hasError)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_showControls && !_isLoading && !_hasError,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                                tooltip: 'Close Player',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
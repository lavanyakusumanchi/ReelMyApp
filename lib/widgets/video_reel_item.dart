import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../models/reel.dart';
import '../providers/reel_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'comments_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'animated_like_button.dart'; 
import 'animated_save_button.dart';
import '../utils/app_localizations.dart';
import '../providers/settings_provider.dart';
import 'app_store_bottom_sheet.dart';
import '../utils/api_config.dart';

class VideoReelItem extends StatefulWidget {
  final Reel reel;
  final VoidCallback? onVideoFinished;
  final bool isVisible;
  final bool shouldPreload;

  const VideoReelItem({
    super.key,
    required this.reel,
    this.onVideoFinished,
    this.isVisible = false,
    this.shouldPreload = false,
  });

  @override
  State<VideoReelItem> createState() => _VideoReelItemState();
}

class _VideoReelItemState extends State<VideoReelItem>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _initError;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _isRetrying = false;
  bool _isMuted = false;
  bool _videoFinished = false;
  bool _isLiking = false;
  bool _isDescriptionExpanded = false;

  // Save Feedback State
  String? _saveFeedbackMessage;
  bool _showSaveFeedback = false;
  Timer? _feedbackTimer;

  // Heart Animation State
  bool _showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    
    if (widget.reel.isSaved) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) Provider.of<ReelProvider>(context, listen: false).syncReelState(widget.reel);
       });
    }

    if (widget.isVisible || widget.shouldPreload) {
      _initializeVideo();
    }
    
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeInOut));
  }


  @override
  void didUpdateWidget(VideoReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reel.videoUrl != widget.reel.videoUrl) {
      _initializeVideo();
    } else if (!oldWidget.isVisible && !oldWidget.shouldPreload && (widget.isVisible || widget.shouldPreload)) {
      if (!_initialized) _initializeVideo();
    }
    
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        if (_initialized) {
           _controller.play();
        }
      } else {
        if (_initialized) _controller.pause();
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      if (_initialized) {
        await _controller.dispose();
      }

      final settings = Provider.of<SettingsProvider>(context, listen: false);

      print('🎥 [VideoReelItem] Initializing video: ${widget.reel.videoUrl}');
      final fullUrl = ApiConfig.getFullVideoUrl(widget.reel.videoUrl);

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(fullUrl),
      );

      await _controller.initialize();
      _controller.addListener(_onVideoControllerUpdate);
      
      await _controller.setPlaybackSpeed(1.0); 
      _videoFinished = false; 
      _controller.setLooping(!settings.autoScrollEnabled);

      if (widget.isVisible) {
          await _controller.play();
      }

      if (mounted) {
        setState(() {
          _initialized = true;
          _initError = null;
          _isRetrying = false;
        });
      }
    } catch (error) {
       if (mounted) {
        if (_retryCount < _maxRetries) {
          _retryCount++;
          final delayMs = 1000 * _retryCount;
          setState(() => _isRetrying = true);
          await Future.delayed(Duration(milliseconds: delayMs));
          if (mounted) {
            _initializeVideo();
          }
        } else {
          setState(() {
            _initError = error.toString();
            _isRetrying = false;
          });
        }
      }
    }
  }

  void _onVideoControllerUpdate() {
    if (!mounted) return;
    
    if (_initialized && 
        _controller.value.isInitialized && 
        !_controller.value.isPlaying && 
        _controller.value.position >= _controller.value.duration) {
          
      if (!_videoFinished) {
         _videoFinished = true;
         if (widget.onVideoFinished != null) {
            widget.onVideoFinished!();
         }
      }
    } else {
       if (_videoFinished && _controller.value.isPlaying && _controller.value.position < _controller.value.duration) {
          _videoFinished = false;
       }
    }
    setState(() {});
  }

  void _manualRetry() async {
    if (mounted) {
      setState(() {
        _retryCount = 0;
        _initError = null;
        _initialized = false;
        _isRetrying = false;
      });
    }
    _controller.removeListener(_onVideoControllerUpdate);
    await _controller.dispose();
    _initializeVideo();
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.removeListener(_onVideoControllerUpdate);
      _controller.dispose();
    }
    _heartController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_initialized) {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
      if (mounted) setState(() {});
    }
  }

  void _toggleMute() {
    if (_initialized) {
      setState(() {
        _isMuted = !_isMuted;
        _controller.setVolume(_isMuted ? 0 : 1);
      });
    }
  }

  Future<void> _handleDoubleTap() async {
    _triggerHeartAnimation();
    if (_isLiking) return; 
    
    if (!widget.reel.isLiked) {
      _isLiking = true;
      try {
          final storage = const FlutterSecureStorage();
          final token = await storage.read(key: 'token');
          if (mounted && token != null) {
            await context.read<ReelProvider>().toggleLike(widget.reel.id, token);
          }
      } finally {
          _isLiking = false;
      }
    }
  }

  void _triggerHeartAnimation() {
    if (mounted) setState(() => _showHeart = true);
    _heartController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _showHeart = false);
      });
    });
  }

  void _triggerSaveFeedback(bool isSaved) {
    _feedbackTimer?.cancel();
    if (mounted) {
      setState(() {
        _saveFeedbackMessage = isSaved ? 'Reel Saved!' : 'Removed from saved';
        _showSaveFeedback = true;
      });
      
      _feedbackTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSaveFeedback = false);
      });
    }
  }
  
  void _showCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.6,
        child: CommentsSheet(
          reelId: widget.reel.id,
          comments: [],
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
       _controller.setLooping(!Provider.of<SettingsProvider>(context).autoScrollEnabled);
    }

    return ClipRect(
      child: Container(
        color: Colors.black, // Opaque Black Background
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), // Removed top padding entirely
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              children: [
                 // 1. Header (User Info) - Top
                 SafeArea(
                   bottom: false,
                   child: Transform.translate(
                     offset: const Offset(0, -35), // Max UP
                     child: _buildNeoHeader(),
                   ),
                 ),
                 
                 // 2. Video Card - Middle (Expanded)
                 Expanded(
                   child: Center(
                     child: GestureDetector(
                        onTap: _togglePlay,
                        onDoubleTap: _handleDoubleTap,
                        child: Stack(
                          children: [
                            _initialized 
                               ? _buildVideoCard() 
                               : (_buildVideoCardWithThumbnail() ?? _buildVideoLoadingOrError()),
                               
                            // Heart Animation Overlay
                            if (_showHeart) 
                              Positioned.fill(
                                child: Center(
                                  child: ScaleTransition(
                                    scale: _heartScale, 
                                    child: const Icon(Icons.favorite, color: AppColors.neonCyan, size: 120),
                                  ),
                                ),
                              ),
                          ],
                        ),
                     ),
                   ),
                 ),
                 
                 const SizedBox(height: 16),
  
                 // 3. Control Island - Bottom
                 _buildControlIsland(context),
                 
                 const SizedBox(height: 70), // Push Bottom Bar UP
              ],
            ),

            // Custom Save Notification (Bottom Centered - Overlapping Island Area)
            if (_showSaveFeedback)
                Positioned(
                  bottom: 150, // Positioned above the control island (60px) + spacer (70px) + margin
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, (1.0 - value) * 20), // Slide up
                          child: Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black, // Solid black to stand out against UI
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: AppColors.neonYellow, width: 1), // Yellow border for visibility
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.neonYellow.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _saveFeedbackMessage!.contains('Removed') ? Icons.bookmark_remove : Icons.bookmark_added,
                                      color: _saveFeedbackMessage!.contains('Removed') ? Colors.redAccent : AppColors.neonYellow,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _saveFeedbackMessage!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundStage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Persistent Thumbnail (Blurred) - Cinematic Backdrop
        if (widget.reel.thumbnailUrl != null)
           ImageFiltered(
             imageFilter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
             child: Image.network(
               widget.reel.thumbnailUrl!,
               fit: BoxFit.cover,
               alignment: Alignment.center,
             ),
           ),

        // 2. Video Overlay (Blurred) - Fades in when ready
        // We also blur the video background if it's playing
        if (_initialized)
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Transform.scale(
              scale: 1.05, // Reduced scale to minimize bleed risk
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                   width: _controller.value.size.width,
                   height: _controller.value.size.height,
                   child: VideoPlayer(_controller),
                ),
              ),
            ),
          ),
          
        // 3. Heavy Dark Overlay to mask background details
        Container(color: Colors.black.withOpacity(0.7)),
      ],
    );
  }

  Widget? _buildVideoCardWithThumbnail() {
    if (widget.reel.thumbnailUrl == null) return null;
    // Card Layout
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.neonCyan.withOpacity(1.0), width: 1.8), // Switched to Neon Cyan
          boxShadow: [
             // 1. Subtle Elevation (Depth) - Enhanced
             BoxShadow(
               color: Colors.black.withOpacity(0.8), // Darker shadow
               blurRadius: 30, // Softer blur
               offset: const Offset(0, 15),
             ),
             // 2. Neon Glow (Atmosphere) - Enhanced
             BoxShadow(
               color: AppColors.neonCyan.withOpacity(0.55), // Cyan Glow
               blurRadius: 25, // Wider glow
               spreadRadius: 1,
             ),
          ],
          image: DecorationImage(
             image: NetworkImage(widget.reel.thumbnailUrl!),
             fit: BoxFit.cover,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
           color: Colors.black12,
           child: const Center(
             child: SizedBox(
               width: 30, height: 30,
               child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
             ),
           ),
        ),
      ),
    );
  }

  Widget _buildNeoHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: (widget.reel.logoUrl != null && widget.reel.logoUrl!.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(widget.reel.logoUrl!), fit: BoxFit.cover)
                      : null,
                  color: Colors.white24,
                ),
                child: widget.reel.logoUrl == null || widget.reel.logoUrl!.isEmpty 
                    ? const Icon(Icons.person, color: Colors.white, size: 18) 
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.reel.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Paid/Free Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.reel.isPaid ? AppColors.neonYellow.withOpacity(0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.reel.isPaid ? AppColors.neonYellow : Colors.white24,
                    width: 1,
                  ),
                  boxShadow: widget.reel.isPaid ? [
                     BoxShadow(color: AppColors.neonYellow.withOpacity(0.4), blurRadius: 8)
                  ] : null,
                ),
                child: Text(
                  widget.reel.isPaid 
                      ? (widget.reel.price > 0 ? '\$${widget.reel.price.toStringAsFixed(2)}' : 'PAID') 
                      : 'FREE',
                  style: TextStyle(
                    color: widget.reel.isPaid ? AppColors.neonYellow : Colors.white70,
                    fontSize: 12, // Increased font size
                    fontWeight: FontWeight.w900, // Maximized boldness
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              widget.reel.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: _isDescriptionExpanded ? null : 1,
              overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard() {
    if (!_initialized) return const SizedBox();
    
    // Enforce 9/16 Aspect Ratio to match ThumbnailCard and prevent layout jumps ("getting fit")
    // Card Layout requires defined aspect ratio
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: Colors.black, // Solid background
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.neonCyan.withOpacity(1.0), width: 1.8), // Switched to Neon Cyan
          boxShadow: [
             // 1. Subtle Elevation (Depth) - Enhanced
             BoxShadow(
               color: Colors.black.withOpacity(0.8), // Darker shadow
               blurRadius: 30, // Softer blur
               offset: const Offset(0, 15),
             ),
             // 2. Neon Glow (Atmosphere) - Enhanced
             BoxShadow(
               color: AppColors.neonCyan.withOpacity(0.55), // Cyan Glow
               blurRadius: 25, // Wider glow
               spreadRadius: 1,
             ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video scaled to cover the 9/16 card
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
            
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black45, 
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up, 
                    color: Colors.white, 
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLoadingOrError() {
      return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_initError != null) ...[
                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                const Text('Failed', style: TextStyle(color: Colors.white54, fontSize: 12)),
                TextButton(onPressed: _manualRetry, child: const Text('Retry')),
              ] else 
                const CircularProgressIndicator(color: AppColors.neonCyan),
            ],
          ),
      );
  }

  Widget _buildControlIsland(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark grey pill like screenshot
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
                // Left Actions
                Consumer<ReelProvider>(
                  builder: (context, reelProvider, _) {
                    final currentReel = reelProvider.reels.firstWhere(
                       (r) => r.id == widget.reel.id,
                       orElse: () => widget.reel,
                    );
                    return Row(
                      children: [
                        _buildIslandIcon(
                          icon: currentReel.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: currentReel.isLiked ? Colors.red : Colors.white,
                          label: currentReel.likes > 0 ? '${currentReel.likes}' : null,
                          onTap: () async {
                              if (_isLiking) return;
                              _isLiking = true;
                              try {
                                final storage = const FlutterSecureStorage();
                                final token = await storage.read(key: 'token');
                                if (context.mounted && token != null) {
                                  await context.read<ReelProvider>().toggleLike(currentReel.id, token);
                                }
                              } finally {
                                _isLiking = false;
                              }
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildIslandIcon(
                          icon: Icons.comment_outlined,
                          color: Colors.white,
                          label: currentReel.comments > 0 ? '${currentReel.comments}' : null,
                          onTap: () => _showCommentsSheet(context),
                        ),
                        const SizedBox(width: 16),
                        // Save Button
                        _buildIslandIcon(
                          icon: currentReel.isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: currentReel.isSaved ? AppColors.neonCyan : Colors.white,
                          onTap: () async {
                              final wasSaved = currentReel.isSaved; // Capture state before toggle
                              try {
                                final storage = const FlutterSecureStorage();
                                final token = await storage.read(key: 'token');
                                if (context.mounted && token != null) {
                                  final success = await context.read<ReelProvider>().toggleSave(currentReel.id, token);
                                  if (success && context.mounted) {
                                      _triggerSaveFeedback(!wasSaved);
                                  }
                                }
                              } catch (e) {
                                debugPrint("Error saving reel: $e");
                              }
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildIslandIcon(
                          icon: Icons.share_outlined,
                          color: Colors.white,
                          onTap: () {
                             final url = currentReel.appLink ?? currentReel.videoUrl;
                             Share.share('Check out this reel: ${currentReel.title}\n$url');
                          },
                        ),
                      ],
                    );
                  }
                ),

                // Right Action (Install)
                if (widget.reel.appLink != null && widget.reel.appLink!.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                       final url = widget.reel.appLink!;
                       if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                       }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                           colors: [AppColors.neonCyan, AppColors.neonPurple],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                           BoxShadow(color: AppColors.neonCyan.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                        ]
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate('install_app').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
             ],
          ),
        );
  }

  Widget _buildIslandIcon({
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap,
    String? label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 14, 
                fontWeight: FontWeight.w600
              ),
            ),
          ],
        ],
      ),
    );
  }
}

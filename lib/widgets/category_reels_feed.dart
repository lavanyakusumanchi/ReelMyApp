import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reel.dart';
import '../widgets/video_reel_item.dart';
import '../providers/settings_provider.dart';

class CategoryReelsFeed extends StatefulWidget {
  final List<Reel> reels;
  final bool isVisible;
  final Future<void> Function() onRefresh; // NEW Callback

  const CategoryReelsFeed({
    super.key,
    required this.reels,
    required this.isVisible,
    required this.onRefresh,
  });

  @override
  State<CategoryReelsFeed> createState() => _CategoryReelsFeedState();
}

class _CategoryReelsFeedState extends State<CategoryReelsFeed> with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  bool get wantKeepAlive => true; // Keep state alive when swiping away

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for KeepAlive

    // 1. Empty State (Scrollable for Refresh)
    if (widget.reels.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: Colors.cyan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(
              child: Text("No reels found in this category", style: TextStyle(color: Colors.white54)),
            ),
          ),
        ),
      );
    }

    final settings = Provider.of<SettingsProvider>(context);

    // 2. List State
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: Colors.cyan,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (overscroll) {
          overscroll.disallowIndicator(); // Disable Android 12+ Stretch/Blur effect
          return true;
        },
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          clipBehavior: Clip.hardEdge, // Enforce strict clipping to prevent bleed-through
          physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), 
          itemCount: widget.reels.length,
          itemBuilder: (context, index) {
            final reel = widget.reels[index];
            // Video plays ONLY if:
            // 1. This category page is visible (widget.isVisible)
            // 2. This specific reel is the active one in the vertical list (index == _currentIndex)
            final shouldPlay = widget.isVisible && (index == _currentIndex);
            
            // Preload both Next and Previous videos for smoother scrolling in both directions
            final shouldPreload = (index == _currentIndex + 1) || (index == _currentIndex - 1);
  
            return VideoReelItem(
              key: ValueKey(reel.id),
              reel: reel,
              isVisible: shouldPlay,
              shouldPreload: shouldPreload,
              onVideoFinished: () {
                if (settings.autoScrollEnabled && index < widget.reels.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
            );
          },
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

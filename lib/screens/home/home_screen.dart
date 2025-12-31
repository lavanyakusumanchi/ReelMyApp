import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/reel_provider.dart';
import '../../widgets/video_reel_item.dart';
import '../create/create_reel_screen.dart';
import '../../widgets/side_menu.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/category_reels_feed.dart'; // NEW IMPORT
import '../../providers/settings_provider.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/animated_top_button.dart'; 
import '../search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Horizontal Controller for Categories
  final PageController _horizontalPageController = PageController();
  int _currentCategoryIndex = 0;

  final List<Map<String, String>> _categories = [
    {'key': 'cat_all', 'val': 'All'},
    {'key': 'cat_business', 'val': 'Business'},
    {'key': 'cat_entertainment', 'val': 'Entertainment'},
    {'key': 'cat_education', 'val': 'Education'},
    {'key': 'cat_lifestyle', 'val': 'Lifestyle'},
    {'key': 'cat_foodi', 'val': 'Foodi'},
    {'key': 'cat_other', 'val': 'Other'},
  ];

  @override
  void dispose() {
    _horizontalPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Consume Settings
    final settings = Provider.of<SettingsProvider>(context);
    final title = AppLocalizations.of(context).translate('app_title');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      backgroundColor: theme.scaffoldBackgroundColor, // Dynamic
      body: Column(
        children: [
          // 1. Top Bar & Categories Section
          Container(
            padding: EdgeInsets.only(top: 50.h, bottom: 10.h),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top App Bar Area
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Menu + Upload
                      Row(
                        children: [
                          AnimatedTopButton(
                            icon: Icons.menu,
                            isBlue: false,
                            theme: theme,
                            onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          ),
                          SizedBox(width: 12.w),
                          // App Logo
                          ClipOval(
                            child: Image.asset(
                              'assets/images/logo_v6.png',
                              width: 40.w,
                              height: 40.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),

                      // Center: Title
                      Text(
                        title, 
                        style: GoogleFonts.lobster(
                          textStyle: theme.textTheme.titleLarge,
                          fontSize: 28.sp,
                          color: theme.primaryColor,
                        ),
                      ),

                      // Right: Plus + Search
                      Row(
                        children: [
                          AnimatedTopButton(
                            icon: Icons.add,
                            isBlue: false,
                            isCircle: true,
                            theme: theme,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateReelScreen(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          AnimatedTopButton(
                            icon: Icons.search,
                            isBlue: false,
                            isCircle: true,
                            theme: theme,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Category Tabs
                SizedBox(
                  height: 35.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final catKey = cat['key']!;
                      final catVal = cat['val']!; 
                      
                      final displayText = AppLocalizations.of(context).translate(catKey);
                      final isSelected = index == _currentCategoryIndex;
                          
                      return GestureDetector(
                        onTap: () {
                          // Animate Horizontal PageView to this index
                          _horizontalPageController.animateToPage(
                            index, 
                            duration: const Duration(milliseconds: 300), 
                            curve: Curves.easeInOut
                          );
                        },
                        child: _buildTab(displayText, isSelected, theme),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. Horizontal PageView for Categories
          Expanded(
            child: Consumer<ReelProvider>(
              builder: (context, reelProvider, _) {
                 // We use the full list from provider and filter locally
                 final allReels = reelProvider.reels;

                 return PageView.builder(
                    controller: _horizontalPageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                       setState(() {
                         _currentCategoryIndex = index;
                       });
                       // Optional: Sync back to provider if other parts of app depend on it, 
                       // but for now we are driving from local state for smooth UI.
                       // reelProvider.setCategory(_categories[index]['val']!);
                    },
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                        final catVal = _categories[index]['val'];
                        
                        // Local Filter
                        final filteredReels = (catVal == 'All')
                            ? allReels
                            : allReels.where((r) => r.category == catVal).toList();

                        // Pass isVisible to ensure only the active page plays video
                        return CategoryReelsFeed(
                           reels: filteredReels,
                           isVisible: index == _currentCategoryIndex,
                           onRefresh: () async => await reelProvider.fetchReels(),
                        );
                    },
                 );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(right: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isSelected ? theme.primaryColor : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              fontSize: 14.sp,
            ),
          ),
          if (isSelected)
            Container(
              height: 2,
              width: 25.w,
              color: theme.primaryColor,
              margin: const EdgeInsets.only(top: 4),
            ),
        ],
      ),
    );
  }

}

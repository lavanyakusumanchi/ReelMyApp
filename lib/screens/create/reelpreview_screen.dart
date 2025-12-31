import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/reel_provider.dart';
import '../../services/reel_service.dart';
import '../../theme/app_colors.dart';

class ReelPreviewScreen extends StatefulWidget {
  final File? logo;
  final String title;
  final String category;
  final String description;
  final File? audio;
  final List<File> images;
  final File thumbnail;
  final File video;
  final String? link;
  final bool isPaid;
  final double price;
  final bool isSingleImage;

  const ReelPreviewScreen({
    super.key,
    required this.title,
    required this.category,
    required this.description,
    this.audio,
    required this.images,
    required this.thumbnail,
    required this.video,
    this.link,
    this.logo,
    this.isPaid = false,
    this.price = 0.0,
    this.isSingleImage = false,
  });

  @override
  State<ReelPreviewScreen> createState() => _ReelPreviewScreenState();
}

class _ReelPreviewScreenState extends State<ReelPreviewScreen> {
  late VideoPlayerController _videoController;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(widget.video)
      ..initialize().then((_) {
        setState(() {}); // Refresh to show video
        _videoController.play();
        _videoController.setLooping(true);
      }).catchError((error) {
        print("🔴 [ReelPreview] Video Error: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load video: $error")),
        );
      });
      
    _videoController.addListener(() {
      if (_videoController.value.hasError) {
        print("🔴 [ReelPreview] Controller Error: ${_videoController.value.errorDescription}");
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _launchLink() async {
    if (widget.link == null || widget.link!.isEmpty) return;

    final Uri url = Uri.parse(widget.link!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not launch link")));
    }
  }

  Future<void> _postReel() async {
    setState(() => _isPosting = true);

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Authentication Error. Please login again."),
            ),
          );
        setState(() => _isPosting = false);
        return;
      }

      final success = await ReelService().createReel(
        title: widget.title,
        description: widget.description,
        category: widget.category,
        videoFile: widget.video,
        thumbnailFile: widget.thumbnail,
        link: widget.link ?? "",
        logo: widget.logo,
        token: token,
        isPaid: widget.isPaid,
        price: widget.price,
        isSingleImage: widget.isSingleImage,
      );

      if (!mounted) return;

      if (success) {
        // Refresh feed before showing success
        if (mounted) {
          await Provider.of<ReelProvider>(context, listen: false).fetchReels();
        }
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PostSuccessPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload reel. Try again.")),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final safeBottom = mq.viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1️⃣ Video Background
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  widget.thumbnail,
                  fit: BoxFit.cover,
                ),
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.neonCyan),
                  ),
                ),
              ],
            ),

          // 2️⃣ Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3️⃣ Content Overlay (Branding)
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Branding Bar (Logo + Title)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      if (widget.logo != null)
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            image: DecorationImage(
                              image: FileImage(widget.logo!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  const Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              widget.category,
                              style: TextStyle(
                                color: AppColors.neonCyan.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    widget.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      shadows: [
                        const Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 20),

                // Download App Button
                if (widget.link != null && widget.link!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: GestureDetector(
                      onTap: _launchLink,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2979FF), Color(0xFF00E5FF)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Download App",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Bottom Post Button
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, safeBottom + 20),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: _isPosting
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.neonCyan,
                            ),
                          )
                        : GestureDetector(
                            onTap: _postReel,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF33CCFF),
                                    Color(0xFF3366FF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3366FF,
                                    ).withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Post Reel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostSuccessPage extends StatelessWidget {
  const PostSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0720),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0720), Color(0xFF0F0A29)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 84,
                  color: Colors.greenAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your reel was posted!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'It will appear in your feed shortly.',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Feed',
                    style: TextStyle(color: Colors.white),
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

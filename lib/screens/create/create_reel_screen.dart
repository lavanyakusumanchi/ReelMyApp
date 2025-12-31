import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../services/reel_service.dart';
import 'reelpreview_screen.dart';

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  // Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();
  final _customCategoryController = TextEditingController(); // Added for Other category
  final _priceController = TextEditingController(); // Added for Price

  // State Variables
  String _selectedCategory = 'Business';
  bool _isPaid = false; // Added
  final List<String> _categories = [
    'Business',
    'Entertainment',
    'Education',
    'Lifestyle',
    'Technology',
    'Foodi',
    'Other',
  ];

  // Files
  File? _logoFile;
  File? _audioFile;
  String? _audioName;
  List<File> _limitImages = [];

  // Pickers
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    _customCategoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // 📂 File Picking Logic
  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _logoFile = File(image.path));
    }
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _audioFile = File(result.files.single.path!);
        _audioName = result.files.single.name;
      });
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _limitImages = images.map((e) => File(e.path)).toList();
      });
    }
  }

  // ✅ Validation & Generation
  Future<void> _createReel() async {
    final title = _titleController.text.trim();
    final link = _linkController.text.trim();
    final desc = _descController.text.trim();

    // 1️⃣ Validation
    if (title.isEmpty) {
      _showError("Please enter a title");
      return;
    }
    if (link.isEmpty) {
      _showError("Please enter an App Link");
      return;
    }
    if (desc.isEmpty) {
      _showError("Please enter a description");
      return;
    }
    if (_limitImages.isEmpty) {
      _showError("Please upload at least one image");
      return;
    }

    if (_selectedCategory == 'Other' && _customCategoryController.text.trim().isEmpty) {
      _showError("Please specify the category");
      return;
    }
    
    // Determine final category
    final categoryToUse = _selectedCategory == 'Other' 
        ? _customCategoryController.text.trim() 
        : _selectedCategory;

    final price = double.tryParse(_priceController.text) ?? 0.0;

    // 2️⃣ Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.neonCyan),
      ),
    );

    try {
      // 3️⃣ Call Backend to Generate
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final result = await ReelService().generateReel(
        title: title,
        link: link,
        images: _limitImages,
        audio: _audioFile,
        logo: _logoFile,
        token: token,
      );

      // Dismiss Loading
      if (mounted) Navigator.pop(context);

      if (result != null) {
        // 4️⃣ Success -> Download and navigate to Preview
        final videoUrl = result['video']!;
        final thumbUrl = result['thumbnail']!;

        print("📥 [CreateReel] Downloading Video from: $videoUrl");

        final tempDir = Directory.systemTemp;
        final videoPath =
            '${tempDir.path}/gen_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        await Dio().download(videoUrl, videoPath);

        final videoFile = File(videoPath);
        print("✅ [CreateReel] Video Downloaded to: $videoPath");
        print("📦 [CreateReel] Video Size: ${await videoFile.length()} bytes");

        final thumbPath =
            '${tempDir.path}/gen_thumb_${DateTime.now().millisecondsSinceEpoch}.png';
        await Dio().download(thumbUrl, thumbPath);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReelPreviewScreen(
                title: title,
                description: desc,
                category: categoryToUse, // Use custom category if applicable
                images: _limitImages,
                video: File(videoPath),
                thumbnail: File(thumbPath),
                logo: _logoFile,
                link: link,
                isPaid: _isPaid,
                price: price,
                isSingleImage: _limitImages.length == 1,
              ),
            ),
          );
        }
      } else {
        if (mounted)
          _showError("Generation failed on server. Please check backend logs.");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading
      String errorMsg = e.toString();
      if (e is DioException) {
        errorMsg = e.message ?? "Connection Error";
        if (e.response != null) {
          errorMsg += " (${e.response?.statusCode}: ${e.response?.data})";
        }
      }
      if (mounted) _showError("Error: $errorMsg");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Darker background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        "Create Reel",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Balance back button
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo & Title Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _pickLogo,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF252525),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.neonCyan.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                image: _logoFile != null
                                    ? DecorationImage(
                                        image: FileImage(_logoFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _logoFile == null
                                  ? const Icon(
                                      Icons.add_a_photo_outlined,
                                      color: Colors.white54,
                                      size: 28,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Reel Title",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildGlassTextField(
                                  controller: _titleController,
                                  hint: "Enter catchy title...",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      // Category Dropdown
                      const Text(
                        "Category",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: null, // Key fix: Value null prevents auto-scroll positioning
                            hint: Text(
                              _selectedCategory,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                            ),
                            dropdownColor: const Color(0xFF252525),
                            isExpanded: true,
                            menuMaxHeight: 300,
                            borderRadius: BorderRadius.circular(16),
                            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.neonCyan),
                            items: _categories.map((String category) {
                              final isSelected = category == _selectedCategory;
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      category,
                                      style: GoogleFonts.inter(
                                        color: isSelected ? AppColors.neonCyan : Colors.white,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    if (isSelected) 
                                      const Icon(Icons.check, color: AppColors.neonCyan, size: 18),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) => setState(() => _selectedCategory = newValue!),
                          ),
                        ),
                      ),
                      
                      // Custom Category Input
                      if (_selectedCategory == 'Other') ...[
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          controller: _customCategoryController,
                          hint: "Specify Category (e.g., Gaming)",
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        "Description",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildGlassTextField(
                        controller: _descController,
                        hint: "Tell your story...",
                        maxLines: 3,
                        height: 100,
                      ),

                      const SizedBox(height: 24),

                      // App Link
                      const Text(
                        "App Link (Optional)",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildGlassTextField(
                        controller: _linkController,
                        hint: "https://...",
                        icon: Icons.link,
                      ),

                      const SizedBox(height: 24),

                      // Paid App Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Is this a paid app?",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch(
                              value: _isPaid,
                              onChanged: (val) => setState(() => _isPaid = val),
                              activeColor: AppColors.neonCyan,
                              activeTrackColor: AppColors.neonCyan.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),

                      // Price Input (Conditional)
                      if (_isPaid) ...[
                        const SizedBox(height: 16),
                        const Text(
                          "Price (\$)",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildGlassTextField(
                          controller: _priceController,
                          hint: "Enter amount (e.g. 1.99)",
                          icon: Icons.attach_money,
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Media Actions
                      Row(
                        children: [
                          Expanded(
                            child: _buildMediaButton(
                              icon: Icons.music_note,
                              label: _audioName ?? "Audio",
                              color: const Color(0xFFE91E63),
                              onTap: _pickAudio,
                              isSelected: _audioFile != null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMediaButton(
                              icon: Icons.image,
                              label: _limitImages.isEmpty 
                                  ? "Images" 
                                  : "${_limitImages.length} Pics",
                              color: const Color(0xFF2196F3),
                              onTap: _pickImages,
                              isSelected: _limitImages.isNotEmpty,
                            ),
                          ),
                        ],
                      ),

                      if (_limitImages.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _limitImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 70,
                                    margin: const EdgeInsets.only(right: 12, top: 8), // Fixed duplicate right
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24),
                                      image: DecorationImage(
                                        image: FileImage(_limitImages[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _limitImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 48),

                      // Generate Button
                      GestureDetector(
                        onTap: _createReel,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0072FF).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "GENERATE REEL",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    double? height,
    IconData? icon,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: icon != null ? Icon(icon, color: Colors.white38, size: 20) : null,
          contentPadding: icon != null ? const EdgeInsets.only(top: 14) : null,
        ),
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF252525),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle : icon,
              color: isSelected ? color : Colors.white70,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

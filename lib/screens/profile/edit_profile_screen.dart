import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../utils/api_config.dart';
import '../../utils/app_localizations.dart';
import '../../utils/profile_photo_cropper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?['name'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (!mounted) return;
      final File? croppedFile = await ProfilePhotoCropper.cropImage(context, File(pickedFile.path));
      if (croppedFile != null) {
        setState(() {
          _imageFile = croppedFile;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
       final auth = Provider.of<AuthProvider>(context, listen: false);
       final success = await auth.updateProfile(
           _nameController.text.trim(), 
           _emailController.text.trim(), 
           _imageFile
       );

       if (success && mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(AppLocalizations.of(context).translate('profile_updated')))
           );
       } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(auth.errorMessage ?? AppLocalizations.of(context).translate('update_failed')))
           );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final currentAvatar = user?['profile_pic'];
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Dynamic background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(t.translate('edit_profile'), style: theme.textTheme.titleLarge), // Localized & Themed
        iconTheme: theme.iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
               // Avatar Picker
               GestureDetector(
                 onTap: _pickImage,
                 child: Stack(
                   children: [
                     Container(
                       width: 120, height: 120,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         color: isDark ? Colors.grey[800] : Colors.grey[200],
                         border: Border.all(color: theme.primaryColor, width: 2),
                         image: _imageFile != null 
                            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                            : (currentAvatar != null && currentAvatar.isNotEmpty)
                                ? DecorationImage(image: NetworkImage(ApiConfig.getFullVideoUrl(currentAvatar)), fit: BoxFit.cover)
                                : null
                       ),
                       child: (_imageFile == null && (currentAvatar == null || currentAvatar.isEmpty))
                           ? Icon(Icons.person, size: 60, color: isDark ? Colors.white54 : Colors.black54)
                           : null,
                     ),
                     Positioned(
                       bottom: 0, right: 0,
                       child: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: theme.primaryColor,
                           shape: BoxShape.circle
                         ),
                         child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                       ),
                     )
                   ],
                 ),
               ),
               
               const SizedBox(height: 30),

               // Name Field
               TextFormField(
                 controller: _nameController,
                 style: theme.textTheme.bodyLarge,
                 decoration: InputDecoration(
                   labelText: t.translate('name_label'),
                   labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                   filled: true,
                   fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                 ),
                 validator: (val) => val!.isEmpty ? t.translate('name_required') : null,
               ),
               
               const SizedBox(height: 20),
               
               // Email Field
               TextFormField(
                 controller: _emailController,
                 style: theme.textTheme.bodyLarge,
                 decoration: InputDecoration(
                   labelText: t.translate('email_label'),
                   labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                   filled: true,
                   fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                 ),
                 validator: (val) => val!.isEmpty ? t.translate('email_required') : null,
               ),
               
               const SizedBox(height: 40),
               
               // Save Button
               SizedBox(
                 width: double.infinity,
                 height: 50,
                 child: ElevatedButton(
                   onPressed: Provider.of<AuthProvider>(context).isLoading ? null : _saveProfile,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: theme.primaryColor,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                   ),
                   child: Provider.of<AuthProvider>(context).isLoading 
                       ? const CircularProgressIndicator(color: Colors.white)
                       : Text(t.translate('save_changes'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }
}

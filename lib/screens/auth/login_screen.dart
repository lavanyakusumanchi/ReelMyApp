import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../utils/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Animation Controllers
  late AnimationController _splashController;
  late AnimationController _moveUpController;
  late AnimationController _formController;
  late AnimationController _glowController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Alignment> _logoAlign;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;
  late Animation<double> _textFade;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // 1. Splash Entrance (Logo Scale & Fade)
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 200),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeInOut),
    );
    
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );

    // 2. Breathing Glow (Repeats)
    _glowController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glowOpacity = Tween<double>(begin: 0.2, end: 0.6).animate(
       CurvedAnimation(parent: _glowController, curve: Curves.easeInOut)
    );

    // 3. Move Up Transition
    _moveUpController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 200), // Slow, graceful
    );

    _logoAlign = Tween<Alignment>(
      begin: Alignment.center,
      end: const Alignment(0.0, -0.7), // Move to top area
    ).animate(
      CurvedAnimation(parent: _moveUpController, curve: Curves.easeInOutCubic),
    );

    // 4. Form Entrance
    _formController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 800),
    );

    _formSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
       CurvedAnimation(parent: _formController, curve: Curves.easeOutQuart),
    );
    
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
       CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
  }

  void _startAnimationSequence() async {
    // Stage 1: Splash In
    await _splashController.forward();
    
    // Stage 2: Pause
    await Future.delayed(const Duration(milliseconds: 800));

    // Stage 3: Transition (Move Up + Show Form)
    if (mounted) {
       _moveUpController.forward();
       // Stagger form slightly after movement starts
       Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _formController.forward();
       });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _splashController.dispose();
    _moveUpController.dispose();
    _formController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    final success = await auth.login(email, password);

    if (!success && mounted) {
      if (auth.errorMessage != null && auth.errorMessage!.contains("User not found")) {
         auth.clearError();
         showDialog(
           context: context, 
           builder: (context) => AlertDialog(
             backgroundColor: const Color(0xFF1F222E),
             title: const Text("Account Missing", style: TextStyle(color: Colors.white)),
             content: const Text("This email is not registered. Would you like to create an account?", style: TextStyle(color: Colors.white70)),
             actions: [
               TextButton(
                 onPressed: () => Navigator.pop(context), 
                 child: const Text("Cancel")
               ),
               TextButton(
                 onPressed: () {
                   Navigator.pop(context);
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (_) => const SignupScreen(initialEmail: null)),
                   );
                 }, 
                 child: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold))
               ),
             ],
           )
         );
      }
    }
  }

  Future<void> _googleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.googleLogin();
    
    if (!success && mounted) {
      if (auth.errorMessage != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1F222E),
              title: const Text("Google Sign-In Failed", style: TextStyle(color: Colors.white)),
              content: Text(
                auth.errorMessage ?? "Unknown Error",
                style: const TextStyle(color: Colors.white70)
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("OK")
                ),
              ],
            )
          );
      }
    }
  }

  Future<void> _showIpDialog() async {
    final ipController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F222E),
        title: const Text("Dev Options: Set Server IP", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your PC's LAN IP (e.g. 192.168.1.5)", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "192.168.x.x",
                hintStyle: TextStyle(color: Colors.white24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              ),
            ),
          ],
        ),
        actions: [
           TextButton(
             onPressed: () {
                ApiConfig.setCustomBaseUrl("");
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reverted to default (127.0.0.1)")));
             }, 
             child: const Text("Reset Default", style: TextStyle(color: Colors.redAccent))
           ),
           TextButton(
             onPressed: () {
               final ip = ipController.text.trim();
               if (ip.isNotEmpty) {
                 ApiConfig.setCustomBaseUrl(ip);
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server IP set to $ip")));
               }
             }, 
             child: const Text("Save")
           ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // 1. Logo & Branding (Animated Align)
          AnimatedBuilder(
            animation: _moveUpController,
            builder: (context, child) {
              return Align(
                alignment: _logoAlign.value,
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keep minimal height to center properly
              children: [
                 // Logo Gesture (IP Dialog)
                 GestureDetector(
                   onLongPress: _showIpDialog,
                   child: AnimatedBuilder(
                     animation: Listenable.merge([_splashController, _glowController]),
                     builder: (context, child) {
                       return Transform.scale(
                         scale: _logoScale.value,
                         child: Container(
                           width: 120.w,
                           height: 120.w,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             image: const DecorationImage(
                               image: AssetImage('assets/images/logo_v6.png'),
                               fit: BoxFit.cover,
                             ),
                             boxShadow: [
                               BoxShadow(
                                 color: const Color(0xFF6C63FF).withOpacity(_glowOpacity.value),
                                 blurRadius: 30,
                                 spreadRadius: 2,
                               )
                             ]
                           ),
                         ),
                       );
                     },
                   ),
                 ),
                 SizedBox(height: 16.h),
                 
                 // Text Branding
                 FadeTransition(
                   opacity: _textFade,
                   child: Column(
                     children: [
                       Text(
                         'ReelMyApp',
                         style: TextStyle(
                           fontSize: 28.sp,
                           fontWeight: FontWeight.bold,
                           color: Colors.white,
                         ),
                       ),
                       SizedBox(height: 8.h),
                       Text(
                         'Endless reels. Endless discovery.',
                         textAlign: TextAlign.center,
                         style: TextStyle(
                           fontSize: 14.sp,
                           color: Colors.white70,
                         ),
                       ),
                     ],
                   ),
                 ),
              ],
            ),
          ),

          // 2. Login Form (Slides up from bottom)
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _formSlide,
              child: FadeTransition(
                opacity: _formFade,
                child: Container(
                   height: 0.55.sh, // Take lower portion of screen
                   margin: EdgeInsets.only(bottom: 20.h),
                   padding: EdgeInsets.symmetric(horizontal: 20.w),
                   child: SingleChildScrollView(
                     // Wrap card content to avoid overflow
                     child: Container(
                       padding: EdgeInsets.all(20.w),
                       decoration: BoxDecoration(
                         color: const Color(0xFF151520),
                         borderRadius: BorderRadius.circular(20.r),
                         border: Border.all(color: Colors.white10),
                         boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            )
                         ]
                       ),
                       child: Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: const TextStyle(color: Colors.white60),
                                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white60),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.white24)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.white24)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
                                      filled: true,
                                      fillColor: Colors.transparent, 
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: Validators.validateEmail,
                                  ),
                                  SizedBox(height: 16.h),
      
                                  // Password
                                  TextFormField(
                                    controller: _passwordController,
                                    style: const TextStyle(color: Colors.white),
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: const TextStyle(color: Colors.white60),
                                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white60),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white60),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.white24)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.white24)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
                                      filled: true,
                                      fillColor: Colors.transparent,
                                    ),
                                    validator: Validators.validatePassword,
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
      
                                  // Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                         Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                                      },
                                      child: const Text('Forgot Password?', style: TextStyle(color: Colors.white70)),
                                    ),
                                  ),
                                  
                                  if (auth.errorMessage != null)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 12.h),
                                      child: Text(auth.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                                    ),
      
                                  // Login Button
                                  SizedBox(height: 12.h),
                                  Container(
                                    height: 50.h,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF2E8AF6), Color(0xFF6C63FF)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30.r),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                                      ),
                                      child: auth.isLoading
                                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                          : Text('Login', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
      
                                  SizedBox(height: 24.h),
                                  Row(
                                    children: [
                                      const Expanded(child: Divider(color: Colors.white24)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                                        child: const Text('or', style: TextStyle(color: Colors.white54)),
                                      ),
                                      const Expanded(child: Divider(color: Colors.white24)),
                                    ],
                                  ),
                                  SizedBox(height: 24.h),
      
                                  // Social Buttons Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: auth.isGoogleLoading ? null : _googleLogin,
                                          icon: auth.isGoogleLoading 
                                            ? const SizedBox(
                                                width: 24, 
                                                height: 24, 
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                              )
                                            : const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                                          label: Text(auth.isGoogleLoading ? 'Loading...' : 'Continue with Google', style: const TextStyle(color: Colors.white, fontSize: 16)),
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(vertical: 12.h),
                                            side: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 20.h),
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.center,
                                     children: [
                                       const Text("New to Reel My App? ", style: TextStyle(color: Colors.white60)),
                                       GestureDetector(
                                         onTap: () {
                                             final auth = Provider.of<AuthProvider>(context, listen: false);
                                             auth.clearError();
                                             Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                                         },
                                         child: const Text('Sign Up', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                                       ),
                                     ],
                                   ),
                                ],
                              ),
                            );
                          }
                       ),
                     ),
                   ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


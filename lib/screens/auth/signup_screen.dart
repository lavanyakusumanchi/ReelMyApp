import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import 'login_screen.dart'; // For navigation back 

class SignupScreen extends StatefulWidget {
  final String? initialEmail;
  const SignupScreen({super.key, this.initialEmail});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the Terms & Conditions')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.signup(name, email, password);

    if (success && mounted) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1F222E),
          title: const Text('Success', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Account created successfully! Please login with your credentials.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to Login Screen
              },
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (mounted) {
       // Check for "Email already exists" error
       if (auth.errorMessage != null && auth.errorMessage!.contains("Email already exists")) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1F222E),
              title: const Text('Account Exists', style: TextStyle(color: Colors.white)),
              content: const Text(
                'An account with this email already exists. Would you like to login instead?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(); // Go back to Login
                  },
                  child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
       }
    }
  }

  Widget _buildStrengthIndicator() {
    // Determine strength
    String password = _passwordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    Color color = Colors.red;
    if (strength > 2) color = Colors.orange;
    if (strength > 4) color = Colors.green;

    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
      child: Row(
        children: [
           Expanded(
             child: LinearProgressIndicator(
               value: strength / 5,
               backgroundColor: Colors.grey[800],
               color: color,
               minHeight: 4,
             ),
           ),
           SizedBox(width: 10.w),
           Text(
             strength <= 2 ? 'Weak' : (strength <= 4 ? 'Medium' : 'Strong'),
             style: TextStyle(color: color, fontSize: 12.sp),
           ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Dark background
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               // Header (Consistent with Login)
               Container(
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
                       color: const Color(0xFF6C63FF).withOpacity(0.3),
                       blurRadius: 20,
                       spreadRadius: 5,
                     )
                   ]
                 ),
               ),
               SizedBox(height: 16.h),
               Text(
                 'Create Account',
                 style: TextStyle(
                   fontSize: 28.sp,
                   fontWeight: FontWeight.bold,
                   color: Colors.white,
                 ),
               ),
               SizedBox(height: 8.h),
               Text(
                 'Join ReelFlow today.',
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 14.sp,
                   color: Colors.white70,
                 ),
               ),
               SizedBox(height: 32.h),

               // Card Container
               Container(
                 padding: EdgeInsets.all(20.w),
                 decoration: BoxDecoration(
                   color: const Color(0xFF151520), // Slightly lighter card bg
                   borderRadius: BorderRadius.circular(20.r),
                   border: Border.all(color: Colors.white10),
                 ),
                 child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Name
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: const TextStyle(color: Colors.white60),
                                prefixIcon: const Icon(Icons.person_outline, color: Colors.white60),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.white24)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.white24)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: Validators.validateName,
                            ),
                            SizedBox(height: 16.h),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
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
                              validator: Validators.validateSignupPassword,
                              onChanged: (_) => setState(() {}),
                            ),
                            _buildStrengthIndicator(),
                            SizedBox(height: 16.h),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              style: const TextStyle(color: Colors.white),
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                labelStyle: const TextStyle(color: Colors.white60),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white60),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white60),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.white24)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.white24)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Confirm Password is required';
                                if (val != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            SizedBox(height: 24.h),

                            // Terms
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreedToTerms, 
                                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                                  fillColor: MaterialStateProperty.all(const Color(0xFF6C63FF)),
                                ),
                                const Expanded(child: Text("I agree to the Terms & Conditions", style: TextStyle(color: Colors.white70))),
                              ],
                            ),
                            SizedBox(height: 16.h),

                            if (auth.errorMessage != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: Text(auth.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                              ),

                            // Create Account Button
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
                                  padding: EdgeInsets.symmetric(vertical: 0.h), // Remove vertical padding to let container control height
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                                ),
                                child: auth.isLoading
                                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                    : Text('Create Account', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),

                            SizedBox(height: 24.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Already have an account? ", style: TextStyle(color: Colors.white60)),
                                GestureDetector(
                                  onTap: () {
                                     Navigator.pop(context);
                                  },
                                  child: const Text('Sign In', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                 ),
               ),
               
               SizedBox(height: 20.h),
               const Text(
                   "By creating an account, you agree to our Terms of Service and Privacy Policy",
                   textAlign: TextAlign.center,
                   style: TextStyle(color: Colors.white38, fontSize: 10),
               )
            ],
          ),
        ),
      ),
    );
  }
}

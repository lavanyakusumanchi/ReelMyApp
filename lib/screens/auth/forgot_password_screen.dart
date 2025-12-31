import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Step 0: Email, 1: OTP, 2: New Password, 3: Success
  int _currentStep = 0;
  
  // Timer
  Timer? _timer;
  int _start = 60; // 1 minute
  bool _canResend = false;

  void startTimer() {
    setState(() {
      _start = 60; 
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  String get timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Logic ---

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty || Validators.validateEmail(_emailController.text) != null) {
        // Simple manual validation check since we aren't using Form strictly everywhere
        return; 
    }
    
    final success = await context.read<AuthProvider>().sendOtp(_emailController.text.trim());
    if (success) {
      setState(() => _currentStep = 1);
      startTimer();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length < 6) return;
    final success = await context.read<AuthProvider>().verifyOtp(_emailController.text.trim(), _otpController.text.trim());
    if (success) {
      setState(() => _currentStep = 2);
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text.length < 8) return;
    if (_passwordController.text != _confirmPasswordController.text) return;

    final success = await context.read<AuthProvider>().resetPasswordWithOtp(
      _emailController.text.trim(), 
      _otpController.text.trim(), 
      _passwordController.text
    );
    
    if (success) {
      setState(() => _currentStep = 3);
    }
  }

  // --- UI Components ---

  Widget _buildStep1Email() {
    return Column(
      children: [
        Icon(Icons.lock_reset, size: 80.w, color: const Color(0xFF6C63FF)),
        SizedBox(height: 24.h),
        Text('Forgot Password', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8.h),
        const Text('Enter your email to receive a verification code.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        SizedBox(height: 32.h),
        TextFormField(
           controller: _emailController,
           style: const TextStyle(color: Colors.white),
           validator: Validators.validateEmail,
           decoration: _inputDecoration('Email Address', Icons.email_outlined),
        ),
        SizedBox(height: 24.h),
        _buildGradientButton(
             label: "Send Code", 
             onPressed: _sendOtp
        )
      ],
    );
  }

  Widget _buildStep2Otp() {
    return Column(
      children: [
        Icon(Icons.mark_email_unread_outlined, size: 80.w, color: const Color(0xFF6C63FF)),
        SizedBox(height: 24.h),
        Text('Verification', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8.h),
        Text('Enter the 6-digit code sent to\n${_emailController.text}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        SizedBox(height: 32.h),
        
        // OTP Input (Simple Text Field for now, can be PinPut later)
        TextFormField(
           controller: _otpController,
           style: TextStyle(color: Colors.white, fontSize: 24.sp, letterSpacing: 8),
           textAlign: TextAlign.center,
           keyboardType: TextInputType.number,
           maxLength: 6,
           decoration: _inputDecoration('OTP Code', Icons.lock_clock),
        ),
        SizedBox(height: 16.h),
        
        Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Text("Expires in $timerText", style: const TextStyle(color: Colors.grey)),
             if (_canResend) ...[
                 SizedBox(width: 10.w),
                 GestureDetector(
                     onTap: _sendOtp,
                     child: const Text("Resend", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold))
                 )
             ]
           ]
        ),
        
        SizedBox(height: 24.h),
        _buildGradientButton(
             label: "Verify", 
             onPressed: _verifyOtp
        )
      ],
    );
  }

  Widget _buildStep3NewPassword() {
     // Password Strength Logic
     String pwd = _passwordController.text;
     bool hasUpper = pwd.contains(RegExp(r'[A-Z]'));
     bool hasLower = pwd.contains(RegExp(r'[a-z]'));
     bool hasDigits = pwd.contains(RegExp(r'[0-9]'));
     bool hasSpecial = pwd.contains(RegExp(r'[!@#\$&*~]'));
     bool minLen = pwd.length >= 8;
     
     int strength = 0;
     if (minLen) strength++;
     if (hasUpper) strength++;
     if (hasLower) strength++;
     if (hasDigits) strength++;
     if (hasSpecial) strength++;

     Color strengthColor = Colors.red;
     if (strength > 2) strengthColor = Colors.orange;
     if (strength > 4) strengthColor = Colors.green;

    return Column(
      children: [
        Icon(Icons.shield_outlined, size: 80.w, color: const Color(0xFF6C63FF)),
        SizedBox(height: 24.h),
        Text('New Password', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 32.h),
        
        TextFormField(
           controller: _passwordController,
           style: const TextStyle(color: Colors.white),
           obscureText: true,
           onChanged: (_) => setState((){}),
           decoration: _inputDecoration('New Password', Icons.lock_outline),
        ),
        SizedBox(height: 8.h),
        // Strength Indicator
        Row(
           children: [
              Expanded(child: Container(height: 4, margin: const EdgeInsets.only(right: 5), color: strength >= 1 ? strengthColor : Colors.grey[800])),
              Expanded(child: Container(height: 4, margin: const EdgeInsets.only(right: 5), color: strength >= 2 ? strengthColor : Colors.grey[800])),
              Expanded(child: Container(height: 4, margin: const EdgeInsets.only(right: 5), color: strength >= 3 ? strengthColor : Colors.grey[800])),
              Expanded(child: Container(height: 4, color: strength >= 4 ? strengthColor : Colors.grey[800])),
           ]
        ),
        SizedBox(height: 4.h),
        Align(
            alignment: Alignment.centerRight,
            child: Text(
                strength < 3 ? "Weak" : (strength < 5 ? "Medium" : "Strong"),
                style: TextStyle(color: strengthColor, fontSize: 12.sp)
            )
        ),
        
        SizedBox(height: 16.h),
        TextFormField(
           controller: _confirmPasswordController,
           style: const TextStyle(color: Colors.white),
           obscureText: true,
           decoration: _inputDecoration('Confirm Password', Icons.lock_outline),
        ),

        SizedBox(height: 24.h),
        _buildGradientButton(
             label: "Reset Password", 
             onPressed: _resetPassword
        )
      ],
    );
  }
  
  Widget _buildStep4Success() {
      return Column(
          children: [
              Icon(Icons.check_circle_outline, size: 80.w, color: Colors.greenAccent),
              SizedBox(height: 24.h),
              Text('Success!', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 16.h),
              const Text('Your password has been reset successfully.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              SizedBox(height: 32.h),
              _buildGradientButton(
                  label: "Login Now", 
                  onPressed: () => Navigator.pop(context)
              )
          ]
      );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white60),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
        filled: true,
        fillColor: const Color(0xFF151520),
      );
  }

  Widget _buildGradientButton({required String label, required VoidCallback onPressed}) {
      return Container(
        height: 50.h,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E8AF6), Color(0xFF6C63FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: ElevatedButton(
          onPressed: context.watch<AuthProvider>().isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
          ),
          child: context.watch<AuthProvider>().isLoading 
             ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
             : Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );
  }


  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
                if (_currentStep == 0) _buildStep1Email(),
                if (_currentStep == 1) _buildStep2Otp(),
                if (_currentStep == 2) _buildStep3NewPassword(),
                if (_currentStep == 3) _buildStep4Success(),
                
                 if (auth.errorMessage != null)
                   Padding(
                     padding: EdgeInsets.only(top: 20.h),
                     child: Text(
                       auth.errorMessage!,
                       style: const TextStyle(color: Colors.red),
                       textAlign: TextAlign.center,
                     ),
                   ),
                   
                 if (_currentStep < 3)
                   Padding(
                     padding: EdgeInsets.only(top: 16.h),
                     child: TextButton(
                       onPressed: () {
                           if (_currentStep == 0) Navigator.pop(context);
                           else setState(() => _currentStep--);
                       },
                       child: Text(_currentStep == 0 ? 'Back to Login' : 'Back', style: const TextStyle(color: Colors.white70)),
                     ),
                   ),
            ]
          ),
        ),
      ),
    );
  }
}

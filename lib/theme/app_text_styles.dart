import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get title => GoogleFonts.poppins(
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get body => GoogleFonts.poppins(
    color: Colors.white,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    color: Colors.white54,
    fontSize: 12,
  );
}

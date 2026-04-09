import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle h1({Color? color}) {
    return GoogleFonts.montserrat(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  static TextStyle h2({Color? color}) {
    return GoogleFonts.montserrat(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle texto({Color? color}) {
    return GoogleFonts.montserrat(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle boton({Color? color}) {
    return GoogleFonts.montserrat(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle etiqueta({Color? color}) {
    return GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle microEtiqueta({Color? color}) {
    return GoogleFonts.montserrat(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }
}
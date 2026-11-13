import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Cores {
  static const fundo = Color(0xFF0B1220);
  static const fundoEscuro = Color(0xFF070B14);
  static const superficie = Color(0x0BFFFFFF);
  static const superficie2 = Color(0x13FFFFFF);
  static const superficieSolida = Color(0xFF101828);
  static const texto = Color(0xFFE7EEFC);
  static const textoSuave = Color(0xB3E7EEFC);
  static const textoFraco = Color(0x7AE7EEFC);
  static const borda = Color(0x1CE7EEFC);
  static const bordaForte = Color(0x33E7EEFC);

  static const marca = Color(0xFF7C3AED);
  static const marcaClara = Color(0xFF8B5CF6);
  static const marcaEscura = Color(0xFF6D28D9);
  static const lilas = Color(0xFFC4B5FD);
  static const verde = Color(0xFF22C55E);
  static const verdeClaro = Color(0xFF86EFAC);
  static const azul = Color(0xFF38BDF8);
  static const azulClaro = Color(0xFF7DD3FC);
  static const amarelo = Color(0xFFF59E0B);
  static const amareloClaro = Color(0xFFFCD34D);
  static const vermelho = Color(0xFFEF4444);
  static const vermelhoClaro = Color(0xFFFCA5A5);
}

ThemeData temaCcam() {
  final base = ThemeData.dark(useMaterial3: true);
  final texto = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: Cores.texto,
    displayColor: Cores.texto,
  );

  return base.copyWith(
    scaffoldBackgroundColor: Cores.fundo,
    colorScheme: const ColorScheme.dark(
      primary: Cores.marcaClara,
      secondary: Cores.verde,
      surface: Cores.superficieSolida,
      error: Cores.vermelho,
      onPrimary: Colors.white,
      onSurface: Cores.texto,
    ),
    textTheme: texto,
    dividerColor: Cores.borda,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Cores.superficieSolida,
      contentTextStyle: GoogleFonts.inter(color: Cores.texto, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Cores.bordaForte),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x8C070B14),
      labelStyle: const TextStyle(color: Cores.textoSuave),
      hintStyle: const TextStyle(color: Cores.textoFraco),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.bordaForte),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.bordaForte),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.marcaClara, width: 1.5),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF111A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF111A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Cores.bordaForte),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xF20A0F1B),
      indicatorColor: Cores.marca.withValues(alpha: 0.28),
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => GoogleFonts.inter(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? Cores.texto : Cores.textoFraco,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? Cores.lilas : Cores.textoFraco,
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Cores.marcaClara),
  );
}

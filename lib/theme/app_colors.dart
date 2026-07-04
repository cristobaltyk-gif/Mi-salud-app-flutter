/// lib/theme/app_colors.dart
///
/// Paleta de marca HypokratIA, usada en toda la app.
library;

import 'package:flutter/material.dart';

// --- Marca principal ---
const Color kHypoBlue = Color(0xFF1A3B8C);       // azul primario (logo, botones)
const Color kHypoBlueDark = Color(0xFF0F235A);   // azul oscuro (títulos, énfasis)
const Color kHypoBlueLight = Color(0xFF5E7FCB);  // azul claro (hover, fondos suaves)

const Color kHypoTeal = Color(0xFF0F9B8E);       // turquesa primario (acentos, íconos)
const Color kHypoTealDark = Color(0xFF0B2E45);   // turquesa oscuro (fondos, gradientes)
const Color kHypoTealLight = Color(0xFF5FCFC0);  // turquesa claro (chips, badges)

// --- Gradiente de marca (pantallas de bienvenida/login) ---
const List<Color> kHypoGradient = [kHypoBlue, kHypoTealDark, Color(0xFF071A26)];

// --- Superficies y fondos ---
const Color kHypoBackground = Color(0xFFF4F7FB); // fondo general de la app
const Color kHypoSurface = Colors.white;          // cards, sheets
const Color kHypoBorder = Color(0xFFE1E7F0);      // bordes sutiles, dividers

// --- Texto ---
const Color kHypoTextPrimary = Color(0xFF13213B);
const Color kHypoTextSecondary = Color(0xFF5A6B85);
const Color kHypoTextOnBrand = Colors.white;      // texto sobre fondos azul/teal

// --- Estados ---
const Color kHypoSuccess = Color(0xFF1E9E6B);
const Color kHypoWarning = Color(0xFFE0A100);
const Color kHypoError = Color(0xFFD64545);
const Color kHypoInfo = Color(0xFF3B82C4);

// --- Triage clínico (heredado de MiSalud: ROJO/NARANJO/AMARILLO/VERDE) ---
const Color kTriageRojo = Color(0xFFD64545);
const Color kTriageNaranjo = Color(0xFFE07B39);
const Color kTriageAmarillo = Color(0xFFE0A100);
const Color kTriageVerde = Color(0xFF1E9E6B);

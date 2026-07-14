import 'package:flutter/material.dart';

/// AURA COUTURE — Unified Color Palette
/// Primary: #0F766E | All tokens match the website & admin panel.
class AppColors {
  AppColors._(); // non-instantiable

  // ── PRIMARY TEAL ────────────────────────────────────────────
  static const Color primary       = Color(0xFF0F766E); // Premium Teal
  static const Color primaryHover  = Color(0xFF115E59); // Hover/pressed state
  static const Color primaryLight  = Color(0xFFCCFBF1); // Tinted background
  static const Color primaryBorder = Color(0xFF99F6E4); // Border accent
  static const Color primaryBg     = Color(0xFFF0FDFA); // Subtle teal surface

  // ── SECONDARY / ACCENT ─────────────────────────────────────
  static const Color secondary = Color(0xFF64748B); // Slate 500
  static const Color accent    = Color(0xFFF59E0B); // Amber — warm accent

  // ── STATUS ──────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A); // Green 600
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color danger  = Color(0xFFDC2626); // Red 600
  static const Color info    = Color(0xFF0F766E); // Use primary teal

  // ── NEUTRAL / BACKGROUND ────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface    = Color(0xFFFFFFFF); // Pure white card
  static const Color border     = Color(0xFFE2E8F0); // Slate 200
  static const Color divider    = Color(0xFFCBD5E1); // Slate 300

  // ── TEXT ────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A); // Slate 900 — heading
  static const Color textBody      = Color(0xFF334155); // Slate 700 — body
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textDisabled  = Color(0xFF94A3B8); // Slate 400
  static const Color textLight     = Color(0xFF94A3B8); // Alias for disabled

  // ── ERROR ───────────────────────────────────────────────────
  static const Color error = Color(0xFFDC2626); // Danger red

  // ════════════════════════════════════════════════════════════
  // DARK THEME
  // ════════════════════════════════════════════════════════════

  // ── DARK PRIMARY ────────────────────────────────────────────
  static const Color darkPrimary       = Color(0xFF14B8A6); // Teal 500 — brighter in dark
  static const Color darkPrimaryHover  = Color(0xFF0D9488); // Teal 600
  static const Color darkPrimaryLight  = Color(0xFF042F2E); // Deep teal tint
  static const Color darkPrimaryBorder = Color(0xFF115E59); // Dark teal border
  static const Color darkPrimaryBg     = Color(0xFF022C2A); // Subtle dark teal surface

  // ── DARK SECONDARY / ACCENT ─────────────────────────────────
  static const Color darkSecondary = Color(0xFF475569); // Slate 600
  static const Color darkAccent    = Color(0xFFD97706); // Amber 600

  // ── DARK STATUS ─────────────────────────────────────────────
  static const Color darkSuccess = Color(0xFF059669); // Emerald 600
  static const Color darkWarning = Color(0xFFF59E0B); // Amber 500
  static const Color darkDanger  = Color(0xFFF43F5E); // Rose 500
  static const Color darkInfo    = Color(0xFF14B8A6);

  // ── DARK NEUTRAL ────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF050505);
  static const Color darkSurface    = Color(0xFF0A0A0A);
  static const Color darkBorder     = Color(0xFF1E1E1E);
  static const Color darkDivider    = Color(0xFF262626);

  // ── DARK TEXT ───────────────────────────────────────────────
  static const Color darkTextPrimary   = Color(0xFFF1F5F9); // Slate 100
  static const Color darkTextBody      = Color(0xFFCBD5E1); // Slate 300
  static const Color darkTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color darkTextDisabled  = Color(0xFF475569); // Slate 600
  static const Color darkTextLight     = Color(0xFF475569); // Alias

  // ── DARK ERROR ──────────────────────────────────────────────
  static const Color darkError = Color(0xFFF43F5E); // Rose 500
}

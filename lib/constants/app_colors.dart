import 'package:flutter/material.dart';

/// FCI SELLER — Unified Color Palette
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
  static const Color darkPrimary       = Color(0xFF2DD4BF); // Teal 400 — brighter and more vibrant
  static const Color darkPrimaryHover  = Color(0xFF14B8A6); // Teal 500
  static const Color darkPrimaryLight  = Color(0xFF134E4A); // Soft teal tint for backgrounds
  static const Color darkPrimaryBorder = Color(0xFF0F766E); // Original primary for borders
  static const Color darkPrimaryBg     = Color(0xFF0D3D3A); // Soft teal surface

  // ── DARK SECONDARY / ACCENT ─────────────────────────────────
  static const Color darkSecondary = Color(0xFF94A3B8); // Slate 400 — lighter for better contrast
  static const Color darkAccent    = Color(0xFFFBBF24); // Amber 400 — warmer and more visible

  // ── DARK STATUS ─────────────────────────────────────────────
  static const Color darkSuccess = Color(0xFF34D399); // Emerald 400 — brighter
  static const Color darkWarning = Color(0xFFFCD34D); // Amber 300 — more visible
  static const Color darkDanger  = Color(0xFFF87171); // Red 400 — softer but clear
  static const Color darkInfo    = Color(0xFF2DD4BF); // Match dark primary

  // ── DARK NEUTRAL ────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900 — deep blue-gray
  static const Color darkSurface    = Color(0xFF1E293B); // Slate 800 — elevated surfaces
  static const Color darkBorder     = Color(0xFF334155); // Slate 700 — visible borders
  static const Color darkDivider    = Color(0xFF475569); // Slate 600 — subtle dividers

  // ── DARK TEXT ───────────────────────────────────────────────
  static const Color darkTextPrimary   = Color(0xFFF8FAFC); // Slate 50 — crisp white
  static const Color darkTextBody      = Color(0xFFE2E8F0); // Slate 200 — readable body
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400 — secondary text
  static const Color darkTextDisabled  = Color(0xFF64748B); // Slate 500 — disabled state
  static const Color darkTextLight     = Color(0xFF94A3B8); // Alias for disabled

  // ── DARK ERROR ──────────────────────────────────────────────
  static const Color darkError = Color(0xFFF87171); // Red 400 — consistent with danger
}

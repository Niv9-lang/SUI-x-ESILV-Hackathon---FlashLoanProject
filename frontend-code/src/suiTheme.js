// src/suiTheme.js
import { lightTheme } from "@mysten/dapp-kit";

export const darkBunniLikeTheme = {
  // On part du thème officiel
  ...lightTheme,

  // ---------- TYPO ----------
  typography: {
    ...lightTheme.typography,
    fontFamily:
      'Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif',
    lineHeight: "1.5",
    letterSpacing: "0.4",
  },

  fontSizes: {
    ...lightTheme.fontSizes,
    small: "22px",   // au lieu de 14px
    medium: "24px",  // au lieu de 16px
    large: "26px",   // au lieu de 18px
    xlarge: "28px",  // au lieu de 20px
  },

  // ---------- FLOU (overlay) ----------
  blurs: {
    ...lightTheme.blurs,
    modalOverlay: "blur(0px)",
  },

  // ---------- FONDS ----------
  backgroundColors: {
    ...lightTheme.backgroundColors,

    // overlay derrière le modal
    modalOverlay: "rgba(15, 23, 42, 0.85)",

    // fond du modal
    modalPrimary: "#020617",   // bg principal
    modalSecondary: "#020617", // colonne de gauche

    // boutons & items
    primaryButton: "#111827",
    primaryButtonHover: "#1f2937",
    outlineButtonHover: "#0f172a",
    iconButton: "transparent",
    iconButtonHover: "#020617",
    dropdownMenu: "#020617",
    dropdownMenuSeparator: "#111827",
    walletItemSelected: "#020617",
    walletItemHover: "#111827",
  },

  // ---------- COULEURS DE TEXTE / ICONES ----------
  colors: {
    ...lightTheme.colors,
    primaryButton: "#e5e7eb", // texte bouton principal
    outlineButton: "#e5e7eb",
    iconButton: "#e5e7eb",
    body: "#e5e7eb",          // texte principal du modal
    bodyMuted: "#94a3b8",     // texte secondaire
    bodyDanger: "#f97316",    // messages d’erreur
  },

  // ---------- SHADOWS ----------
  shadows: {
    ...lightTheme.shadows,
    primaryButton: "0 4px 18px rgba(0, 0, 0, 0.5)",
    walletItemSelected: "0 0 0 1px rgba(148, 163, 184, 0.6)",
  },
};

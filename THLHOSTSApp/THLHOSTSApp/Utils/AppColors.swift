import UIKit
import SwiftUI

// MARK: - Design System Token Map
//
//  Background Layers  (dark → less dark)
//  ───────────────────────────────────────
//  appBackground   #030712   Deepest OLED black-blue
//  appPrimary      #0D1117   Card / section fill
//  appSecondary    #141C2B   Row / elevated surface
//  appDivider      #1E293B   Borders & separators
//
//  Text  (bright → muted)
//  ───────────────────────────────────────
//  appText         #CBD5E1   Primary text   (slate-300, soft white)
//  appSubText      #94A3B8   Secondary text (slate-400)
//  appMutedText    #475569   Disabled / hint (slate-600)
//
//  Accent
//  ───────────────────────────────────────
//  appCTA          #698df9   Brand blue-violet (user-specified)
//  appCTADim       #698df9·60 Dimmed brand (for bg tint)
//  appSuccess      #34D399   Active/enabled green
//  appWarning      #FBBF24   Warning amber
//  appDestructive  #F87171   Error / delete red

// MARK: - UIColor tokens
extension UIColor {

    // Backgrounds
    public static var appBackground: UIColor  { UIColor(hex: "#030712") }
    public static var appPrimary: UIColor     { UIColor(hex: "#0D1117") }
    public static var appSecondary: UIColor   { UIColor(hex: "#141C2B") }
    public static var appDivider: UIColor     { UIColor(hex: "#1E293B") }

    // Text
    public static var appText: UIColor        { UIColor(hex: "#CBD5E1") }
    public static var appSubText: UIColor     { UIColor(hex: "#94A3B8") }
    public static var appMutedText: UIColor   { UIColor(hex: "#475569") }

    // Accent
    public static var appCTA: UIColor         { UIColor(hex: "#698df9") }
    public static var appSuccess: UIColor     { UIColor(hex: "#34D399") }
    public static var appWarning: UIColor     { UIColor(hex: "#FBBF24") }
    public static var appDestructive: UIColor { UIColor(hex: "#F87171") }
}

// MARK: - SwiftUI Color tokens
extension Color {
    // Backgrounds
    public static var appBackground: Color  { Color(uiColor: .appBackground) }
    public static var appPrimary: Color     { Color(uiColor: .appPrimary) }
    public static var appSecondary: Color   { Color(uiColor: .appSecondary) }
    public static var appDivider: Color     { Color(uiColor: .appDivider) }

    // Text
    public static var appText: Color        { Color(uiColor: .appText) }
    public static var appSubText: Color     { Color(uiColor: .appSubText) }
    public static var appMutedText: Color   { Color(uiColor: .appMutedText) }

    // Accent
    public static var appCTA: Color         { Color(uiColor: .appCTA) }
    public static var appSuccess: Color     { Color(uiColor: .appSuccess) }
    public static var appWarning: Color     { Color(uiColor: .appWarning) }
    public static var appDestructive: Color { Color(uiColor: .appDestructive) }

    // Derived semantic aliases (for backward compat)
    public static var appAccent: Color      { Color(uiColor: .appCTA).opacity(0.75) }
}

// MARK: - Hex Initialization
extension UIColor {
    convenience init(hex: String) {
        let hexHash = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexHash).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexHash.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 105, 141, 249)  // fallback: appCTA
        }
        self.init(
            red:   CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue:  CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

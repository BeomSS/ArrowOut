import SwiftUI
import UIKit

public struct AppTheme: Sendable {
    public let isDark: Bool

    public init(isDark: Bool) {
        self.isDark = isDark
    }

    // MARK: - SwiftUI Colors
    public var backgroundColor: Color {
        isDark ? Color(red: 0.07, green: 0.08, blue: 0.12) : Color(red: 0.965, green: 0.972, blue: 0.985)
    }

    public var surfaceColor: Color {
        isDark ? Color(red: 0.13, green: 0.15, blue: 0.21) : Color.white
    }

    public var primaryText: Color {
        isDark ? Color(red: 0.95, green: 0.96, blue: 0.99) : Color(red: 0.11, green: 0.13, blue: 0.19)
    }

    public var secondaryText: Color {
        isDark ? Color(red: 0.60, green: 0.64, blue: 0.74) : Color(red: 0.45, green: 0.49, blue: 0.58)
    }

    public var accentColor: Color {
        Color(red: 0.24, green: 0.48, blue: 0.96)
    }

    public var heartActiveColor: Color {
        Color(red: 0.95, green: 0.25, blue: 0.34)
    }

    public var heartLostColor: Color {
        isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.10)
    }

    // MARK: - SpriteKit / UIKit Colors
    public var sceneBackgroundUIColor: UIColor {
        isDark
            ? UIColor(red: 0.07, green: 0.08, blue: 0.12, alpha: 1.0)
            : UIColor(red: 0.965, green: 0.972, blue: 0.985, alpha: 1.0)
    }

    public var gridDotUIColor: UIColor {
        isDark
            ? UIColor(white: 1.0, alpha: 0.11)
            : UIColor(red: 0.76, green: 0.80, blue: 0.86, alpha: 0.55)
    }

    /// Clean minimalist monochrome arrow ink (no multi-color palette).
    public var arrowInkUIColor: UIColor {
        isDark
            ? UIColor(red: 0.93, green: 0.95, blue: 0.99, alpha: 1.0)
            : UIColor(red: 0.11, green: 0.13, blue: 0.19, alpha: 1.0)
    }

    /// Persistent crimson red applied to an arrow after a failed tap until it escapes.
    public var arrowFailedUIColor: UIColor {
        UIColor(red: 0.95, green: 0.22, blue: 0.31, alpha: 1.0)
    }

    public var hintGlowUIColor: UIColor {
        isDark
            ? UIColor(red: 1.0, green: 0.84, blue: 0.28, alpha: 1.0)
            : UIColor(red: 0.98, green: 0.68, blue: 0.12, alpha: 1.0)
    }

    public var celebrationColors: [UIColor] {
        [
            UIColor(red: 0.24, green: 0.52, blue: 0.98, alpha: 1.0),
            UIColor(red: 0.16, green: 0.78, blue: 0.56, alpha: 1.0),
            UIColor(red: 0.98, green: 0.72, blue: 0.18, alpha: 1.0),
            UIColor(red: 0.95, green: 0.32, blue: 0.42, alpha: 1.0)
        ]
    }
}

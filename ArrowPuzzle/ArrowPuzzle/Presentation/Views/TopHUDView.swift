import SwiftUI

public struct TopHUDView: View {
    @ObservedObject var viewModel: GameViewModel

    public var body: some View {
        let theme = viewModel.theme

        VStack(spacing: 10) {
            HStack(spacing: 12) {
                #if DEBUG
                // Debug-only level selector trigger
                Button {
                    viewModel.isLevelSheetPresented = true
                } label: {
                    levelBadgeContent(theme: theme, showChevron: true)
                }
                #else
                levelBadgeContent(theme: theme, showChevron: false)
                #endif

                Spacer()

                // Quick settings pills (Theme / Sound / Haptics)
                HStack(spacing: 6) {
                    HUDIconToggle(
                        systemName: viewModel.isDarkTheme ? "sun.max.fill" : "moon.fill",
                        isActive: true,
                        theme: theme,
                        action: viewModel.toggleTheme
                    )
                    HUDIconToggle(
                        systemName: viewModel.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                        isActive: viewModel.isSoundEnabled,
                        theme: theme,
                        action: viewModel.toggleSound
                    )
                    HUDIconToggle(
                        systemName: viewModel.isHapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash",
                        isActive: viewModel.isHapticsEnabled,
                        theme: theme,
                        action: viewModel.toggleHaptics
                    )
                }
            }

            // Hearts + Progress Bar Row
            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    ForEach(0..<viewModel.maxHearts, id: \.self) { index in
                        let isFilled = index < viewModel.hearts
                        Image(systemName: isFilled ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isFilled ? theme.heartActiveColor : theme.heartLostColor)
                            .scaleEffect(isFilled ? 1.0 : 0.86)
                            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: viewModel.hearts)
                    }
                }

                Spacer()

                // Remaining arrow counter + slim progress track
                HStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(theme.secondaryText.opacity(0.18))
                            Capsule()
                                .fill(theme.accentColor)
                                .frame(width: max(0, geo.size.width * viewModel.clearProgress))
                                .animation(.easeOut(duration: 0.22), value: viewModel.clearProgress)
                        }
                    }
                    .frame(width: 72, height: 6)

                    Text("남은 화살표 \(viewModel.remainingArrows)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(theme.surfaceColor.opacity(0.94), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(theme.isDark ? 0.22 : 0.05), radius: 8, y: 2)

            if let subtitle = viewModel.levelSubtitle {
                HStack(spacing: 6) {
                    if viewModel.boardShape != .rectangle {
                        Image(systemName: viewModel.boardShape.symbolName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.accentColor)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.accentColor)
                    }
                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.surfaceColor.opacity(0.88), in: Capsule())
                .shadow(color: .black.opacity(theme.isDark ? 0.2 : 0.04), radius: 6, y: 2)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: 640)
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private func levelBadgeContent(theme: AppTheme, showChevron: Bool) -> some View {
        HStack(spacing: 6) {
            Text("LV. \(viewModel.levelNumber)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            if viewModel.isHardChallenge {
                Text("HARD")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.heartActiveColor, in: Capsule())
            }
            HStack(spacing: 3) {
                if viewModel.boardShape != .rectangle {
                    Image(systemName: viewModel.boardShape.symbolName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.accentColor)
                }
                Text(viewModel.gridDimensionsText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(theme.secondaryText.opacity(0.14), in: Capsule())
            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .foregroundStyle(theme.primaryText)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(theme.surfaceColor, in: Capsule())
        .shadow(color: .black.opacity(theme.isDark ? 0.25 : 0.06), radius: 8, y: 3)
    }
}

private struct HUDIconToggle: View {
    let systemName: String
    let isActive: Bool
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isActive ? theme.primaryText : theme.secondaryText.opacity(0.55))
                .frame(width: 36, height: 36)
                .background(theme.surfaceColor, in: Circle())
                .shadow(color: .black.opacity(theme.isDark ? 0.24 : 0.06), radius: 6, y: 2)
        }
    }
}

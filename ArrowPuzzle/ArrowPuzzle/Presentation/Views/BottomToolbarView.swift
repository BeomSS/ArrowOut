import SwiftUI

public struct BottomToolbarView: View {
    @ObservedObject var viewModel: GameViewModel

    public var body: some View {
        let theme = viewModel.theme

        HStack(spacing: 14) {
            ToolbarActionButton(
                icon: "arrow.counterclockwise",
                title: "다시하기",
                tint: theme.primaryText,
                theme: theme,
                action: viewModel.restartCurrentLevel
            )

            ToolbarActionButton(
                icon: "lightbulb.fill",
                title: "힌트",
                tint: Color(red: 0.96, green: 0.66, blue: 0.14),
                theme: theme,
                action: viewModel.requestHint
            )

            ToolbarActionButton(
                icon: "viewfinder",
                title: "화면맞춤",
                tint: theme.accentColor,
                theme: theme,
                action: viewModel.resetCamera
            )
        }
        .frame(maxWidth: 460)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

private struct ToolbarActionButton: View {
    let icon: String
    let title: LocalizedStringKey
    let tint: Color
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(theme.surfaceColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(theme.isDark ? 0.28 : 0.07), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}

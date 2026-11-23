import SwiftUI

public struct LevelCompleteOverlay: View {
    @ObservedObject var viewModel: GameViewModel

    public var body: some View {
        let theme = viewModel.theme

        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.16, green: 0.76, blue: 0.54).opacity(0.16))
                        .frame(width: 72, height: 72)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(Color(red: 0.16, green: 0.76, blue: 0.54))
                }

                VStack(spacing: 6) {
                    Text("레벨 \(viewModel.levelNumber) 클리어!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryText)

                    Text("모든 화살표를 완벽하게 탈출시켰습니다.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                }

                HStack(spacing: 12) {
                    StatBadge(title: "소요 시간", value: formatDuration(viewModel.elapsedSeconds), theme: theme)
                    StatBadge(title: "남은 하트", value: "\(viewModel.hearts)/\(viewModel.maxHearts)", theme: theme)
                    StatBadge(title: "힌트", value: String(localized: "\(viewModel.hintsUsedCount)회"), theme: theme)
                }

                VStack(spacing: 10) {
                    Button(action: viewModel.advanceToNextLevel) {
                        HStack(spacing: 8) {
                            Text("다음 레벨 \(viewModel.levelNumber + 1)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(theme.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Button(action: viewModel.restartCurrentLevel) {
                        Text("이 레벨 다시 플레이")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.secondaryText)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background(theme.surfaceColor, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 24, y: 12)
            .padding(.horizontal, 28)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.94)))
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return mins > 0 ? String(format: "%d:%02d", mins, secs) : String(localized: "\(secs)초")
    }
}

private struct StatBadge: View {
    let title: LocalizedStringKey
    let value: String
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .monospacedDigit()
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(theme.secondaryText.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

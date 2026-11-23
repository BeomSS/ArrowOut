import SwiftUI

public struct GameOverOverlay: View {
    @ObservedObject var viewModel: GameViewModel

    public var body: some View {
        let theme = viewModel.theme

        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(theme.heartActiveColor.opacity(0.16))
                        .frame(width: 72, height: 72)
                    Image(systemName: "heart.slash.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(theme.heartActiveColor)
                }

                VStack(spacing: 6) {
                    Text("하트를 모두 사용했어요")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryText)

                    Text("화살표 앞이 막히지 않았는지 확인하고\n다시 도전해 보세요!")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                Button(action: viewModel.restartCurrentLevel) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15, weight: .bold))
                        Text("레벨 \(viewModel.levelNumber) 다시 도전")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(theme.heartActiveColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
}

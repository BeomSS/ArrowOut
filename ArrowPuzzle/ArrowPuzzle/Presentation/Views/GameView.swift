import SwiftUI

public struct GameView: View {
    @StateObject private var viewModel: GameViewModel

    public init(viewModel: GameViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        let theme = viewModel.theme

        ZStack {
            // Full-screen interactive SpriteKit puzzle canvas
            PuzzleBoardView(scene: viewModel.scene)
                .ignoresSafeArea()

            // Floating Minimalist HUD
            VStack {
                TopHUDView(viewModel: viewModel)
                Spacer()
                BottomToolbarView(viewModel: viewModel)
            }

            // Modals
            if viewModel.phase == .levelComplete {
                LevelCompleteOverlay(viewModel: viewModel)
            } else if viewModel.phase == .gameOver {
                GameOverOverlay(viewModel: viewModel)
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .preferredColorScheme(theme.isDark ? .dark : .light)
        #if DEBUG
        .sheet(isPresented: $viewModel.isLevelSheetPresented) {
            LevelSelectSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        #endif
    }
}

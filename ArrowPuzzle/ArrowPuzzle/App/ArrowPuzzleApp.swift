import SwiftUI

@main
struct ArrowPuzzleApp: App {
    private let container = DIContainer()

    var body: some Scene {
        WindowGroup {
            GameView(viewModel: container.makeGameViewModel())
        }
    }
}
